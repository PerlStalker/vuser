#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use warnings;
use strict;

# Copyright (c) 2006 Randy Smith
# $Id: gen-wsdl.pl,v 1.1 2006-09-25 22:54:16 perlstalker Exp $

our $REVISION = (split (' ', '$Revision: 1.1 $'))[1];
our $VERSION = "0.1.0";

our $DEBUG = 0;

use FindBin;

BEGIN {

    our @etc_dirs = (
		             "$FindBin::Bin/../etc",
		             "$FindBin::Bin",
		             "$FindBin::Bin/..",
                     "$FindBin::Bin/vuser",
                     "$FindBin::Bin/../vuser",
                     "$FindBin::Bin/../etc/vuser",
                     '/usr/local/etc',
		             '/usr/local/etc/vuser',
		             '/etc',
		             '/etc/vuser',
                     );
}

use vars qw(@etc_dirs);

use Config::IniFiles;
use Getopt::Long;

use lib (map { "$_/extensions" } @etc_dirs);
use lib (map { "$_/lib" } @etc_dirs);

use VUser::ExtLib;
use VUser::ExtHandler;
use VUser::Log qw(:levels);

my $config_file;
my $debug = 0;
my @keywords = ();
my $result = GetOptions( "config=s" => \$config_file,
                         "debug|d+" => \$debug,
                         "keywords=s" => \@keywords
                        );

if( defined $config_file )
{
    die "FATAL: config file: $config_file not found" unless( -e $config_file );
}
else
{
    for my $etc_dir (@etc_dirs)
    {
	if (-e "$etc_dir/vuser.conf") {
	    $config_file = "$etc_dir/vuser.conf";
	    last;
	}
    }
}

if (not defined $config_file) {
    die "Unable to find a vuser.conf file in ".join (", ", @etc_dirs).".\n";
}

my %cfg;
tie %cfg, 'Config::IniFiles', (-file => $config_file);

our $log = VUser::Log->new(\%cfg, 'vsoapd/wsdl');

$log->log(LOG_DEBUG, "Config loaded from $config_file");

if (not $debug) {
    $DEBUG = VUser::ExtLib::strip_ws($cfg{'vuser'}{'debug'}) || 0;
    $DEBUG = VUser::ExtLib::check_bool($DEBUG) unless $DEBUG =~ /^\d+$/;
    $debug = $DEBUG;
}

my $eh = new VUser::ExtHandler (\%cfg);

@keywords = $eh->get_keywords() unless @keywords;
# Skip a few special keywords.
foreach my $key (grep { $_ ne 'config' || $_ ne 'help' || $_ ne 'man' } @keywords) {
    next unless $eh->is_keyword($key);
    
    # TODO: Figure out how to format the WSDL and write it. :-)
    my @actions = $eh->get_actions($key);
}

1;

__END__

=head1 NAME

gen-wsdl.pl - Generate WSDL file(s) that match the services offered by vsoapd

=head1 SYNOPSIS

 get-wsdl.pl [--config=/path/to/vuser.conf] [--keywords=key1[,key2]]

=head1 DESCRIPTION

Generate WSDL files that match the services offered by vsoapd.

=head1 CONFIGURATION

=head1 BUGS

Doesn't actually do anything yet.

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE

 This file is part of vsoapd.
 
 vsoapd is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vsoapd is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vsoapd; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
