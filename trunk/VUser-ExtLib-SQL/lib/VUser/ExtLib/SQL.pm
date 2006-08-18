package VUser::ExtLib::SQL;
use warnings;
use strict;

# Copyright 2006 Randy Smith <perlstalker@vuser.org>
# $Id: SQL.pm,v 1.1 2006-08-18 20:50:26 perlstalker Exp $

our $VERSION = "0.1.0";

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = (); # Export nothing by default
our @EXPORT_OK = qw(execute);
our %EXPORT_TAGS = ();

use VUser::Log qw(:levels);
use DBI;

=pod

=head1 Class Methods

=head2 new

 VUser::ExtLib::SQL->new($cfg, $paramters);
 
=over 4

=item $cfg

The config hash

=item $paramters

 { user => 'foo',
   password => 'bar',
   dsn => 'dbi:mysql:database=baz',
   macros => { 'u' => 'username',
               'p' => 'password'
              }
 }

=back

=cut

sub new {
    my $class = shift;
    my $cfg = shift;
    my $params = shift;
    
    my $self = {dns => undef,
                user => undef,
                password => undef,
                macros => {},
                _log => undef                
                };
    bless $self, $class; 

    if (UNIVERSAL::isa($class, 'VUser::ExtLib::SQL')) {
        $self->dsn($class->dsn());
        $self->user($class->user());
        $self->password($class->password());
        $self->macros($class->macros());
        $self->{_log} = $class->log();
    } else {
        if (defined $main::log
            and UNIVERSAL::isa($main::log, 'VUser::Log'))
        {
            $self->{_log} = $main::log;
        } else {
            $self->{_log} = VUser::Log->new($cfg, 'VUser::ExtLib::SQL');
        }
    }
    
    $self->dsn($params->{dns});
    $self->user($params->{user});
    $self->password($params->{password});
    $self->macros($params->{macros});    
    return $self;
}

=pod

=head2 execute

Execute a SQL query.

There are a few predefined macros that you can use in your
SQL. The values will be quoted and escaped before being inserted into
the SQL. You can specify your own custom macros if you use the OO
interface for VUser::ExtLib::SQL. See L<new|the new() method> above.

=over 4

=item %%

Unquoted %

=item %-option

This will be replaced by the value of --option passed in when vuser is called.

=item %$option

This will be replaced by the value of $args{option} passed to execute().
option may only match I<\w> or I<-> e.g. execute($cfg, $opts,
                          "select * from foo where bar = %$bar",
                          (bar => 'baz') )

execute() returns the statement handle after ->execute() has been run.
Remember to run ->finish() on the returned statement handle when you're
done with it.

=cut

sub execute {
    my $self;
    my $dbh;

    my $macros = '';
    my %macros = ();

    if (UNIVERSAL::isa($_[0], 'VUser::ExtLib::SQL')) {
        $self = shift;
        $dbh = $self->db_connect();
        $macros = join('|', keys %{$self->macros()});
        %macros = $self->macros();
    } elsif (UNIVERSAL::isa($_[0], '')) {
        $dbh = shift;
    }
    
    my $opts = shift;
    my $sql  = shift;
    my %args = @_;

    if ( not defined $sql or $sql =~ /^\s*$/ ) {
        log()->log( LOG_ERROR, "No SQL command given." );
        die "No SQL command given\n";
    }

    log()->log( LOG_DEBUG, "Original SQL: $sql" );

    # This will match the macros we are using
    my $re = qr/(?:%($macros|%|-[\w-]+|%[\w-]+))/o;

    # Pull the options out of the query
    my @options = $sql =~ /$re/g;

    # replace the options with ? placeholders
    $sql =~ s/$re/?/go;

    log()->log( LOG_DEBUG, "Options (" .scalar @options .'): ' . join( ', ', @options ) );
    log()->log( LOG_DEBUG, "New SQL: $sql" );

    my @passed_options = ();
    foreach my $opt (@options) {
        if ( defined $macros{$opt} ) {
            push @passed_options, $opts->{$macros{$opt}};
        } elsif ( $opt eq '%') {
            push @passed_options, '%';
        } elsif ( $opt =~ /^-([\w-]+)/ ) {
            push @passed_options, $opts->{$1};
        } elsif ( $opt =~ /^\$([\w-]+)/ ) {
            push @passed_options, $args{$1};
        }
    }

    log()->log( LOG_DEBUG, "Passed Options (" . scalar @passed_options .'): '
        . join( ', ', @passed_options ) );

    my $sth = $dbh->prepare($sql)
      or die "Cannot prepare SQL: ", $dbh->errstr, "\n";
    my $rc;
    if (@passed_options) {
        $rc = $sth->execute( @passed_options )
    } else {
        $rc = $sth->execute( )
    }
    die ("Cannot execute SQL: ", $sth->errstr, "\n") unless $rc;

    return $sth;
}

=pod

=head2 db_connect

Connect to the database.

Returns a DBI database handle.

=cut

sub db_connect {
    my $self;
    
    my $dsn;
    my $user;
    my $password;
    
    my $scope;
    
    if (UNIVERSAL::isa($_[0], 'VUser::ExtLib::SQL')) {
        $self = shift;
        $dsn = $self->dsn();
        $user = $self->user();
        $password = $self->password();
    } else {
        ($dsn, $user, $password) = @_;
    }
    
    $scope = shift || 'VUser::ExtLib::SQL';
    
    my $dbh =
      DBI->connect_cached( $dsn, $user, $password,
                           { private_vuser_cachekey => $scope } )
      or die $DBI::errstr;
    return $dbh;
}

=pod

=head1 Instance Methods

=head2 dsn

=head2 user

=head2 password

=cut

sub dsn { $_[0]->{dsn} = $_[1] if defined $_[1]; return $_[0]->{dsn}; }
sub user { $_[0]->{user} = $_[1] if defined $_[1]; return $_[0]->{user}; }
sub password { $_[0]->{password} = $_[1] if defined $_[1]; return $_[0]->{password}; }
sub macros { $_[0]->{macros} = $_[1] if defined $_[1]; return $_[0]->{macros}; }

sub log {
    my $self = shift;
    if (defined $self and UNIVERSAL::isa($self, 'VUser::ExtLib::SQL')) {
        return $self->{_log};
    } else {
        if (defined ($main::log) and UNIVERSAL::isa($main::log, 'VUser::Log')) {
            return $main::log;
        } elsif (defined $VUser::ExtLog::log
                 and UNIVERSAL::isa($main::log, 'VUser::Log')
                 ) {
            return $VUser::ExtLog::log;
        } else {
            # I need to create VUser::ExtLib::log but don't have a $cfg. Hmmm.
            die "I can't find a VUser::Log\n";
        }
    }
}

# Clean up after ourself
sub DESTROY {
    my $self = shift;
    my $cached_connections = $self->db_connect();
    %$cached_connections = () if $cached_connections;
}

1;