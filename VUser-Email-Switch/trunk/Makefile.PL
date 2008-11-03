#!/usr/bin/perl

# Copyright 2005 Randy Smith <perlstalker@gmail.com>
# $Id: Makefile.PL,v 1.1 2007-09-21 15:28:34 perlstalker Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME            => 'VUser-Email-Switch',
	      VERSION_FROM    => 'lib/VUser/Email/Switch.pm',
	      PREREQ_PM       => {'VUser::Email'      => 0,
				  'VUser::ExtHandler' => '0.3.2',
				  'VUser::Log'        => 0
				  }
	      );

__END__

=head1 AUTHOR

Randy Smith <perlstalker@gmail.com>

=head1 LICENSE
 
 This file is part of VUser-Email-Switch.
 
 VUser-Email-Switch is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 VUser-Email-Switch is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with VUser-Email-Switch; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
