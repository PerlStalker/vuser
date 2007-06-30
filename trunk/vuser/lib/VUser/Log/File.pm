package VUser::Log::File;
use warnings;
use strict;

# Copyright 2005 Randy Smith <perlstalker@vuser.org>
# $Id: File.pm,v 1.1 2007-06-30 00:58:40 perlstalker Exp $

our $VERSION = "0.3.0";

use VUser::ExtLib qw(strip_ws);
use VUser::Log qw(:levels);
our @ISA = qw(VUser::Log);

use IO::File;

my $c_sec = 'Log File';

my @levels = ('', 'DEBUG', 'INFO', 'NOTICE', 'WARN',
	      'ERROR', 'CRIT', 'ALERT', 'EMERG');

sub init {
    my $self = shift;
    my $cfg = shift;

    my $log_file = strip_ws($cfg->{$c_sec}{'log file'});
    $self->add_member('log_file', $log_file);

    my $fh = new IO::File;
    if ($fh->open(">> ".$self->log_file)) {
	$self->add_member('fh', $fh);
    } else {
	die "Unable to open log file ".$self->log_file.": $!\n";
    }
}

sub write_msg {
    my $self = shift;
    my ($level, $msg) = @_;

    if (not defined $level) {
	$level = VUser::Log::LOG_ERR();
    }

    my $out = sprintf ('%s: %s ', $self->ident, $levels[$level]);
    $out .= "$msg\n";

    print STDERR "Out: $out";

    eval {
	print $self->{'fh'} ($out);
	print STDERR "After print\n";
    };

    if ($@) {
	# There was a problem printing. Try reopening the file and try again.
	$self->fh->close();

	$self->{'fh'} = IO::File->new();
	if ($self->{'fh'}->open('>>'.$self->log_file)) {
	    eval {
		print $self->{'fh'} ($out);
	    };
	    if ($@) {
		# We cannot log any more
		die "Unable to write logs: $@\n";
	    }
	} else {
	    die "Unable to write logs. Reopen failed: $@\n";
	}
    }
}


1;

__END__

=head1 NAME

VUser::Log::File - File log module

=head1 DESCRIPTION

Sends vuser logs to syslog. This will probably not work on Windows systems.

=head1 CONFIGURATION

 [Log File]
 log file = /var/log/vuser.log

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

