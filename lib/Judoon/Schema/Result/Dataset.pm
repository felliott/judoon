package Judoon::Schema::Result::Dataset;

=pod

=for stopwords datastore shortnames tablename longname longnames de

=encoding utf8

=head1 NAME

Judoon::Schema::Result::Dataset

=cut

use Clone qw(clone);
use Data::UUID;
use DateTime;
use Judoon::Error::Devel::Arguments;
use Judoon::Error::Devel::Impossible;
use Judoon::Schema::Candy;
use Judoon::Tmpl;
use Judoon::TypeRegistry;
use List::MoreUtils qw();
use MooX::Types::MooseLike::Base qw(InstanceOf);
use Spreadsheet::WriteExcel ();
use Text::Unidecode;

use Moo;
use namespace::clean;


table 'datasets';

primary_column id => {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    is_serializable   => 1,
    is_numeric        => 1,
};
column user_id => {
    data_type       => "integer",
    is_foreign_key  => 1,
    is_nullable     => 0,
    is_serializable => 1,
    is_numeric        => 1,
};
column name => {
    data_type       => "text",
    is_nullable     => 0,
    is_serializable => 1,
};
column description => {
    data_type       => "text",
    is_nullable     => 0,
    is_serializable => 1,
};
column original => {
    data_type       => "text",
    is_nullable     => 0,
    is_serializable => 0,
};
column tablename => {
    data_type       => "text",
    is_nullable     => 0,
    is_serializable => 0,
};
column nbr_rows => {
    data_type       => "integer",
    is_nullable     => 0,
    is_serializable => 1,
    is_numeric      => 1,
};
column nbr_columns => {
    data_type       => "integer",
    is_nullable     => 0,
    is_serializable => 1,
    is_numeric      => 1,
};


has_many ds_columns => "::DatasetColumn",
    { "foreign.dataset_id" => "self.id" },
    { cascade_copy => 0, cascade_delete => 1 };

has_many pages => "::Page",
    { "foreign.dataset_id" => "self.id" },
    { cascade_copy => 0, cascade_delete => 1 };

belongs_to user => "::User",
    { id => "user_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };



=head1 EXTRA COMPONENTS

=head2 ::Role::Result::HasPermissions

Add C<permission> column / methods to C<Dataset>.

=head2 ::Role::Result::HasTimestamps

Add <created> and <modified> columns to C<Dataset>.

=cut

with qw(
    Judoon::Schema::Role::Result::DoesTabularData
    Judoon::Schema::Role::Result::HasPermissions
    Judoon::Schema::Role::Result::HasTimestamps
);
__PACKAGE__->register_permissions;
__PACKAGE__->register_timestamps;

with 'Judoon::Role::ScrubHTML';


=head1 ATTRIBUTES

=head2 type_registry

An instance of L<Judoon::TypeRegistry>

=cut

has type_registry => (
    is  => 'lazy',
    isa => InstanceOf['Judoon::TypeRegistry']
);
sub _build_type_registry { Judoon::TypeRegistry->new; }


=head1 METHODS

=head2 TO_JSON()

Return a data structure that represents this DatasetColumn suitable
for serialization.

=cut

sub TO_JSON {
    my ($self) = @_;
    my $json = $self->next::method();
    return $json;
}


=head2 delete()

Delete datastore table after deleting object

=cut

sub delete {
    my ($self) = @_;
    $self->next::method(@_);
    $self->_delete_datastore();
    return $self;
}


=head2 ds_columns_ordered()

Get DatasetColumns in sorted order

=cut

sub ds_columns_ordered {
    my ($self) = @_;
    return $self->ds_columns_rs->search_rs({},{order_by => {-asc => 'sort'}});
}


=head2 pages_ordered()

Get related Pages in sorted order

=cut

sub pages_ordered {
    my ($self) = @_;
    return $self->pages_rs->search_rs({}, {order_by => {-asc => 'created'}});
}


=head2 import_from_spreadsheet( $spreadsheet )

Update a new C<Dataset> from a C<Judoon::Spreadsheet> object.  Calling this
will create a new table in the Datastore and store the meta-information in the
C<Dataset> and C<DatasetColumns>.

=cut

sub import_from_spreadsheet {
    my ($self, $spreadsheet) = @_;

    Judoon::Error::Devel::Arguments->throw({
        message  => q{'spreadsheet' argument to Result::Dataset must be a Judoon::Spreadsheet'},
        expected => q{->isa('Judoon::Spreadsheet')},
        got      => q{->isa('} . ref($spreadsheet) . q{')},
    }) unless (ref $spreadsheet eq 'Judoon::Spreadsheet');

    my ($table_name, $fields) = $self->_store_data($spreadsheet);

    $self->name($spreadsheet->name);
    $self->tablename($table_name);
    $self->nbr_rows($spreadsheet->nbr_rows);
    $self->nbr_columns($spreadsheet->nbr_columns);
    $self->description(q{});
    $self->original(q{});
    $self->update;

    my $sort = 1;
    for my $field (@$fields) {
        $self->create_related('ds_columns', {
            name => $field->{longname}, shortname => $field->{shortname},
            data_type => $self->type_registry->pg_to_judoon->{$field->{type}},
            sort => $sort++,
        });
    }

    return $self;
}


=head2 new_computed_column( $name, $lookup_actor )

Add a new column to the Dataset, derived by applying a lookup (in
the form of a C<Judoon::Lookup::*Actor>) to an existing column.

=cut

sub new_computed_column {
    my ($self, $name, $lookup_actor) = @_;

    my $join_col = $lookup_actor->this_joincol_id // '';
    if (! grep {$_->shortname eq $join_col} $self->ds_columns_rs->all) {
        die "This dataset does not have a column named '$join_col'";
    }

    my $computed_ds = $self->new_related('ds_columns', {}); #computed => 1,});

    my ($longname, $shortname) = @{ ($self->_unique_names($name))[0] };
    $computed_ds->name($longname);
    $computed_ds->shortname($shortname);

    $computed_ds->data_type($lookup_actor->result_data_type());
    $computed_ds->insert();

    $self->_deploy_computed_column($computed_ds, $lookup_actor);
    return $computed_ds;
}


=head2 create_basic_page()

Turn a dataset into a simple page with a one-to-one mapping between
data columns and page columns.

=cut

sub create_basic_page {
    my ($self) = @_;

    my $DEFAULT_PREAMBLE = <<'EOS';
<p>This is a standard table.</p>
<p>Edit this by logging into your account and selecting 'edit view'.</p>
EOS
    my $DEFAULT_POSTAMBLE = <<'EOS';
Created with Judoon on 
EOS
    $DEFAULT_POSTAMBLE .= DateTime->now();

    my $page = $self->create_related('pages', {
        title     => $self->scrub_html_string($self->name),
        preamble  => $DEFAULT_PREAMBLE,
        postamble => $DEFAULT_POSTAMBLE,
    });

    my $i = 1;
    for my $ds_column ($self->ds_columns_ordered->all) {
        my $page_column = $page->create_related('page_columns', {
            title    => $self->scrub_html_string($ds_column->name),
            template => Judoon::Tmpl->new_from_data([
                {type => 'variable', name => $ds_column->shortname,}
            ]),
            sort     => $i++,
        });
    }

    return $page;
}

=head2 tabular_name

For C<::DoesTabularData>: name for this table

=cut

sub tabular_name { $_[0]->name }

=head2 long_headers

Return list of the human-readable C<DatasetColumn> names.

=cut

sub long_headers {
    my ($self) = @_;
    return [map {$_->name} $self->ds_columns_ordered->all];
}


=head2 short_headers

Return list of the computer-friendly C<DatasetColumn> C<shortnames>.

=cut

sub short_headers {
    my ($self) = @_;
    return [map {$_->shortname} $self->ds_columns_ordered->all];
}


=head1 VIEW METHODS

The following methods return a representation of the C<Dataset> in
different formats.

=head2 data_table( $args )

Returns an arrayref of arrayref of the dataset's data.

=cut

sub data_table {
    my ($self) = @_;
    return $self->data;
}



=head1 DATASTORE

The following methods create and retrieve the actual dataset data,
which is stored in a different schema and table.

=head2 schema_name() / _build_schema_name()

Return schema name, which changes based on database engine.  For
SQLite, the schema name is always 'data'.  For Pg, it's based on the
name of the user.

=cut

has schema_name => (is => 'lazy',);
sub _build_schema_name {
    my ($self) = @_;
    return $self->user->schema_name;
}


=head2 datastore_name()

Convenience method for getting fully-qualified datastore
name ($schema_name.$table_name).

=cut

sub datastore_name {
    my ($self) = @_;
    return $self->schema_name . '.' . $self->tablename;
}


=head2 data() / _build_data()

Attribute for getting at the data stored in the Datastore.

=cut

has data => (is => 'lazy',);
sub _build_data {
    my ($self) = @_;

    my @columns = map {$_->shortname} sort {$a->sort <=> $b->sort}
        $self->ds_columns_ordered->all;
    return $self->column_data(@columns);
}


=head2 id_data() / _build_id_data()

Attribute for storing the id column data in the datastore.

=cut

has id_data => (is => 'lazy',);
sub _build_id_data {
    my ($self) = @_;
    return $self->column_data('id');
}


=head2 sample_data( $sample_count?, @columns? )

Method for retrieving sample data i.e. the first C<$sample_count>
non-blank entries for each column in C<@columns>. C<$sample_count>
defaults to 1. C<@columns> defaults to all columns in the dataset.

=cut

sub sample_data {
    my ($self, $sample_count, @cols) = @_;

    $sample_count ||= 1;

    my $data;
    if (@cols) {
        $data = $self->column_data(@cols);
    }
    else {
        @cols = map {$_->{shortname}} $self->ds_columns_ordered->hri->all;
        $data = $self->data;
    }

    my @sample_data = map {[]} @cols;
    for my $idx (0..$#cols) {
        my $samples_found = 0;
      ROW_SEARCH:
        for my $row (@$data) {
            last ROW_SEARCH if ($samples_found >= $sample_count);
            if (defined($row->[$idx]) && $row->[$idx] =~ m/\S/) {
                push @{$sample_data[$idx]}, $row->[$idx];
                $samples_found++;
            }
        }
    }

    my %sample_data;
    @sample_data{@cols} = @sample_data;
    return \%sample_data;
}


=head2 column_data(@columns)

Fetch arrayref of arrayrefs of column data for each entry in
C<@column>. Entries in C<@column> must be a valid C<shortname>.

=cut

sub column_data {
    my ($self, @columns) = @_;
    my $select = join ', ', @columns;
    my $table = $self->datastore_name;
    return $self->result_source->storage->dbh_do(
        sub {
            my ($storage, $dbh) = @_;
            my $sth = $dbh->prepare("SELECT $select FROM $table");
            $sth->execute;
            return $sth->fetchall_arrayref();
        },
    );
}


=head2 _store_data( $spreadsheet )

This private method creates the new table for the data in the
Datastore.  It also checks for table name collisions and changes the
name accordingly.  After creating the table, it inserts the
data. Returns the new table name.

=cut

sub _store_data {
    my ($self, $spreadsheet) = @_;

    Judoon::Error::Devel::Arguments->throw({
        message  => q{'spreadsheet' argument to Result::Dataset must be a Judoon::Spreadsheet'},
        expected => q{->isa('Judoon::Spreadsheet')},
        got      => q{->isa('} . ref($spreadsheet) . q{')},
    }) unless (ref $spreadsheet eq 'Judoon::Spreadsheet');

    my $schema     = $self->schema_name;
    my $table_name = $self->_gen_table_name( $spreadsheet->name );

    my @fields       = @{ clone $spreadsheet->fields };
    my @unique_names = $self->_unique_names(map {$_->{name}} @fields);
    for (my $i=0; $i<=$#fields; $i++) {
        @{$fields[$i]}{qw(longname shortname)} = @{$unique_names[$i]};
    }

    my $sql        = qq{CREATE TABLE "$schema"."$table_name" (\n}
        . qq|"id" serial,\n|
        . join(",\n", map { qq|"$_->{shortname}" text| } @fields)
        . ')';

    # create table
    $self->_run_sql($sql);

    # populate table
    my $field_list = join ', ', map {$_->{shortname}} @fields;
    my $join_list  = join ', ', (('?') x @fields);
    $self->result_source->storage->dbh_do(
        sub {
            my ($storage, $dbh) = @_;
            my $sth_insert = $dbh->prepare_cached(
                "INSERT INTO $schema.$table_name ($field_list) VALUES ($join_list)"
            );
            $sth_insert->execute(@$_) for (@{$spreadsheet->data});
        },
    );

    return ($table_name, \@fields);
}


=head2 _delete_datastore()

Delete the datastore table from the user's schema.

=cut

sub _delete_datastore {
    my ($self) = @_;
    $self->_run_sql('DROP TABLE ' . $self->datastore_name);
    return;
}


=head2 _deploy_computed_column( $ds_col, $lookup_actor )

Add the computed column to the datastore and fill in its data by
applying the C<Judoon::Lookup::*Actor> to the source field.

=cut

sub _deploy_computed_column {
    my ($self, $ds_col, $lookup_actor) = @_;

    my $alter_stmt = 'ALTER TABLE ' . $self->datastore_name
        . ' ADD COLUMN ' . $ds_col->shortname . ' '
            . $lookup_actor->result_data_type->pg_type;
    $self->_run_sql($alter_stmt);

    my @col_data = map {$_->[0]}
        @{ $self->column_data($lookup_actor->this_joincol_id) };
    my $lookup_data = $lookup_actor->lookup(\@col_data);
    my $id_data     = $self->id_data;

    my @virtual_col
        = List::MoreUtils::pairwise {no warnings q(once); [$a->[0], $b]}
           @$id_data, @$lookup_data;

    my $dstore_name  = $self->datastore_name;
    my $ds_col_sname = $ds_col->shortname;
    my $value_list   = join(', ',
        map {q{('} . $_->[1] . q{', } . $_->[0] . ')'} @virtual_col
    );
    my $update_stmt = 'UPDATE ' . $dstore_name . ' AS src SET '
        . $ds_col_sname . " = v.computed_value\n   FROM (VALUES "
        . $value_list . ") AS v (computed_value, id) \n   WHERE src.id=v.id";
    $self->_run_sql($update_stmt);

    # UPDATE moo SET (lc_column) = v.computed_value
    #   FROM (VALUES ("grr", 1), ("meow", "2"), ("quack", "3")) AS v (computed_value, id)
    #   WHERE moo.id=v.id;
    return;
}


=head2 _gen_table_name( $table_name )

Private method to generate a new table name.  This method tries a
couple different techniques, but will die if it's unable to find a
unique name.

=cut

sub _gen_table_name {
    my ($self, $table_name) = @_;

    $table_name = lc($table_name);
    $table_name =~ s/[^a-z_0-9]+/_/gi;
    $table_name =~ s/^([0-9])/_$1/; # table can't begin with a number
    return $table_name unless ($self->_table_exists($table_name));

    my $new_name = List::AllUtils::first {not $self->_table_exists($_)}
        map { "${table_name}_" . sprintf('%02d', $_) } (1..99);
    return $new_name if ($new_name);

    $new_name = $table_name . '_' . time();
    return $new_name unless ($self->_table_exists($new_name));

    # if this doesn't work, something is seriously wrong
    $new_name = $table_name . '_' . Data::UUID->new->create_str();
    $new_name =~ s/-/_/g;
    Judoon::Error::Devel::Impossible->throw({
        message => "Unable to find suitable name for table: $table_name",
    })  if ($self->_table_exists($new_name));
    return $new_name;
}


=head2 _table_exists( $table_name )

Private method to test whether a particular table name is already in
use.

=cut

sub _table_exists {
    my ($self, $name) = @_;
    return $self->result_source->storage->dbh_do(
        sub {
            my ($storage, $dbh) = @_;
            my $sth = $dbh->table_info(undef, $self->schema_name, $name, "TABLE");
            my $ary = $sth->fetchall_arrayref();
            return @$ary;
        },
    );
}


=head2 _run_sql

Convenience method for running sql directly.

=cut

sub _run_sql {
    my ($self, $sql) = @_;
    $self->result_source->storage->dbh_do(
        sub {
            my ($storage, $dbh) = @_;
            $dbh->do($sql);
        },
    );
    return;
}



=head2 Unique name utilities

We need to be able to generate unique names for our columns when
importing a new dataset or creating new computed columns.  There are
two types of names, longnames and shortnames.

B<Longnames> are the user-friendly names given by the user in the
source spreadsheet or when adding a new computed column.  Longnames
correspond to the C<name> field of the DatasetColumn.  If a given
longname is blank, it is replaced with the string 'C<(untitled
column)>'.  Duplicate longnames are de-duplicated by appending strings
of the format 'C<($number)> e.g. 'C<Foo (1)>', 'C<Foo (2)>', etc.

B<Shortnames> are normalized versions of the longname, suitable for
use as SQL column names. The shortname 'C<id>' is reserved for use by
Judoon as a primary key column on datastore tables.  Duplicate
shortnames have a string of the format 'C<_%02d>' appended. Shortnames
are stored in the C<shortname> field of the DatasetColumn and are used
as the corresponding column name in the datastore.

For both types of names, if we fail to find a unique name after
appending X unique numbers, we use L</Data::UUID> to generate a
globally unique id, then append that.

An sql-normalized version of the name, suitable for use as an SQL
column name.  Must be unique to the entire dataset, so may have
trailing integers appended.  In the pathological case where more than
100 columns have the same name, we start appending UUIDs. Don't do that.
If that doesn't work, then I guess this is the end.

=head3 _seenlong / _build__seenlong

Longnames we've seen already.

=head3 _seenshort / _build__seenshort

Shortnames we've seen already.  'id' is reserved.

=head3 _unique_names( @names )

Convenience method that calls C<_unique_longname()> and
C<_unique_shortname()> for each entry in C<@names>.  Returns a list of
C<[ $longname, $shortname ]> pairs.

=head3 _unique_longname( $name )

Generate a longname as described above.

=head3 _unique_shortname( $name )

Generate a shortname as described above.

=cut

has _seenlong  => (is => 'lazy');
sub _build__seenlong {
    my ($self) = @_;
    my @cols = $self->ds_columns_ordered->hri->all;
    return {map {$_->{name} => 1} @cols};
}

has _seenshort => (is => 'lazy');
sub _build__seenshort {
    my ($self) = @_;
    my @cols = $self->ds_columns_ordered->hri->all;
    return {id => 1, map {$_->{shortname} => 1} @cols};
}

sub _unique_names {
    my ($self, @names) = @_;

    my @uniques;
    for my $name (@names) {
        push @uniques, [
            $self->_unique_longname($name),
            $self->_unique_shortname($name),
        ];
    }

    return @uniques;
}

# generate a unique column title
sub _unique_longname {
    my ($self, $header) = @_;

    $header = '(untitled column)' if (!defined($header) || $header eq '');

    return $header if (not $self->_seenlong->{$header}++);

    for my $i (1..999) {
        my $new_header = $header . " ($i)";
        return $new_header if (not $self->_seenlong->{$new_header}++);
    }

    for my $i (0..10) {
        my $uuid = Data::UUID->new->create_str();
        my $uuid_name = $header . " ($uuid)";
        return $uuid_name if(not $self->_seenlong->{$uuid_name}++);
    }

    Judoon::Error::Devel::Impossible->throw({                        # uncoverable statement
        message => "couldn't generate a unique column name: "        # uncoverable statement
            . p(%{ {header => $header, seen => $self->_seenlong} }), # uncoverable statement
    });                                                              # uncoverable statement
}

# generate a unique sql-valid name for a column based off its text
# name.
sub _unique_shortname {
    my ($self, $name) = @_;

    $name = 'untitled' if (!defined($name) || $name eq '');

    $name = unidecode($name);

    # stolen from SQL::Translator::Utils::normalize_name
    # The name can only begin with a-zA-Z_; if there's anything
    # else, prefix with _
    $name =~ s/^([^a-zA-Z_])/_$1/;

    # anything other than a-zA-Z0-9_ in the non-first position
    # needs to be turned into _
    $name =~ tr/[a-zA-Z0-9_]/_/c;

    # All duplicated _ need to be squashed into one.
    $name =~ tr/_/_/s;

    # Trim a trailing _
    $name =~ s/_$//;

    $name = lc $name;

    return $name if (!$self->_seenshort->{$name}++);

    for my $suffix (map {sprintf '%02d', $_} 1..99) {
        my $new_colname = $name . '_' . $suffix;
        return $new_colname if (!$self->_seenshort->{$new_colname}++);
    }

    for my $i (0..10) {
        my $uuid = Data::UUID->new->create_str();
        my $uuid_name = $name . '_' . $uuid;
        return $uuid_name if(!$self->_seenshort->{$uuid_name}++);
    }

    Judoon::Error::Devel::Impossible->throw({                     # uncoverable statement
        message => "couldn't generate a unique sql column name: " # uncoverable statement
            . p(%{ {name => $name, seen => $self->_seenshort} }), # uncoverable statement
    });                                                           # uncoverable statement
}


1;

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
