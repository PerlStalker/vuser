package VUser::Log;
use warnings;
use strict;

# Copyright 2005 Randy Smith <perlstalker@vuser.org>
# $Id: Log.pm,v 1.1 2005-11-17 00:04:35 perlstalker Exp $

our $VERSION = "0.2.0";

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = qw(LOG_EMERG LOG_ALERT LOG_CRIT LOG_ERR LOG_WARN
		    LOG_NOTICE LOG_INFO LOG_DEBUG
		    );
our %EXPORT_TAGS = (
		    levels => [qw(LOG_EMERG LOG_ALERT LOG_CRIT LOG_ERR
				  LOG_WARN LOG_NOTICE LOG_INFO LOG_DEBUG)]
		    );

sub LOG_EMRGE  { 8 }
sub LOG_ALERT  { 7 }
sub LOG_CRIT   { 6 }
sub LOG_ERR    { 5 }
sub LOG_WARN   { 4 }
sub LOG_NOTICE { 3 }
sub LOG_INFO   { 2 }
sub LOG_DEBUG  { 1 }

my @levels = ('', 'DEBUG', 'INFO', 'NOTICE', 'WARN',
	      'ERROR', 'CRIT', 'ALERT', 'EMERG');

sub new
{
    my $class = shift;
    my $cfg = shift;
    my $ident = shift;

    my $self = {'ident' => 'vuser',
		'level' => LOG_NOTICE
		};

    if ($cfg->{'vuser'}{'log type'} eq 'Syslog') {
	require VUser::Log::Syslog;
	$self = VUser::Log::Syslog->new($cfg);
    } else {
	bless $self, $class;
    }

    my $level = lc(strip_ws($cfg->{'vuser'}{'log level'}));
    if    ($level eq 'emerg') { $self->level(LOG_EMERG); }
    elsif ($level eq 'alert') { $self->level(LOG_ALERT); }
    elsif ($level eq 'crit')  { $self->level(LOG_CRIT); }
    elsif ($level =~ /^err(or)?$/) { $self->level(LOG_ERR); }
    elsif ($level eq 'warn') { $self->level(LOG_WARN); }
    elsif ($level eq 'notice') { $self->level(LOG_NOTICE); }
    elsif ($level eq 'info') { $self->level(LOG_INFO); }
    elsif ($level eq 'debug') { $self->level(LOG_DEBUG); }
    else { $self->level(LOG_NOTICE); }

    $self->ident($ident) if ($ident);

    $self->init($cfg);

    return $self;
}

sub init {}

# $log->log($message)
# $log->log(PRIORITY, $message)
# $log->log(PRIORITY, $pattern, @args)
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

    if ($priority >= $self->level) {
	print STDERR sprintf ('%s: %s: ', $self->ident, $levels[$priority]);
	print STDERR sprintf ($pattern."\n", @args);
    }
}

sub add_member
{
    my $self = shift;
    my $member = shift;
    my $value = shift;

    $self->{$member} = $value;
}

sub AUTOLOAD
{
    use vars '$AUTOLOAD';
    my $self = shift;
    my $value = shift;

    my $name = $AUTOLOAD;
    $name =~ s/.*:://;

    if (exists $self->{$name}) {
	$self->{$name} = $value if defined $value;
	return $self->{$name};
    } else {
	warn "Unknown method: $name\n";
	return undef;
    }
}

sub DESTROY {}
sub version { return $VERSION; }

1;

__END__

=head1 NAME

VUser::Log - Logging support for vuser

=head1 SYNOPSIS

 use VUser::Log qw(:levels);
 my $log = new VUser::Log($cfg, $ident);
 my $msg = "Hello World";
 $log->log($msg); # Log $msg at level LOG_NOTICE
 $log->log(LOG_DEBUG, $msg); # Log $msg at level LOG_DEBUG
 $log->log(LOG_DEBUG, 'Crap! %s', $msg); # Logs 'Crap! Hello World'

=head1 DESCRIPTION

=head1 CONFIGURATION

 [vuser]
 # The log system to use.
 log type = Syslog
 log level = notice

B<Note:> Each log module will have it's own configuration.

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

