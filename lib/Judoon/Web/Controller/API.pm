package Judoon::Web::Controller::API;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }

sub base : Chained('/') PathPart('api') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    if (!$c->user && (my $access_token = $c->req->param('access_token'))) {
        my $token = $c->model('User::Token')->find_by_value($access_token);

        if ($token && !$token->is_expired) {
            $c->authenticate({dbix_class => {result => $token->user}}, 'api');
        }
    }
}

sub list : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->res->redirect('/');
}


__PACKAGE__->meta->make_immutable;

1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::API - Root Controller for API actions

=head2 DESCRIPTION

The base controller for our various API endpoints

=head1 ACTIONS

=head2 base

Our base chained action for api actions. Manages API authentication.

=head2 list

Send requests for '/api' back to the index page.

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
