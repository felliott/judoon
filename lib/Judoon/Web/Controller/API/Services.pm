package Judoon::Web::Controller::API::Services;

=pod

=for stopwords

=encoding utf8

=head1 NAME

Judoon::Web::Controller::API::Services - Miscellaneous read-only services

=head1 DESCRIPTION

This controller is a catch-all for services that don't need to modify
the Judoon database. Example services include: widgets-to-template
translation, descriptors of how to provide links to other sites, and
inter-database lookup service information.

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config(
    default => 'application/json',
    'map' => {
        'application/json' => 'JSON',
        'text/html' => 'YAML::HTML',
    },
);

use List::Util qw();


=head1 COMMON ACTIONS

=head2 base

Base controller. All requests pass through here. Currently does nothing.

=cut

sub base : Chained('/api/base') PathPart('') CaptureArgs(0) {}


=head1 TEMPLATE ACTIONS

=head2 template / template_POST

A POST request to C</api/template> will translate a JSON array of
widgets into a valid Javascript template, or a Javascript template
into a list of widgets.

=cut

sub template : Chained('base') PathPart('template') Args(0) ActionClass('REST') {}
sub template_POST {
    my ($self, $c) = @_;

    my $params = $c->req->data;

    if (not (exists($params->{template}) xor exists($params->{widgets}))) {
        $c->res->status(422);
        $c->res->body('');
        $c->detach();
    }

    my $entity;
    if (exists $params->{widgets}) {
        my $tmpl;
        eval {
            $tmpl = Judoon::Tmpl->new_from_data($params->{widgets});
        };
        unless ($@) {
            $entity = { template => $tmpl->to_jstmpl };
        }
    }
    elsif (exists $params->{template}) {
        my $tmpl;
        eval {
            $tmpl = Judoon::Tmpl->new_from_jstmpl($params->{template});
        };
        unless ($@) {
            $entity = { widgets => $tmpl->to_data };
        }

    }
    else {
        die 'Unreachable condition';
    }

    if (not $entity) {
        $c->res->status(422);
        $c->res->body('');
        $c->detach();
    }

    $self->status_ok($c, entity => $entity);
}


=head1 SITELINKER ACTIONS

=head2 sitelinker / sl_index

Base action. Returns 204 (No Content).

=cut

sub sitelinker : Chained('base') PathPart('sitelinker') CaptureArgs(0) {
    my ($self, $c) = @_;
    if ($c->req->method ne 'GET') {
        $c->res->status('405');
        $c->res->body('');
        $c->detach();
    }
}
sub sl_index : Chained('sitelinker') PathPart('') Args(0) {
    my ($self, $c) = @_;
    # should probably be 204 with link="rel" to sites/accessions
    $self->status_no_content($c);
}

=head2 sl_accession_base / sl_accession_list / sl_accession_id

Requests to C</api/sitelinker/accession> return a list of
accession-to-site mappings.  The specific accession can be requested
at C</api/sitelinker/accession/$accession_id>.

=cut

sub sl_accession_base : Chained('sitelinker') PathPart('accession') CaptureArgs(0) {}
sub sl_accession_list : Chained('sl_accession_base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $self->status_ok(
        $c, entity => $c->model('SiteLinker')->mapping->{accession}
    );
}
sub sl_accession_id :Chained('sl_accession_base') PathPart('') Args(1) {
    my ($self, $c, $acc_id) = @_;

    $acc_id //= '';
    my $accession = List::Util::first {$_->{name} eq $acc_id}
        @{$c->model('SiteLinker')->mapping->{accession}};
    if (not $accession) {
        $self->status_not_found($c, message => "No such accession: '$acc_id'");
        $c->detach();
    }
    $self->status_ok($c, entity => { accession => $accession });
}

=head2 sl_site_base / sl_site_list

Requests to C</api/sitelinker/site> return a list of site-to-accession
mappings.

=cut

sub sl_site_base : Chained('sitelinker') PathPart('site') CaptureArgs(0) {}
sub sl_site_list : Chained('sl_site_base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $self->status_ok($c, entity => {
        sites => $c->model('SiteLinker')->mapping->{site}
    });
}


=head1 LOOKUP ACTIONS

=head2 lookup / lookup_index

The base action. Requests to c</api/lookup> will return all valid
lookups for the logged-in user.

=cut

sub lookup : Chained('base') PathPart('lookup') CaptureArgs(0) {
    my ($self, $c) = @_;
    if ($c->req->method ne 'GET') {
        $c->res->status('405');
        $c->res->body('');
        $c->detach();
    }

    if (not $c->user) {
        $c->res->status('401');
        $c->res->body('');
        $c->detach();
    }
}
sub lookup_index : Chained('lookup') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $self->status_ok(
        $c, entity => [
            map {$_->TO_JSON} $c->model('LookupRegistry')->all_lookups()
        ]
    );
}

=head2 look_type / look_type_final

Requests to C</api/lookup/$lookup_type> will return the list of valid
lookups of the given type for the logged in user.  Current valid
values for C<$lookup_type> are C<internal> or C<external>.

=cut

sub look_type : Chained('lookup') PathPart('') CaptureArgs(1) {
    my ($self, $c, $type) = @_;

    $c->stash->{lookup}{type} = $type;
    $c->stash->{lookup}{list}
        = $type eq 'internal' ? [$c->model('LookupRegistry')->internals()]
        : $type eq 'external' ? [$c->model('LookupRegistry')->externals()]
        :                       undef;

    if (!$c->stash->{lookup}{list}) {
        $self->status_not_found(
            $c, message => "Unrecognized lookup type '$type'"
        );
        $c->detach();
    }
}
sub look_type_final : Chained('look_type') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $self->status_ok($c, entity => [
        map {$_->TO_JSON} @{ $c->stash->{lookup}{list} }
    ]);
}

=head2 look_id / look_id_final

Requests to C</api/lookup/$lookup_type/$lookup_id> will return the
properties of the given lookup (input / output columns, etc.)

=cut

sub look_id : Chained('look_type') PathPart('') CaptureArgs(1) {
    my ($self, $c, $lookup_id) = @_;

    $c->stash->{lookup}{id}     = $lookup_id;
    $c->stash->{lookup}{object} = $c->model('LookupRegistry')
        ->find_by_type_and_id( $c->stash->{lookup}{type}, $lookup_id );

    if (!$c->stash->{lookup}{object}) {
        $self->status_not_found(
            $c, message => "Unrecognized lookup id '$lookup_id'"
        );
        $c->detach();
    }
}
sub look_id_final : Chained('look_id') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $self->status_ok($c, entity => $c->stash->{lookup}{object}->TO_JSON);
}

=head2 look_input / look_input_final

Requests to C</api/lookup/$lookup_type/$lookup_id/input> will return the
valid input columns for the given lookup.

=cut

sub look_input : Chained('look_id') PathPart('input') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash->{lookup}{input}{list}
        = $c->stash->{lookup}{object}->input_columns;
}
sub look_input_final : Chained('look_input') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $self->status_ok($c, entity => $c->stash->{lookup}{input}{list});
}

=head2 look_input_id / look_input_id_final

Requests to C</api/lookup/$lookup_type/$lookup_id/input/$input_id>
will return the properties of the given input column.

=cut

sub look_input_id : Chained('look_input') PathPart('') CaptureArgs(1) {
    my ($self, $c, $id) = @_;

    $c->stash->{lookup}{input}{id} = $id;
    $c->stash->{lookup}{input}{object} = List::Util::first {$_->{id} eq $id}
        @{ $c->stash->{lookup}{input}{list} };

    if (!$c->stash->{lookup}{input}{object}) {
        $self->status_not_found(
            $c, message => "Unrecognized lookup input object '$id'"
        );
        $c->detach();
    }
}
sub look_input_id_final : Chained('look_input_id') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $self->status_ok($c, entity => $c->stash->{lookup}{input}{object});
}

=head2 look_input_to_output / look_input_to_output_final

Requests to C</api/lookup/$lookup_type/$lookup_id/input/$input_id/output>
will return the valid output columns for the given input column.

=cut

sub look_input_to_output : Chained('look_input_id') PathPart('output') CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{lookup}{output}{list}
        = $c->stash->{lookup}{object}->output_columns_for(
            $c->stash->{lookup}{input}{object}
        );
}
sub look_input_to_output_final : Chained('look_input_to_output') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $self->status_ok($c, entity => $c->stash->{lookup}{output}{list});
}


=head1 DATATYPE ACTIONS

=head2 type_base

Base action for common actions. Currently does nothing.

=head2 type_index

Return a serialized list of types.

=head2 type_id

Lookup the given type, returning 404 if not found.

=head2 type

Return the serialized type.

=cut

sub type_base : Chained('base') PathPart('datatype') CaptureArgs(0) {
    my ($self, $c) = @_;
    if ($c->req->method ne 'GET') {
        $c->res->status('405');
        $c->res->body('');
        $c->detach();
    }
}
sub type_index : Chained('type_base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my $typereg = $c->model('TypeRegistry');
    $self->status_ok($c, entity => [map {$_->TO_JSON} $typereg->all_types]);
}
sub type_id : Chained('type_base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $type_id) = @_;

    $type_id //= '';
    $c->stash->{type_id} = $type_id;
    my $type = $c->model('TypeRegistry')->simple_lookup($type_id);

    if (not $type) {
        $self->status_not_found(
            $c, message => qq{No such type "$type_id"},
        );
        $c->detach();
    }
    $c->stash->{type} = $type->TO_JSON;
}
sub type : Chained('type_id') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $self->status_ok( $c, entity => $c->stash->{type}, );
}


__PACKAGE__->meta->make_immutable;
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
