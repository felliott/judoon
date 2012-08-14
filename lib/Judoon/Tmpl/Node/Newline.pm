package Judoon::Tmpl::Node::Newline;

use Moose;
use namespace::autoclean;

with qw(
    Judoon::Tmpl::Node::Role::Base
    Judoon::Tmpl::Node::Role::Composite
    Judoon::Tmpl::Node::Role::Formatting
);

use Method::Signatures;

has '+type' => (default => 'newline',);

method decompose { return $self->make_text_node("<br>"); }

__PACKAGE__->meta->make_immutable;

1;
__END__
