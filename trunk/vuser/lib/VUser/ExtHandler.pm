package VUser::ExtHandler;
use warnings;
use strict;

# Copyright 2004 Randy Smith
# $Id: ExtHandler.pm,v 1.10 2005-01-24 20:31:58 perlstalker Exp $

our $REVISION = (split (' ', '$Revision: 1.10 $'))[1];
our $VERSION = $main::VERSION;

use lib qw(..);
use Getopt::Long;

sub new
{

    my $self = shift;
    my $class = ref($self) || $self;
    my $cfg = shift;

    # {keyword}{action}{tasks}[order][tasks (sub refs)]
    # {keyword}{action}{options}{option} = type
    my $me = {'keywords' => {},
	      'required' => {}
	  };

    bless $me, $class;

    $me->load_extensions(%$cfg);

    return $me;
}

sub register_keyword
{
    my $self = shift;
    my $keyword = shift;

    unless (exists $self->{keywords}{$keyword}) {
	$self->{keywords}{$keyword} = {};
    }
}

sub register_action
{
    my $self = shift;
    my $keyword = shift;
    my $action = shift;

    if ($action =~ /^-/) { 
	die "Unable to register action. Action may not start with a '-'.\n";
    }

    unless (exists $self->{keywords}{$keyword}) {
	die "Unable to register action on unknown keyword '$keyword'.\n";
    }

    unless (exists $self->{keywords}{$keyword}{$action}) {
	$self->{keywords}{$keyword}{$action} = {tasks => [], options => {}};
    }
}

sub register_option
{
    my $self = shift;
    my $keyword = shift;
    my $action = shift;
    my $option = shift;
    my $type = shift;
    my $required = shift;

    unless (exists $self->{keywords}{$keyword}) {
	die "Unable to register option on unknown keyword '$keyword'.\n";
    }

    unless (exists $self->{keywords}{$keyword}{$action}) {
	die "Unable to register option on unknown action '$action'.\n";
    }

    if (exists $self->{keywords}{$keyword}{$action}{options}{$option}) {
	die "Unable to register option. '$option' already exists.\n";
    } else {
	$self->{keywords}{$keyword}{$action}{options}{$option} = $type;
	if ($required) {
	    $self->{required}{$keyword}{$action}{$option} = 1;
	} else {
	    $self->{required}{$keyword}{$action}{$option} = 0;
	}
    }
}

sub is_required
{
    my $self = shift;
    my $keyword = shift;
    my $action = shift;
    my $option = shift;

    if ($self->{required}{$keyword}{$action}{$option}) {
	return 1;
    } else {
	return 0;
    }
}

sub check_required
{
    my $self = shift;
    my $keyword = shift;
    my $action = shift;
    my $opts = shift;

    foreach my $option (grep { $self->is_required($keyword, $action, $_); }
			keys %{$self->{required}{$keyword}{$action}}) {
	if (not exists($opts->{$option})) {
	    return $option;
	}
    }
    return '';
}

sub register_task
{
    my $self = shift;
    my $keyword = shift;
    my $action = shift;
    my $handler = shift;        # sub ref. Takes 1 param: The tied config
    my $priority = shift;

    unless (exists $self->{keywords}{$keyword}) {
	die "Unable to register task on unknown keyword '$keyword'.\n";
    }

    unless (exists $self->{keywords}{$keyword}{$action}) {
	die "Unable to register task on unknown action '$action'.\n";
    }

    $priority = 10 unless defined $priority; # Default priority is 10.
    if (defined $self->{keywords}{$keyword}{$action}{tasks}[$priority]) {
	push @{$self->{keywords}{$keyword}{$action}{tasks}[$priority]}, $handler;
    } else {
	$self->{keywords}{$keyword}{$action}{tasks}[$priority] = [$handler];
    }
}

sub load_extensions
{
    my $self = shift;
    my %cfg = @_;

    $self->load_extension('VUser::CORE');
    foreach my $extension (split( / /, $cfg{ ExtHandler }{ extensions } ) )
    {
	eval { $self->load_extension( "VUser::$extension", %cfg); };
	warn "Unable to load $extension: $@\n" if $@;
    }
    
#     foreach my $key (grep { /^Extension_/ } keys %$cfg) {
#  	my $extension = $key =~ s/^Extension_//;
# 	print( "extension: $key\n" );
#  	eval { $self->load_extension($key, $cfg); };
#  	warn "Unable to load $extension: $@\n" if $@;
#     }
}

sub load_extension
{
    my $self = shift;
    my $ext = shift;
    my %cfg = @_;

    my $pm = $ext;
    $pm =~ s/::/\//g;
    $pm .= ".pm";
       
    eval( "require $ext" );
    die $@ if $@;
    no strict "refs";
    
    &{$ext.'::init'}($self, %cfg);
}

sub unload_extensions
{
    my $self = shift;
    my %cfg = @_;

    $self->load_extension('VUser::CORE');
    foreach my $extension (split( / /, $cfg{ ExtHandler }{ extensions } ) )
    {
	eval { $self->unload_extension( "VUser::$extension", %cfg); };
	warn "Unable to unload $extension: $@\n" if $@;
    }
}

sub unload_extension
{
    my $self = shift;
    my $ext = shift;
    my %cfg = @_;

    &{$ext.'::unload'}($self, %cfg);
}

sub run_tasks
{
    my $self = shift;
    my $keyword = shift;
    my $action = shift;
    my $cfg = shift;

    my %opts = ();

    print "Keyword: '$keyword'\nAction: '$action'\nARGV: @ARGV\n" if $main::DEBUG >= 1;

    unless (exists $self->{keywords}{$keyword}) {
	die "Unknown module '$keyword'\n";
    }

    my $wild_action = 0;
    if (exists $self->{keywords}{$keyword}{$action}) {
	$wild_action = 0;
    } elsif (exists $self->{keywords}{$keyword}{'*'}) {
	$wild_action = 1;
    } else {
	die "Unknown action '$action'\n";
    }

    # Prepare options for GetOptions();
    my @opt_defs = ();

    foreach my $opt (keys %{$self->{keywords}{$keyword}{$action}{options}}) {
	my $def = $opt.$self->{keywords}{$keyword}{$action}{options}{$opt};
	push @opt_defs, $def;
    }

    print "Opt defs: @opt_defs\n" if $main::DEBUG >= 1;
    if (@opt_defs) {
	GetOptions(\%opts, @opt_defs);
    }

    # Check for required options
    my $opt = $self->check_required ($keyword, $action, \%opts);
    if ($opt) {
	die "Missing required option '$opt'.\n";
    }

    my @tasks = ();
    if ($wild_action) {
	@tasks = @{$self->{keywords}{$keyword}{'*'}{tasks}};
    } else {
	@tasks = @{$self->{keywords}{$keyword}{$action}{tasks}};
    }

    foreach my $priority (@tasks) {
	foreach my $task (@$priority) {
	    &$task($cfg, \%opts, $action);
	}
    }
}

sub cleanup
{
    my $self = shift;
    my %cfg = @_;

    eval { $self->unload_extensions(%cfg); }
    warn $@ if $@;
}

1;

__END__

=head1 NAME

ExtHandler - vuser extension handler.

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
