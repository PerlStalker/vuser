package VUser::Trango::AP::M900S;
use warnings;
use strict;

# Copyright 2006 Randy Smith <perlstalker@vuser.org>
# $Id: M900S.pm,v 1.1 2006-01-09 23:15:07 perlstalker Exp $

use VUser::Log qw(:levels);
use VUser::Trango::AP;
use Net::SNMP;

our $log;
our %meta = ();

our $mib_root = '1.3.6.1.4.1.5454.1.30';

our @sudb_map = (undef);
push @sudb_map, qw(
		   suID
		   suMAC
		   suPolling
		   suGroupID
		   suIPAddr
		   suSubnetMask
		   suGateWay
		   suRemarks
		   suHWVer
		   suFWVer
		   suFWChecksum
		   suFPGAVer
		   suFPGAChecksum
		   suAssociation
		   suDistance
		   suRSSIAtSU
		   suRSSIAtAP
		   suTxPower
		   suEthInOctets
		   suEthOutOctets
		   suRfInPackets
		   suRfOutPackets
		   suRfInDropPackets
		   suRfOutRetryAtAP
		   suRfOutRetryMaxedOutAtAP
		   suRfOutRetryAtSU
		   suRfOutRetryMaxedOutAtSU
		   suReboot
		   suBlockBroadcastMulticast
		   suAutoScanning
		   suTcpIpServiceForAP
		   suHTTPD
		   suTCPIPForLocalEthernet
		   suDownLinkCIR
		   suUpLinkCIR
		   suDownLinkMIR
		   suUpLinkMIR
		   suResetTrafficCounters
		   suRfInOctets
		   suRfOutOctets
		   );

sub depends { return qw(Trango::AP); }

sub init
{
    my $eh = shift;
    my %cfg = @_;

    if (defined $main::log
	and UNIVERSAL::isa($main::log, 'VUser::Log')
	) {
	$log = $main::log;
    } else {
	$log = VUser::Log->new(\%cfg, 'VUser::Trango');
    }

    %meta = %VUser::Trango::AP::meta;

    # ap-sudb_view
    $eh->register_task('ap', 'sudb_view', \&sudb_view);
}


sub sudb_view
{
    my ($cfg, $opts, $action, $eh) = @_;

    my $community = $opts->{community} || 'public';

    my $session = snmp_connect($opts->{host}, $community);

    if (VUser::Trango::AP::get_ap_type($session) ne 'M900S') {
	$log->log(LOG_INFO, "%s is not a Trango M900S", $opts->{host});
	return ;
    }

    return get_sudb($session, $mib_root);
}

sub get_sudb
{
    my ($session, $mib_root) = @_;

    my $rs = VUser::ResultSet->new();

    for (my $i = 1; $i < @sudb_map; $i++) {
	#print "$i => $sudb_map[$i]\n";
	#use Data::Dumper; print Dumper $meta{$sudb_map[$i]};
	$rs->add_meta($meta{$sudb_map[$i]});
    }
    $rs->order_by('suID');

    my $sudb_table = $mib_root.".3";
    my $sudb = $session->get_table(-baseoid => $sudb_table);
    die "Can't get sudb: ".$session->error."\n" unless defined $sudb;
    #use Data::Dumper; print Dumper $sudb;

    my %ids = ();
    my %idxs = ();
    foreach my $key (keys %$sudb) {
	if ($key =~ /\.(\d+)\.(\d+)$/) {
	    next if $2 == 0;
	    #print "$key => $2, $1 => ", $sudb->{$key}, "\n";
	    $ids{$2} = 1;
	    $idxs{$1} = 1;
	}
    }

    # Sort by su id. There's no need to sort by idx
    foreach my $id (sort keys %ids) {
	my @data = ();
	foreach my $idx (keys %idxs) {
	    next if $idx >= @sudb_map || $idx < 1;
	    #print "$idx => $sudb_table.6.1.$idx.$id => ", $sudb->{"$sudb_table.6.1.$idx.$id"}, "\n";
	    $data[$idx] = $sudb->{"$sudb_table.6.1.$idx.$id"};
	}
	shift @data; # remove extra item at index 0.
	#use Data::Dumper; print Dumper \@data;
	#print "\@data has ", scalar @data, " elements\n";
	#print "\@sudb_map has ", scalar @sudb_map, " elements\n";
	# Only add the data if the suID is defined.
	$rs->add_data([@data]) if defined $data[1];
    }
    return $rs;
}

sub snmp_connect
{
    my $host = shift;
    my $community = shift;

    my ($session, $error) = Net::SNMP->session(-hostname => $host,
					       -community => $community,
					       -version => 1,
					       -timeout => 10
					       );
    die "Unable to connect to $host: $error\n" unless defined $session;

    return $session;
}

1;

__END__

=head1 HEAD

VUser::Trango::AP::R900S - vuser extension to manage Trango R900S APs

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE
 
This file is part of VUser-Trango.

VUser-Trango is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

VUser-Trango is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with VUser-Trango; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut

