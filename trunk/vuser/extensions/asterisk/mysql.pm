package VUser::asterisk::mysql;
use warnings;
use strict;

# Copyright 2004 Randy Smith
# $Id: mysql.pm,v 1.2 2005-01-10 22:03:33 perlstalker Exp $

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
    die "Unable to connect to database: ".DBI->errstr."\n" unless $self->{_dbh};
}

# Takes a hash with the following keys:
#  name username secret context ipaddr port regseconds callerid
#  restrictcid mailbox
sub sip_add
{
    my $self = shift;
    my %user = @_;

    my @fields = keys %user; # to keep keys in same order.

    my $sql = "insert into sipfriends set ";
    #$sql = join ', ', map { "$_ = ?"; } grep { defined $user{$_}; } @fields;
    $sql .= join ', ', map { "$_ = ?"; } @fields;

    my $sth = $self->{_dbh}->prepare($sql)
	or die "Can't add SIP user: ".$self->{_dbh}->errstr."\n";

    $sth->execute(@user{@fields})
	or die "Can't add SIP user: ".$self->{_dbh}->errstr."\n";

    $sth->finish;
}

# Takes a hash with the following keys:
#  name context
sub sip_del
{
    my $self = shift;
    my %user = @_;

    my $sql = 'delete from sipfriends where name = ? and context = ?';
    my $sth = $self->{_dbh}->prepare($sql)
	or die "Can't delete SIP user: ".$self->{_dbh}->errstr."\n";
    $sth->execute($user{name}, $user{context})
	or die "Can't delete SIP user: ".$self->{_dbh}->errstr."\n";

    $sth->finish;
}

# Takes a hash with the following keys:
#  name username secret context ipaddr port regseconds callerid
#  restrictcid mailbox newname newcontext
sub sip_mod
{
    my $self = shift;
    my %user = @_;

    my @fields = grep { ! /^new/; } keys %user; # to keep keys in same order.

    my $sql = "update sipfriends set ";
    $sql .= join ', ', map { "$_ = ?"; } @fields;
    $sql .= ' where name = ? and context = ?';

    my $sth = $self->{_dbh}->prepare($sql)
	or die "Can't add SIP user: ".$self->{_dbh}->errstr."\n";

    $sth->execute(@user{@fields}, $user{newname}, $user{newcontext})
	or die "Can't add SIP user: ".$self->{_dbh}->errstr."\n";

    $sth->finish;
}

sub sip_exists
{ 
    my $self = shift;
    my $name = shift;
    my $context = shift;

    my $sql = 'select name, context from sipfriends where name = ? and context = ?';
    my $sth = $self->{_dbh}->prepare($sql)
	or die "Can't find SIP user: ".$self->{_dbh}->errstr."\n";

    $sth->execute($name, $context)
	or die "Can't find SIP user: ".$self->{_dbh}->errstr."\n";

    if ($sth->fetchrow) {
	return 1;
    } else {
	return 0;
    }
}

# name, secret, context, ipaddr, port, regseconds (mailbox)
sub iax_add {}
sub iax_del {}
sub iax_mod {}
sub iax_exists { 1; }

# context, extension, priority, application, args, descr, flags
sub ext_add
{
    my $self = shift;
    my %ext = @_;

    my @fields = keys %ext; # to keep keys in same order.

    my $sql = "insert into extensions set ";
    $sql .= join ', ', map { "$_ = ?"; } @fields;

    my $sth = $self->{_dbh}->prepare($sql)
	or die "Can't add extension: ".$self->{_dbh}->errstr."\n";

    $sth->execute(@ext{@fields})
	or die "Can't add extension: ".$self->{_dbh}->errstr."\n";

    $sth->finish;
}

sub ext_del
{
    my $self = shift;
    my %ext = @_;

    my $sql = "delete from extensions where extension = ? and context = ?";

    my $sth = $self->{_dbh}->prepare($sql)
	or die "Can't delete extension: ".$self->{_dbh}->errstr."\n";

    $sth->execute($ext{extension}, $ext->{context})
	or die "Can't delete extension: ".$self->{_dbh}->errstr."\n";

    $sth->finish;
}

sub ext_mod
{
    my $self = shift;
    my %ext = @_;

    my @fields = grep { ! /^new/; } keys %ext; # to keep keys in same order.

    my $sql = "update extensions set ";
    $sql .= join ', ', map { "$_ = ?"; } @fields;
    $sql .= ' where extension = ? and context = ?';

    my $sth = $self->{_dbh}->prepare($sql)
	or die "Can't add SIP user: ".$self->{_dbh}->errstr."\n";

    $sth->execute(@ext{@fields}, $ext{newext}, $ext{newcontext})
	or die "Can't add SIP user: ".$self->{_dbh}->errstr."\n";

    $sth->finish;
}

sub ext_exists
{
    my $self = shift;
    my $ext = shift;
    my $context = shift;

    my $sql = 'select name, context from extensions where extensions = ? and context = ?';
    my $sth = $self->{_dbh}->prepare($sql)
	or die "Can't find extension: ".$self->{_dbh}->errstr."\n";

    $sth->execute($ext, $context)
	or die "Can't find extension: ".$self->{_dbh}->errstr."\n";

    if ($sth->fetchrow) {
	return 1;
    } else {
	return 0;
    }
    1;
}

sub vm_add {}
sub vm_del {}
sub vm_mod {}
sub vm_exists { 1; }

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
