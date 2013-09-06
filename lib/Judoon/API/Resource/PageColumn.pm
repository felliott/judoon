package Judoon::API::Resource::PageColumn;

use Moo;

extends 'Web::Machine::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Item';

use Judoon::Tmpl;

around update_resource => sub {
    my $orig = shift;
    my $self = shift;
    my $data = shift;

    if (my $jstmpl = delete $data->{template}) {
        my $tmpl   = Judoon::Tmpl->new_from_jstmpl($jstmpl);
        $data->{template} = $tmpl;
    }
    elsif (my $widgets = delete $data->{widgets}) {
        my $tmpl = Judoon::Tmpl->new_from_data($widgets);
        $data->{template} = $tmpl;
    }
    return $self->$orig($data);
};

1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::API::Resource::PageColumn - An individual PageColumn

=head1 DESCRIPTION

See L</Web::Machine::Resource>.

=head1 METHODS

=head2 update_resource

Translate the C<template> parameter into a L<Judoon::Tmpl> object
suitable for insertion into the database.

=cut
