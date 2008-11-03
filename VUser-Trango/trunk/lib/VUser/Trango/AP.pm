package VUser::Trango::AP;
use warnings;
use strict;

# Copyright 2006 Randy Smith <perlstalker@vuser.org>
# $Id: AP.pm,v 1.1 2006-01-09 23:15:07 perlstalker Exp $

use VUser::Log qw(:levels);
use VUser::Meta;
use VUser::ResultSet;

our $VERSION = "0.1.0";

our $c_sec = 'Extension Trango::AP';
our %meta = (
	     'host' => VUser::Meta->new('name' => 'host',
					'type' => 'string',
					'description' => 'Host name or IP address'),
	     suID => VUser::Meta->new(name => 'suID',
				      type => 'int',
				      description => 'Subscriber unit ID'),
	     suMAC => VUser::Meta->new(name => 'suMAC',
				       type => 'string',
				       description => 'SU MAC address'),
	     suPolling => VUser::Meta->new(name => 'suPolling',
					   type => 'int',
					   description => 'Service level'),
	     suGroupID => VUser::Meta->new(name => 'suGroupId',
					   type => 'int',
					   description => 'peer-to-peer group this SU belongs to'),
	     suSUtoSU => VUser::Meta->new(name => 'suSUtoSU',
					  type => 'int',
					  description => 'peer-to-peer group this SU belongs to'),
	     suCIR => VUser::Meta->new(name => 'suCIR',
				       type => 'int',
				       description => 'Committed information rate (Kbps)'),
	     suMIR => VUser::Meta->new(name => 'suMIR',
				       type => 'int',
				       description => 'Maximum information rate (Kbps)'),
	     suIPAddr => VUser::Meta->new(name => 'suIPAddr',
					  type => 'string',
					  description => 'SU IP address'),
	     suSubnetMask => VUser::Meta->new(name => 'suSubnetMask',
					      type => 'string',
					      description => 'SU subnet mask'),
	     suGateWay => VUser::Meta->new(name => 'suGateWay',
					   type => 'string',
					   description => 'SU gateway address'),
	     suRemarks => VUser::Meta->new(name => 'suRemarks',
					   type => 'string',
					   description => 'SU remark'),
	     suHWVer => VUser::Meta->new(name => 'suHWVer',
					 type => 'string',
					 description => 'SU Hardware version'),
	     suFWVer => VUser::Meta->new(name => 'suFWVer',
					 type => 'string',
					 description => "SU Firmware version"),
	     suFWChecksum => VUser::Meta->new(name => 'suFWChecksum',
					      type => 'string',
					      description => 'SU firmware checksum'),
	     suFPGAVer => VUser::Meta->new(name => 'suFPGAVer',
					   type => 'string',
					   description => 'SU FPGA firmware version'),
	     suFPGAChecksum => VUser::Meta->new(name => 'suFPGAChecksum',
						type => 'string',
						description => 'SU FPGA firmware checksum'),
	     suChecksum => VUser::Meta->new(name => 'suChecksum',
					    type => 'string',
					    description => 'SU firmware checksum'),
	     suAssociation => VUser::Meta->new(name => 'suAssociation',
					       type => 'int',
					       description => 'SU association status'),
	     suDistance => VUser::Meta->new(name => 'suDistance',
					    type => 'int',
					    description => 'Distance of SU'),
	     suRSSIAtSU => VUser::Meta->new(name => 'suRSSIAtSU',
					    type => 'int',
					    description => "RSSI at SU (dBm)"),
	     suRSSIFromSU => VUser::Meta->new(name => 'suRSSIFromSU',
					      type => 'int',
					      description => 'RSSI from SU (dBm)'),
	     suRSSIAtAP => VUser::Meta->new(name => 'suRSSIAtAP',
					    type => 'int',
					    desctription => 'RSSI at AP (dBm)'),
	     suRSSIFromAP => VUser::Meta->new(name => 'suRSSIFromAP',
					      type => 'int',
					      description => 'RSSI from AP (dBm)'),
	     suTxPower => VUser::Meta->new(name => 'suTxPower',
					   type => 'int',
					   description => 'SU Tx poer level (dBm)'),
	     suEthInOctets => VUser::Meta->new(name => 'suEthInOctets',
					       type => 'counter',
					       description => "Number of octets received on the Ethernet port."),
	     suEthOutOctets => VUser::Meta->new(name => 'suEthOutOctets',
						type => 'counter',
						description => "Number of octets transmitted on the Ethernet port."),
	     suRfInPackets => VUser::Meta->new(name => 'suRfInPackets',
					       type => 'counter',
					       description => "Number of payload packets received on the RF port."),
	     suRfOutPackets => VUser::Meta->new(name => 'suRfOutPackets',
						type => 'counter',
						description => "Number of payload packets transmitted on the RF port."),
	     suRfInDropPackets => VUser::Meta->new(name => 'suRfInDropPackets',
						   type => 'counter',
						   description => "Number of payload drop packets received on the RF port."),
	     suRfOutRetryAtAP => VUser::Meta->new(name => 'suRfOutRetryAtAP',
						  type => 'counter',
						  description => "Number of packets AP resent to SUs through RF port."),
	     suRfOutRetryMaxedOutAtAP => VUser::Meta->new(name => 'suRfOutRetryOutAtAP',
							  type => 'counter',
							  description => "Number of packets AP resent to SUs through RF port hits maximum."),
	     suRfOutRetryAtSU => VUser::Meta->new(name => 'suRfOutRetryAtSU',
						  type => 'counter',
						  description => "Number of payload retry packets transmitted to the RF port."),
	     suRfOutRetryMaxedOutAtSU => VUser::Meta->new(name => 'suRfOutRetryMaxedOutAtSU',
							  type => 'counter',
							  description => "Number of payload retry maxed-out packets."),
	     suBlockBroadcastMulticast => VUser::Meta->new(name => 'suBlockBroadcastMulticast',
							   type => 'int', #bool?
							   description => "When it is turned on, then the SU will block all the broadcast/multicast packets."),
	     suAutoScanning => VUser::Meta->new(name => 'suAutoScanning',
						type => 'int', #bool?
						description => "When it is turned on, then the SU will scan all channels during boot-up."),
	     suTcpIpServiceForAP => VUser::Meta->new(name => 'suTcpIpServiceForAp',
						     type => 'init', #bool?
						     description => "When it is turned on, then the SU will serve the TCP/IP service for AP."),
	     suHTTPD => VUser::Meta->new(name => 'suHTTP',
					 type => 'int', # bool?
					 description => "When it is turned on, then the SU will serve the web service."),
	     suTCPIPForLocalEthernet => VUser::Meta->new(name => 'suTCPIPForLocalEthernet',
							 type => 'int', #bool?
							 description => "When it is turned on, then the SU will process all the local TCP/IP service."),
	     suDownLinkCIR => VUser::Meta->new(name => 'suDownLinkCIR',
					       type => 'int',
					       description => "DownLink Committed Information Rate (Kbps)"),
	     suUpLinkCIR => VUser::Meta->new(name => 'suUpLinkCIR',
					     type => 'int',
					     description => "UpLink Committed Information Rate (Kbps)"),
	     suDownLinkMIR => VUser::Meta->new(name => 'suDownLinkMIR',
					       type => 'int',
					       description => 'DownLink Maximum Information Rate (Kbps)'),
	     suUpLinkMIR => VUser::Meta->new(name => 'suUpLinkMIR',
					     type => 'int',
					     description => 'UpLink Maximum Information Rate (Kbps)'),
	     suResetTrafficCounters => VUser::Meta->new(name => 'suResetTrafficCounters',
							type => 'int',
							description => "Clear the traffic counters"),
	     suEthRxAvgThroughputLog => VUser::Meta->new(name => 'suEthRxAvgThroughputLog',
							 type => 'int',
							 description => 'Avg throughput received (Kbps)'),
	     suEthTxAvgThroughputLog => VUser::Meta->new(name => 'suEthTxAvgThroughputLog',
							 type => 'int',
							 description => 'Avg throughput sent (Kbps)'),
	     suRfRxAvgThroughputLog => VUser::Meta->new(name => 'suRfRxAvgThroughputLog',
							type => 'int',
							description => 'Avg throughput received (Kbps)'),
	     suRfTxAvgThroughputLog => VUser::Meta->new(name => 'suRfTxAvgThroughputLog',
							type => 'int',
							description => 'Avg throughput sent (Kbps)'),
	     suRfInOctets => VUser::Meta->new(name => 'suRfInOctets',
					      type => 'counter',
					      description => 'Number of octets received'),
	     suRfOutOctets => VUser::Meta->new(name => 'suRfOutOctets',
					       type => 'counter',
					       description => 'Number of octets sent'),
	     suPowerLevel => VUser::Meta->new(name => 'suPowerLevel',
					      type => 'int',
					      description => 'SU power level'),
	     suTemperature => VUser::Meta->new(name => 'suTemperature',
					       type => 'int',
					       description => 'SU temperature (Celsius)'),
	     suReboot => VUser::Meta->new(name => 'suReboot',
					  type => 'init',
					  description => 'Issue a reboot command to a SU')
	     );

my $log;

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

    # ap
    $eh->register_keyword('ap', 'Manage Trango APs');

    # ap-sudb_view
    $eh->register_action('ap', 'sudb_view', 'View the APs sudb (slow)');
    $eh->register_option('ap', 'sudb_view', $meta{'host'}, 'req');
}

sub get_ap_type
{
    my $host = shift; # Host or open connection to radio
    my $pass = shift; # password or community string (not used if already connected)

    if (UNIVERSAL::isa($host, 'Net::SNMP')) {
	return get_ap_type_snmp($host);
    } else {
    }
}

sub get_ap_type_snmp
{
    my $host = shift; # Net::SNMP object

    # Trango puts the AP description in system.sysDescr
    my $sysDescr = '1.3.6.1.2.1.1.1.0';
    my $res = $host->get_request(-varbindlist => [$sysDescr]);
    die "Can't get sysDescr: ". $host->error. "\n" unless defined $res;
    
    if ($res->{$sysDescr} =~ /SNMP agent for (.*)$/i) {
	$log->log(LOG_DEBUG, "Radio is a %s", $1);
	return $1;
    } else {
	$log->log(LOG_NOTICE, "Can't determine type");
    }

    return undef;
}

1;

__END__

=head1 HEAD

VUser::Trango::AP - vuser extension to manage Trango APs

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
