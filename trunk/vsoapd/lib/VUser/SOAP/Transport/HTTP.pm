package VUser::SOAP::Transport::HTTP;
use warnings;
use strict;

# Copyright (c) 2006 Randy Smith
# $Id: HTTP.pm,v 1.1 2006-09-25 22:54:15 perlstalker Exp $

use VUser::ExtLib qw(:config);
use SOAP::Transport::HTTP;

my $c_sec = 'vsoapd HTTP';

sub new {
    my $class = shift;
    my $cfg = shift;
    
    my $port = strip_ws($cfg->{$c_sec}{port});
    my $address = strip_ws($cfg->{$c_sec}{address});
    
    my %daemon_opts = ('LocalPort' => $port);
    if ($address) {
        $daemon_opts{'LocalAddress'} = $address;
    }
    
    my $daemon = SOAP::Transport::HTTP::Daemon->new (%daemon_opts);
    $daemon->objects_by_reference(qw(VUser::SOAP::Dispatcher));
    $daemon->dispatch_to('VUser::SOAP::Dispatcher');
    return $daemon;
}

1;

__END__

=head1 NAME

VUser::SOAP::Transport::HTTP - Setup the HTTP SOAP transport for vsoapd

=head1 DESCRIPTION

=head1 CONFIGURATION

 [vsoapd HTTP]
 # TCP port to listen on. Defaults to 8000
 port = 8000
 
 # Specify an address to listen on.
 # address = localhost 
 
=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE

 This file is part of vsoapd.
 
 vsoapd is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vsoapd is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vsoapd; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
