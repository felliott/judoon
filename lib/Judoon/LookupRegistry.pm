package Judoon::LookupRegistry;

=pod

=for stopwords uniprot

=encoding utf8

=head1 NAME

Judoon::LookupRegistry - Registry for fetching Lookup classes

=head1 SYNOPSIS

 use Judoon::LookupRegistry;

 my $registry = Judoon::LookupRegistry->new;
 my $lookup   = $registry->find_by_full_id('internal_260');

=head1 DESCRIPTION

This module is a registry of LJudoon::Lookup> types and instances.  It
is used to find and build L<Judoon::Lookup::Internal> and
L<Judoon::Lookup::External> objects with a given id.  An example of an
C<::Internal> id would be "internal_260". An example of an external id
would be C<uniprot>.


=cut

use Judoon::Lookup::Internal;
use Judoon::Lookup::External;
use MooX::Types::MooseLike::Base qw(ArrayRef HashRef InstanceOf);

use Moo;
use namespace::clean;

my $INTERNAL_ID_RE = qr/^\d+$/;
my $EXTERNAL_ID_RE = qr/^\w+$/;
my $LOOKUP_ID_RE   = qr/^(?:internal_\d+|external_\w+)$/;


=head1 ATTRIBUTES

=head2 user

A L<Judoon::Schema::Result::User> instance.  Internal datasets must
belong to C<user>.

=head2 external_db

A list of ids for the available External datasets. Entries should be a
hashref with C<id> and C<name> keys.  Will eventually be replaced by
an actual table in the L<Judoon::Schema> database.

=cut

has user => (
    is       => 'ro',
    isa      => InstanceOf['Judoon::Schema::Result::User'],
    required => 1,
);

has external_db => (is => 'lazy', isa => ArrayRef,);
sub _build_external_db {
    return [
        {id => 'uniprot', name => 'Uniprot',},
    ];
}


=head1 FETCH METHODS

=head2 internals

Returns a list of all available L<Judoon::Lookup::Internal>s for
L</user>.

=head2 externals

Returns a list of all available L<Judoon::Lookup::External>s.

=head2 all_lookups

Returns both L</internals> and L</externals>.

=cut

sub all_lookups {
    my ($self) = @_;
    my @all = ($self->internals(), $self->externals());
    return @all;
}
sub internals {
    my ($self) = @_;
    return map {$self->new_internal_from_obj($_)}
        $self->user->datasets_rs->all;
}

sub externals {
    my ($self) = @_;
    return map {$self->new_external_from_obj($_)}
          @{ $self->external_db };
    #     $schema->resultset('ExternalDataset')->all;
}

=head2 find_by_type_and_id( $type, $id )

=head2 find_by_full_id( $full_id )

Return the Lookup of type C<$type> and with id C<$id>. C<$type> should
be one of either 'internal' or 'external'. C<$id> should be a
L<Judoon::Schema::Result::Dataset> id if C<$type> is 'internal', or
the id of the database if <$type> is external.  <$full_id> is C<$type>
and C<$id> joined with an underscore.

 Lookup  | User Dataset 260 | Uniprot          |
 --------+------------------+------------------+
 type    | internal         | external         |
 id      | 260              | uniprot          |
 full_id | internal_260     | external_uniprot |

The ids of External Lookups are found in the L</external_db> attribute
of this package.

=cut

sub find_by_type_and_id {
    my ($self, $type, $id) = @_;
    $type //= '';
    return $type eq 'internal' ? $self->new_internal_from_id($id)
         : $type eq 'external' ? $self->new_external_from_id($id)
         :                       die "$type is not a valid lookup type";
}

sub find_by_full_id {
    my ($self, $full_id) = @_;

    $full_id //= '';
    die "$full_id is not a valid lookup id" unless ($full_id =~ $LOOKUP_ID_RE);
    return $self->find_by_type_and_id(split /_/, $full_id);
}


=head1 INTERNAL CONSTRUCTOR METHODS

=head2 new_internal( \%attrs )

=head2 new_internal_from_id( $id )

=head2 new_internal_from_obj( $dataset )

These methods build instances of L<Judoon::Lookup::Internal>.
C<new_internal()> passes C<\%attrs> directly to the constructor of
C<::Internal>.  C<new_internal_from_id()> finds the
L<Judoon::Schema::Result::Dataset> with id C<$id> and passes that to
C<::Internal>. C<new_internal_from_obj()> likewise takes a
C<::Dataset> and constructs an object from that.

=cut

sub new_internal_from_obj {
    my ($self, $dataset) = @_;
    return $self->new_internal({dataset => $dataset});
}
sub new_internal_from_id {
    my ($self, $id) = @_;
    $id //= '';
    die "$id is not a valid internal id" unless ($id =~ $INTERNAL_ID_RE);

    my $dataset = $self->user->datasets_rs->find({id => $id});
    die "No dataset found with id: $id" unless ($dataset);
    return $self->new_internal({dataset => $dataset});
}
sub new_internal {
    my ($self, $attrs) = @_;
    return Judoon::Lookup::Internal->new({user => $self->user, %$attrs});
}


=head2 new_external( \%attrs )

=head2 new_external_from_id( $id )

=head2 new_external_from_obj( $dataset )

These methods build instances of L<Judoon::Lookup::External>.
C<new_external()> passes C<\%attrs> directly to the constructor of
C<::External>.  C<new_external_from_id()> finds the dataset descriptor
hash in L<external_db> with id C<$id> and passes that to
C<::External>. C<new_external_from_obj()> likewise takes a descriptor
hash and constructs an object from that.

=cut


sub new_external_from_obj {
    my ($self, $dataset) = @_;
    return $self->new_external({dataset => $dataset});
}
sub new_external_from_id {
    my ($self, $id) = @_;
    $id //= '';
    die "$id is not a valid external id" unless ($id =~ $EXTERNAL_ID_RE);

    # my $dataset = $self->schema->resultset('ExternalDataset')
    #     ->find({id => $id});
    my $dataset;
    for my $ds (@{$self->external_db}) {
        if ($ds->{id} eq $id) {
            $dataset = $ds;
            last;
        }
    }
    die "No database found called: $id" unless ($dataset);
    return $self->new_external({dataset => $dataset});
}
sub new_external {
    my ($self, $attrs) = @_;
    return Judoon::Lookup::External->new({user => $self->user, %$attrs});
}




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
