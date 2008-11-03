package VUser::Trango::AP::Access5830;
use warnings;
use strict;

use VUser::Log qw(:levels);
use VUser::Trango::AP;
use VUser::Trango::AP::Access5800;
use Net::SNMP;

my $log;
my %meta;
my @sudb_map = ();
my $mib_root = '1.3.6.1.4.1.5454.1.20';

sub depends { return qw(Trango::AP Trango::AP::Access5800); }

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
    @sudb_map = @VUser::Trango::AP::Access5800::sudb_map;

    # ap-sudb_view
    $eh->register_task('ap', 'sudb_view', \&sudb_view);
}

sub sudb_view
{
    my ($cfg, $opts, $action, $eh) = @_;

    my $community = $opts->{community} || 'public';

    my $session = snmp_connect($opts->{host}, $community);

    if (VUser::Trango::AP::get_ap_type($session) ne 'M5830S') {
	$log->log(LOG_INFO, "%s is not a Trango Access5830", $opts->{host});
	return ;
    }

    return VUser::Trango::AP::Access5800::get_sudb($session, $mib_root);
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

VUser::Trango::AP::Access5830 - vuser extension to manage Trango Access 5030 APs

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

