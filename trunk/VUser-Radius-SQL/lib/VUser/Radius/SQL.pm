package VUser::Radius::SQL;
use warnings;
use strict;

# Copyright 2006 Randy Smith <perlstalker@vuser.org>
# $Id: SQL.pm,v 1.3 2006-08-17 22:26:32 perlstalker Exp $

use VUser::ExtLib qw(:config);
use VUser::Log qw(:levels);
use DBI;

my $log;
my %meta;

our $VERSION = '0.1.0';
my $c_sec = 'Extension Radius::SQL';

my $dsn;
my $username;
my $password;

sub depends { return qw(Radius); }

sub init {
    my $eh = shift;
    my %cfg = @_;

    if (defined $main::log) {
        $log = $main::log;
    } else {
        $log = VUser::Log->new(\%cfg, 'vuser')
    }

    $dsn = strip_ws($cfg{$c_sec}{'dsn'});
    $username = strip_ws($cfg{$c_sec}{'username'});
    $password = strip_ws($cfg{$c_sec}{'password'});

    $eh->register_task('radius', 'adduser', \&do_sql);
    $eh->register_task('radius', 'rmuser', \&do_sql);
    $eh->register_task('radius', 'moduser', \&radius_moduser);
    $eh->register_task('radius', 'listusers', \&radius_listusers);
    $eh->register_task('radius', 'userinfo', \&radius_userinfo);

    $eh->register_task('radius', 'addattrib', \&do_sql);
    $eh->register_task('radius', 'modattrib', \&do_sql);
    $eh->register_task('radius', 'rmattrib', \&do_sql);
    $eh->register_task('radius', 'listattrib', \&radius_listattrib);
}

sub unload {
    my $cached_connections = db_connect();
    %$cached_connections = () if $cached_connections;
}

sub db_connect {
    my $cfg = shift;

    unless (defined $dsn
	    and defined $username
	    and defined $password) {
	$dsn = strip_ws($cfg->{$c_sec}{'dsn'});
	$username = strip_ws($cfg->{$c_sec}{'username'});
	$password = strip_ws($cfg->{$c_sec}{'password'});
    }

    my $dbh = DBI->connect_cached($dsn, $username, $password,
				  { private_vuser_cachekey => 'VUser::Radius::SQL' }
				  )
	or die $DBI::errstr;
    return $dbh;
}


 ## SQL Queries
 # Here you define the queries used to add, modify and delete users and
 # attributes. There are a few predefined macros that you can use in your
 # SQL. The values will be quoted and escaped before being inserted into
 # the SQL.
 #  %u => username
 #  %p => password
 #  %r => realm
 #  %a => attribute name
 #  %v => attribute value
 #  %-option => This will be replaced by the value of --option passed in
 #              when vuser is called.
 #  %%option => This will be replaced by the value of $args{option} passed
 #              to execute(). option may only match \w or -
 #              e.g. execute($cfg, $opts,
 #                           "select * from foo where bar = %%bar",
 #                           (bar => 'baz') )
 # 
 # execute() returns the statement handle after ->execute() has been run.
 # Remember to run ->finish() on the returned statement handle when you're
 # done with it.
sub execute {
    my $cfg = shift;
    my $opts = shift;
    my $sql = shift;
    my %args = @_;

    my $dbh = db_connect($cfg);

    $log->log(LOG_DEBUG, "Original SQL: $sql");

    my $re = qr/(?:%(u|p|r|a|v|-[\w-]+|%[\w-]+))/o;

    # Pull the options out of the query
    my @options = $sql =~ /$re/g;

    # replace the options with ? placeholders
    $sql =~ s/$re/?/go;

    $log->log(LOG_DEBUG, "Options: ".join(' ', @options));
    $log->log(LOG_DEBUG, "New SQL: $sql");

    my @passed_options = ();
    foreach my $opt (@passed_options) {
	if ($opt eq 'u') {
	    push @passed_options, $opts->{'username'};
	} elsif ($opt eq 'p') {
	    push @passed_options, $opts->{'password'};
	} elsif ($opts eq 'r') {
	    push @passed_options, $opts->{'realm'};
	} elsif ($opts eq 'a') {
	    push @passed_options, $opts->{'attribute'};
	} elsif ($opts eq 'v') {
	    push @passed_options, $opts->{'value'};
	} elsif ($opts =~ /^-([\w-]+)/) {
	    push @passed_options, $opts->{$1};
	} elsif ($opts =~ /^%([\w-]+)/) {
	    push @passed_options, $args{$1};
	}
    }

    my $sth = $dbh->prepare($sql)
	or die "Cannot prepare SQL: ", $dbh->errstr, "\n";
    $sth->execute($sql, @passed_options)
	or die "Cannot execute SQL: ", $sth->errstr, "\n";

    return $sth;
}

sub do_sql {
    my ($cfg, $opts, $action, $eh) = @_;

    my $sql;
    if ($action eq 'adduser') {
	$sql = strip_ws($cfg->{$c_sec}{'adduser_query'});
    } elsif ($action eq 'rmuser') {
	$sql = strip_ws($cfg->{$c_sec}{'rmuser_query'});
    } elsif ($action eq 'addattrib') {
	   if ($opts->{'type'} == 'check') {
	      $sql = strip_ws($cfg->{$c_sec}{'addattrib_check_query'});
	   } elsif ($opts->{'type'} == 'reply') {
	      $sql = strip_ws($cfg->{$c_sec}{'addattrib_reply_query'});
	   }
    } elsif ($action eq 'rmattrib') {
	   if ($opts->{'type'} == 'check') {
	       $sql = strip_ws($cfg->{$c_sec}{'rmattrib_check_query'});
	   } elsif ($opts->{'type'} == 'reply') {
	       $sql = strip_ws($cfg->{$c_sec}{'rmattrib_reply_query'});
	   }
    } elsif ($action eq 'modattrib') {
	   if ($opts->{'type'} == 'check') {
	       $sql = strip_ws($cfg->{$c_sec}{'modattrib_check_query'});
	   } elsif ($opts->{'type'} == 'reply') {
	       $sql = strip_ws($cfg->{$c_sec}{'modattrib_reply_query'});
	   }
    }

    my $sth = execute($cfg, $opts, $sql);
    $sth->finish;
}

sub radius_adduser {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub radius_rmuser {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub radius_moduser {
    my ($cfg, $opts, $action, $eh) = @_;

    ## change password
    if ($opts->{newpassword}) {
        execute($cfg, $opts, strip_ws($cfg->{$c_sec}{'moduser_password_query'}));
    }
    ## change realm only
    if ($opts->{newrealm} and not $opts->{newusername}) {
        execute($cfg, $opts, strip_ws($cfg->{$c_sec}{'moduser_realm_query'}));
    }
    ## change username only
    if ($opts->{newusername} and not $opts->{newrealm}) {
        execute($cfg, $opts, strip_ws($cfg->{$c_sec}{'moduser_username_query'}));
    }
    ## change username and realm
    if ($opts->{newusername} and $opts->{newrealm}) {
        execute($cfg, $opts, strip_ws($cfg->{$c_sec}{'moduser_userrealm_query'}));
    }
}

sub radius_listusers {
    my ($cfg, $opts, $action, $eh) = @_;
    
    my $rs = VUser::ResultSet->new();
    $rs->add_meta($VUser::Radius::meta{'username'});
    $rs->add_meta($VUser::Radius::meta{'realm'});
    
    my $sth = execute ($cfg, strip_ws($cfg->{$c_sec}{'listusers_query'}));
    my @results;
    while (@results = $sth->fetchrow_array) {
        $rs->add_data([@results[0..1]]);
    }
    
    $sth->finish;
    return $rs;
}

sub radius_userinfo {
    my ($cfg, $opts, $action, $eh) = @_;

    my $rs = VUser::ResultSet->new();
    $rs->add_meta($VUser::Radius::meta{'username'});
    $rs->add_meta($VUser::Radius::meta{'realm'});
    $rs->add_meta($VUser::Radius::meta{'password'});
    
    my $sth = execute ($cfg, strip_ws($cfg->{$c_sec}{'userinfo_query'}));
    my @results;
    while (@results = $sth->fetchrow_array) {
        $rs->add_data([@results[0..3]]);
    }
    
    $sth->finish;
    return $rs;
}

sub radius_addattrib {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub radius_modattrib {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub radius_rmattrib {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub radius_listattrib {
    my ($cfg, $opts, $action, $eh) = @_;

    my $sql;
    if ($opts->{'type'} == 'check') {
	   $sql = strip_ws($cfg->{$c_sec}{'listattrib_check_query'});
    } elsif ($opts->{'type'} == 'reply') {
        $sql = strip_ws($cfg->{$c_sec}{'listattrib_reply_query'});
    }

    ## Build resultset
    my $rs = VUser::ResultSet->new();
    $rs->add_meta($VUser::Radius::meta{'username'});
    $rs->add_meta($VUser::Radius::meta{'realm'});
    $rs->add_meta($VUser::Radius::meta{'attribute'});
    $rs->add_meta($VUser::Radius::meta{'type'});
    $rs->add_meta($VUser::Radius::meta{'value'});
    
    my $sth = execute($cfg, $opts, $sql);
    
    my @results;
    while (@results = $sth->fetchrow_array) {
        $rs->add_data([@results[0..3]]);
    }

    $sth->finish;
    return $rs;
}

1;

__END__

=head1 NAME

VUser::Radius::SQL - SQL support for the VUser::Radius vuser extension

=head1 DESCRIPTION

Adds support for storing RADIUS user information in a SQL database.

=head1 CONFIGURATION

 [vuser]
 extensions = Radius::SQL
 
 [Extension Radius::SQL]
 # Database driver to use.
 # The DBD::<driver> must exist or vuser will not be able to connect
 # to your database.
 # See perldoc DBD::<driver> for the format of this string for your database.
 dsn = DBI:mysql:database=database_name;host=localhost;post=3306

 # Database user name
 username = user
 
 # Database password
 # The password may not end with whitespace.
 password = secret
 
 ## SQL Queries
 # Here you define the queries used to add, modify and delete users and
 # attributes. There are a few predefined macros that you can use in your
 # SQL. The values will be quoted and escaped before being inserted into
 # the SQL.
 #  %u => username
 #  %p => password
 #  %r => realm
 #  %a => attribute name
 #  %v => attribute value
 #  %-option => This will be replaced by the value of --option passed in
 #              when vuser is run.
 
 # Add a RADIUS account
 adduser_query = INSERT into user set user = %u, password = %p, realm = %r
 
 # Delete a RADIUS account
 rmuser_query = DELETE from user where user = %s and realm = %r
 
 # Change a user's password
 moduser_password_query = UPDATE user set ...
 
 # Change an account's realm only
 moduser_realm_query = UPDATE user set ...
 
 # Change an account's username only
 moduser_username_query = UPDATE user set ...
 
 # Change both the username and the realm
 moduser_userrealm_query = UPDATE user set ...
 
 # Here, we need a way to map columns to values
 # Fixed columns:
 #   1 username
 #   2 realm
 listusers_query = SELECT username, realm from user
 
 # Here, we need a way to map columns to values
 # Fixed columns:
 #   1 username
 #   2 realm
 #   3 password
 userinfo_query = SELECT * from user where user = %s and realm = %r
 
 addattrib_check_query = INSERT into ...
 rmattrib_check_query  = DELETE from ...
 modattrib_check_query = UPDATE ...
 listattrib_check_query = SELECT ...
 
 addattrib_reply_query = INSERT into ...
 rmattrib_reply_query  = DELETE from ...
 modattrib_reply_query = UPDATE ...
 listattrib_reply_query = SELECT ...

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE
 
 This file is part of vuser.
 
 vuser is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vuser is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vuser; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut

