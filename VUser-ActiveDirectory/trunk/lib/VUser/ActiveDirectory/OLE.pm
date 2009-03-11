package VUser::ActiveDirectory::OLE;
use warnings;
use strict;

# Copyright 2008 Randy Smith
# $Id: OLE.pm,v 1.5 2008-03-25 22:19:00 perlstalker Exp $

use VUser::Log qw(:levels);
use VUser::ExtLib qw(:config);
use VUser::ResultSet;
use VUser::Meta;
use VUser::ActiveDirectory qw(:utils);

use Win32::OLE qw(in);

our $VERSION = '0.1.0';

our $log;
our %meta;
our $c_sec = 'Extension ActiveDirectory';

sub c_sec { return $c_sec; };
sub depends { qw(ActiveDirectory); }

sub unload {}

sub init {
    my $eh = shift;
    my %cfg = @_;
        
    $log = VUser::ActiveDirectory::Log();
    
    ## aduser
    $eh->register_task('aduser', 'add', \&aduser_add);
    $eh->register_task('aduser', 'del', \&aduser_del);
    $eh->register_task('aduser', 'mod', \&aduser_mod);
    $eh->register_task('aduser', 'enable', \&aduser_enable_disable);
    $eh->register_task('aduser', 'disable', \&aduser_enable_disable);
    $eh->register_task('aduser', 'change-password', \&aduser_changepw);
    $eh->register_task('aduser', 'list', \&aduser_list);
    
    ## adgroup
    $eh->register_task('adgroup', 'add', \&adgroup_add);
    $eh->register_task('adgroup', 'del', \&adgroup_del);
    $eh->register_task('adgroup', 'mod', \&adgroup_mod);
    $eh->register_task('adgroup', 'adduser', \&adgroup_adduser);
    $eh->register_task('adgroup', 'rmuser', \&adgroup_rmuser);
    $eh->register_task('adgroup', 'list', \&adgroup_list);
    $eh->register_task('adgroup', 'members', \&adgroup_members);
}

sub aduser_add {
    my ($cfg, $opts, $action, $eh) = @_;
    
    my $ad_server = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'ad server'});
    my $domain = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'domain'});
    my $user_ou = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'user ou'});
    
    $domain = $opts->{'domain'} if $opts->{'domain'};
    $user_ou = $opts->{'ou'} if $opts->{'ou'};
    
    my $dn = domain2ldap($domain);
    my $ADsPath = "LDAP://";
    $ADsPath .= "$ad_server/" if $ad_server;
    $ADsPath .= $dn;
    
    my $ad = Win32::OLE->GetObject($ADsPath)
        or die "Unable to get $ADsPath: ".Win32::OLE->LastError()."\n";
    
    my $username = $opts->{'user'};        
    my $user = $ad->Create('user', "cn=$username,$user_ou");
    $user->{'samAccountName'} = $username;
    $user->SetPassword('someReallyAufulStringWith30983098and^^%$$');
    $user->SetInfo();
    die "OLE Error: ".Win32::OLE->LastError() if Win32::OLE->LastError();
   
    $user->{'displayName'} = $username;
    if ($opts->{'homedir'}) {
        $user->{'homeDirectory'} = $opts->{'homedir'};
    }
    
    if ($opts->{'homedrive'}) {
        $user->{'homeDrive'} = $opts->{'homedrive'};
    }
    
    if ($opts->{'fname'}) {
        $user->{'givenName'} = $opts->{'fname'};
    }
    
    if ($opts->{'lname'}) {
        $user->{'sn'} = $opts->{'lname'};
    }
    
    if ($opts->{'email'}) {
        $user->{'mail'} = $opts->{'email'};
    }
    
    if ($opts->{'password'}) {
        $user->SetPassword($opts->{'password'});
    }
    
    $user->{'accountDisabled'} = 0;
    $user->SetInfo();
    die "OLE Error: ".Win32::OLE->LastError() if Win32::OLE->LastError();
    return;
}

sub aduser_del {
    my ($cfg, $opts, $action, $eh) = @_;

    # TODO Refactor AD connection code?
    my $ad_server = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'ad server'});
    my $domain = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'domain'});
    my $user_ou = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'user ou'});
    
    $domain = $opts->{'domain'} if $opts->{'domain'};
    $user_ou = $opts->{'ou'} if $opts->{'ou'};
    
    my $dn = domain2ldap($domain);
    my $ADsPath = "LDAP://";
    $ADsPath .= "$ad_server/" if $ad_server;
    $ADsPath .= $dn;

    my $ad = Win32::OLE->GetObject($ADsPath)
        or die "Unable to get $ADsPath: ".Win32::OLE->LastError()."\n";
    
    my $user = $opts->{'user'};
    $ad->Delete('user', "cn=$user,$user_ou");
    die "OLE Error: ".Win32::OLE->LastError() if Win32::OLE->LastError();
    
    return;
}

sub aduser_mod {
    my ($cfg, $opts, $action, $eh) = @_;
    
    my $ad_server = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'ad server'});
    my $domain = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'domain'});
    my $user_ou = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'user ou'});
    
    $domain = $opts->{'domain'} if $opts->{'domain'};
    $user_ou = $opts->{'ou'} if $opts->{'ou'};
    
    my $dn = domain2ldap($domain);
    my $ADsPath = "LDAP://";
    $ADsPath .= "$ad_server/" if $ad_server;
    $ADsPath .= $dn;

    my $ad = Win32::OLE->GetObject($ADsPath)
        or die "Unable to get $ADsPath: ".Win32::OLE->LastError()."\n";
    
    my $user_path = sprintf("cn=%s,$user_ou,$dn", $opts->{'user'});
    my $user = Win32::OLE->GetObject("LDAP://$ad_server/$user_path")
        or die "Unable to get user $user_path: ".Win32::OLE->LastError()."\n";
    #$user->{'displayName'} = $username;
    if ($opts->{'homedir'}) {
        $user->{'homeDirectory'} = $opts->{'homedir'};
    }
    
    if ($opts->{'homedrive'}) {
        $user->{'homeDrive'} = $opts->{'homedrive'};
    }
    
    if ($opts->{'fname'}) {
        $user->{'givenName'} = $opts->{'fname'};
    }
    
    if ($opts->{'lname'}) {
        $user->{'sn'} = $opts->{'lname'};
    }
    
    if ($opts->{'email'}) {
        $user->{'mail'} = $opts->{'email'};
    }
    
    if ($opts->{'password'}) {
        $user->SetPassword($opts->{'password'});
    }
    
    $user->SetInfo();
    die "OLE Error: ".Win32::OLE->LastError() if Win32::OLE->LastError();

    ## Now to change the user name, ou, etc if that's what is wanted
    if ($opts->{'newuser'}) {
        my $ou_obj = Win32::OLE->GetObject("LDAP://$ad_server/$user_ou,$dn")
            or die "Unable to get ou $user_ou: ".Win32::OLE->LastError()."\n";
        $log->log(LOG_DEBUG, "Path: %s; user: %s", $user->{'ADsPath'}, $opts->{'newuser'});
        $ou_obj->MoveHere($user->{'ADsPath'}, 'cn='.$opts->{'newuser'});
        die "OLE Error: ".Win32::OLE->LastError() if Win32::OLE->LastError();

        # Refresh user
        $user = Win32::OLE->GetObject("LDAP://$ad_server/cn=".$opts->{'newuser'}.",$user_ou,$dn");
        $log->log(LOG_DEBUG, "New Path: %s", $user->{'ADsPath'});
        die "OLE Error: ".Win32::OLE->LastError() if Win32::OLE->LastError();
        
        $user->{'userPrincipalName'} = $opts->{'newuser'}.'@'.$domain;
        $user->{'sAMAccountName'} = $opts->{'newuser'};
        $user->{'displayName'} = $opts->{'newuser'};
        $user->SetInfo();
        die "OLE Error: ".Win32::OLE->LastError() if Win32::OLE->LastError();
    }

    # Moving the user to a new OU should be the last thing done.    
    if ($opts->{'newou'}) {
        my $newpath = $opts->{'newou'};
        if ($opts->{'newdomain'}) {
            $newpath .= ','.$opts->{'newdomain'};
        } else {
            $newpath .= ",$dn";
        }
        $log->log(LOG_DEBUG, "New OU Path: $newpath");
        my $new_ou = Win32::OLE->GetObject("LDAP://$ad_server/$newpath")
            or die "Unable to get ou $newpath: ".Win32::OLE->LastError()."\n";
        $new_ou->MoveHere($user->{'ADsPath'}, $user->{'Name'});
    }

    return;
}

sub aduser_enable_disable {
    my ($cfg, $opts, $action, $eh) = @_;
    
    my $ad_server = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'ad server'});
    my $domain = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'domain'});
    my $user_ou = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'user ou'});
    
    $domain = $opts->{'domain'} if $opts->{'domain'};
    $user_ou = $opts->{'ou'} if $opts->{'ou'};
    
    my $dn = domain2ldap($domain);
    my $ADsPath = "LDAP://";
    $ADsPath .= "$ad_server/" if $ad_server;
    $ADsPath .= $dn;

    my $ad = Win32::OLE->GetObject($ADsPath)
        or die "Unable to get $ADsPath: ".Win32::OLE->LastError()."\n";
    
    my $user_path = sprintf("cn=%s,$user_ou,$dn", $opts->{'user'});
    my $user = Win32::OLE->GetObject("LDAP://$ad_server/$user_path")
        or die "Unable to get user $user_path: ".Win32::OLE->LastError()."\n";
        
    if ($action eq 'enable') {
        $user->{'accountDisabled'} = 0;
    } elsif ($action eq 'disable') {
        $user->{'accountDisabled'} = 1;
    } elsif ($action eq 'lock') {
    } elsif ($action eq 'unlock') {
        # $user->{'IsAccountLocked'} = 0;
    }
    $user->SetInfo();
    die "OLE Error: ".Win32::OLE->LastError() if Win32::OLE->LastError();
    
    return;
}

sub aduser_changepw {
    my ($cfg, $opts, $action, $eh) = @_;
    
    my $ad_server = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'ad server'});
    my $domain = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'domain'});
    my $user_ou = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'user ou'});
    
    $domain = $opts->{'domain'} if $opts->{'domain'};
    $user_ou = $opts->{'ou'} if $opts->{'ou'};
    
    my $dn = domain2ldap($domain);
    my $ADsPath = "LDAP://";
    $ADsPath .= "$ad_server/" if $ad_server;
    $ADsPath .= $dn;

    my $ad = Win32::OLE->GetObject($ADsPath)
        or die "Unable to get $ADsPath: ".Win32::OLE->LastError()."\n";
    
    my $user_path = sprintf("cn=%s,$user_ou,$dn", $opts->{'user'});
    my $user = Win32::OLE->GetObject("LDAP://$ad_server/$user_path")
        or die "Unable to get user $user_path: ".Win32::OLE->LastError()."\n";
        
    $user->SetPassword($opts->{'password'});
    die "OLE Error: ".Win32::OLE->LastError() if Win32::OLE->LastError();
    
    return;
}

sub aduser_list {
    my ($cfg, $opts, $action, $eh) = @_;

    my $rs = VUser::ResultSet->new();
    $rs->add_meta($VUser::ActiveDirectory::meta{'user'}); # username
    $rs->add_meta(VUser::Meta->new('name' => 'cn',
				   'description' => 'User\'s canonical name',
				   'type' => 'string')); # cn
    if ($opts->{dayssincelogon}) {
	$rs->add_meta(VUser::Meta->new('name' => 'lastlogintime',
				       'description' => 'Posix timestamp of last log in time',
				       'type' => 'integer'))
    }

    my $ole_conn = Win32::OLE->new('ADODB.Connection');
    $ole_conn->{Provider} = 'ADsDSOObject';
    $ole_conn->Open;

    my $ole_comm = Win32::OLE->new('ADODB.Command');
    $ole_comm->{ActiveConnection} = $ole_conn;
    $ole_comm->Properties->{'Page Size'} = 100;

    my $ad_server = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'ad server'});
    my $domain = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'domain'});
    my $ou = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'user ou'});

    $domain = $opts->{'domain'} if $opts->{'domain'};
    $ou = $opts->{'ou'} if $opts->{'ou'};
    my $dn = domain2ldap($domain);

    my $ADsPath = "LDAP://";
    if ($ad_server) {
	$ADsPath .= "$ad_server/";
    } elsif ($domain) {
	$ADsPath .= "$domain/";
    }
    $ADsPath .= "$ou,$dn";

    my $query = "<$ADsPath>;";
    $query .= "(&(objectclass=user)";
    $query .= "(objectcategory=Person)";

    if ($opts->{onlydisabled}) {
	$query .= "(useraccountcontrol:1.2.840.113556.1.4.803:=2)";
    } elsif ($opts->{showdisabled}) {
	# noop
    } else {
	$query .= "(!useraccountcontrol:1.2.840.113556.1.4.803:=2)";
    }

    if ($opts->{dayssincelogon}) {
	my $past_secs = time - 86400 * $opts->{dayssincelogon};
	my $bi_lastlogon = VUser::ActiveDirectory::PosixTimestamp2msTimestamp($past_secs);
	$query .= "(lastLogonTimestamp<=$bi_lastlogon)";
    }

    $query .= ");";
    $query .= "lastLogonTimestamp,cn,distinguishedName;";
    $query .= "subtree";

    $log->log(LOG_DEBUG, "AD Query: $query");

    $ole_comm->{CommandText} = $query;
    my $res = $ole_comm->Execute($query);
    die Win32::OLE->LastError() if Win32::OLE->LastError();
    while (not $res->EOF) {
	# pull out fields
	my %data = ('user' => $res->Fields('distinguishedName')->value,
		    'cn' => $res->Fields('cn')->value
	    );

	#$log->log(LOG_DEBUG, "Found user: %s", $data{'cn'});

	if ($opts->{dayssincelogon}) {
	    $data{'lastlogintime'} = undef;
	    $Win32::OLE::Warn = 3;

	    my $dom = defined $ad_server ? $ad_server : $domain;

	    my $user = Win32::OLE->GetObject("LDAP://$dom/$data{user}");
	    
	    my $timestamp = VUser::ActiveDirectory::msTimestamp2PosixTimestamp($user->{'lastlogontimestamp'});
	    #print "time:".$timestamp;
	    #print " ", scalar localtime($timestamp);
	    #print "\n";

	    $log->log(LOG_DEBUG, "User %s last logged in at %s",
		      $data{'user'},
		      $timestamp);

	    $data{'lastlogintime'} = $timestamp;
	}

	$rs->add_data(\%data); # Add user to result set

	#last;
	$res->MoveNext; # proceed to next record
    }

    return $rs;
}

## adgroup

sub adgroup_add {
    my ($cfg, $opts, $action, $eh) = @_;

    my $ad_server = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'ad server'});
    my $domain = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'domain'});
    my $group_ou = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'group ou'});
    
    $domain = $opts->{'domain'} if $opts->{'domain'};
    $group_ou = $opts->{'ou'} if $opts->{'ou'};

    my $group = $opts->{'group'};

    my $ad_str = defined $ad_server ? $ad_server : $domain;

    my $dn = domain2ldap($domain);
    my $ADsPath = "LDAP://$ad_str/$group_ou,$dn";

    my $ou_obj = Win32::OLE->GetObject("$ADsPath")
        or die "Unable to get $ADsPath: ".Win32::OLE->LastError()."\n";

    my $group_obj = $ou_obj->Create('group', "cn=$group");
    #$group_obj->Put("groupType", ADS_GROUP_TYPE_SECURITY_GROUP
    $group_obj->Put('sAMAccountName', $group);
    $group_obj->SetInfo();

    return undef;
}

sub adgroup_del {
    my ($cfg, $opts, $action, $eh) = @_;

    my $ad_server = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'ad server'});
    my $domain = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'domain'});
    my $group_ou = strip_ws($cfg->{VUser::ActiveDirectory::c_sec()}{'group ou'});
    
    $domain = $opts->{'domain'} if $opts->{'domain'};
    $group_ou = $opts->{'ou'} if $opts->{'ou'};
    
    my $dn = domain2ldap($domain);
    my $ADsPath = "LDAP://";
    $ADsPath .= "$ad_server/" if $ad_server;
    $ADsPath .= $dn;

    my $ad = Win32::OLE->GetObject($ADsPath)
        or die "Unable to get $ADsPath: ".Win32::OLE->LastError()."\n";

    my $group = $opts->{'group'};

    $ad->Delete('group', "cn=$group,$group_ou");
    die "OLE Error: ".Win32::OLE->LastError() if Win32::OLE->LastError();
    
    return undef;
}

sub adgroup_mod {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub adgroup_adduser {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub adgroup_rmuser {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub adgroup_list {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub adgroup_members {
    my ($cfg, $opts, $action, $eh) = @_;
}

1;

__END__

=head1 NAME

VUser::ActiveDirectory::OLE - VUser extension for managing ActiveDirectory via OLE.

=head1 DESCRIPTION

VUser extension for managing user and groups in Microsoft Active Directory via OLE. 

=head1 CONFIGURATION

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
