#! /usr/bin/perl -w

# SOAP interface to VUser.  
#

use warnings;
use strict;

use vars qw(@ISA);

our $REVISION = (split (' ', '$Revision: 1.1 $'))[1];
our $VERSION = $main::VERSION;

use VUser::CORE;

package VUser::SOAP;

sub hi {                        
  return "hello, world\n";        
}

# Rather useless example of exposing a VUser function via SOAP.
sub CORE_version {
  return VUser::CORE::version();
  #return "test\n";
}

1;
