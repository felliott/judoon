package Judoon::Schema::Result::Token;

=pod

=for stopwords

=encoding utf8

=head1 NAME

Judoon::Schema::Result::Token - unique action tokens

=cut

use Moo;
extends 'Judoon::Schema::Result';


use Data::Entropy::Algorithms qw/rand_bits/;
use DateTime;
use MIME::Base64 qw/encode_base64url/;


__PACKAGE__->table("tokens");
__PACKAGE__->add_columns(
    id => {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    value => {
        data_type     => "text",
        is_nullable   => 0,
        dynamic_default_on_create => \&_build_value,
    },
    expires => {
        data_type     => 'timestamp with time zone',
        is_nullable   => 0,
        dynamic_default_on_create => \&_build_expires,
    },
    action => {
        data_type   => "text",
        is_nullable => 0,
    },
    user_id => {
        data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 0,
    },
);


__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("token_value_is_uniq", ["value"]);


__PACKAGE__->belongs_to(
    user => "::User",
    { "foreign.id" => "self.user_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


sub _build_value {
    my ($self) = @_;
    return encode_base64url( rand_bits(192) );
}

sub _build_expires {
    my ($self) = @_;
    return DateTime->now->add(hours => 24);
}


=head1 METHODS

=head2 password_reset()

Sets the C<action> column to 'password_reset'.

=cut

sub password_reset { return $_[0]->action('password_reset'); }


=head2 is_expired

Return true if C<Token>'s C<expires> field is less than now.

=cut

sub is_expired {
    my ($self) = @_;
    return DateTime->compare($self->expires, DateTime->now) != 1;
}

1;