package Judoon::Web::Controller::Page;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Page - display public pages

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }

with qw(
    Judoon::Web::Controller::Role::PublicDirectory
    Judoon::Role::JsonEncoder
);


__PACKAGE__->config(
    action => {
        base => { Chained => '/base', PathPart => 'page', },
    },

    resultset_class => 'User::Page',
    stash_key       => 'page',
    template_dir    => 'public_page',
);



=head1 METHODS

=head2 populate_stash

Fill in the stash with the necessary data.

=cut

sub populate_stash {
    my ($self, $c, $page) = @_;

    $c->stash->{dataset}{id} = $page->dataset_id;
    my @page_columns = $page->page_columns_ordered->all;
    $c->stash->{page_column}{templates}
        = [map {$_->template->to_jstmpl} @page_columns];
    $c->stash->{page_column}{list} = [map {$_->TO_JSON} @page_columns];
    return;
}


__PACKAGE__->meta->make_immutable;
1;
__END__
