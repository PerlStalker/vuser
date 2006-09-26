package VUser::SOAP;
use warnings;
use strict;

# Copyright (c) 2006 Randy Smith
# $Id: SOAP.pm,v 1.2 2006-09-26 21:44:28 perlstalker Exp $

use VUser::Log qw(:levels);
use VUser::ExtHandler;
use VUser::ACL;
use Digest::MD5 qw(md5);
my $eh;
my $log;
my $cfg;
my $acl;
my $debug = 0;

my $c_sec = 'vsoapd';

sub init {
    $cfg = shift;
    
    $eh = VUser::ExtHandler->new($cfg);
    
    if (ref $main::log and UNIVERSAL::isa($main::log, 'VUser::Log')) {
        $log = $main::log;
    } else {
        $log = VUser::Log->new($cfg, 'VUser::SOAP');
    }
    
    if (defined $main::debug) {
        $debug = $main::debug;
    }
    
    ## Load up the ACL and auth info
    $acl = new VUser::ACL ($cfg);
    $acl->load_auth_modules($cfg);
    $acl->load_acl_modules($cfg);
    
    return;
}

sub login {
    my $user = shift;
    my $password = shift;
    my $ip = shift;
    
    if (check_bool($cfg->{$c_sec}{'require_authentication'})) {
        if (not $acl->auth_user($cfg, $user, $password, $ip)) {
            if ($debug) {
                $log->log(LOG_NOTICE, "Authentication failed for $user\@$ip [$password]");
            } else {
                $log->log(LOG_NOTICE, "Authentication failed for $user\@$ip");
            }
        }
    }
    
    my ($ticket, $expr);
    
    my $timeout = strip_ws($cfg->{$c_sec}{'ticket lifetime'});
    # Default to 10 minutes if timeout is not a valid number 
    $timeout = 10 unless defined $timeout and $timeout =~ /^\d+(?:\.\d+)$/;
    
    $expr = time() + 60 * $timeout;
    $ticket = calculate_ticket($user, $ip, $expr);
    return { user => $user, ip => $ip, ticket => $ticket, expires => $expr };  
}

sub check_ticket {
    my $authinfo = shift;
    
    if (time() > $authinfo->{expires}) {
        # Ticket has expired
        return 0;
    }
    
    if (calculate_ticket($authinfo->{user}, $authinfo->{ip}, $authinfo->{expires})
        ne $authinfo->{ticket})
    {
        # Bad creds or invalid ticket
        $log->log(LOG_NOTICE, "Invalid ticket for %s\@%s", $authinfo->{user}, $authinfo->{ip});
        return 0;
    }
    
    return 1;
}

sub calculate_ticket {
    return md5(join '', $cfg->{$c_sec}{'digest key'}, @_);
}

sub run_tasks {
    my $user = shift;
    my $ip = shift;
    my $keyword = shift;
    my $action = shift;
    my @params = shift;
    
    # We need to translate the SOAP::Data params into a hash
    # suitable for ::ExtHandler->run_tasks.
    my %opts = build_opts(@params);
    
    if (check_bool($cfg->{$c_sec}{'require authentication'})) {
        # Do all of the ACL checks.
        eval {check_acls($cfg, $user, $ip, $keyword, $action, \%opts) };
        # FAULT if a check fails
        # VUser::ACL logs the reason so we don't need to log it here.
        die SOAP::Failt
            ->faultcode('Server.Custom')
            ->faultstring('Permission denied') if $@;
    }
    
    # We've passed all of the ACL checks. Run the task.
    my $rs = [];
    $log->log(LOG_NOTICE, "$user\@$ip running $keyword | $action");
    eval { $rs = $eh->run_tasks($keyword, $action, $cfg, %opts); };
    if ($@) {
	   die SOAP::Fault
	       ->faultcode('Server.Custom')
	       ->faultstring($@)
	       ;
    }

    return $rs;
};

sub check_acls {
    my $user = shift;
    my $ip = shift;
    my $keyword = shift;
    my $action = shift;
    my $opts = shift;

    # Check ACLs
    if (not $acl->check_acls($cfg, $user, $ip, $keyword)) {
	   $log->log(LOG_NOTICE, "Permission denined for %s: %s",
		         $user, $keyword);
	   die "Permission denied for $user on $keyword";
    }

    if ($action
	    and not $acl->check_acls($cfg, $user, $ip, $keyword, $action)) {
	   $log->log(LOG_NOTICE, "Permission denied for %s: %s %s",
		         $user, $keyword, $action);
	   die "Permission denied for $user on $keyword - $action";
    }

    if ($action and $opts) {
	   foreach my $key (keys %$opts) {
	       if (not $acl->check_acls($cfg,
			                	    $user, $ip,
				                    $keyword, $action,
				                    $key, $opts->{$key}
				                    )
			   ) {
                $log->log(LOG_NOTICE, "Permission denied for %s: %s %s - %s",
			                 $user, $keyword, $action, $key);
		        die "Permission denied for $user on $keyword - $action - $key";
            }
        }
    }

    return 1;
}

sub get_keywords {
    my $authinfo = shift;
    
    my @keywords = ();
    foreach my $key ($eh->get_keywords()) {
        if (check_bool($cfg->{$c_sec}{'require authentication'})) {
            eval { $acl->check_acls($cfg, $authinfo->{'user'}, $authinfo->{'ip'}, $key); };
            next if ($@);
        }
        push @keywords, { keyword => $key,
                          description => $eh->get_description($key) };
    }
    return @keywords;
}

sub get_actions {
    my $authinfo = shift;
    my $keyword = shift;
    
    my @actions = ();
    foreach my $act ($eh->get_actions($keyword)) {
        if (check_bool($cfg->{$c_sec}{'require authentication'})) {
            eval { $acl->check_acls($cfg, $authinfo->{'user'}, $authinfo->{'ip'}, $keyword, $act); };
            next if ($@);
        }
        
        push @actions, {action => $act,
                        description => $eh->get_description($keyword, $act) };
    }
    
    return @actions;
}

sub get_options {
    my $authinfo = shift;
    my $keyword = shift;
    my $action = shift;
    
    my @options = ();
    foreach my $opt ($eh->get_options($keyword, $action)) {
        if (check_bool($cfg->{$c_sec}{'require authentication'})) {
            eval { $acl->check_acls($cfg,
                                    $authinfo->{'user'},
                                    $authinfo->{'ip'},
                                    $keyword, $action, $opt); };
            next if $@;
        }
        
        my $meta = $eh->get_meta($keyword, $opt);
        push @options, { option => $opt,
                         description => $eh->get_description($keyword, $action, $opt),
                         required => $eh->is_required($keyword, $action, $opt),
                         type => $meta->type() };
    }
    return @options;
}

sub build_opts {
    my $env;
    if (ref $_[-1] and UNIVERSAL::isa($_[-1], "SOAP::SOM")) {
        $env = pop @_;
    }
    my @params = @_;
    my %opts = ();
    
    foreach my $param (@params) {
        $opts{$param->name()} = $param->value();
    }
    
    return %opts;
}

sub cleanup {
    eval { $eh->cleanup($cfg); };
}

sub conf {
    my $section = shift;
    my $key = shift;
    return $cfg->{$section}{$key};
}

1;

__END__

=head1 NAME

VUser::SOAP - SOAP handling for vsoapd

=head1 DESCRIPTION

Function description here

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
