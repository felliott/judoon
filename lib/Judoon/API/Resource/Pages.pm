package Judoon::API::Resource::Pages;

use Moo;

extends 'Web::Machine::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Set';

1;
__END__