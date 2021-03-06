package Judoon::Web::Model::LookupRegistry;

use Moose;
use namespace::autoclean;
extends 'Catalyst::Model::Factory::PerRequest';

__PACKAGE__->config( class => 'Judoon::LookupRegistry' );


sub prepare_arguments {
    my ($self, $c) = @_;
    return {user => $c->user->get_object};
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Model::LookupRegistry - Catalyst Adaptor Model for Judoon::LookupRegistry

=head1 SYNOPSIS

See L<Judoon::Web>

=head1 DESCRIPTION

L<Catalyst::Model::Adaptor> Model wrapping L<Judoon::LookupRegistry>

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
