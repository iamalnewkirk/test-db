package Test::DB::Postgres;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Test::DB::Object';

with 'Data::Object::Role::Buildable';
with 'Data::Object::Role::Immutable';
with 'Data::Object::Role::Stashable';

use DBI;

# VERSION

# ATTRIBUTES

has 'dbh' => (
  is => 'ro',
  isa => 'Object',
  new => 1,
);

fun new_dbh($self) {
  DBI->connect($self->dsn, $self->username, $self->password, {
    RaiseError => 1,
    AutoCommit => 1
  })
}

has 'dsn' => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_dsn($self) {
  $self->dsngen($self->database)
}

has 'hostname' => (
  is => 'ro',
  isa => 'Maybe[Str]',
  new => 1,
);

fun new_hostname($self) {
  $ENV{TESTDB_HOSTNAME}
}

has 'hostport' => (
  is => 'ro',
  isa => 'Maybe[Str]',
  new => 1,
);

fun new_hostport($self) {
  $ENV{TESTDB_HOSTPORT}
}

has 'initial' => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_initial($self) {
  $ENV{TESTDB_INITIAL} || 'postgres'
}

has 'uri' => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_uri($self) {
  $self->urigen($self->database)
}

has 'username' => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_username($self) {
  $ENV{TESTDB_USERNAME} || ''
}

has 'password' => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_password($self) {
  $ENV{TESTDB_PASSWORD} || ''
}

# METHODS

method clone(Str $source = $self->template) {
  my $initial = $self->initial;

  my $dbh = DBI->connect($self->dsngen($initial),
    $self->username,
    $self->password,
    {
      RaiseError => 1,
      AutoCommit => 1
    }
  );

  my $sth = $dbh->prepare(qq(CREATE DATABASE "@{[$self->database]}" TEMPLATE "$source"));

  $sth->execute;
  $dbh->disconnect;

  $self->dbh;
  $self->uri;
  $self->immutable;

  return $self;
}

method create() {
  my $initial = $self->initial;

  my $dbh = DBI->connect($self->dsngen($initial),
    $self->username,
    $self->password,
    {
      RaiseError => 1,
      AutoCommit => 1
    }
  );

  my $sth = $dbh->prepare(qq(CREATE DATABASE "@{[$self->database]}"));

  $sth->execute;
  $dbh->disconnect;

  $self->dbh;
  $self->uri;
  $self->immutable;

  return $self;
}

method destroy() {
  my $initial = $self->initial;

  $self->dbh->disconnect if $self->{dbh};

  my $dbh = DBI->connect($self->dsngen($initial),
    $self->username,
    $self->password,
    {
      RaiseError => 1,
      AutoCommit => 1
    }
  );

  my $sth = $dbh->prepare(qq(DROP DATABASE "@{[$self->database]}"));

  $sth->execute;
  $dbh->disconnect;

  return $self;
}

method dsngen(Str $name) {
  join(';', "dbi:Pg:dbname=$name", join ';',
    ($self->hostname ? ("host=@{[$self->hostname]}") : ()),
    ($self->hostport ? ("port=@{[$self->hostport]}") : ()),
  )
}

method urigen(Str $name) {
  join('/', 'postgresql:', ($self->username ? '' : ()), ($self->username ?
    join('@', join(':', $self->username ? ($self->username, ($self->password ? $self->password : ())) : ()),
    $self->hostname ? ($self->hostport ? (join(':', $self->hostname, $self->hostport)) : $self->hostname) : '') : ()),
    $name
  )
}

1;
