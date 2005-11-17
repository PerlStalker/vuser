package VUser::Log::Syslog;
use warnings;
use strict;

# Copyright 2005 Randy Smith <perlstalker@vuser.org>
# $Id: Syslog.pm,v 1.1 2005-11-17 00:04:35 perlstalker Exp $

our $VERSION = "0.2.0";

use VUser::Log qw(:levels);
our @ISA = qw(VUser::Log);

use Sys::Syslog qw(:DEFAULT);

my $c_sec = 'Log Syslog';

my %prior_map = (LOG_EMERG => 'emerg',
		 LOG_ALERT => 'alert',
		 LOG_CRIT  => 'crit',
		 LOG_ERR   => 'err',
		 LOG_WARN  => 'warn',
		 LOG_NOTICE => 'notice',
		 LOG_INFO  => 'info',
		 LOG_DEBUG => 'debug');

sub init
{
    my $self = shift;
    my $cfg = shift;

    my $facility = strip_ws($cfg->{$c_sec}{facility});
    $self->add_member('facility', $facility);

    my $opts = strip_ws($cfg->{$c_sec}{options});
    $self->add_member('opts', $opts);

    openlog ($self->ident, $self->opts, $self->facility);

    setlogmask(join('|', @proir_map{$self->level .. LOG_EMRGE}));
}

sub log
{
    my $self = shift;

    my $priority = LOG_NOTICE;
    my $pattern = '%s';
    my @args = ();
    
    if (scalar @_ == 0) {
	warn "No log message";
	return;
    } elsif (scalar @_ == 1) {
    } elsif (scalar @_ == 2) {
	$priority = shift;
    } else {
	$priority = shift;
	$pattern = shift;
    }

    # Remove trailing newline from pattern. We'll add that later.
    $pattern =~ s/(\\n|\n)$//;

    @args = @_;

    syslog ($prior_map{$priority}, $pattern, @args);
}

sub version { return $VERSION; }

sub DESTROY { closelog(); }

1;

_END_

=head1 NAME

VUser::Log::Syslog - Syslog log module

=head1 DESCRIPTION

Sends vuser logs to syslog. This will probably not work on Windows systems.

=head1 CONFIGURATION

 [Log Syslog]
 # Syslog facility to use. See syslog(3) for a list of facilities on your
 # system.
 # Common facilities are: daemon, user, local0 - local7
 facility = daemon
 
 # Comma separated list if Syslog options.
 # Possible options: pid, ndelay, nowait
 # options = pid

=head1 AUTHORS

Randy Smith <perlstalker@vuser.org>

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
