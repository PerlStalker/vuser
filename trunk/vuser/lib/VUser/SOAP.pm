package VUser::SOAP;

use warnings;
use strict;

# Copyright 2005 Randy Smith
# $Id: SOAP.pm,v 1.6 2005-03-25 20:14:29 perlstalker Exp $

use vars qw(@ISA);

our $REVISION = (split (' ', '$Revision: 1.6 $'))[1];
our $VERSION = $main::VERSION;

our %cfg;
our $eh;

sub version {
    return $VERSION;
}

sub hash_test {
    my $class = shift;
    my %hash = @_;
    print "Class: $class\n";
    use Data::Dumper; print Dumper \%hash;
    return 1;
}

sub do_fault
{
    print "Faulting\n";
    die SOAP::Fault
	->faultcode('Server.Custom')
	->faultstring('Oh! The humanity!');
}

sub AUTOLOAD
{
    use vars '$AUTOLOAD';
    my $class = shift;
    my %opts = @_;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;
    print "name: $name\n";
    if ($name =~ /^([^_]+)_([^_]+)$/) {
	my $keyword = $1;
	my $action = $2;
	print "Key: $keyword Act: $action\n";
	eval { $eh->run_tasks($keyword, $action, \%cfg, %opts); };
	if ($@) {
	    die SOAP::Fault
		->faultcode('Server.Custom')
		->faultstring($@)
		;
	}
    } else {
	return;
    }
}

1;

__END__

=head1 NAME

VUser::SOAP - SOAP interface to VUser.

=head1 SYNOPSIS

=head1 AUTHORS

Mark Bucciarelli <mark@gaiahost.coop>
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
