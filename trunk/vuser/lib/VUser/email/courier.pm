package VUser::email::courier;

# Copyright 2005 Michael O'Connor <stew@vireo.org>
# $Id: courier.pm,v 1.1 2005-06-27 20:57:47 stewatvireo Exp $

use warnings;
use strict;
use Pod::Usage;

use vars qw(@ISA);

our $REVISION = (split (' ', '$Revision: 1.1 $'))[1];
our $VERSION = $main::VERSION;

use VUser::email::authlib;
use VUser::email::driver;
push @ISA, 'VUser::email::driver';

sub new
{
    my $class = shift;
    my %cfg = @_;

    my $self = { _conf => undef, _authlib => undef };

    bless $self, $class;
    $self->init(%cfg);

    return $self;
}

sub init
{
    my $self = shift;
    my %cfg = @_;
    $self->{_conf} = $cfg{Extension_courier};

    my $whichauthlib = $self->cfg( "authlib" );
    
    die "required option \"authlib\" unset for Extension_courier.  Please fix your vuser.conf" unless $whichauthlib;
    
    if( $whichauthlib =~ /mysql/ )
    {
	use VUser::email::courier::mysql;
	eval( "require VUser::email::courier::mysql;" );
	die $@ if $@;
	$self->{_authlib} = new VUser::email::courier::mysql(%cfg);
    }
    else
    {
	die "unsupported authlib for Extension_courier"
    }
}

sub cfg
{
    my $self = shift;
    my $option = shift;

    return $self->{_conf}{ $option };
}

sub list_domains
{
    my $self = shift;
    
    return $self->{_authlib}->list_domains();
}

sub domain_exists
{
    my $self = shift;
    my $domain = shift;
    
    return $self->{_authlib}->domain_exists( $domain );
}

sub user_exists
{
    my $self = shift;
    my $user = shift;

    return $self->{_authlib}->user_exists( $user );
}

sub get_user_info
{
    my $self = shift;
    my $account = shift;
    my $user = shift;
    
    $self->{_authlib}->get_user_info( $account, $user );
}

sub domain_add
{
    my $self = shift;
    my $domain = shift;
    my $domaindir = shift;
    
    return $self->{_authlib}->domain_add( $domain, $domaindir );
}

sub add_user
{
    my $self = shift;
    my $account = shift;
    my $password = shift;
    my $userdir = shift;
    my $name = shift || '';
    

    $self->{_authlib}->add_user( $account, $password, $userdir, $name );
}
