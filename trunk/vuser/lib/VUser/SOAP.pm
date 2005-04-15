package VUser::SOAP;

use warnings;
use strict;

# Copyright 2005 Randy Smith
# $Id: SOAP.pm,v 1.9 2005-04-15 19:21:44 perlstalker Exp $

use vars qw(@ISA);

our $REVISION = (split (' ', '$Revision: 1.9 $'))[1];
our $VERSION = $main::VERSION;

our %cfg;
our $eh;

use VUser::ACL;

sub version {
    return $main::VERSION;
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

# This was written as a cheap hack to get data to a soap client I had
# written that uses vuser to do some local stuff. There should be a nicer
# way to do this but I haven't taken the time to work one out.
sub get_data
{
    my $class = shift;
    my $user = shift; # username for future ACLs
    my $pass = shift; # username for future ACLs
    my $pkg = shift;
    my $func = shift;
    my $opts = shift;

    # Check ACL here.

    # Should to options checking here like what is done in run_tasks()
    my $data = $pkg->$func(\%cfg, $opts);
    #use Data::Dumper; print Dumper $data;
    return $data;
}

# Get a list of keywords for a soap client.
sub get_keywords
{
    my $class = shift;
    my $user = shift; # For ACL
    my $pass = shift; # For ACL

    my @keywords = ();
    foreach my $keyword ($eh->get_keywords) {
	push @keywords, {keyword => $keyword,
			 description => $eh->get_description($keyword)};
    }
    return @keywords;
}

sub get_actions
{
    my $class = shift;
    my $user = shift; # username for ACL
    my $pass = shift; # password
    my $keyword = shift;

    my @actions = ();
    foreach my $action ($eh->get_actions($keyword)) {
	push @actions, {action => $action,
			description => $eh->get_description($keyword, $action)
			};
    }
    return @actions;
}

sub get_options
{
    my $class = shift;
    my $user = shift;
    my $pass = shift;
    my $keyword = shift;
    my $action = shift;

    my @options = ();
    foreach my $option ($eh->get_options($keyword, $action)) {
	push @options, {option => $option,
			description => $eh->get_description($keyword,
							    $action,
							    $option)
			};
    }
    return @options;
}

sub authenticate
{
    my $class = shift;
    my $user = shift;
    my $pass = shift;

    return 1;
}

sub check_acl
{
    my $class = shift;
    my $user = shift;
    # Need the pass? I don't think so.
    my $keyword = shift;
    my $action = shift;
    my $opt_name = shift;
    my $opt_value = shift;

    return 1;
}

sub AUTOLOAD
{
    use vars '$AUTOLOAD';
    my $class = shift;
    my $user = shift; # User name (For future ACLs)
    my $pass = shift; # Password  (for Future ACLs)
    my %opts = @_;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;
    #print "name: $name\n";
    if ($name =~ /^([^_]+)_([^_]+)$/) {
	my $keyword = $1;
	my $action = $2;
	#print "Key: $keyword Act: $action\n";
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
