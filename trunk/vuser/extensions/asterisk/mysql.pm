package VUser::asterisk::mysql;
use warnings;
use strict;

# Copyright 2004 Randy Smith
# $Id: mysql.pm,v 1.1 2004-12-30 22:09:57 perlstalker Exp $

use DBI;

use lib('../..');
use ExtLib;

sub new
{
    my $class = shift;
    my $service = shift;
    my %cfg = @_;

    my $self = {_dbh => undef};

    bless $self, $class;
    $self->init($service, %cfg);

    return $self;
}

sub init
{
    my $self = shift;
    my $service = shift;
    my %cfg = @_;

    # Connect to DB here
    my $dsn = 'DBI:mysql:';
    $dsn .= 'database='.ExtLib::strip_ws($cfg{Extension_asterisk}{$service.'_dbname'});

    my $host = defined $cfg{Extension_asterisk}{$service.'_dbhost'} ?
	$cfg{Extension_asterisk}{$service.'_dbhost'} : 'localhost';
    $host = ExtLib::strip_ws($host);
    $dsn .= ";host=$host";

    my $port = defined $cfg{Extension_asterisk}{$service.'_dbport'} ?
	$cfg{Extension_asterisk}{$service.'_dbport'} : 3306;
    $dsn .= ";port=$port"
    
    my $user = defined $cfg{Extension_asterisk}{$service.'_dbuser'} ?
	$cfg{Extension_asterisk}{$service.'_dbuser'} : '';
    $user = ExtLib::strip_ws($user);

    my $pass = defined $cfg{Extension_asterisk}{$service.'_dbpass'} ?
	$cfg{Extension_asterisk}{$service.'_dbpass'} : '';
    $pass = ExtLib::strip_ws($pass);

    $self->{_dbh} = DBI->connect($dsn, $user, $pass);
}

sub sip_add {}
sub sip_del {}
sub sip_mod {}
sub sip_write {}

sub iax_add {}
sub iax_del {}
sub iax_mod {}
sub iax_write {}

sub ext_add {}
sub ext_del {}
sub ext_mod {}
sub ext_write {}

sub vm_add {}
sub vm_del {}
sub vm_mod {}
sub vm_write {}

1;

__END__

=head1 NAME

asterisk::mysql - asterisk mysql support

=head1 DESCRIPTION

=head1 AUTHOR

Randy Smith <perlstalker@gmail.com>

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
