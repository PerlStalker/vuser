package VUser::ActiveDirecory::OLE;
use warnings;
use strict;

# Copyright 2008 Randy Smith
# $Id: OLE.pm,v 1.1 2008-03-17 20:37:16 perlstalker Exp $

use VUser::Log qw(:levels);
use VUser::ExtLib qw(:config);
use VUser::ResultSet;
use VUser::Meta;
use VUser::ActiveDirectory;

use Win32::OLE qw(in);

our $VERSION = '0.1.0';

our $log;
our %meta;
our $c_sec = 'Extension ActiveDirectory';

sub c_sec { return $c_sec; };
sub depends { qw(ActiveDirectory); }

sub init {
	my $eh = shift;
	my %cfg = @_;
	
	$log = VUser::ActiveDirectory::Log();
}

1;

__END__

=head1 NAME

VUser::ActiveDirectory::OLE - VUser extension for managing ActiveDirectory via OLE.

=head1 DESCRIPTION

VUser extension for managing user and groups in Microsoft Active Directory via OLE. 

=head1 CONFIGURATION

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
