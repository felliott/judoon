package Judoon::Web::Controller::Private::Dataset;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Private::Dataset - dataset actions

=head1 DESCRIPTION

The RESTful controller for managing actions on one or more datasets.

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::ControllerBase::Private'; }
with qw(
    Judoon::Web::Controller::Role::TabularData
);

use JSON qw(encode_json);

__PACKAGE__->config(
    action => {
        base => { Chained => '/user/id', PathPart => 'dataset', },
    },
    rpc => {
        template_dir => 'dataset',
        stash_key    => 'dataset',
        api_path     => 'dataset',
    },
);


my $SPREADSHEET_MAX_SIZE = 10_000_000;


before private_base => sub {
    my ($self, $c) = @_;
    if (!$c->stash->{user}{is_owner} and $c->req->method ne 'GET') {
        $self->set_error_and_redirect(
            $c, 'You must be the owner to do this', ['/login/login'],
        );
        $c->detach;
    }
};


=head2 list_GET

Send user to their overview page.

=cut

override list_GET => sub {
    my ($self, $c) = @_;
    $self->go_here($c, '/user/edit');
};



=head1 list_POST

Create a basic page for the user after creating the dataset

=cut

before list_POST => sub {
    my ($self, $c) = @_;
    if (not $c->req->params->{'dataset.file'}) {
        $self->set_error_and_redirect(
            $c, 'No file provided',
            ['/user/edit', [$c->stash->{user}{id}]],
        );
        $c->detach();
    }
    elsif ($c->req->upload('dataset.file')->size > $SPREADSHEET_MAX_SIZE)  {
        $self->set_error_and_redirect(
            $c, 'Your spreadsheet is too big. It must be less than 10 megabytes.',
            ['/user/edit', [$c->stash->{user}{id}]],
        );
        $c->detach();
    }
};

after list_POST => sub {
    my ($self, $c) = @_;
    my $dataset = $c->req->get_object(0)->[0];
    $dataset->create_basic_page();
};


=head2 object_GET (after)

Add the dataset's first page to the stash.

=cut

after object_GET => sub {
    my ($self, $c) = @_;

    my $dataset = $c->req->get_object(0)->[0];

    my $view = $c->req->param('view') // '';
    if (!$c->stash->{user}{is_owner} || $view eq 'preview') {
        my @ds_columns = $dataset->ds_columns_ordered->all;
        $c->stash->{dataset_column}{list} = \@ds_columns;
        $c->stash->{column_names_json} = encode_json([map {$_->shortname} @ds_columns]);
        $c->stash->{template} = 'dataset/preview.tt2';
        $c->detach();
    }


    my $data_table = $dataset->data_table;
    my $headers = shift @$data_table;
    $self->table_view(
        $c, $view, $dataset->name,
        $headers, $data_table,
    );

    if (my (@pages) = $dataset->pages_rs->all) {
        $c->stash->{page}{list} = [
            map {{ $_->get_columns }} @pages
        ];
    }

    my @all_pages;
    for my $ds ($c->user->obj->datasets_rs->all) {
        push @all_pages, $ds->pages_rs->all;
    }
    $c->stash->{all_pages}{list} = \@all_pages;
};



=head2 object_DELETE (after)

return to user overview instead of dataset list

=cut

after object_DELETE => sub {
    my ($self, $c) = @_;
    my @captures = @{$c->req->captures};
    pop @captures;
    $self->go_here($c, '/user/edit', \@captures);
};


__PACKAGE__->meta->make_immutable;

1;
__END__
