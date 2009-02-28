package VUser::Google::Apps;
use warnings;
use strict;

# Copyright (c) 2006 Randy Smith <perlstalker@vuser.org>
# $Id: Apps.pm,v 1.6 2008-10-29 05:13:03 perlstalker Exp $

use VUser::Log qw(:levels);
use VUser::ExtLib qw(:config);
use VUser::ResultSet;
use VUser::Meta;

use VUser::Google::ProvisioningAPI;
use VUser::Google::ApiProtocol::V2_0;
use VUser::Google::EmailSettings::V2_0;
use Config::IniFiles;

our $VERSION = '0.2.1';

our $log;
our %meta = ('username' => VUser::Meta->new('name' => 'username',
					    'type' => 'string',
					    'description' => 'User name'),
	     'domain' => VUser::Meta->new('name' => 'domain',
					  'type' => 'string',
					  'description' => 'Domain name'),
	     'givenname' => VUser::Meta->new('name' => 'given-name',
					     'type' => 'string',
					     'description' => 'User\'s given name'),
	     'familyname' => VUser::Meta->new('name' => 'family-name',
					      'type' => 'string',
					      'description' => 'User\'s family name'),
	     'password' => VUser::Meta->new('name' => 'password',
					    'type' => 'string',
					    'description' => 'Account password'),
	     'suspended' => VUser::Meta->new('name' => 'suspended',
					     'type' => 'boolean',
					     'description' => 'Is account suspended'),
	     'quota' => VUser::Meta->new('name' => 'quota',
					 'type' => 'integer',
					 'description' => 'Mailbox quota in KB'),
	     'nickname' => VUser::Meta->new('name' => 'nickname',
					    'type' => 'string',
					    'description' => 'Nickname'),
	     'list' => VUser::Meta->new('name' => 'list',
					'type' => 'string',
					'description' => 'Email list'),
	     'email' => VUser::Meta->new('name' => 'email',
					 'type' => 'string',
					 'description' => 'Email address'),
	     'active' => VUser::Meta->new('name' => 'active',
					  'type' => 'boolean',
					  'description' => 'Is account active'),
	     'label' => VUser::Meta->new('name' => 'label',
					 'type' => 'string',
					 'description' => 'Name of label'),
	     'crit-from' => VUser::Meta->new('name' => 'from',
					     'type' => 'string',
					     'description' => 'Pattern of "From" address'),
	     'crit-to' => VUser::Meta->new('name' => 'to',
					   'type' => 'string',
					   'description' => 'Pattern of "To" address'),
	     'crit-subject' => VUser::Meta->new('name' => 'subject',
						'type' => 'string',
						'description' => 'Pattern of subject'),
	     'has-the-word' => VUser::Meta->new('name' => 'has-the-word',
						'type' => 'string',
						'description' => 'Message contains the word'),
	     'does-not-have-the-word'
	     => VUser::Meta->new('name' => 'does-not-have-the-word',
				 'type' => 'string',
				 'description' => 'Message does not contain the word'),
	     'has-attachment' => VUser::Meta->new('name' => 'has-attachment',
						  'type' => 'boolean',
						  'description' => 'Message contains an attachment'),
	     'should-mark-as-read'
	     => VUser::Meta->new('name' => 'should-mark-as-read',
				 'type' => 'boolean',
				 'description' => 'Mark the message as read'),
	     'should-archive' => VUser::Meta->new('name' => 'should-archive',
						  'type' => 'boolean',
						  'description' => 'Archive the message'),
	     'from-name' => VUser::Meta->new('name' => 'from-name',
					     'type' => 'string',
					     'description' => 'The name that will appear in the "From" field'),
	     'address' => VUser::Meta->new('name' => 'address',
					   'type' => 'string',
					   'description' => 'The email address that appears as the "From" address'),
	     'reply_to' => VUser::Meta->new('name' => 'reply-to',
					    'type' => 'string',
					    'description' => 'This address will be included as the reply-to address'),
	     'make_default' => VUser::Meta->new('name' => 'make-default',
						'type' => 'boolean',
						'description' => 'Make this the default to send-as'),
	     'enabled' => VUser::Meta->new('name' => 'enabled',
					   'type' => 'boolean',
					   'description' => 'Enable this setting. Use --no-enabled to disable'),
	     'fwd-to' => VUser::Meta->new('name' => 'forward-to',
					  'type' => 'string',
					  'description' => 'Email address to forward to'),
	     'fwd-action' => VUser::Meta->new('name' => 'action',
					      'type' => 'string',
					      'description' => 'What to do with email after forwarding. (KEEP, ARCHIVE, DELETE)')
	     );

our %mail_meta;
our $c_sec = 'Extension Google::Apps';
our %multi_conf;

my $debug;

sub c_sec { return $c_sec; }

sub depends
{
    my $self = shift;
    my $cfg = shift;

    my @depends = ();

    if (check_bool($cfg->{$c_sec}{'use email keyword'})) {
	push @depends, 'Email';
    }

    return @depends;
}

sub init {
    my $eh = shift;
    my %cfg = @_;

    # Use the main vuser log if available
    if (ref $main::log and $main::log->isa('VUser::Log')) {
	$log = $main::log;
    } else {
	$log = VUser::Log->new(\%cfg, 'vuser');
    }

    $debug = $main::DEBUG;

    my $multi_conf_file = strip_ws($cfg{$c_sec}{'multi-domain configuration'});
    if ($multi_conf_file) {
	tie %multi_conf, 'Config::IniFiles', (-file => $multi_conf_file);
	if (@Config::IniFile::errors) {
	    warn "There were errors loading $multi_conf_file\n";
	    foreach my $error (@Config::IniFiles::errors) {
		warn "$error\n";
	    }
	    die "Please correct the errors and try again.\n";
	}
    }

    if (check_bool($cfg{$c_sec}{'use email keyword'})) {
	%mail_meta = VUser::Email::meta();

	$eh->register_task('email', 'add', \&email_add);

	# Add the active attribute
	$eh->register_option('email', 'mod', $meta{'active'});
	$eh->register_task('email', 'mod', \&email_mod);

	$eh->register_task('email', 'del', \&email_del);
	$eh->register_task('email', 'info', \&email_info);
	$eh->register_task('email', 'list', \&email_list);
	$eh->register_task('email', 'suspend', \&email_suspend);
	$eh->register_task('email', 'release', \&email_release);
    }

    # gapps
    $eh->register_keyword('gapps', 'Manage Google Apps for Your Domain');

    ## Users
    
    # gapps-createuser
    $eh->register_action('gapps', 'createuser', 'Add a user');
    $eh->register_option('gapps', 'createuser', $meta{'username'}, 1);
    $eh->register_option('gapps', 'createuser', $meta{'domain'});
    $eh->register_option('gapps', 'createuser', $meta{'password'}, 1);
    $eh->register_option('gapps', 'createuser', $meta{'givenname'}, 1);
    $eh->register_option('gapps', 'createuser', $meta{'familyname'}, 1);
    $eh->register_option('gapps', 'createuser', $meta{'quota'});
    $eh->register_task('gapps', 'createuser', \&gapps_createuser);

    # gapps-retrieveuser
    $eh->register_action('gapps', 'retrieveuser', 'Retrieve a user');
    $eh->register_option('gapps', 'retrieveuser', $meta{'username'}, 1);
    $eh->register_option('gapps', 'retrieveuser', $meta{'domain'});
    $eh->register_task('gapps', 'retrieveuser', \&gapps_retrieveuser);

    # gapps-retrieveallusers
    $eh->register_action('gapps', 'retrieveallusers', 'Retrieve all users for the domain');
    $eh->register_option('gapps', 'retrieveallusers', $meta{'domain'});
    $eh->register_task('gapps', 'retrieveallusers', \&gapps_retrieveallusers);

    # gapps-updateuser
    $eh->register_action('gapps', 'updateuser', 'Modify a user');
    $eh->register_option('gapps', 'updateuser', $meta{'username'}, 1);
    $eh->register_option('gapps', 'updateuser', $meta{'username'}->new('name' => 'new-username'));
    $eh->register_option('gapps', 'updateuser', $meta{'domain'});
    $eh->register_option('gapps', 'updateuser', $meta{'password'});
    $eh->register_option('gapps', 'updateuser', $meta{'givenname'});
    $eh->register_option('gapps', 'updateuser', $meta{'familyname'});
    $eh->register_option('gapps', 'updateuser', $meta{'quota'});
    $eh->register_task('gapps', 'updateuser', \&gapps_updateuser);

    # gapps-deleteuser
    $eh->register_action('gapps', 'deleteuser', 'Delete a user');
    $eh->register_option('gapps', 'deleteuser', $meta{'username'}, 1);
    $eh->register_option('gapps', 'deleteuser', $meta{'domain'});
    $eh->register_task('gapps', 'deleteuser', \&gapps_deleteuser);

    # gapps-suspenduser
    $eh->register_action('gapps', 'suspenduser', 'Suspend a user');
    $eh->register_option('gapps', 'suspenduser', $meta{'username'}, 1);
    $eh->register_option('gapps', 'suspenduser', $meta{'domain'});
    $eh->register_task('gapps', 'suspenduser', \&gapps_suspenduser);

    # gapps-restoreuser
    $eh->register_action('gapps', 'restoreuser', 'Restore a suspended user');
    $eh->register_option('gapps', 'restoreuser', $meta{'username'}, 1);
    $eh->register_option('gapps', 'restoreuser', $meta{'domain'});
    $eh->register_task('gapps', 'restoreuser', \&gapps_restoreuser);

    ## Nicknames

    # gapps->createnick
    $eh->register_action('gapps', 'createnick', 'Create a new nickname');
    $eh->register_option('gapps', 'createnick', $meta{'username'}, 1);
    $eh->register_option('gapps', 'createnick', $meta{'nickname'}, 1);
    $eh->register_option('gapps', 'createnick', $meta{'domain'});
    $eh->register_task('gapps', 'createnick', \&gapps_createnick);

    # gapps-retrievenick
    $eh->register_action('gapps', 'retrievenick', 'Retrieve a nickname');
    $eh->register_option('gapps', 'retrievenick', $meta{'nickname'}, 1);
    $eh->register_option('gapps', 'retrievenick', $meta{'domain'});
    $eh->register_task('gapps', 'retrievenick', \&gapps_retrievenick);

    # gapps-retrievenicks
    $eh->register_action('gapps', 'retrievenicks', 'Retrieve all nicknames for a user');
    $eh->register_option('gapps', 'retrievenicks', $meta{'username'}, 1);
    $eh->register_option('gapps', 'retrievenicks', $meta{'domain'});
    $eh->register_task('gapps', 'retrievenicks', \&gapps_retrievenicks);

    # gapps-retrieveallnicks
    $eh->register_action('gapps', 'retrieveallnicks', 'Retrieve all nicknames in the domain');
    $eh->register_option('gapps', 'retrieveallnicks', $meta{'domain'});
    $eh->register_task('gapps', 'retrieveallnicks', \&gapps_retrieveallnicks);

    # gapps->deletenick
    $eh->register_action('gapps', 'deletenick', 'Delete a nickname');
    $eh->register_option('gapps', 'deletenick', $meta{'nickname'}, 1);
    $eh->register_option('gapps', 'deletenick', $meta{'domain'});
    $eh->register_task('gapps', 'deletenick', \&gapps_deletenick);

    ## Email lists

    # gapps-createlist
    $eh->register_action('gapps', 'createlist', 'Create a new list');
    $eh->register_option('gapps', 'createlist', $meta{'list'}, 1);
    $eh->register_option('gapps', 'createlist', $meta{'domain'});
    $eh->register_task('gapps', 'createlist', \&gapps_createlist);

    # gapps-retrievelist
    $eh->register_action('gapps', 'retrievelist', 'Retrieve a list');
    $eh->register_option('gapps', 'retrievelist', $meta{'list'}, 1);
    $eh->register_option('gapps', 'retrievelist', $meta{'domain'});
    $eh->register_task('gapps', 'retrievelist', \&gapps_retrievelist);

    # gapps-retrievealllists
    $eh->register_action('gapps', 'retrievealllists', 'Retrieve all lists for the domain');
    $eh->register_option('gapps', 'retrievealllists', $meta{'domain'});
    $eh->register_task('gapps', 'retrievealllists', \&gapps_retrievealllists);

    # gapps-deletelist
    $eh->register_action('gapps', 'deletelist', 'Delete a list');
    $eh->register_option('gapps', 'deletelist', $meta{'list'}, 1);
    $eh->register_option('gapps', 'deletelist', $meta{'domain'});
    $eh->register_task('gapps', 'deletelist', \&gapps_deletelist);

    ## List subscriptions

    # gapps-addlistsub
    $eh->register_action('gapps', 'addlistsub', 'Add a subscriber to a list');
    $eh->register_option('gapps', 'addlistsub', $meta{'list'}, 1);
    $eh->register_option('gapps', 'addlistsub', $meta{'email'}, 1);
    $eh->register_option('gapps', 'addlistsub', $meta{'domain'});
    $eh->register_task('gapps', 'addlistsub', \&gapps_addlistsub);

    # gapps-retrievesubs
    $eh->register_action('gapps', 'retrievesubs', 'Retrieve list subscriptions for a user');
    $eh->register_option('gapps', 'retrievesubs', $meta{'username'}, 1);
    $eh->register_option('gapps', 'retrievesubs', $meta{'domain'});
    $eh->register_task('gapps', 'retrievesubs', \&gapps_retrievesubs);

    # gapps-retrievelistsubs
    $eh->register_action('gapps', 'retrievelistsubs', 'Retrieve all subscribers to a list');
    $eh->register_option('gapps', 'retrievelistsubs', $meta{'list'}, 1);
    $eh->register_option('gapps', 'retrievelistsubs', $meta{'domain'});
    $eh->register_task('gapps', 'retrievelistsubs', \&gapps_retrievelistsubs);

    # gapps-removelistsub
    $eh->register_action('gapps', 'removelistsub', 'Remove a subscriber from a list');
    $eh->register_option('gapps', 'removelistsub', $meta{'list'}, 1);
    $eh->register_option('gapps', 'removelistsub', $meta{'email'}, 1);
    $eh->register_option('gapps', 'removelistsub', $meta{'domain'});
    $eh->register_task('gapps', 'removelistsub', \&gapps_removelistsub);

    # gapps create-label
    $eh->register_action('gapps', 'create-label', 'Create a label');
    $eh->register_option('gapps', 'create-label', $meta{'username'}, 1);
    $eh->register_option('gapps', 'create-label', $meta{'domain'});
    $eh->register_option('gapps', 'create-label', $meta{'label'}, 1);
    $eh->register_task('gapps', 'create-label', \&gapps_create_label);

    # gapps create-filter
    $eh->register_action('gapps', 'create-filter', 'Create a filter');
    $eh->register_option('gapps', 'create-filter', $meta{'username'}, 1);
    $eh->register_option('gapps', 'create-filter', $meta{'domain'});
    # criteria
    $eh->register_option('gapps', 'create-filter', $meta{'crit-from'});
    $eh->register_option('gapps', 'create-filter', $meta{'crit-to'});
    $eh->register_option('gapps', 'create-filter', $meta{'crit-subject'});
    $eh->register_option('gapps', 'create-filter', $meta{'has-the-word'});
    $eh->register_option('gapps', 'create-filter', $meta{'does-not-have-the-word'});
    $eh->register_option('gapps', 'create-filter', $meta{'has-attachment'});
    # actions
    $eh->register_option('gapps', 'create-filter', $meta{'should-mark-as-read'});
    $eh->register_option('gapps', 'create-filter', $meta{'should-archive'});
    $eh->register_option('gapps', 'create-filter', $meta{'label'});
    $eh->register_task('gapps', 'create-filter', \&gapps_create_filter);

    # gapps create-sendas
    $eh->register_action('gapps', 'create-sendas', "Create send-as alias");
    $eh->register_option('gapps', 'create-sendas', $meta{'username'}, 'req');
    $eh->register_option('gapps', 'create-sendas', $meta{'domain'});
    $eh->register_option('gapps', 'create-sendas', $meta{'from-name'}, 'req');
    $eh->register_option('gapps', 'create-sendas', $meta{'address'}, 'req');
    $eh->register_option('gapps', 'create-sendas', $meta{'reply_to'});
    $eh->register_option('gapps', 'create-sendas', $meta{'make_default'});
    $eh->register_task('gapps', 'create-sendas', \&gapps_create_sendas);

    # gapps update-webclip
    $eh->register_action('gapps', 'update-webclip', "Update WebClip");
    $eh->register_option('gapps', 'update-webclip', $meta{'username'}, 'req');
    $eh->register_option('gapps', 'update-webclip', $meta{'domain'});
    $eh->register_option('gapps', 'update-webclip', $meta{'enabled'}, "req");
    $eh->register_task('gapps', 'update-webclip', \&gapps_update_webclip);

    # gapps update-forwarding
    $eh->register_action('gapps', 'update-forwarding', "Update fowarding");
    $eh->register_option('gapps', 'update-forwarding', $meta{'username'}, 'req');
    $eh->register_option('gapps', 'update-forwarding', $meta{'domain'});
    $eh->register_option('gapps', 'update-forwarding', $meta{'enabled'}, 'req');
    $eh->register_option('gapps', 'update-forwarding', $meta{'fwd-to'});
    $eh->register_option('gapps', 'update-forwarding', $meta{'fwd-action'});
    $eh->register_task('gapps', 'update-forwarding', \&gapps_update_forwarding);

}

## Email actions

sub email_add {
    my ($cfg, $opts, $action, $eh) = @_;

    # Split off domain
    my ($user, $domain);
    VUser::Email::split_address($cfg, $opts->{'account'}, \$user, \$domain);

    # Try to guess given and family names.
    my ($givenname, $familyname) = split (/ /, $opts->{'name'});
    $givenname = 'User' if (not $givenname);
    $familyname = $user if not $familyname;

    my %gopts = ('username' => $user,
		 'domain' => $domain,
		 'given-name' => $givenname,
		 'family-name' => $familyname,
		 'password' => $opts->{'password'}
		 );
    $gopts{'quota'} = $opts->{'quota'} if $opts->{'quota'};

    # Now run the Google Apps tasks
    $eh->run_tasks('gapps', 'createuser', $cfg, %gopts);

    return undef;
}

sub email_mod {
    my ($cfg, $opts, $action, $eh) = @_;


    # Split off domain
    my ($user, $domain);
    VUser::Email::split_address($cfg, $opts->{'account'}, \$user, \$domain);

    my %gopts = ('username' => $user,
		 'domain' => $domain);
    if ($opts->{'newaccount'}
	and $opts->{'newaccount'} ne $opts->{'account'}) {
	$gopts{'new-username'} = $opts->{'newaccount'};
    }

    # Try to guess given and family names.
    if ($opts->{'name'}) {
	my ($givenname, $familyname) = split (/ /, $opts->{'name'});
	$givenname = 'User' if (not $givenname);
	$familyname = $user if not $familyname;

	$gopts{'given-name'} = $givenname;
	$gopts{'family-name'} = $familyname;
    }
    $gopts{'password'} = $opts->{'password'} if $opts->{'password'};
    $gopts{'quota'} = $opts->{'quota'} if $opts->{'quota'};

    # Now run the Google Apps tasks
    $eh->run_tasks('gapps', 'updateuser', $cfg, %gopts);

    $log->log(LOG_DEBUG, "Active? ".$opts->{'active'});
    if (defined $opts->{'active'}) {
	if ($opts->{'active'}) {
	    $eh->run_tasks('gapps', 'restoreuser', $cfg, %gopts);
	} else {
	    $eh->run_tasks('gapps', 'suspenduser', $cfg, %gopts);
	}
    }

    return undef;
}

sub email_del {
    my ($cfg, $opts, $action, $eh) = @_;

    # Split off domain
    my ($user, $domain);
    VUser::Email::split_address($cfg, $opts->{'account'}, \$user, \$domain);

    # Try to guess given and family names.
    my ($givenname, $familyname) = split (/ /, $opts->{'name'});
    $givenname = 'User' if (not $givenname);
    $familyname = $user if not $familyname;

    my %gopts = ('username' => $user,
		 'domain' => $domain,
		 );
    $gopts{'quota'} = $opts->{'quota'} if $opts->{'quota'};

    # Now run the Google Apps tasks
    $eh->run_tasks('gapps', 'deleteuser', $cfg, %gopts);

    return undef;
}

sub email_suspend {
    my ($cfg, $opts, $action, $eh) = @_;

    # Split off domain
    my ($user, $domain);
    VUser::Email::split_address($cfg, $opts->{'account'}, \$user, \$domain);

    # Try to guess given and family names.
    my ($givenname, $familyname) = split (/ /, $opts->{'name'});
    $givenname = 'User' if (not $givenname);
    $familyname = $user if not $familyname;

    my %gopts = ('username' => $user,
		 'domain' => $domain,
		 );
    $gopts{'quota'} = $opts->{'quota'} if $opts->{'quota'};

    # Now run the Google Apps tasks
    $eh->run_tasks('gapps', 'suspenduser', $cfg, %gopts);

    return undef;
}

sub email_release {
    my ($cfg, $opts, $action, $eh) = @_;

    # Split off domain
    my ($user, $domain);
    VUser::Email::split_address($cfg, $opts->{'account'}, \$user, \$domain);

    # Try to guess given and family names.
    my ($givenname, $familyname) = split (/ /, $opts->{'name'});
    $givenname = 'User' if (not $givenname);
    $familyname = $user if not $familyname;

    my %gopts = ('username' => $user,
		 'domain' => $domain,
		 );
    $gopts{'quota'} = $opts->{'quota'} if $opts->{'quota'};

    # Now run the Google Apps tasks
    $eh->run_tasks('gapps', 'restoreuser', $cfg, %gopts);

    return undef;
}

sub email_info {
    my ($cfg, $opts, $action, $eh) = @_;

    # Split off domain
    my ($user, $domain);
    VUser::Email::split_address($cfg, $opts->{'account'}, \$user, \$domain);

    # Talk directly to google API or use run_tasks()?
    # Use API. It's simpler.
    $domain = get_domain($cfg, $opts) unless $domain;
    my $google = google_login($domain, $cfg);

    my $entry = $google->RetrieveUser($user);

    if ($entry) {
	my $rs = VUser::ResultSet->new();
	$rs->add_meta($mail_meta{'account'});
	$rs->add_meta($mail_meta{'name'});
	$rs->add_meta($mail_meta{'quota'});
	$rs->add_meta($meta{'active'});

	my $data = [$entry->User.'@'.$domain,
		    $entry->GivenName.' '.$entry->FamilyName,
		    $entry->Quota,
		    $entry->isSuspended? '0' : '1'];
	$rs->add_data($data);
	return $rs;
    } else {
	my $msg = "Unable to get user info: ".$google->{result}{reason};
	$log->log(LOG_ERROR, $msg);
	die "$msg\n";
    }

    return undef;
}

sub email_list {
    my ($cfg, $opts, $action, $eh) = @_;

    my $domain = get_domain($cfg, $opts);
    my $google = google_login($domain, $cfg);

    my @users = $google->RetrieveAllUsers();
    if (@users and defined $users[0]) {
	my $rs = VUser::ResultSet->new();
	$rs->add_meta($mail_meta{'account'});
	$rs->add_meta($mail_meta{'name'});
	$rs->add_meta($mail_meta{'quota'});
	$rs->add_meta($meta{'active'});

	foreach my $user (@users) {
	    my $data = [$user->User,
			$user->GivenName.' '.$user->FamilyName,
			$user->Quota,
			$user->isSuspended? '0' : '1'];
	    $rs->add_data($data);
	}
	return $rs;
    }
}

## Google Apps User actions

sub gapps_createuser {
    my ($cfg, $opts, $action, $eh) = @_;

    my $domain = get_domain($cfg, $opts);
    my $google = google_login($domain, $cfg);

    my @args = ($opts->{'username'},
		$opts->{'given-name'},
		$opts->{'family-name'},
		$opts->{'password'});
    push @args, $opts->{'quota'} if defined $opts->{'quota'};

    my $entry = $google->CreateUser(@args);
    if (not defined $entry) {
	my $msg = "Unable to create user: ".$google->{result}{reason};
	$log->log(LOG_ERROR, $msg);
	die "$msg\n";
    }

    return undef;
}

sub gapps_retrieveuser {
    my ($cfg, $opts, $action, $eh) = @_;

    my $domain = get_domain($cfg, $opts);
    my $google = google_login($domain, $cfg);

    my $entry = $google->RetrieveUser($opts->{username});

    if ($entry) {
	my $rs = VUser::ResultSet->new();
	$rs->add_meta($meta{'username'});
	$rs->add_meta($meta{'familyname'});
	$rs->add_meta($meta{'givenname'});
	$rs->add_meta($meta{'quota'});
	$rs->add_meta($meta{'suspended'});

	my $data = [$entry->User,
		    $entry->FamilyName,
		    $entry->GivenName,
		    $entry->Quota,
		    $entry->isSuspended];
	$rs->add_data($data);
	return $rs;
    } else {
	my $msg = "Unable to get user info: ".$google->{result}{reason};
	$log->log(LOG_ERROR, $msg);
	die "$msg\n";
    }

    return undef;
}

sub gapps_retrieveallusers {
    my ($cfg, $opts, $action, $eh) = @_;

    my $domain = get_domain($cfg, $opts);
    my $google = google_login($domain, $cfg);

    my @users = $google->RetrieveAllUsers();
    if (@users and defined $users[0]) {
	my $rs = VUser::ResultSet->new();
	$rs->add_meta($meta{'username'});
	$rs->add_meta($meta{'familyname'});
	$rs->add_meta($meta{'givenname'});
	$rs->add_meta($meta{'quota'});
	$rs->add_meta($meta{'suspended'});

	foreach my $user (@users) {
	    my $data = [$user->User,
			$user->FamilyName,
			$user->GivenName,
			$user->Quota,
			$user->isSuspended];
	    $rs->add_data($data);
	}
	return $rs;
    } else {
	$log->log(LOG_INFO, $google->{result}{reason});
    }
}

sub gapps_updateuser {
    my ($cfg, $opts, $action, $eh) = @_;

    my $domain = get_domain($cfg, $opts);
    my $google = google_login($domain, $cfg);

    my $updates = VUser::Google::ProvisioningAPI::V2_0::UserEntry->new();
    $updates->User($opts->{'new-username'}) if $opts->{'new-username'};
    $updates->Password($opts->{'password'}) if $opts->{'password'};
    $updates->GivenName($opts->{'given-name'}) if $opts->{'given-name'};
    $updates->FamilyName($opts->{'family-name'}) if $opts->{'family-name'};
    $updates->Quota($opts->{'quota'}) if $opts->{'quota'};

    my $user = $google->UpdateUser($opts->{'username'}, $updates);
    if (not defined ($user)) {
	my $msg = "Unable to update user: ".$google->{result}{reason};
	$log->log(LOG_ERROR, $msg);
	die "$msg\n";
    }

    return undef;
}

sub gapps_deleteuser {
    my ($cfg, $opts, $action, $eh) = @_;

    my $domain = get_domain($cfg, $opts);
    my $google = google_login($domain, $cfg);

    my $res = $google->DeleteUser($opts->{'username'});
    if (not $res) {
	my $msg = "Unable to delete user: ".$google->{result}{reason};
	$log->log(LOG_ERROR, $msg);
	die "$msg\n";
    }

    return undef;
}

sub gapps_suspenduser {
    my ($cfg, $opts, $action, $eh) = @_;

    my $domain = get_domain($cfg, $opts);
    my $google = google_login($domain, $cfg);

    my $user = $google->SuspendUser($opts->{'username'});
    if (not defined $user) {
	my $msg = "Unable to suspend user: ".$google->{result}{reason};
	$log->log(LOG_ERROR, $msg);
	die "$msg\n";
    }

    return $user;
}

sub gapps_restoreuser {
    my ($cfg, $opts, $action, $eh) = @_;

    my $domain = get_domain($cfg, $opts);
    my $google = google_login($domain, $cfg);

    my $user = $google->RestoreUser($opts->{'username'});
    if (not defined $user) {
	my $msg = "Unable to restore user: ".$google->{result}{reason};
	$log->log(LOG_ERROR, $msg);
	die "$msg\n";
    }

    return $user;
}

## Google Apps Nickname actions

sub gapps_createnick {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub gapps_retrievenick {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub gapps_retrievenicks {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub gapps_retrieveallnicks {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub gapps_deletenick {
    my ($cfg, $opts, $action, $eh) = @_;
}

## Google Apps Email list actions

sub gapps_createlist {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub gapps_retrievelist {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub gapps_retrievealllists {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub gapps_deletelist {
    my ($cfg, $opts, $action, $eh) = @_;
}

## Google Apps Email list subscription actions

sub gapps_retrievelistsubs {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub gapps_retrievesubs {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub gapps_retrievelistsubss {
    my ($cfg, $opts, $action, $eh) = @_;
}

sub gapps_removelistsub {
    my ($cfg, $opts, $action, $eh) = @_;
}

## Email settings
sub gapps_create_label {
    my ($cfg, $opts, $action, $eh) = @_;

    my $domain = get_domain($cfg, $opts);

    my $settings = VUser::Google::EmailSettings::V2_0->new
	(user => $opts->{username},
	 google => google_login2($cfg, $domain)
	 );
    $settings->debug(1) if $debug;

    $settings->CreateLabel($opts->{label});

    return undef;
}

sub gapps_create_filter {
    my ($cfg, $opts, $action, $eh) = @_;

    my $domain = get_domain($cfg, $opts);

    ## Validate criteria
    if (not $opts->{'from'}
	and not $opts->{'to'}
	and not $opts->{'subject'}
	and not $opts->{'has-the-word'}
	and not $opts->{'does-not-have-the-word'}
	and not $opts->{'has-attachment'})
    {
	die "No filter criteria specified.";
    }

    my %criteria = (from               => $opts->{'from'},
		    to                 => $opts->{'to'},
		    subject            => $opts->{'subject'},
		    hasTheWord         => $opts->{'has-the-word'},
		    doesNotHaveTheWord => $opts->{'does-not-have-the-word'},
		    hasAttachment      => $opts->{'has-attachment'}
		    );

    ## Validate actions
    if (not defined $opts->{'should-mark-as-read'}
	and not defined $opts->{'should-archive'}
	and not $opts->{'label'})
    {
	die "No filter action specified.";
    }

    my %actions = (shouldMarkAsRead => $opts->{'should-mark-as-read'},
		   shouldArchive    => $opts->{'should-archive'},
		   label            => $opts->{'label'}
		   );

    my $settings = VUser::Google::EmailSettings::V2_0->new
	(user => $opts->{username},
	 google => google_login2($cfg, $domain)
	 );
    $settings->debug(1) if $debug;

    $settings->CreateFilter(\%criteria, \%actions);

    return undef;
}

sub gapps_create_sendas {
    my ($cfg, $opts, $action, $eh) = @_;

    my $domain = get_domain($cfg, $opts);

    my $settings = VUser::Google::EmailSettings::V2_0->new
	(user => $opts->{username},
	 google => google_login2($cfg, $domain)
	 );

    $settings->debug(1) if $debug;

    $settings->CreateSendAsAlias($opts->{'from-name'},
				 $opts->{'address'},
				 $opts->{'reply-to'},
				 $opts->{'make-default'});

    return undef;
}

sub gapps_update_webclip {
    my ($cfg, $opts, $action, $eh) = @_;

    my $domain = get_domain($cfg, $opts);

    my $settings = VUser::Google::EmailSettings::V2_0->new
	(user => $opts->{username},
	 google => google_login2($cfg, $domain)
	 );

    $settings->debug(1) if $debug;

    $settings->UpdateWebClip($opts->{'enabled'});

    return undef;
}

sub gapps_update_forwarding {
    my ($cfg, $opts, $action, $eh) = @_;

    my $domain = get_domain($cfg, $opts);

    my $settings = VUser::Google::EmailSettings::V2_0->new
	(user => $opts->{username},
	 google => google_login2($cfg, $domain)
	 );

    $settings->debug(1) if $debug;

    $settings->UpdateForwarding($opts->{'enabled'},
				$opts->{'forward-to'},
				$opts->{'action'}
				);

    return undef;
}

## Util functions

sub get_domain {
    my $cfg = shift;
    my $opts = shift;

    my $domain = strip_ws($cfg->{$c_sec}{'default domain'});
    $domain = $opts->{'domain'} if defined $opts->{'domain'};

    if (not defined $domain or $domain =~ /^\s*$/) {
	$log->log(LOG_ERROR, "No domain specified");
	die "No domain specified. Please use --domain or set 'default domain'\n";
    }

    return $domain
}

# This is possibly misnamed since it doesn't actually login. The class
# methods do that as needed. Oh, well.
sub google_login {
    my $domain = shift;
    my $cfg = shift;

    my $admin_user;
    my $password;

    my $default_domain = strip_ws($cfg->{$c_sec}{'default domain'});

    # The default domain is special because the admin credentials can be
    # in the main config file.
    if ($default_domain and $domain eq $default_domain) {
	$admin_user = strip_ws($cfg->{$c_sec}{'domain admin'});
	$password = strip_ws ($cfg->{$c_sec}{'admin password'});
    }

    # Now check the multi-domain config
    $admin_user = strip_ws($multi_conf{$domain}{'domain admin'}) unless defined $admin_user;
    $password = strip_ws($multi_conf{$domain}{'admin password'}) unless defined $password;

    die "No admin user set for $domain.\n" unless $admin_user;
    die "No password set for $domain.\n" unless $password;

    $log->log(LOG_DEBUG, "Logging in to G.Apps as $admin_user\@$domain");

    # Now's the time on our show when we log into Google.
    my $google = VUser::Google::ProvisioningAPI->new($domain,
					      $admin_user,
					      $password,
					      '2.0');
    return $google;
}

## Login function for new google framework.
# TODO: make google protocol version configurable.
sub google_login2 {
    my $cfg = shift;
    my $domain = shift;

    my $admin_user;
    my $password;

    my $default_domain = strip_ws($cfg->{$c_sec}{'default domain'});
    if ($default_domain and $domain eq $default_domain) {
	$admin_user = strip_ws($cfg->{$c_sec}{'domain admin'});
	$password = strip_ws ($cfg->{$c_sec}{'admin password'});
    }

    # Now check the multi-domain config
    $admin_user = strip_ws($multi_conf{$domain}{'domain admin'}) unless defined $admin_user;
    $password = strip_ws($multi_conf{$domain}{'admin password'}) unless defined $password;

    die "No admin user set for $domain.\n" unless $admin_user;
    die "No password set for $domain.\n" unless $password;

    $log->log(LOG_DEBUG, "Logging in to G.Apps as $admin_user\@$domain");

    ## Login to google.
    my $google = VUser::Google::ApiProtocol::V2_0->new
	(domain => $domain,
	 admin => $admin_user,
	 password => $password
	 );
    $google->debug(1) if $debug;
    return $google;
}

sub DESTROY {};

1;

__END__

=head1 NAME

VUser::Google::Apps - VUser extension for managing Google Apps for your domain

=head1 DESCRIPTION

VUser::Google::Apps integrates Google Apps for your Domain in vuser for
simple integration with other systems.

Currently on version 2.0 of the Google Apps API is supported.

=head1 SAMPLE CONFIGURATION

 [vuser]
 extensions = Google::Apps
 
 [Extension Google::Apps]
 # Connect Google::Apps to the email keyword and actions.
 # This allows you to use the standard vuser email keyword actions
 # to manage accounts. This requires that VUser::Email be installed.
 use email keyword = yes
 
 # The default domain. If this is not set, you must use the --domain
 # option when running vuser.
 default domain = example.com
 
 # The name of the user that vuser will use to manage your domain.
 # The is user must have administration priviledges.
 #
 # You should not need set 'domain admin' or 'admin password', below,
 # if you are using the 'multi-domain configuration' file below. 
 domain admin = vuser
 
 # The admin user's (above) password
 admin password = supersecret
 
 # You can use vuser to manage multiple Google Apps domains by uncommenting
 # the 'multi-domain configuration' option. The file is an INI file (just
 # like this one). Domain names are section headings and must have the
 # options 'domain admin' and 'admin password' set. For example:
 #
 # [domain1.com]
 # domain admin = admin
 # admin password = password
 #
 # [domain2.com]
 # domain admin = vuser
 # admin password = password
 #
 # multi-domain configuration = /etc/vuser/google-apps.ini

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE

 This file is part of VUser-Google-Apps.
 
 VUser-Google-Apps is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 VUser-Google-Apps is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with VUser-Google-Apps; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut

