package Judoon::Tmpl::Node::Text;

=pod

=encoding utf8

=head1 NAME

Judoon::Tmpl::Node::Text - A Node that represents static text

=cut

use Moose;
use namespace::autoclean;

with qw(
    Judoon::Tmpl::Node::Role::Base
    Judoon::Tmpl::Node::Role::Formatting
);


=head1 ATTRIBUTES

=head2 value

The string represented by the node.

=cut

has '+type' => (default => 'text',);
has value => (is => 'ro', isa => 'Str', required => 1,);


=head1 METHODS

=head2 decompose

A C<Text> node is one of the base node types and so decomposes to
itself.

=cut

sub decompose { return shift; }



__PACKAGE__->meta->make_immutable;

1;
__END__
