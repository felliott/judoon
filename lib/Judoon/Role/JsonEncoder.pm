package Judoon::Role::JsonEncoder;

use JSON::MaybeXS qw(JSON);

use Moo::Role;


has _json_encoder => (
   is => 'ro',
   lazy => 1,
   builder => '_build_json_encoder',
   handles => {
      encode_json => 'encode',
      decode_json => 'decode',
   },
);

sub _build_json_encoder { JSON->new->utf8(1); }


1;
__END__


=pod

=encoding utf8

=head1 NAME

Judoon::Role::JsonEncoder - basic JSON encoding/decoding support

=head1 DESCRIPTION

This role holds a JSON encoder/decoder object.  utf8 support is turned
on by default.

=head1 Methods

=head2 encode_json( $perl_struct )

Produces the JSON representation of C<$perl_struct>.

=head2 decode_json( $json_string )

Turns a valid JSON string into a perl data structure.

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
