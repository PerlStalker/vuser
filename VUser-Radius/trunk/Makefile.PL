#!/usr/bin/perl

# Copyright 2005 Randy Smith <perlstalker@vuser.org>
# $Id: Makefile.PL,v 1.1 2006-08-16 19:55:54 perlstalker Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME            => 'VUser-Radius',
	      VERSION_FROM    => 'lib/VUser/Radius.pm',
	      INSTALLSCRIPT   => '$(PREFIX)/sbin',
	      PREREQ_PM       => {
				  'VUser::ExtLib'    => '0.2.1',
				  'VUser::ExtHandler'=> '0.2.1',
				  'VUser::Meta'      => '0.2.0',
				  'VUser::ResultSet' => '0.2.0',
				  'VUser::Extension' => '0.2.0',
				  'VUser::Log'       => '0.2.0',
				  }
	      );

__END__

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
