package VUser::SOAP;

# SOAP interface to VUser.  
#

use warnings;
use strict;

# Copyright 2005 Randy Smith
# $Id: SOAP.pm,v 1.3 2005-03-25 00:16:15 perlstalker Exp $

use vars qw(@ISA);

our $REVISION = (split (' ', '$Revision: 1.3 $'))[1];
our $VERSION = $main::VERSION;

use VUser::CORE;

sub hi {                        
  return "hello, world\n";        
}

# Rather useless example of exposing a VUser function via SOAP.
sub CORE_version {
  return VUser::CORE::version();
  #return "test\n";
}

sub hash_test {
    my $class = shift;
    my %hash = @_;
    print "Class: $class\n";
    use Data::Dumper; print Dumper \%hash;
    return 1;
}

sub AUTOLOAD
{
    use vars '$AUTOLOAD';
    my $class = shift;
    my $name = $AUTOLOAD;
    $name =~ s/.*://;
    print "name: $name\n";
    if ($name =~ /^([^_]+)_([^_]+)$/) {
	my $keyword = $1;
	my $action = $2;
	print "Key: $keyword Act: $action\n";
	# Where am I getting $cfg from?
	my $cfg;
	eval { $eh->run_tasks($keyword, $action, $cfg, %opts); };
    } else {
	return;
    }
}

1;
