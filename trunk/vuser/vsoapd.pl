#!/usr/bin/perl

use warnings;

#use strict; 
use SOAP::Lite +trace; 

# Copyright 2005 Mark Bucciarelli
# $Id: vsoapd.pl,v 1.1 2005-03-21 23:42:40 mbucc Exp $

use Pod::Usage;
use Getopt::Long;
use FindBin;
use Config::IniFiles;

our $REVISION = (split (' ', '$Revision: 1.1 $'))[1];
our $VERSION = '0.1.0';

our $DEBUG = 0;

BEGIN {

    our @etc_dirs = ('/usr/local/etc',
		     '/etc',
		     "$FindBin::Bin/../etc",
		     "$FindBin::Bin");
}

use vars qw(@etc_dirs);

use lib (map { "$_/extensions" } @etc_dirs);
use lib (map { "$_/lib" } @etc_dirs);

use SOAP::Transport::HTTP;

use VUser::SOAP;

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
