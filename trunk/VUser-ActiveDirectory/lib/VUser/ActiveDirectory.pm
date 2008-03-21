package VUser::ActiveDirectory;
use warnings;
use strict;

# Copyright 2008 Randy Smith
# $Id: ActiveDirectory.pm,v 1.3 2008-03-21 15:52:35 perlstalker Exp $

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
	'user' => VUser::Meta->new('name' => 'user',
							'type' => 'string',
							'description' => 'User name'
							),
	'password' => VUser::Meta->new('name' => 'password',
	                            'type' => 'string',
	                            'description' => 'Password'
	                            ),
	'domain' => VUser::Meta->new('name' => 'domain',
	                          'type' => 'string',
	                          'description' => 'AD Domain; e.g. ad.yourdomain.com'
	                          ),
	'ou' => VUser::Meta->new('name' => 'ou',
			              'type' => 'string',
			              'description' => 'OU to modify; e.g. ou=Regular,ou=Users'
			              ),
    'homedir' => VUser::Meta->new('name' => 'homedir',
                               'type' => 'string',
                               'description' => 'Path of user\'s home dir; e.g. \\server\Home\user'
                               ),
    'homedrive' => VUser::Meta->new('name' => 'homedrive',
                                 'type' => 'string',
                                 'description' => 'Drive letter to map home directory to; e.g. N:'
                                 ),
    'group' => VUser::Meta->new('name' => 'group',
                             'type' => 'string',
                             'description' => 'Group name'
                             ),
    'createhome' => VUser::Meta->new('name' => 'createhome',
                                        'type' => 'boolean',
                                        'description' => 'Create the user\'s home directory'
                                        ),
    'deletehome' => VUser::Meta->new('name' => 'deletehome',
                                        'type' => 'boolean',
                                        'description' => 'Delete the user\'s home directory'
                                        ),
    'recurse' => VUser::Meta->new('name' => 'recurse',
                                  'type' => 'boolean',
                                  'description' => 'Show members from sub-OUs')
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
	$eh->register_option('aduser', 'add', $meta{'createhome'});
	
	# aduser del
	$eh->register_action('aduser', 'del', 'Delete an AD user');
	$eh->register_option('aduser', 'del', $meta{'user'}, 1);
	$eh->register_option('aduser', 'del', $meta{'domain'});
	$eh->register_option('aduser', 'del', $meta{'ou'});
	$eh->register_option('aduser', 'del', $meta{'deletehome'});
	
	# aduser mod
	$eh->register_action('aduser', 'mod', 'Modify an AD user');
	$eh->register_option('aduser', 'mod', $meta{'user'}, 1);
	$eh->register_option('aduser', 'mod', $meta{'domain'});
	$eh->register_option('aduser', 'mod', $meta{'ou'});
	$eh->register_option('aduser', 'mod', $meta{'user'}->new('name' => 'useruser'));
	# For now, the user cannot change domains
	# $eh->register_option('aduser', 'mod', $meta{'domain'}->new('name' => 'newdomain'));
	$eh->register_option('aduser', 'mod', $meta{'ou'}->new('name' => 'newou'));
    # More options
    
    # aduser enable
	$eh->register_action('aduser', 'enable', 'Enable an AD user');
	$eh->register_option('aduser', 'enable', $meta{'user'}, 1);
	$eh->register_option('aduser', 'enable', $meta{'domain'});
	$eh->register_option('aduser', 'enable', $meta{'ou'});

    # aduser disable
	$eh->register_action('aduser', 'disable', 'Disable an AD user');
	$eh->register_option('aduser', 'disable', $meta{'user'}, 1);
	$eh->register_option('aduser', 'disable', $meta{'domain'});
	$eh->register_option('aduser', 'disable', $meta{'ou'});
    
    # aduser change-password
    $eh->register_action('aduser', 'change-password', 'Change an AD user\'s password');
	$eh->register_option('aduser', 'change-password', $meta{'user'}, 1);
	$eh->register_option('aduser', 'change-password', $meta{'domain'});
	$eh->register_option('aduser', 'change-password', $meta{'ou'});
	$eh->register_option('aduser', 'change-password', $meta{'password'}, 1);

    # aduser list
    $eh->register_action('aduser', 'list', 'List AD users');
    $eh->register_option('aduser', 'list', $meta{'domain'});
    $eh->register_option('aduser', 'list', $meta{'ou'});
    $eh->register_option('aduser', 'list', VUser::Meta->new('name' => 'showdisabled',
                                                            'type' => 'boolean',
                                                            'description' => 'Show disabled accounts'));
    $eh->register_option('aduser', 'list', VUser::Meta->new('name' => 'onlydisabled',
                                                            'type' => 'boolean',
                                                            'description' => 'Only show disabled accounts'));
    $eh->register_option('aduser', 'list', VUser::Meta->new('name' => 'dayssincelogon',
                                                            'type' => 'boolean',
                                                            'description' => 'Number of says since last logon'));
    $eh->register_option('aduser', 'list', $meta{'recurse'});
    
    ## adgroup
    $eh->register_keyword('adgroup', 'Manage AD groups');
    
    # adgroup add
    $eh->register_action('adgroup', 'add', 'Add a group to AD');
    $eh->register_option('adgroup', 'add', $meta{'group'}, 1);
    $eh->register_option('adgroup', 'add', $meta{'domain'});
    $eh->register_option('adgroup', 'add', $meta{'ou'});

    # adgroup del
    $eh->register_action('adgroup', 'del', 'Delete a group to AD');
    $eh->register_option('adgroup', 'del', $meta{'group'}, 1);
    $eh->register_option('adgroup', 'del', $meta{'domain'});
    $eh->register_option('adgroup', 'del', $meta{'ou'});
    
    # adgroup mod
    $eh->register_action('adgroup', 'mod', 'Modify a group to AD');
    $eh->register_option('adgroup', 'mod', $meta{'group'}, 1);
    $eh->register_option('adgroup', 'mod', $meta{'domain'});
    $eh->register_option('adgroup', 'mod', $meta{'ou'});
    $eh->register_option('adgroup', 'mod', $meta{'group'}->new('name' => 'newgroup'));
    #$eh->register_option('adgroup', 'mod', $meta{'domain'}->new('name' => 'newdomain'));
    $eh->register_option('adgroup', 'mod', $meta{'ou'}->new('name' => 'newou'));

    # adgroup adduser
    $eh->register_action('adgroup', 'adduser', 'Add a user to the group');
    $eh->register_option('adgroup', 'adduser', $meta{'group'}, 1);
    $eh->register_option('adgroup', 'adduser', $meta{'user'}, 1);
    $eh->register_option('adgroup', 'adduser', $meta{'domain'});
    $eh->register_option('adgroup', 'adduser', $meta{'ou'});
    $eh->register_option('adgroup', 'adduser', $meta{'domain'}->new('name' => 'userdomain'));
    $eh->register_option('adgroup', 'adduser', $meta{'ou'}->new('name' => 'userou'));

    # adgroup rmuser
    $eh->register_action('adgroup', 'rmuser', 'Remove a user from the group');
    $eh->register_option('adgroup', 'rmuser', $meta{'group'}, 1);
    $eh->register_option('adgroup', 'rmuser', $meta{'user'}, 1);
    $eh->register_option('adgroup', 'rmuser', $meta{'domain'});
    $eh->register_option('adgroup', 'rmuser', $meta{'ou'});
    $eh->register_option('adgroup', 'rmuser', $meta{'domain'}->new('name' => 'userdomain'));
    $eh->register_option('adgroup', 'rmuser', $meta{'ou'}->new('name' => 'userou'));
    
    # adgroup list
    $eh->register_action('adgroup', 'list', 'List groups');
    $eh->register_option('adgroup', 'list', $meta{'domain'});
    $eh->register_option('adgroup', 'list', $meta{'ou'});
    $eh->register_option('adgroup', 'list', $meta{'recurse'});
    
    # adgroup members
    $eh->register_action('adgroup', 'members', 'List group members');
    $eh->register_option('adgroup', 'members', $meta{'group'}, 1);
    $eh->register_option('adgroup', 'members', $meta{'domain'});
    $eh->register_option('adgroup', 'members', $meta{'ou'});
    
    
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
