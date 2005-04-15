#!/usr/bin/perl
use warnings;
use strict;

# Copyright 2005 Randy Smith
# $Id: vsoapc.cgi,v 1.1 2005-04-15 22:15:43 perlstalker Exp $

# Called as:
#  vsoapc.cgi/keyword/action/
#  vsoapc.cgi/keyword/
#  vsoapc.cgi

use Config::IniFiles;
use Text::Template;
use SOAP::Lite;
use FindBin;
use CGI;
use CGI::Carp qw/fatalsToBrowser/;

our $REVISION = (split (' ', '$Revision: 1.1 $'))[1];
our $VERSION = '0.1.0';

my $title = "vuser $VERSION - $REVISION";

our $DEBUG = 0;

BEGIN {

    our @etc_dirs = ('/usr/local/etc',
		     '/usr/local/etc/vuser',
		     '/etc',
		     '/etc/vuser',
		     "$FindBin::Bin/../etc",
		     "$FindBin::Bin",
		     "$FindBin::Bin/../",
                     "$FindBin::Bin/vuser",
                     "$FindBin::Bin/../etc/vuser"
                     );
}

use vars qw(@etc_dirs);

use lib (map { "$_/extensions" } @etc_dirs);
use lib (map { "$_/lib" } @etc_dirs);

use VUser::ExtLib;
use VUser::Widget;

my $config_file;
for my $etc_dir (@etc_dirs)
{
    if (-e "$etc_dir/vuser.conf") {
	$config_file = "$etc_dir/vuser.conf";
	last;
    }
}

if (not defined $config_file) {
    die "Unable to find a vuser.conf file in ".join (", ", @etc_dirs).".\n";
}

my %cfg;
tie %cfg, 'Config::IniFiles', (-file => $config_file);

my $template_dir = VUser::ExtLib::strip_ws($cfg{'vsoapc.cgi'}{'template dir'});
$template_dir = "$FindBin::Bin/templates" unless $template_dir;

my $session_dir = VUser::ExtLib::strip_ws($cfg{'vsoapc.cgi'}{'session dir'});
$session_dir = "$FindBin::Bin/sessions" unless $session_dir;

my $vuser_host = VUser::ExtLib::strip_ws($cfg{'vsoapc.cgi'}{'vsoap host'});
$vuser_host = 'http://localhost:8080/' unless $vuser_host;
$vuser_host .= '/' unless $vuser_host =~ m|/$|;

my $q = new CGI;

# Commands:
#  Login
#  get actions
#  get options
#  do action
#  logout
my $cmd = $q->param('cmd') || '';

my $path_info = $q->path_info();
# $other should never be defined but I want to be sure that I can easily
# get $keyword and $action if someone does something stupid.
my ($keyword, $action, $other) = split '/', $path_info;

# URL of this script. Suitable for use in <form action="$url">
my $url = $q->url('-path');

my $session = $q->param('session');
my %sess = ();
if (not defined $session
    or not -e "$session_dir/$session") {
    # No session. User must log in again.
    login_page();
    exit;
} else {
    if (open (SESS, "$session_dir/$session")) {
	$sess{'ip'} = <SESS>;
	$sess{'user'} = <SESS>;
	$sess{'pass'} = <SESS>;
	close SESS;
    } else {
	login_page("Unable to get session data: $!");
	exit;
    }
}

sub login_page
{
    my $message = shift || '';
    
    my $user;
    if ($cmd eq 'Login') {
	$user = VUser::ExtLib::strip_ws($q->param('user'));
	my $pass = $q->param('password'); # password may start/end with ws
	if ($user and $pass
	    and SOAP::Lite
	    -> url($vuser_host.'VUser/SOAP')
	    -> proxy($vuser_host)
	    -> authenticate($user, $pass)
	    -> result) {
	    $session = VUser::ExtLib::generate_password(20, 'a' .. 'z',
							'A' .. 'Z',
							0 .. 9);
	    if (open (SESS, ">$session_dir/$session")) {
		print SESS "$ENV{REMOTE_ADDR}\n";
		print SESS "$user";
		print SESS "$pass";
		close SESS;
		return;
	    } else {
		$message = 'Unable to write session data: $!';
	    }
	} else {
	    $message = 'Bad user name or password.';
	}
    }
    # Show the login page
    my $args = {user => $user,
		title => "Please log in - $title",
		url => $url
		};

    print $q->header;
    my $template = Text::Template->new (TYPE => 'FILE',
					SOURCE => "$template_dir/login.html",
					DELIMITERS => ['{', '}']
					)
	or die "Template error: $Text::Template::ERROR";
    $template->fill_in(OUTPUT => \*STDOUT,
		       HASH => $args
		       );
}

sub choose_keyword {
}

__END__

=head1 NAME

vsoapc.cgi - Web interface for vuser that uses vsoapd.

=head1 SYNOPSIS

=head1 OPTIONS

=head1 DESCRIPTION

=head1 BUGS

=head1 SEE ALSO

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
