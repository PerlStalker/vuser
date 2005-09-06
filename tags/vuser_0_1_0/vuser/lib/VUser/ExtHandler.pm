package VUser::ExtHandler;
use warnings;
use strict;

# Copyright 2004 Randy Smith
# $Id: ExtHandler.pm,v 1.31 2005-07-02 21:04:04 perlstalker Exp $

our $REVISION = (split (' ', '$Revision: 1.31 $'))[1];
our $VERSION = "0.1.0";

use lib qw(..);
use Getopt::Long;
use VUser::ExtLib;
use VUser::Meta;

use Regexp::Common qw /number/;
#use Regexp::Common qw /number RE_ALL/;

sub new
{

    my $self = shift;
    my $class = ref($self) || $self;
    my $cfg = shift;

    # {keyword}{action}{tasks}[order][tasks (sub refs)]
    # {keyword}{action}{options}{option} = type
    # {keyword}{_meta}{option} = VUser::Meta
    my $me = {'keywords' => {},
	      'required' => {},
	      'descrs' => {},
	  };

    bless $me, $class;

    $me->load_extensions(%$cfg);

    return $me;
}

sub register_keyword
{
    my $self = shift;
    my $keyword = shift;
    my $descr = shift;

    unless (exists $self->{keywords}{$keyword}) {
	$self->{keywords}{$keyword} = {};

	$self->{descrs}{$keyword} = {_descr => $descr};
    }
}

sub register_action
{
    my $self = shift;
    my $keyword = shift;
    my $action = shift;
    my $descr = shift;

    if ($action =~ /^-/) { 
	die "Unable to register action. Action may not start with a '-'.\n";
    }

    unless (exists $self->{keywords}{$keyword}) {
	die "Unable to register action on unknown keyword '$keyword'.\n";
    }

    unless (exists $self->{keywords}{$keyword}{$action}) {
	$self->{keywords}{$keyword}{$action} = {tasks => [], options => {}};
	$self->{descrs}{$keyword}{$action} = {_descr => $descr};
    }
}

#$eh->register_option('key', 'action',
#                      $option, $type, $required, $descr, $widget
#			- OR -
#		      $meta, $required
#                      );
sub register_option
{
    my $self = shift;
    my $keyword = shift;
    my $action = shift;
    my $option = shift;

    my $meta;
    my $required = 0;

    if (not ref $option) {
	# It's not a ref, build a VUser::Meta object
	my $type = shift;
	$required = shift;
	my $descr = shift;
	my $widget = shift;     # Widget class (Optional)

	if ($self->{$keyword}{'_meta'}{$option}) {
	    $meta = $self->{$keyword}{'_meta'}{$option};
	} else {

	    $type = lc($type);
	    my $d_type = 'string';
	    if ($type eq '!'
		or $type eq ''
		or $type eq 'boolean') {
		$d_type = 'boolean';
	    } elsif ($type eq '+'
		     or $type eq 'counter') {
		$d_type = 'counter';
	    } elsif ($type =~ /^([=:])([siof])([@%])?$/) {
		my $gol_type = $2;
		if ($gol_type eq 's') {
		    $d_type = 'string';
		} elsif ($gol_type eq 'i'
			 or $gol_type eq 'o'
			 or $gol_type eq 'integer'
			 ) {
		    $d_type = 'integer';
		} elsif ($gol_type eq 'f') {
		    $d_type = 'float';
		}
	    } else {
		$d_type = 'string';
	    }

	    $meta = new VUser::Meta(name => $option,
				    description => $descr,
				    type => $d_type
				    );
	}

    } elsif ($option->isa('VUser::Meta')) {
	$meta = $option;
	$required = shift;
    } else {
	die "Option was not a VUser::Meta\n";
    }

    print STDERR "Reg Opt: $keyword|$action ".$meta->name." ".$meta->type." ", $required?'Req':'',"\n" if $main::DEBUG >= 2;
    unless (exists $self->{keywords}{$keyword}) {
	die "Unable to register option on unknown keyword '$keyword'.\n";
    }

    unless (exists $self->{keywords}{$keyword}{$action}) {
	die "Unable to register option on unknown action '$action'.\n";
    }

#    if (exists $self->{keywords}{$keyword}{$action}{options}{$option}) {
    if (exists $self->{keywords}{$keyword}{$action}{options}{$meta->name}) {
	# Let's silently ignore duplicate option definitions the way we
	# do for keywords and actions. This will allow an extension to
	# register an option to guarantee that it's there rather than having
	# to rely on another extension to register the option.
	#die "Unable to register option for $keyword|$action. '$option' already exists.\n";
    } else {
	$self->{keywords}{$keyword}{$action}{options}{$meta->name} = $meta;
	if ($required) {
	    $self->{required}{$keyword}{$action}{$meta->name} = 1;
	} else {
	    $self->{required}{$keyword}{$action}{$meta->name} = 0;
	}
	$self->{descrs}{$keyword}{$action}{$meta->name} = {_descr => $meta->description};
    }

    if (exists $self->{$keyword}{'_meta'}{$meta->name}) {
	# silently discard dups
    } else {
	$self->{$keyword}{'_meta'}{$meta->name} = $meta;
    }
}

sub register_meta
{
    my $self = shift;
    my $keyword = shift;
    
    my $meta;
    
    if (ref $_[0] and $_[0]->isa('VUser::Meta')) {
	$meta = $_[0];
    } else {
	$meta = new VUser::Meta(@_);
    }

    unless (exists $self->{keywords}{$keyword}) {
	die "Unable to register option on unknown keyword: '$keyword'.\n";
    }

    if (defined $self->{$keyword}{'_meta'}{$meta->name}) {
	# Silently ignore duplicates.
    } else {
	$self->{$keyword}{'_meta'}{$meta->name} = $meta;
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
    my $handler = shift;        # sub ref. Takes 2 params: The tied config
				#  the options ref, and the action
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

sub get_keywords
{
    my $self = shift;

    return sort keys %{ $self->{keywords}};
}

sub get_actions
{
    my $self = shift;
    my $keyword = shift;

    return sort keys %{ $self->{keywords}{$keyword} };
}

sub get_options
{
    my $self = shift;
    my $keyword = shift;
    my $action = shift;

    return sort keys %{ $self->{keywords}{$keyword}{$action}{options}};
}

# Return unsorted list of VUser::Meta objects;
sub get_meta
{
    my $self = shift;
    my $keyword = shift;
    my $option = shift;

    my @meta = ();

    return undef if not defined $self->{$keyword};

    if (defined $option) {
	push @meta, $self->{$keyword}{'_meta'}{$option};
    } else {
	foreach my $opt (keys %{$self->{$keyword}{'_meta'}}) {
	    push @meta, $self->{$keyword}{'_meta'}{$opt};
	}
    }

    return @meta;
}

sub get_description
{
    my $self = shift;
    my $keyword = shift;
    my $action = shift;
    my $option = shift;

    if ($keyword and $action and $option) {
	return $self->{descrs}{$keyword}{$action}{$option}{_descr};
    } elsif ($keyword and $action) {
	return $self->{descrs}{$keyword}{$action}{_descr};
    } elsif ($keyword) {
	return $self->{descrs}{$keyword}{_descr};
    }
}

sub load_extensions
{
    my $self = shift;
    my %cfg = @_;

    print STDERR "Loading CORE\n" if $main::DEBUG >= 1;
    $self->load_extension('VUser::CORE');
    my $exts = $cfg{ vuser }{ extensions };
    $exts = '' unless $exts;
    VUser::ExtLib::strip_ws($exts);
    print STDERR "extensions: $exts\n" if $main::DEBUG >= 1;
    foreach my $extension (split( / /, $exts))
    {
	print STDERR "Loading $extension\n" if $main::DEBUG >= 1;
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

    $self->unload_extension('VUser::CORE');
    my $exts = $cfg{ vuser }{ extensions };
    $exts = '' unless $exts;
    VUser::ExtLib::strip_ws($exts);
    foreach my $extension (split( / /, $exts))
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

    no strict ('refs');
    &{$ext.'::unload'}($self, %cfg);
}

sub run_tasks
{
    my $self = shift;
    my $keyword = shift;
    my $action = shift;
    my $cfg = shift;

    my %opts = @_;

    print "Keyword: '$keyword'\nAction: '$action'\nARGV: @ARGV\n" if $main::DEBUG >= 1;
    if ($main::DEBUG >= 1) {
	print "Options: ";
	use Data::Dumper; print Dumper \%opts;
    }

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

    # If we're processessing a wild action, we need to check the
    # '*' action instead of the passed in action.
    my $real_action = $wild_action? '*': $action;

    # If opts is not empty, we'll just use the option's we're given
    # otherwise, we'll get the options using GetOptions()

    if (%opts) {
	# We need to do some error checking here on the option type.
	# Getopt::Long takes care of it in the other case, but we need to
	# do that ourselves here.
	foreach my $opt (keys %{$self->{keywords}{$keyword}{$real_action}{options}}) {
	    my $type = $self->{keywords}{$keyword}{$real_action}{options}{$opt};

	    # Giant switch-type block to validate Getopt::Long types with the
	    # passed in values.
	    if ($type eq '!') {
		if ($opts{$opt}) {
		    $opts{$opt} = 1;
		} else {
		    $opts{$opt} = 0;
		}

		if ($opts{"no$opt"} or $opts{"no-$opt"}) {
		    $opts{$opt} = 0;
		}
	    } elsif ($type eq '+') {
		# All we can do here is make sure the option is an int.
		unless ($opts{$opt} =~ $RE{num}{int}) {
		    die "$opt is not an integer.\n";
		}
	    } elsif ($type =~ /^([=:])([siof])([@%])?$/) {
		if ($1 eq '='
		    and exists $opts{$opt}
		    and not defined $opts{$opt}) {
		    die "Missing required value: $opt\n";
		}

		my $d_type = $2;
		my $dest_type = $3;

		if ($main::DEBUG > 2) {
		    print "Key: $keyword; Act: $real_action, Opt: $opt; Type: $type d_type: $d_type\n";
		    print "Req: ";
		    print $self->is_required($keyword, $real_action, $opt)? 'Yes':'No';
		    print " ";
		    print "Def: ",defined $opts{$opt}?"Yes ($opts{$opt})":'No',"\n";
		}

		if ($d_type eq 's') {
		    # There's nothing to verify here
		} elsif ($d_type eq 'i'
			 #and defined $opts{$opt}
			 # This line is causing the warnings.
			 #and not $opts{$opt} =~ /^$RE{num}{int}$/
			 ) {
		    # Ok, this is really stupid. I had to move this
		    # check into a seperate if because it was causing
		    # a weird warning about 'Use of uninitialized value
		    # in string eq at vuser-ng/lib/VUser/ExtHandler.pm
		    # line 339.'
		    if (defined $opts{$opt}
			and not $opts{$opt} =~ /^$RE{num}{int}$/) {
			die "$opt is not an integer.\n";
		    }
		} elsif ($d_type eq 'o'
			 and defined $opts{$opt}
			 and not ($opts{$opt} =~ /^$RE{num}{int}$/
				  or $opts{$opt} =~ /^$RE{num}{oct}$/
				  or $opts{$opt} =~ /^$RE{num}{hex}$/
				  )
			 ) {
		    die "$opt is not an extended integer.";
		} elsif ($2 eq 'f'
			 and defined $opts{$opt}
			 and not $opts{$opt} =~ /^$RE{num}{real}$/) {
		    die "$opt is not a real number.";
		}
	    } elsif ($type =~ /^:(-?\d+)([@%])?$/) {
		my $num = $1;
		if (defined $opts{$opt}) {
		    die "$opt is not an integer." unless $opts{$opt} =~ /$RE{num}{int}/;
		} else {
		    $opts{$opt} = $num;
		}
	    } elsif ($type =~ /^:+([@%])?$/) {
		if (defined $opts{$opt}) {
		    die "$opt is not an integer." unless $opts{$opt} =~ /$RE{num}{int}/;
		} else {
		    $opts{$opt}++;
		}
	    }
	}
    } else {
	# Prepare options for GetOptions();
	my @opt_defs = ();
	
	foreach my $opt (keys %{$self->{keywords}{$keyword}{$real_action}{options}}) {
	    my $gopt_type = '';
	    #my $type = $self->{keywords}{$keyword}{$real_action}{options}{$opt}a;
	    #$type = '' unless defined $type;

	    my $type = $self->{keywords}{$keyword}{$real_action}{options}{$opt}->type;
	    if ($type eq 'string') {
		$gopt_type = '=s';
	    } elsif ($type eq 'integer') {
		$gopt_type = '=i';
	    } elsif ($type eq 'counter') {
		$gopt_type = '+';
	    } elsif ($type eq 'boolean') {
		$gopt_type = '!';
	    } elsif ($type eq 'float') {
		$gopt_type = '=f';
	    }

	    my $def = $opt.$gopt_type;
	    push @opt_defs, $def;
	}
	
	print "Opt defs: @opt_defs\n" if $main::DEBUG >= 1;
	if (@opt_defs) {
	    GetOptions(\%opts, @opt_defs);
	}
    }

    # Check for required options
    my $opt = $self->check_required ($keyword, $real_action, \%opts);
    if ($opt) {
	die "Missing required option '$opt'.\n";
    }

    my @tasks = ();
    if ($wild_action) {
	@tasks = @{$self->{keywords}{$keyword}{'*'}{tasks}};
    } else {
	@tasks = @{$self->{keywords}{$keyword}{$action}{tasks}};
    }

    my @results = ();
    foreach my $priority (@tasks) {
	foreach my $task (@$priority) {
	    # Return values?
	    my $rs = &$task($cfg, \%opts, $action, $self);
	    if (defined $rs and UNIVERSAL::isa($rs, "VUser::ResultSet")) {
		push @results, $rs;
	    }
	}
    }

    return \@results;
}

sub cleanup
{
    my $self = shift;
    my %cfg = @_;

    eval { $self->unload_extensions(%cfg); };
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