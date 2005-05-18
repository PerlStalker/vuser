package VUser::SOAP;

use warnings;
use strict;

# Copyright 2005 Randy Smith
# $Id: SOAP.pm,v 1.10 2005-05-18 20:16:08 perlstalker Exp $

use vars qw(@ISA);

our $REVISION = (split (' ', '$Revision: 1.10 $'))[1];
our $VERSION = $main::VERSION;

our %cfg;
our $eh;

use VUser::ACL;
my $acl;

sub init
{
    $eh = shift;
    %cfg = @_;

    $acl = new VUser::ACL (\%cfg);
    $acl->load_auth_modules(\%cfg);
    $acl->load_acl_modules(\%cfg);
}

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
    # This doesn't fit the current ACL model. :-(
    # $class->check_acls(...)

    # Should do options checking here like what is done in run_tasks()
    my $data = $pkg->$func(\%cfg, $opts);
    #use Data::Dumper; print Dumper $data;
    return $data;
}

sub get_data2
{
    my $class = shift;
    my $user = shift;
    my $pass = shift;
    my $ip = shift;
    my $keyword = shift;
    my $opts = shift;

    # Check ACLs
    # Special flag for action?
    check_acl(\%cfg, $user, $pass, $ip, $keyword, undef, $opts);
}

# Get a list of keywords for a soap client.
sub get_keywords
{
    my $class = shift;
    my $user = shift; # For ACL
    my $pass = shift; # For ACL
    my $ip = shift;   # for ACL

    my @keywords = ();
    foreach my $keyword ($eh->get_keywords) {
	eval { $acl->check_acls($user, $pass, $ip, $keyword); };
	warn $@ if $@;
	next if $@;
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
    my $ip = shift;

    if ($acl->auth_user(\%cfg, $user, $pass, $ip)) {
	return 1;
    } else {
	return 0;
    }
}

sub check_acl
{
    my $class = shift;
    my $user = shift;
    my $pass = shift;
    my $ip = shift;
    my $keyword = shift;
    my $action = shift;
    my $opts = shift;

    if (not $acl->auth_user(\%cfg, $user, $pass, $ip) eq ALLOW()) {
	die "Bad user name or password.";
    }

    # Check ACLs
    if (not $acl->check_acls(\%cfg, $user, $ip, $keyword) eq ALLOW()) {
	die "Permission denied for $user on $keyword";
    }

    if ($action
	and not $acl->check_acls(\%cfg, $user, $ip, $keyword, $action) eq ALLOW()) {
	die "Permission denied for $user on $keyword - $action";
    }

    if ($action and $opts) {
	foreach my $key (keys %$opts) {
	    if (not $acl->check_acls(\%cfg,
				     $user, $ip,
				     $keyword, $action,
				     $key, $opts->{$key}
				     ) eq ALLOW()) {
		die "Permission denied for $user on $keyword - $action - $key";
	    }
	}
    }

    return 1;
}

=pod

{
    # key is the name of the option to pass to set and what is passed
    # to the client from the server on get calls.
    option => { default => [],
		description => '',
		widget => 'select', # or text, hidden, etc.
		values => [], # only for select, radio, checkbox
		labels => [], # labels for values,
		index => 0, #/1. If >0, this key is an index value and searchable
		mode = 'r' # Or 'w'. r => read-only, w => read-write
	     }
}

=cut

sub get_meta_data
{
    my $class = shift;
    my $user = shift;
    my $pass = shift;
    my $ip = shift;
    my $keyword = shift;
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
