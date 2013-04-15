package Judoon::Web::Controller;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller - base controller for Judoon

=head1 SYNOPSIS

 package Judoon::Web::Controller::User;
 BEGIN { extends 'Judoon::Web::Controller'; }

 sub add {
    my ($self, $c) = @_;
    # ...add new user...
    if ($@) { #error
        # sets the flash and redirects to /user/new
        $self->set_error_and_redirect(
            $c, 'unable to add user', ['/user/new'],
        );
    }
    elsif ($newuser) {
        # redirects to /user/$id/edit
        $self->go_relative($c, 'edit', [$new_user->id]);
    }
    else {
        $self->go_here($c, '/signup');
    }
 }

=head1 DESCRIPTION

This provides common utility methods for Judoon::Web controllers.

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::ActionRole'; }

use Judoon::Error::Devel::Arguments;
use Safe::Isa;


# use ActionRole::DetachOnDie, so we don't keep running though the
# action chain after a die.
__PACKAGE__->config(
   action => {
      '*' => { Does => 'DetachOnDie' },
   },
);


=head1 METHODS

=head2 set_notice( $c, $notice_msg )

Sets the notice key in the flash.  This is the key used in the
notification template component.

=cut

sub set_notice {
    my ($self, $c, $notice_msg) = @_;
    $c->flash->{alert}{notice} = $notice_msg;
}


=head2 set_warning( $c, $warning_msg )

Sets the warning key in the flash.  This is the key used in the
notification template component.

=cut

sub set_warning {
    my ($self, $c, $warning_msg) = @_;
    $c->flash->{alert}{warning} = $warning_msg;
}


=head2 set_error_and_redirect( $c, $errmsg, \@action )

Sets the flash to C<$errmsg> and redirects to the action given by
C<\@action>, where C<\@action> is an arrayref of args suitable for
passing to C<< $c->uri_for_action >>.

=cut

sub set_error_and_redirect {
    my ($self, $c, $error, $action_ar) = @_;
    $c->flash->{alert}{error} = $error;
    $self->go_here($c, @$action_ar);
}


=head2 go_here($c, $action, \@captures?, \%query?)

C<go_here()> is an alias for:

 $c->res->redirect($c->uri_for_action($action, \@captures, \%query))

except C<\@captures> defaults to C<< $c->req->captures >>, and
C<\%query> defaults to C<< $c->req->query_params >>.  If you want to
redirect to a url without captures from an action with them, you must
explicitly pass an empty arrayref as the C<\@captures> argument, and
likewise with C<\%query>.

=cut

sub go_here {
    my ($self, $c, $action, @args) = @_;
    my ($captures, $query);
    for my $arg (@args) {
        ref $arg eq 'ARRAY' ? $captures = $arg
      : ref $arg eq 'HASH'  ? $query    = $arg
      : Judoon::Error::Devel::Arguments->throw({
          message  => q{arguments to go_here() should be captures or query params},
          got      => (!defined($arg) ? 'undef' : ref($arg)),
          expected => 'arrayref or hashref',
      });
    }
    $captures //= $c->req->captures;
    $query    //= $c->req->query_params;
    $c->res->redirect($c->uri_for_action($action, $captures, $query));
}


=head2 go_relative($c, $action, \@captures?, \%query?)

C<go_relative()> is like L</go_here()>, except C<$action> is assumed
to be an action in the current controller, and therefore doesn't need
the full action path.

 # if current controller is ::User, this goes to /user/add
 $c->go_relative('add', $captures);

 # it's equivalent to:
 $c->response->redirect(
     $c->uri_for_action(
         $c->controller->action_for('add'),
         $captures,
     )
 );

This method calls L</go_here> with the C<$action> argument replaced
with the result of C<< $c->controller->action_for($action) >>. The C<<
\@captures >> and C<< \%query >> are passed unmodified.

=cut

sub go_relative {
    my ($self, $c, $action_path, @args) = @_;
    my $action = $c->controller->action_for($action_path);
    $self->go_here($c, $action, @args);
}


__PACKAGE__->meta->make_immutable;
1;
__END__
