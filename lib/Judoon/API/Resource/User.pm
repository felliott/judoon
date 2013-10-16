package Judoon::API::Resource::User;

use Moo;
use namespace::clean;

extends 'Web::Machine::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Item';

sub update_allows { return qw(name); }
sub update_ignore { return qw(created modified); }
sub update_valid  { return {}; }
with 'Judoon::API::Resource::Role::ValidateParams';


sub allowed_methods {
    my ($self) = @_;
     return [
        qw(GET HEAD),
        ( $_[0]->writable ) ? (qw(PUT)) : ()
    ];
}


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::API::Resource::User - An individual User

=head1 DESCRIPTION

See L</Web::Machine::Resource>.

=head1 METHODS

=head2 update_allows()

List of updatable parameters.

=cut
