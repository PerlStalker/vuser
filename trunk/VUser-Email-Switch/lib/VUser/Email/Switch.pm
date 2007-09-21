package VUser::Email::Switch;
use warnings;
use strict;

# Copyright 2007 Randy Smith <perlstalker@vuser.org>
# $Id: Switch.pm,v 1.1 2007-09-21 15:28:35 perlstalker Exp $

our $VERSION='0.1.0';

use VUser::Log qw(:levels);
use VUser::ExtLib qw(:config);
use VUser::ExtHandler;

# Maps to EventHandlers for each defined system
my %systems = ();

# Domain => system map.
# Keys are domains; systems are the names of the system
my %domains = ();

my $lcfg;                              # local config file
my $log;                               # VUser::Log
my $c_sec = 'Extension Email::Switch'; # vuser.conf section name

sub depends { qw(Email); }

sub unload {
    foreach my $system (keys %systems) {
	eval { $systems{$system}{eh}->cleanup(%{$systems{$system}->{cfg}}) };
    }
}

sub init {
    my $eh = shift;
    my %cfg = @_;

    if (defined $main::log) {
        $log = $main::log;
    } else {
        $log = VUser::Log->new(\%cfg, 'vuser')
    }

    my $config = strip_ws($cfg{$c_sec}{'configuration'});
    if (not $config) {
	# configuration was not set, use main config
	$lcfg = \%cfg;
	$log->log(LOG_WARN, "Email::Switch|configuration not set. Using vuser.conf");
    } else {
	my %lcfg;
	tie %lcfg, 'Config::IniFiles', (-file => $config);
	$lcfg = \%lcfg; # Switch to reference for consitancy

	if (@Config::IniFiles::errors) {
	    $log->log(LOG_ERR, "There were errors loading $config");
	    foreach my $error (@Config::IniFiles::errors) {
		$log->log(LOG_ERR, "$error");
	    }
	    die "There were errors loading $config. See log for details.\n";
	}
    }

    ## Assuming we get here, we can start loading the Systems.
    foreach my $section (keys %{$lcfg}) {
	if ($section =~ /^(System\s+(\w+))$/i) {
	    my $sec = $1; # Get the section name, we'll need it later
	    my $sysname = $2;
	    $systems{$sysname} = {'cfg' => undef, 'eh' => undef};

	    ## Load the system config file
	    my $sysconfig = strip_ws($lcfg->{$sec}{configuration});
	    if ($sysconfig) {
		$log->log(LOG_DEBUG, "Reading $sysconfig for $sysname");
		my %scfg;
		tie %scfg, 'Config::IniFiles', (-file => $sysconfig);
		$systems{$sysname}{'cfg'} = \%scfg;

		if (@Config::IniFiles::errors) {
		    $log->log(LOG_ERR, "There were errors loading $sysconfig");
		    foreach my $error (@Config::IniFiles::errors) {
			$log->log(LOG_ERR, "$error");
		    }
		    die "There were errors loading $sysconfig. See log for details.\n";
	}
	    } else {
		$log->log(LOG_WARN, "No configuration defined for system $sysname. Using default.");
	    }

	    ## Now create the new ExtHandler for this system
	    my $exts = strip_ws($lcfg->{$sec}{'extensions'});
	    $exts = '' unless defined $exts;
	    my @exts = split (/ /, $exts);
	    $systems{$sysname}{'eh'} = VUser::ExtHandler->new($systems{$sysname}{'cfg'});
	    $systems{$sysname}{'eh'}->load_extensions_list($systems{$sysname}{'cfg'}, @exts);

	    ## Create the domain => system map for this system
	    my $doms = strip_ws($lcfg->{$sec}{'domains'});
	    if (defined $doms) {
		my @doms = split(/ /, $doms);
		foreach my $dom (@doms) {
		    next if $dom eq '*'; # Quietly skip our magical wildcard
		    if (defined $domains{$dom}) {
			$log->log(LOG_WARN, "Domain $dom defined more than once. Skipping.");
		    } else {
			$domains{$dom} = $sysname;
		    }
		}
	    }

	    $log->log(LOG_DEBUG, "%s is Default: %s", $sysname,
		      $lcfg->{$sec}{'default'});
	    if (not defined $domains{'*'}
		and check_bool($lcfg->{$sec}{'default'})) {
		$domains{'*'} = $sysname;
	    }
	}
    }

    ## All systems go. Let's register the email handlers.
    $eh->register_task('email', 'add', \&email_switch);
    $eh->register_task('email', 'mod', \&email_switch);
    $eh->register_task('email', 'del', \&email_switch);
    $eh->register_task('email', 'info', \&email_switch);
    $eh->register_task('email', 'list', \&email_switch);

    $eh->register_task('domain', 'add', \&domain_switch);
    $eh->register_task('domain', 'mod', \&domain_switch);
    $eh->register_task('domain', 'del', \&domain_switch);
    $eh->register_task('domain', 'info', \&domain_switch);
    $eh->register_task('domain', 'list', \&domain_switch);
}

sub email_switch {
    my ($cfg, $opts, $action, $eh) = @_;

    my ($user, $domain);
    VUser::Email::split_address($cfg, $opts->{'account'}, \$user, \$domain);

    my $real_dom;

    if (defined $domains{$domain}) {
	$real_dom = $domain;
    } elsif (defined $domains{'*'}) {
	$real_dom = '*';
    }

    if (defined $real_dom) {
	my $rs = $systems{$domains{$real_dom}}{'eh'}->run_tasks('email',
								$action,
								$systems{$domains{$real_dom}}{'cfg'},
								%$opts);
	#use Data::Dumper; print Dumper $rs;
	return $rs;
    } else {
	$log->log(LOG_WARN, "Unmanaged domain: $domain.");
    }
}

sub domain_switch {
    my ($cfg, $opts, $action, $eh) = @_;

    my $domain = $opts->{'domain'};
    my $real_dom;

    if (defined $domains{$domain}) {
	$real_dom = $domain;
    } elsif (defined $domains{'*'}) {
	$real_dom = '*';
    }

    if (defined $real_dom) {
	return $systems{$domains{$real_dom}}{'eh'}->run_tasks('domain',
							      $action,
							      $systems{$domains{$real_dom}}{'cfg'},
							      %$opts);
    } else {
	$log->log(LOG_WARN, "Unmanaged domain: $domain.");
    }
}

1;

__END__

=head1 NAME

VUser::Email::Switch - Allow the vuser to use different email extensions depending on the domain.

=head1 DESCRIPTION

VUser::Email::Switch is an extention to vuser that allows vuser to use
different email extensions depending on the domain. This is primarily
designed to assist with email migrations but can be used when domains are
hosted on different mail systems. For example, a shared mail server for
residential users some groupware platform for business domains.

There are drawbacks to using this extension. The first is that additional
options cannot be used. This is especially problematic if those options are
required. The second issue is that Email::Switch will load an entirely new
VUser::ExtHandler for each system increasing the amount of memory that vuser
uses.

=head1 SAMPLE CONFIGURATION

F<vuser.conf>

 [vuser]
 extensions = Email::Switch

 [Extension Email::Switch]
 # Path to the Email-Switch config file.
 # Defaults to the main vuser config if not defined.
 configuration = /etc/vuser/email-switch.conf

F<email-switch.conf>

 # The System names are not important but may only contain a-z,A-Z,0-9,_
 [System system1]
 # Space seperated list of extensions.
 extensions = Google::Apps
 # The configuration file contains the extension configuration. This will
 # Be the same as the options that would normally go in vuser.conf.
 # If the configuration is not set, this file will be used.
 configuration = /path/to/system1-config
 
 # whitespace seperated list of domains that use this system
 domains = example1.com example2.com
 
 # Is this the default system to use if the domain is not in one of the
 # domain lists. If no default is set, then domains that are not in one of
 # the system domain lists will be ignored.
 default = no
 
 [System system2]
 extensions = Email::Postfix::SQL Email::Local::Extention

=head1 AUTHORS

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE

 This file is part of VUser-Email-Switch.
 
 VUser-Email-Switch is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 VUser-Email-Switch is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with VUser-Email-Switch; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
