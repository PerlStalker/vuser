package VUser::ActiveDirectory;
use warnings;
use strict;

# Copyright 2008 Randy Smith
# $Id: ActiveDirectory.pm,v 1.2 2008-03-17 22:54:28 perlstalker Exp $

use VUser::Log qw(:levels);
use VUser::ExtLib qw(:config);
use VUser::ResultSet;
use VUser::Meta;

our $VERSION = '0.1.0';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = qw(domain2ldap);
our %EXPORT_TAGS = (utils => [qw(domain2ldap)]);

our $log;
our $c_sec = 'Extension ActiveDirectory';
our %meta = (
	'user' => VUser::Meta->('name' => 'user',
							'type' => 'string',
							'description' => 'User name'
							),
	'password' => VUser::Meta->('name' => 'password',
	                            'type' => 'string',
	                            'description' => 'Password'
	                            ),
	'domain' => VUser::Meta->('name' => 'domain',
	                          'type' => 'string',
	                          'description' => 'AD Domain; e.g. ad.yourdomain.com'
	                          ),
	'ou' => VUser::Meta->('name' => 'ou',
			              'type' => 'string',
			              'description' => 'OU to modify; e.g. ou=Regular,ou=Users'
			              ),
    'homedir' => VUser::Meta->('name' => 'homedir',
                               'type' => 'string',
                               'description' => 'Path of user\'s home dir; e.g. \\server\Home\user'
                               ),
    'homedrive' => VUser::Meta->('name' => 'homedrive',
                                 'type' => 'string',
                                 'description' => 'Drive letter to map home directory to; e.g. N:'
                                 ),
    'group' => VUser::Meta->('name' => 'group',
                             'type' => 'string',
                             'description' => 'Group name'
                             )
);

sub c_sec { return $c_sec; }
sub Log {
	if (UNIVERSAL::isa($log, 'VUser::Log')) {
		return $log
	} elsif (UNIVERSAL::isa($main::log, 'VUser::Log')) {
		$log = $main::log;
	} else {
		$log = VUser::Log->new('VUser-ActiveDirectory');
	} 
	return $log;
}

sub init {
	my $eh = shift;
	my %cfg = @_;
	
	$log = Log();
	
	# aduser
	$eh->register_keyword('aduser', 'Manage AD users');
	
	# aduser add
	$eh->register_action('aduser', 'add', 'Add an AD user');
	$eh->register_option('aduser', 'add', $meta{'user'}, 1);
	$eh->register_option('aduser', 'add', $meta{'password'});
	$eh->register_option('aduser', 'add', $meta{'domain'});
	$eh->register_option('aduser', 'add', $meta{'ou'});
	$eh->register_option('aduser', 'add', $meta{'homedir'});
	$eh->register_option('aduser', 'add', $meta{'homedrive'});
	# Option to create homedir
	
	# aduser del
	$eh->register_action('aduser', 'del', 'Delete an AD user');
	$eh->register_option('aduser', 'del', $meta{'user'}, 1);
	$eh->register_option('aduser', 'del', $meta{'domain'});
	$eh->register_option('aduser', 'del', $meta{'ou'});
	# Option to delete homedir
	
	# aduser mod
	$eh->register_action('aduser', 'mod', 'Modify an AD user');
	$eh->register_action('aduser', 'mod', 'Delete an AD user');
	$eh->register_option('aduser', 'mod', $meta{'user'}, 1);
	$eh->register_option('aduser', 'mod', $meta{'domain'});
	$eh->register_option('aduser', 'mod', $meta{'ou'});
    # More options
    
    # aduser change-password
    $eh->register_action('aduser', 'change-password', 'Change an AD user\'s password');
	$eh->register_option('aduser', 'change-password', $meta{'user'}, 1);
	$eh->register_option('aduser', 'change-password', $meta{'domain'});
	$eh->register_option('aduser', 'change-password', $meta{'ou'});
	$eh->register_option('aduser', 'change-password', $meta{'password'}, 1);
    
}

sub domain2ldap {
    my $domain = shift;
    my $dn = join ',', map { "dn=$_" } split /\./, $domain;
    return $dn;
}

1;

__END__

=head1 NAME

VUser::ActiveDirectory - VUser extension for managing user and groups in Microsoft Active Directory

=head1 DESCRIPTION

VUser extension for managing user and groups in Microsoft Active Directory. 

=head1 CONFIGURATION

 [Extension ActiveDirectory]
 # Your Active Directory domain
 domain = ad.yourdomain
 
 # Default user OU
 user ou = CN=Users
 
 # Default group OU
 group ou = CN=Users
 
 # Address/name of your AD server
 ad server = ad_server 

=head1 AUTHOR

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
