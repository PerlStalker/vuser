package CORE;
use warnings;
use strict;

# Copyright 2004 Randy Smith
# $Id: CORE.pm,v 1.2 2004-12-25 15:23:12 perlstalker Exp $

use vars qw(@ISA);

our $REVISION = (split (' ', '$Revision: 1.2 $'))[1];
our $VERSION = $main::VERSION;

use Pod::Usage;

use Extension;
push @ISA, 'Extension';

sub config_file
{
    my $cfg = shift;
    my $opts = shift;

    print ("Current config file: ", tied (%$cfg)->GetFileName, "\n");
}

sub config_sample
{
    my $cfg = shift;
    my $opts = shift;

    my $fh;
    if (defined $opts->{file}) {
	open ($fh, ">".$opts->{file})
	    or die "Can't open '".$opts->{file}."': $!\n";
    } else {
	$fh = \*STDOUT;
    }

    print $fh <<'CONFIG';
[vuser]
# Enable debugging
debug = yes

CONFIG

    if (defined $opts->{file}) {
	close CONF;
    }
}

sub version
{
    my $cfg = shift;
    my $opts = shift;

    print ("Version: $main::VERSION\n");
}

sub help
{
    pod2usage('-verbose' => 1);
}

sub man
{
    pod2usage('-verbose' => 2);
}

sub init
{
    my $eh = shift; # ExtHandler
    my %cfg = @_;

    # Config
    $eh->register_keyword('config');
    $eh->register_action('config', 'file');
    $eh->register_task('config', 'file', \&config_file, 0);

    $eh->register_action('config', 'sample');
    $eh->register_task('config', 'sample', \&config_sample, 0);
    $eh->register_option('config', 'sample', 'file', '=s');

    # Help
    $eh->register_keyword('help');
    $eh->register_action('help', '*');
    $eh->register_task('help', '*', \&help);

    # Man
    $eh->register_keyword('man');
    $eh->register_action('man', '*');
    $eh->register_task('man', '*', \&man);

    # Version
    $eh->register_keyword('version');
    $eh->register_action('version', '');
    $eh->register_task('version', '', \&version);
}

1;

__END__

=head1 NAME

CORE - vuser core extensions

=head1 DESCRIPTION

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
