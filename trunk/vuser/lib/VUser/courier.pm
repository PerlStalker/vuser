package VUser::courier;
use warnings;
use strict;

# Copyright 2004 Randy Smith
# $Id: courier.pm,v 1.1 2004-12-30 22:09:56 perlstalker Exp $

use vars qw(@ISA);

our $REVISION = (split (' ', '$Revision: 1.1 $'))[1];
our $VERSION = $main::VERSION;

use Pod::Usage;

use VUser::Extension;
push @ISA, 'VUser::Extension';

my $authlib;

sub config_sample
{
    my $cfg = shift;
    my $opts = shift;

    my $fh;
    if (defined $opts->{file}) {
	open ($fh, ">".$opts->{file})
	    or die "Can't open '".$opts->{file}."': $!\n";
    } else {
	$fh = \*STDOUT;
    }

    print $fh <<'CONFIG';
[Extension_courier]
# the location of the courier configuration
etc=/etc/courier

# the user/group that the MDA will run as
user=courier
group=courier

# the command to run to restart courier
courier_rc=/usr/local/etc/rc.d/courier.sh

# These commands may be wrapped but they MUST take the same options
# as the commands themselves.

# the path to makehosteddomains.
# This may also be any command that wraps makehosteddomains.
# makehosteddomains=chroot /netboot/beta /usr/local/sbin/makehosteddomains
makehosteddomains=/usr/sbin/makehosteddomains

# the path to makeacceptmailfor.
# This may also be any command that wraps makeacceptmailfor.
# makeacceptmailfor=chroot /netboot/beta /usr/local/sbin/makeacceptmailfor
makeaccptmailfor=/usr/sbin/makeacceptmailfor

# the path to couriermlm
# This may be a wrapper as above.
# couriermlm=chroot /netboot/beta /usr/local/sbin/couriermlm
couriermlm=/usr/bin/couriermlm

# The location of the files which are copies into a brand new home dir
skeldir=/usr/local/etc/courier/skel

# Set to 1 to force user names to lower case
lc_user = 0

# the domain to use if the account doesn't have one
default domain=example.com

# Given $user and $domain, where will the user's home directory be located?
# This may be a valid perl expression.
#
# PerlStalker's scheme:
# domaindir="/var/mail/virtual/$domain"
# userhomedir="/var/mail/virtual/$domain/".substr($user, 0, 2)."/$user"
#
# stew's scheme:
domaindir="/home/virtual/$domain"
userhomedir="/home/virtual/$domain/var/mail/$user"

# which authentication system to use
# Only 'mysql' is supported currently.
authlib=mysql

mysql_server=localhost
mysql_username=courier
mysql_password=secret
mysql_socket=/tmp/mysql.sock
mysql_port=3306
mysql_database=
mysql_user_table=
mysql_crypt_pwfield=
mysql_clear_pwfield=
mysql_uid_field=
mysql_gid_field=
mysql_login_field=
mysql_home_field=
mysql_name_field=
mysql_maildir_field=
mysql_quota_field=
mysql_auxoptions_field=
mysql_alias_field=aliasfor

list_prefix=list

CONFIG

    if (defined $opts->{file}) {
	close CONF;
    }
}

sub init
{
    my $eh = shift;
    my %cfg = @_;

    if ($cfg{Extension_courier}{authlib} =~ /mysql/) {
	require courier::mysql;
	$authlib = new courier::mysql(%cfg);
    } else {
	die "Unsupported courier authlib '$cfg{Extension_courier}{authlib}'\n";
    }

    # Config
    $eh->regiter_task('config', 'sample', \&config_sample);

    # email
    $eh->register_keyword('email');
    $eh->register_action('email', 'add');
    $eh->register_task('email', 'add', \&email_add, 0);
    $eh->register_option('email', 'add', 'account', '=s');
    $eh->register_option('email', 'add', 'name', '=s');
    $eh->register_option('email', 'add', 'password', '=s');
    $eh->register_option('email', 'add', 'quota', '=s');
}

sub email_add
{
    my $cfg = shift;
    my $opts = shift;

    # ... other stuff?

    my $account = $opts->{account};
    my $user, $domain;
    if ($account =~ /^(\S+)\@(\S+)$/) {
	$user = $1;
	$domain = $2;
    } else {
	$user = $account;
	$domain = $cfg{Extension_courier}{'default domain'};
	$domain =~ s/^\s*(\S+)\s*/$1/;
    }

    if ($authlib->user_exists($account)) {
	die "Unable to add email: address exists\n";
    }

    # ... more stuff
}

sub generate_password
{
    my $len = shift || 10;
    my @valid = (0..9, 'a'..'z', 'A'..'Z', '@', '#', '%', '^', '*');
    my $password = '';
    for (1 .. $len)
    {
        $password .= $valid[int (rand $#valid)];
    }
    return $password;
}

sub mkdir_p
{
    my ($dir, $mode, $uid, $gid) = @_;
    $dir =~ s/\/$//;

    if( -e "$dir" )
    {
	return 1;
    }

    my $parent = $dir;
    $parent =~ s/\/[^\/]*$//;

    if( !$parent ) { return 0; }
    else 
    { 
	return mkdir_p( $parent, $mode, $uid, $gid ) 
	    && mkdir( $dir ) 
	    && chown( $uid, $gid, $dir );
    }
}

sub add_line_to_file
{
    my ($file, $line) = @_[0,1];

    open (FILE, ">>$file") or die "Can't open $file: $!\n";
    print FILE "$line\n";
    close FILE;
}

sub del_line_from_file
{
    my ($file, $line) = @_[0,1];

    while (-e "$file.tmp") { sleep(rand(int 3)); }

    open (FILE, $file) or die "Can't open $file: $!\n";
    open (TMP, ">$file.tmp") or die "Can't open $file.tmp: $!\n";
    while (<FILE>)
    {
	chomp;
	print TMP "$_\n" unless /^\Q$line\E$/;
    }
    close FILE;
    close TMP;

    rename ("$file.tmp", $file) or die "Can't rename $file.tmp to $file: $!\n";
}

sub repl_line_in_file
{
    my ($file, $oline, $nline) = @_[0..2];

    while (-e "$file.tmp") { sleep(rand(int 3)); }

    open (FILE, $file) or die "Can't open $file: $!\n";
    open (TMP, ">$file.tmp") or die "Can't open $file.tmp: $!\n";
    while (<FILE>)
    {
	chomp;
	if (/^\Q$oline\E$/)
	{
	    print TMP "$nline\n";
	}
	else
	{
	    print TMP "$_\n";
	}
	
    }
    close FILE;
    close TMP;

    rename "$file.tmp", $file or die "Can't rename $file.tmp to $file: $!\n";
}

1;

__END__

=head1 NAME

courier - vuser courier-mta support extension

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