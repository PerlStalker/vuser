package VUser::bind;

use warnings;
use strict;

# Copyright 2004 Mike O'Connor <stew@vireo.org>
# $Id: bind.pm,v 1.1 2005-01-21 20:55:07 stewatvireo Exp $

use vars qw(@ISA);

our $REVISION = (split (' ', '$Revision: 1.1 $'))[1];
our $VERSION = $main::VERSION;

use Pod::Usage;

use VUser::Extension;
push @ISA, 'VUser::Extension';


sub init
{
    my $eh = shift;
    my %cfg = @_;

    # Config
#    $eh->regiter_task('config', 'sample', \&config_sample);

    # email
    $eh->register_keyword('dns');
    
    $eh->register_action('dns', 'listdomains');
    $eh->register_task('dns', 'listdomains', \&dns_listdomains, 0);
    $eh->register_option('dns', 'listdomains', 'view', '=s');
    $eh->register_action('dns', 'listviews');
    $eh->register_task('dns', 'listviews', \&dns_listviews, 0);
    $eh->register_action('dns', 'show');
    $eh->register_task('dns', 'show', \&dns_show, 0);
}

sub dns_listdomains
{
    my $cfg = shift;
    my $opts = shift;

    my $view = $opts->{view};

    
    get_zones( $cfg, $view );
}

sub dns_listviews
{
    my $cfg = shift;
    my $opts = shift;

    get_views( $cfg );
}

sub dns_show
{
    my $cfg = shift;
    my $opts = shift;

    # ... other stuff?

    my $account = $opts->{account};
}

sub get_zones
{
    my $cfg = shift;
    my $v = shift;
	
    require VUser::bind::namedparser;

    my $namedfile = $cfg->{Extension_bind}{namedconf};

    foreach my $view ( VUser::bind::namedparser::parse( $namedfile ) )
    {
	if( $v )
	{
	    if( !($view->{name}) || (  !($v eq $view->{name} ) ))
	    {
		next;
	    }
	}
	my $zones = $view->{zones};
	foreach my $zone ( @$zones)
	{
	    print( $view->{name}.":".$zone->{name}."\n" );
	}
    }
}

sub get_views
{
    require VUser::bind::namedparser;

    my $cfg = shift;
    my $namedfile = $cfg->{Extension_bind}{namedconf};

    foreach my $zone ( VUser::bind::namedparser::parse( $namedfile ) )
    {
	print( $zone->{name }."\n" )
    }
}

