#!/usr/bin/perl

use warnings;
use strict;

#use SOAP::Lite ('trace'); 
use SOAP::Lite;

# Copyright 2005 Mark Bucciarelli
# $Id: vsoapd.pl,v 1.6 2005-03-25 22:23:33 perlstalker Exp $

use Pod::Usage;
use Getopt::Long;
use FindBin;
use Config::IniFiles;
use SOAP::Transport::HTTP;

our $REVISION = (split (' ', '$Revision: 1.6 $'))[1];
our $VERSION = '0.1.0';

our $DEBUG = 0;

BEGIN {

    our @etc_dirs = ('/usr/local/etc',
		     '/etc',
		     "$FindBin::Bin/../etc",
		     "$FindBin::Bin");
    foreach my $dir (@etc_dirs) {
        push @etc_dirs, "$dir/vuser";
    }
}

use vars qw(@etc_dirs);

use lib (map { "$_/extensions" } @etc_dirs);
use lib (map { "$_/lib" } @etc_dirs);

use VUser::ExtHandler;
use VUser::SOAP;

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

my $eh = new VUser::ExtHandler (\%cfg);

# This is really ugly and there should be a better way of doing this.
%VUser::SOAP::cfg = %cfg;
$VUser::SOAP::eh = $eh;

# don't die on 'Broken pipe' or Ctrl-C
#$SIG{PIPE} = $SIG{INT} = 'IGNORE';

my $daemon = SOAP::Transport::HTTP::Daemon
  # if you do not specify LocalAddr then you can access it with 
  # any hostname/IP alias, including localhost or 127.0.0.1. 
  # if do you specify LocalAddr in ->new() then you can only access it 
  # from that interface. -- Michael Percy <mpercy@portera.com>
  -> new (LocalAddr => 'localhost', LocalPort => 8080) 
  # you may also add other options, like 'Reuse' => 1 and/or 'Listen' => 128

  # specify list of objects-by-reference here 
  #-> objects_by_reference(qw(My::PersistentIterator My::SessionIterator My::Chat))
  -> objects_by_reference(qw(VUser::SOAP))

  # specify path to My/Examples.pm here
  #-> dispatch_to('/Your/Path/To/Deployed/Modules', 'Module::Name', 'Module::method') 
  -> dispatch_to('VUser::SOAP')

  # enable compression support
  -> options({compress_threshold => 10000})
;
print "Contact to SOAP server at ", $daemon->url, "\n";
$daemon->handle;

eval { $eh->cleanup(%cfg); };
