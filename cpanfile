requires 'Archive::Builder';
requires 'Archive::Extract';
requires 'Authen::Passphrase::BlowfishCrypt';
requires 'autodie';
requires 'Catalyst::Action::FromPSGI' => '0.001004';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Action::REST';
requires 'Catalyst::Authentication::Store::DBIx::Class';
requires 'Catalyst::Devel';
requires 'Catalyst::Controller::DBIC::API';
requires 'Catalyst::Model::Adaptor';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::CustomErrorMessage';
requires 'Catalyst::Plugin::ErrorCatcher';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Session::Store::File';
requires 'Catalyst::Plugin::Session::Store::Memcached';
requires 'Catalyst::Plugin::StackTrace';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Runtime' => '5.90042';
requires 'Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack';
requires 'Catalyst::View::TT';
requires 'CatalystX::RoleApplicator';
requires 'Clone';
requires 'Config::General' => '2.51';
requires 'Data::Entropy::Algorithms';
requires 'Data::UUID';
requires 'Data::Printer';
requires 'Data::Section::Simple';
requires 'Data::Visitor::Callback';
requires 'DateTime';
requires 'DBD::Pg';
requires 'DBD::SQLite' => '1.27'; # DBIx::Class::Fixtures needs this
requires 'DBIx::Class';
requires 'DBIx::Class::Candy';
requires 'DBIx::Class::Helpers';
requires 'DBIx::Class::Migration';
requires 'DBIx::Class::Migration::RunScript::Trait::AuthenPassphrase';
requires 'DBIx::Class::PassphraseColumn';
requires 'DBIx::Class::Schema::Loader';
requires 'DBIx::Class::Schema::Config';
requires 'DBIx::Class::TimeStamp';
requires 'DBIx::Class::DynamicDefault';
requires 'DBIx::RunSQL';
requires 'Elastic::Model';
requires 'Email::Address';
requires 'Email::MIME::Kit';
requires 'Email::MIME::Kit::Renderer::TT';
requires 'Email::Sender::Simple';
requires 'Email::Simple';
requires 'Encode';
requires 'Encode::Guess';
requires 'Excel::Writer::XLSX';
requires 'File::Spec';
requires 'File::Temp';
requires 'FindBin';
requires 'FileHandle';
requires 'Getopt::Long';
requires 'HTML::Scrubber';
requires 'HTML::Selector::XPath::Simple';
requires 'HTML::TreeBuilder';
requires 'HTTP::Throwable';
requires 'IO::All';
requires 'IO::File';
requires 'JSON::MaybeXS';
requires 'List::AllUtils';
requires 'MIME::Base64';
requires 'Module::Load';
requires 'Module::Pluggable';
requires 'Module::Versions';
requires 'Moo' => '1.001000';
requires 'MooX::Types::MooseLike';
requires 'Moose';
requires 'MooseX::MarkAsMethods';
requires 'MooseX::MethodAttributes::Role';
requires 'MooseX::NonMoose';
requires 'MooseX::Storage';
requires 'MooseX::Types';
requires 'MooseX::Types::Common';
requires 'MooseX::Types::DateTime';
requires 'MooseX::Types::URI';
requires 'namespace::autoclean';
requires 'Params::Validate';
requires 'Path::Class';
requires 'Plack::Middleware::Debug';
requires 'Plack::Middleware::Debug::DBIC::QueryLog';
requires 'Pod::Usage';
requires 'Regexp::Common';
requires 'Safe::Isa';
requires 'Scalar::Util';
requires 'Spreadsheet::ParseExcel';
requires 'Spreadsheet::WriteExcel';
requires 'Sub::Name';
requires 'Template';
requires 'Text::CSV';
requires 'Text::Unidecode';
requires 'Throwable::Error' => '0.200003';
requires 'Try::Tiny';
requires 'Type::Registry';
requires 'Type::Tiny';
requires 'URI';
requires 'Web::Machine';


# Excel::Reader::XLSX deps
requires 'Archive::Zip';
requires 'OLE::Storage_Lite';
requires 'XML::LibXML';


# deployment deps
requires 'Net::Server::SS::PreFork';
requires 'Server::Starter' => '0.12';
requires 'Starman' => '0.3003';


test_requires 'indirect';
test_requires 'multidimensional';
test_requires 'bareword::filehandles';
test_requires 'CGI::Compile';
test_requires 'CGI::Emulate::PSGI';
test_requires 'HTML::Selector::XPath::Simple';
test_requires 'HTTP::Request::Common';
test_requires 'Plack';
test_requires 'Pod::Coverage';
test_requires 'Pod::Coverage::TrustPod';
test_requires 'Test::DBIx::Class';
test_requires 'Test::Differences';
test_requires 'Test::More' => '0.88';
test_requires 'Test::Fatal';
test_requires 'Test::JSON';
test_requires 'Test::NoTabs';
test_requires 'Test::Pod';
test_requires 'Test::Pod::Coverage';
test_requires 'Test::postgresql';
test_requires 'Test::Roo';
test_requires 'Test::Spelling';
test_requires 'Test::WWW::Mechanize::Catalyst';



on 'develop' => sub {
   requires 'Devel::NYTProf';
   requires 'Devel::Cover';
};
