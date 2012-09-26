package Judoon::Tmpl::Node::Variable;

use Moose;
use namespace::autoclean;

with qw(
    Judoon::Tmpl::Node::Role::Base
    Judoon::Tmpl::Node::Role::Formatting
);

use Method::Signatures;

our $AUTHORITY = '';

has '+type' => (default => 'variable',);
has name => (is => 'ro', isa => 'Str', required => 1,);

method decompose() { return $self; }

__PACKAGE__->meta->make_immutable;

1;
__END__
