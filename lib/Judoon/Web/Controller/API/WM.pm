package Judoon::Web::Controller::API::WM;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::WM - dispatcher to our Judoon::API::Machine::* modules

=head1 DESCRIPTION

This controller manages permissions and dispatch requests for our
L</Web::Machine>-based REST API.

=cut

use Moose;
use namespace::autoclean;

BEGIN {extends 'Judoon::Web::Controller'; }

use Judoon::API::Machine;
use Module::Load;
use HTTP::Response;
use HTTP::Throwable::Factory qw(http_throw);


=head1 Methods

=head2 wm( $c, $machine_class, $machine_args )

Construct a L</Web::Machine::Resource> app of class C<$machine_class>
with the given arguments (C<$machine_args>).

=cut

sub wm {
    my ($self, $c, $machine_class, $machine_args) = @_;
    load $machine_class;
    Judoon::API::Machine->new(
        resource      => $machine_class,
        resource_args => [ %{ $machine_args } ],
    )->to_app;
}


=head1 Actions

=head2 wm_base

The base action for all other actions.

=cut

sub wm_base : Chained('/api/base') PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;
}


=head1 Unauthenticated Actions

These actions are available to all users and do not require any sort
of authentication.

 /users
 /users/$username
 /users/$username/datasets
 /users/$username/pages
 /public_datasets
 /public_pages

=head2 user_base / users / user_id / user

Public information about Judoon users.

=cut

sub user_base : Chained('wm_base') PathPart('users') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash->{user_rs} = $c->model('User::User');
}
sub users : Chained('user_base') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::Users', {
            set      => $c->model('User::User'),
            writable => 0,
        }
    );
}
sub user_id : Chained('user_base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    $c->stash->{user_id}     = $id;
    $c->stash->{user_object} = $c->stash->{user_rs}->find({username => $id});
}
sub user : Chained('user_id') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::User', {
            item     => $c->stash->{user_object},
            writable => 0,
        }
    );
}

=head2 public_datasets / public_pages

Return lists of publicly available datasets and pages.

=cut

sub public_datasets : Chained('wm_base') PathPart('public_datasets') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::Datasets', {
            set      => $c->model('User::Dataset')->public(),
            writable => 0,
        }
    );
}
sub public_pages : Chained('wm_base') PathPart('public_pages') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::Pages', {
            set      => $c->model('User::Page')->public(),
            writable => 0,
        }
    );
}



=head1 Authenticated Routes

These routes require that the user be authenticated.  They return
information about the authenticated user.

 /user
 /user/datasets
 /user/pages

=head2 authd_user_base / authd_user / authd_user_datasets / authd_user_pages

Validate the authenticated user, then return information about
themselves, their datasets, or their pages.

=cut

sub authd_user_base : Chained('wm_base') PathPart('user') CaptureArgs(0) {
    my ($self, $c) = @_;
    if ($c->user) {
        $c->stash->{authd_user} = $c->user->get_object;
    }
    else {
        #http_throw(Unauthorized => {www_authenticate => "moo"});
        $c->res->status(401);
        $c->res->body('');
        $c->detach;
    }
}
sub authd_user : Chained('authd_user_base') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::User', {
            item     => $c->stash->{authd_user},
            writable => 0,
        }
    );
}
sub authd_user_datasets : Chained('authd_user_base') PathPart('datasets') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::Datasets', {
            set      => $c->stash->{authd_user}->datasets_rs,
            writable => 0,
        }
    );
}
sub authd_user_pages : Chained('authd_user_base') PathPart('pages') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::Pages', {
            set      => $c->stash->{authd_user}->pages_rs,
            writable => 0,
        }
    );
}



=head1 Primary Resource Routes

These are the routes for our primary data structures, Datasets and
Pages.  These routes will have different methods available to them
depending upon whether the user is logged in, and if the logged-in
user owns the requested resource id.

 GET requires $is_public || ($authd && $authd->owns($ds_id))
 POST PUT DELETE requires $authd && $authd->owns($ds_id)

 /datasets *XXX NO! XXX*
 /datasets/$ds_id (GET,PUT,DELETE)
 /datasets/$ds_id/columns (GET, POST, DELETE)
 /datasets/$ds_id/columns/$dscol_id (GET,PUT,DELETE) (not really delete)
 /datasets/$ds_id/pages (GET)
 /datasets/$ds_id/data (GET)

 GET requires $is_public || ($authd && $authd->owns($ds_id))
 POST PUT DELETE requires $authd && $authd->owns($ds_id)

 /pages *XXX NO! XXX*
 /pages/$page_id (GET, PUT, DELETE)
 /pages/$page_id/columns (GET, POST, DELETE)
 /pages/$page_id/columns/$dscol_id (GET, PUT, DELETE)

=head2 dataset_base / datasets / dataset_id / dataset


=cut

sub mixed_base : Chained('wm_base') PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;
    if ($c->user) {
        $c->stash->{authd_user} = $c->user->get_object;
    }
}

sub dataset_base : Chained('mixed_base') PathPart('datasets') CaptureArgs(0) {}
sub datasets : Chained('dataset_base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    if ($c->req->method eq 'GET') {
        $self->go_here($c, '/api/wm/public_datasets');
    }
    else {
        $c->res->status(405);
        $c->res->body('');
    }
    $c->detach;
}
sub dataset_id : Chained('dataset_base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    $id //= '';
    $c->stash->{dataset_id}     = $id;
    $c->stash->{dataset_object} = $c->model('User::Dataset')->find({id => $id});

    if (not $c->stash->{dataset_object}) {
        # http_throw('NotFound');
        $c->res->status(404);
        $c->res->body('');
        $c->detach;
    }

    my $is_public = !$c->stash->{dataset_object}->is_private;
    $c->stash->{authd_owns} = $c->stash->{authd_user}
        && $c->stash->{authd_user}->datasets_rs->search({id => $id})->count;

    #http_throw('NotFound')
    unless ($is_public || $c->stash->{authd_owns}) {
        $c->res->status(404);
        $c->res->body('');
        $c->detach;
    }

}
sub dataset : Chained('dataset_id') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::Dataset', {
            item      => $c->stash->{dataset_object},
            writable  => $c->stash->{authd_owns},
        }
    );
}


=head2 dscol_base() / dscols() / dscol()

Chains off of the parent dataset's C<dataset_id> action.  Actions are
restricted to the parent dataset's columns.

=cut

sub dscol_base : Chained('dataset_id') PathPart('columns') CaptureArgs(0) {
    my ($self, $c) = @_;
    my $ds = $c->stash->{dataset_object};
    $c->stash->{dscol_rs} = $ds ? $ds->ds_columns_ordered : undef;
}
sub dscols : Chained('dscol_base') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::DatasetColumns', {
            set       => $c->stash->{dscol_rs},
            writable  => $c->stash->{authd_owns},
        }
    );
}
sub dscol : Chained('dscol_base') PathPart('') Args(1) ActionClass('FromPSGI') {
    my ($self, $c, $id) = @_;
    my $item = $c->stash->{dscol_rs}
        ? $c->stash->{dscol_rs}->find($id) : undef;
    return $self->wm(
        $c, 'Judoon::API::Resource::DatasetColumn', {
            item      => $item,
            writable  => $c->stash->{authd_owns},
        }
    );
}


=head2 ds_page()

Get the list of pages for the given dataset.

=cut

sub ds_page : Chained('dataset_id') PathPart('pages') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::Pages', {
            set       => $c->stash->{dataset_object}->pages_ordered,
            writable  => 0,
        }
    );
}


=head2 ds_data()

Get the data the given dataset.

=cut

sub ds_data : Chained('dataset_id') PathPart('data') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    #http_throw(NotImplemented => {message => 'Fitz is still working on this'});
    $c->res->status(501);
    $c->res->body('Fitz is still working on this');
    $c->detach;
}



=head2 page_base / pages / page_id / page

Authenticated users get full access to their pages and read access
to public pages.

=cut

sub page_base : Chained('mixed_base') PathPart('pages') CaptureArgs(0) {}
sub pages : Chained('page_base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    if ($c->req->method eq 'GET') {
        $self->go_here($c, '/api/wm/public_pages');
    }
    else {
        $c->res->status(405);
        $c->res->body('');
    }
    $c->detach;
}
sub page_id : Chained('page_base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    $id //= '';
    $c->stash->{page_id}     = $id;
    $c->stash->{page_object} = $c->model('User::Page')->find({id => $id});

    if (not $c->stash->{page_object}) {
        # http_throw('NotFound');
        $c->res->status(404);
        $c->res->body('');
        $c->detach;
    }

    my $is_public = !$c->stash->{page_object}->is_private;
    $c->stash->{authd_owns}      = $c->stash->{authd_user}
        && $c->stash->{authd_user}->pages_rs->search({id => $id})->count;

    #http_throw('NotFound')
    unless ($is_public || $c->stash->{authd_owns}) {
        $c->res->status(404);
        $c->res->body('');
        $c->detach;
    }
}
sub page : Chained('page_id') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c, $id) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::Page', {
            item      => $c->stash->{page_object},
            writable  => $c->stash->{authd_owns},
        }
    );
}


=head2 pagecol_base() / pagecols() / pagecol()

Chains off of the parent page's C<page_id> action.  Actions are
restricted to the parent page's columns.

=cut

sub pagecol_base : Chained('page_id') PathPart('columns') CaptureArgs(0) {
    my ($self, $c) = @_;
    my $page = $c->stash->{page_object};
    $c->stash->{pagecol_rs} = $page ? $page->page_columns_ordered : undef;
}
sub pagecols : Chained('pagecol_base') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::PageColumns', {
            set       => $c->stash->{pagecol_rs},
            writable  => $c->stash->{authd_owns},
        }
    );
}
sub pagecol : Chained('pagecol_base') PathPart('') Args(1) ActionClass('FromPSGI') {
    my ($self, $c, $id) = @_;
    my $item = $c->stash->{pagecol_rs}
        ? $c->stash->{pagecol_rs}->find({id => $id}) : undef;
    return $self->wm(
        $c, 'Judoon::API::Resource::PageColumn', {
            item      => $item,
            writable  => $c->stash->{authd_owns},
        }
    );
}



1;
__END__
