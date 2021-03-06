package Judoon::Schema::Result::TtDscolumnDatatype;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::Result::TtDscolumnDatatype

=cut

use Judoon::Schema::Candy;

use Moo;
use namespace::clean;


table 'tt_dscolumn_datatypes';

primary_column data_type => {
    data_type   => "text",
    is_nullable => 0,
};


has_many ds_columns => "::DatasetColumn",
    { "foreign.data_type" => "self.data_type" };


1;
__END__

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
