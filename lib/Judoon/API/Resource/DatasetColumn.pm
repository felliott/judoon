package Judoon::API::Resource::DatasetColumn;

use Moo;

extends 'Web::Machine::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Item';

1;
__END__