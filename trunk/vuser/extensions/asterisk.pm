package asterisk;
use warnings;
use strict;

# Copyright 2004 Randy Smith
# $Id: asterisk.pm,v 1.1 2004-12-27 18:36:50 perlstalker Exp $

use vars qw(@ISA);

our $REVISION = (split (' ', '$Revision: 1.1 $'))[1];
our $VERSION = $main::VERSION;

use Extension;
push @ISA, 'Extension';

sub config_sample
{
    my $fh;
    if (defined $opts->{file}) {
	open ($fh, ">".$opts->{file})
	    or die "Can't open '".$opts->{file}."': $!\n";
    } else {
	$fh = \*STDOUT;
    }

    print $fh <<'CONFIG';
[Extension_asterisk]
# The location of the asterisk config files.
etc=/etc/asterisk

# The name of the file to write for SIP friends.
# I recommend writting to some place other than sip.conf and including that
# file from sip.conf.
sip.conf=sip.vuser

# SIP database info.
sip_dbtype=mysql
sip_dbuser=asterisk
sip_dbpass=secret
sip_dbhost=localhost
sip_dbname=asterisk
sip_dbport=3306

# The name of the file to write for IAX friends.
# I recommend writting to some place other than iax.conf and including that
# file from iax.conf.
iax.conf=iax.vuser

# IAX database info.
iax_dbtype=mysql
iax_dbuser=asterisk
iax_dbpass=secret
iax_dbhost=localhost
iax_dbname=asterisk
iax_dbport=3306

# The name of the file to write extension data to.
extensions.conf=extensions.vuser

# Extension database info.
ext_dbtype=mysql
ext_dbuser=asterisk
ext_dbpass=secret
ext_dbhost=localhost
ext_dbname=asterisk
ext_dbport=3306

CONFIG

    if (defined $opts->{file}) {
	close CONF;
    }
}

sub init
{
    my $eh = shift;
    my %cfg = @_;

    # Config
    $eh->register_task('config', 'sample', \&config_sample);

    # SIP
    $eh->register_keyword('sip');

    # SIP-add
    $eh->register_action('sip', 'add');
    $eh->register_option('sip', 'add', 'name', '=s');
    $eh->register_option('sip', 'add', 'username', '=s');
    $eh->register_option('sip', 'add', 'secret', '=s');
    $eh->register_option('sip', 'add', 'context', '=s');
    $eh->register_option('sip', 'add', 'ipaddr', '=s');
    $eh->register_option('sip', 'add', 'port', '=i');
    $eh->register_option('sip', 'add', 'regseconds', '=i');
    $eh->register_option('sip', 'add', 'callerid', '=s');
    $eh->register_option('sip', 'add', 'restrictcid', '');

    # SIP-del
    $eh->register_action('sip', 'del');
    $eh->register_option('sip', 'del', 'name', '=s');

    # SIP-mod
    $eh->register_action('sip', 'mod');

    # IAX
    $eh->register_keyword('iax');
    $eh->register_action('iax', 'add');
    $eh->register_action('iax', 'del');
    $eh->register_action('iax', 'mod');

    # Extensions
    $eh->register_keyword('ext');
    $eh->register_action('ext', 'add');
    $eh->register_action('ext', 'del');
    $eh->register_action('ext', 'mod');

    # Voice mail
    $eh->register_keyword('vm');
    $eh->register_action('vm', 'add');
    $eh->register_action('vm', 'del');
    $eh->register_action('vm', 'mod');

    # Asterisk control
    $eh->register_keyword('asterisk');
    $eh->register_action('asterisk', 'write');   # force a write
    $eh->register_action('asterisk', 'restart'); # force a restart
}

1;

__END__

=head1 NAME

asterisk - vuser asterisk support extension

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
