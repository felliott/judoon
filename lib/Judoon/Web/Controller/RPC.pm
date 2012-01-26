package Judoon::Web::Controller::RPC;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

has rpc => (
    is  => 'ro',
    isa => 'HashRef',
);

__PACKAGE__->config(
    rpc => {
        template_dir => undef,
        stash_key    => undef,
    },
);


sub base      : Chained('fixme') PathPart('fixme')      CaptureArgs(0) { shift->private_base(        @_); }
sub list      : Chained('base')  PathPart('')           Args(0)        { shift->private_list(        @_); }
sub add       : Chained('base')  PathPart('add')        Args(0)        { shift->private_add(         @_); }
sub add_do    : Chained('base')  PathPart('add_do')     Args(0)        { shift->private_add_do(      @_); }
sub id        : Chained('base')  PathPart('')           CaptureArgs(1) { shift->private_id(          @_); }
sub view      : Chained('id')    PathPart('')           Args(0)        { shift->private_view(        @_); }
sub edit      : Chained('id')    PathPart('edit')       Args(0)        { shift->private_edit(        @_); }
sub edit_do   : Chained('id')    PathPart('edit_do')    Args(0)        { shift->private_edit_do(     @_); }
sub delete    : Chained('id')    PathPart('delete')     Args(0)        { shift->private_delete(      @_); }
sub delete_do : Chained('id')    PathPart('delete_do')  Args(0)        { shift->private_delete_do(   @_); }


sub private_base :Private {}

sub private_list :Private {
    my ($self, $c) = @_;
    my $key                 = $self->rpc->{stash_key};
    $c->stash->{$key}{list} = $self->get_list($c);
    $c->stash->{template}   = $self->rpc->{template_dir} . '/list.tt2';
}

sub private_add :Private {
    my ($self, $c) = @_;
    $c->stash->{template} = $self->rpc->{template_dir} . '/add.tt2';
}

sub private_add_do :Private {
    my ($self, $c) = @_;
    my $params = $self->munge_add_params($c);
    my $id     = $self->add_object($c, $params);
    $c->res->redirect($c->uri_for_action('view', [@{$c->req->captures}, $id]));
}

sub private_id :Private {
    my ($self, $c, $id) = @_;
    my $key                   = $self->rpc->{stash_key};
    $c->stash->{$key}{id}     = $self->validate_id($c, $id);
    $c->stash->{$key}{object} = $self->get_object($c);
}

sub private_view :Private {
    my ($self, $c) = @_;
    $c->stash->{template}   = $self->rpc->{template_dir} . '/view.tt2';
}

sub private_edit :Private {
    my ($self, $c) = @_;
    $c->stash->{template}   = $self->rpc->{template_dir} . '/edit.tt2';
}

sub private_edit_do :Private {
    my ($self, $c) = @_;
    my $params                = $self->munge_edit_params($c);
    my $key                   = $self->rpc->{stash_key};
    $c->stash->{$key}{object} = $self->edit_object($c, $params);
    $c->stash->{template}     = $self->rpc->{template_dir} . '/edit.tt2';
}

sub private_delete :Private {
    my ($self, $c) = @_;
    $c->stash->{template}   = $self->rpc->{template_dir} . '/delete.tt2';
}

sub private_delete_do :Private {
    my ($self, $c) = @_;
    $self->delete_object($c);
    my @captures = @{$c->req->captures};
    pop @captures;
    $c->res->redirect($c->uri_for_action('list', \@captures));
}


sub get_list          :Private { return [];    }
sub munge_add_params  :Private { return $_[1]->req->params; }
sub add_object        :Private { return undef; }
sub validate_id       :Private { return $_[2]; }
sub get_object        :Private { return undef; }
sub munge_edit_params :Private { return $_[1]->req->params; }
sub edit_object       :Private { return undef; }
sub delete_object     :Private { return;       }


__PACKAGE__->meta->make_immutable;

1;
__END__
