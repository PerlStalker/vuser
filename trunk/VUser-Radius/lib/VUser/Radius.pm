package VUser::Radius;
use warnings;
use strict;

# Copyright 2006 Randy Smith <perlstalker@vuser.org>
# $Id: Radius.pm,v 1.3 2006-08-16 19:59:35 perlstalker Exp $

use VUser::Meta;
use VUser::Log;

our $VERSION = '0.1.0';

our $c_sec = 'Extension Radius';
our %meta = ('username' => VUser::Meta->new('name' => 'username',
					    'type' => 'string',
					    'description' => 'User name'),
	     'password' => VUser::Meta->new('name' => 'password',
					    'type' => 'string',
					    'description' => 'User\'s password'),
	     'realm' => VUser::Meta->new('name' => 'realm',
					 'type' => 'string',
					 'description' => 'Realm for this user'),
	     'attribute' => VUser::Meta->new('name' => 'realm',
					     'type' => 'string',
					     'description' => 'Attribute to set for this user'),
	     'value' => VUser::Meta->new('name' => 'value',
					 'type' => 'string',
					 'description' => 'Value of passed attribute')
	     );

my $log;

sub init {
    my $eh = shift;
    my %cfg = @_;

    $log = $main::log;

    # Radius
    $eh->register_keyword ('radius', 'Manage RADIUS users');

    # radius-adduser
    $eh->register_action ('radius', 'adduser', 'Add a user to RADIUS');
    $eh->register_option ('radius', 'adduser', $meta{'username'}, 'req');
    $eh->register_option ('radius', 'adduser', $meta{'password'}, 'req');
    $eh->register_option ('radius', 'adduser', $meta{'realm'});

    # radius-rmuser
    $eh->register_action ('radius', 'rmuser', 'Remove a user from RADIUS');
    $eh->register_option ('radius', 'rmuser', $meta{'username'}, 'req');
    $eh->register_option ('radius', 'rmuser', $meta{'realm'});

    # radius-moduser
    $eh->register_action ('radius', 'moduser', 'Modify a RADIUS user');
    $eh->register_option ('radius', 'moduser', $meta{'username'}, 'req');
    $eh->register_option ('radius', 'moduser', $meta{'realm'});
    $eh->register_option ('radius', 'moduser', $meta{'username'}->new('name' => 'newusername'));
    $eh->register_option ('radius', 'moduser', $meta{'password'}->new('name' => 'newpassword'));
    $eh->register_option ('radius', 'moduser', $meta{'realm'}->new('name' => 'newrealm'));
    
}

sub meta { return %meta; }
sub c_sec { return $c_sec; }

1;

__END__

=head1 NAME

VUser::Radius - vuser extension to manage RADIUS users

=head1 DESCRIPTION

VUser::Radius is an extension to vuser that allows one to manage RADIUS
users. VUser::Radius is not meant to be used by itself but, instead,
registers the basic keywords, actions and options that other VUser::Radius::*
extensions will use. Other options may be added by RADIUS server specific
extensions.

=head1 CONFIGURATION

 [Extension Radius]

Any Radius::* extensions will automatically load I<Radius>. There is no
need to add I<Radius> to I<vuser|extensions>.
Other VUser::Radius::* extensions may have their own configuration.

=head1 META SHORTCUTS

VUser::Firewall provides a few VUser::Meta objects that may be used by
other firewall extensions. The safest way to access them is to call
VUser::Firewall::meta() from within the extension's init() function.

Provided keys: username, password, realm, attribute, value

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE
 
 This file is part of VUser-Radius.
 
 VUser-Radius is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 VUser-Radius is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vuser; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
