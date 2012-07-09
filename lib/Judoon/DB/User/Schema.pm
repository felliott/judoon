use utf8;
package Judoon::DB::User::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-05-15 21:44:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0l6zHRqmj0fSyhLXxLAuog

=pod

=encoding utf8

=head2 C<$VERSION>

C<$VERSION> is very important for the DBIx::Class::Migration scripts
to work

=cut

our $VERSION = 3;

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
