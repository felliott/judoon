use utf8;
package Judoon::DB::User::Schema;

our $VERSION = '2.001';

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;