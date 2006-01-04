package VUser::email::driver;

# Copyright 2005 Michael O'Connor <stew@vireo.org>
# $Id: driver.pm,v 1.4 2006-01-04 21:57:49 perlstalker Exp $

use warnings;
use strict;

our $REVISION = (split (' ', '$Revision: 1.4 $'))[1];
our $VERSION = "0.3.0";

use Pod::Usage;

sub new
{
    my $class = shift;
    my %cfg = @_;

    my $self = { _dbh => undef, _conf =>undef };

    bless $self, $class;
    $self->init(%cfg);

    return $self;
}

sub init
{
    
}

sub cfg
{
    my $self = shift;
    my $option = shift;

    return $self->{_conf}{ $option };
}

