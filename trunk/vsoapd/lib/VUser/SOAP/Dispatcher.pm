package VUser::SOAP::Dispatcher;
use warnings;
use strict;

# Copyright (c) 2006 Randy Smith
# $Id: Dispatcher.pm,v 1.3 2006-09-26 21:30:33 perlstalker Exp $

use SOAP::Lite;
use VUser::SOAP;
use VUser::ExtLib qw(:config);

our @ISA = qw(SOAP::Server::Parameters);

my $c_sec = 'vsoapd';

sub login {
    my $class = shift;
    my $user = shift;
    my $password = shift;
    my $envelope = shift; # SOAP::SOM object
    
    # Is there a way to get the IP from a SOAP::SOM object?
    my $ip = '127.0.0.1';
    
    # Check auth
    my $authinfo = VUser::SOAP::login($user, $password, $ip);
    
    if ($authinfo == 0) {
        # auth failed FAULT
    } else {
        return $authinfo;
    }
}

sub get_keywords {
    my $envelope = pop; # SOAP::SOM object
    my $authinfo = $envelope->valueof ("//authinfo");
    
    # authenticate here
    if (check_bool(VUser::SOAP::conf($c_sec, 'require authentication'))) {
       if (not VUser::SOAP::check_ticket($authinfo)) {
           # error: invalid or expired ticket: FAULT
           die SOAP::Failt
            ->faultcode('Server.Custom')
            ->faultstring('Authentication failed');
        }
    }
    
    return VUser::SOAP::get_keywords($authinfo);
}

sub get_actions {
    my $envelop = pop; # SOAP::SOM object
    my $authinfo = $envelop->valueof ("//authinfo");
    
    # authenticate here
    if (check_bool(VUser::SOAP::conf($c_sec, 'require authentication'))) {
       if (not VUser::SOAP::check_ticket($authinfo)) {
           # error: invalid or expired ticket: FAULT
           die SOAP::Failt
            ->faultcode('Server.Custom')
            ->faultstring('Authentication failed');
        }
    }
    
    my $keyword;
    foreach my $elm (@_) {
        if ($elm->isa('SOAP::Data')
            and $elm->name() eq 'keyword') {
            $keyword = $elm->value;
        }
    }
    
    return VUser::SOAP::get_actions ($authinfo, $keyword);
}

sub get_options {
    my $envelop = pop; # SOAP::SOM object
    my $authinfo = $envelop->valueof ("//authinfo");
    
    # authenticate here
    if (check_bool(VUser::SOAP::conf($c_sec, 'require authentication'))) {
       if (not VUser::SOAP::check_ticket($authinfo)) {
           # error: invalid or expired ticket: FAULT
           die SOAP::Failt
            ->faultcode('Server.Custom')
            ->faultstring('Authentication failed');
        }
    }
    
    my $keyword;
    my $action;
    foreach my $elm (@_) {
        if ($elm->isa('SOAP::Data')) {
            if ($elm->name() eq 'keyword') {
                $keyword = $elm->value;
            } elsif ($elm->name() eq 'action') {
                $action = $elm->value;
            }
        }
    }
    
    return VUser::SOAP::get_options ($authinfo, $keyword, $action);
}

# SOAP Param order: keyword, action, @params

# This might be hairy from a WSDL perspective since the options change
# based on the keyword/action pair that's used. It might be better if, instead,
# a hash is used (as per the original vsoapd) in this case. Or it might be 
# be better if it's not here at all.
# For now, I'll leave it here as an undocumented feature.
sub run_tasks {
    my $class = shift;
    
    my $env = $_[-1]; # SOAP::SOM object

    my $keyword = shift;
    my $action = shift;
    my @params = @_;
    
    my $authinfo = $env->valueof ("//authinfo");
        
    # authenticate here
    if (check_bool(VUser::SOAP::conf($c_sec, 'require authentication'))) {
        if (not VUser::SOAP::check_ticket($authinfo)) {
            # error: invalid or expired ticket: FAULT
            die SOAP::Failt
             ->faultcode('Server.Custom')
             ->faultstring('Authentication failed');
        }
    }
       
    # We've successfully gotten passed the authentication.
    # Let's do some work.
	return VUser::SOAP::run_tasks($authinfo->{'username'},
	                              $authinfo->{'ip'},
	                              $keyword->value,
	                              $action->value,
	                              @params);
}

sub AUTOLOAD {
    use vars '$AUTOLOAD';
    my $class = shift;
    
    my $envelope = $_[-1]; # SOAP::SOM object
    
    my @params = @_;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;
    #print "name: $name\n";
    if ($name =~ /^([^_]+)_([^_]+)$/) {
	   my $keyword = $1;
	   my $action = $2;
	   
	   my $authinfo = $envelope->valueof ("//authinfo");
    
       # authenticate here
       if (check_bool(VUser::SOAP::conf($c_sec, 'require authentication'))) {
           if (not VUser::SOAP::check_ticket($authinfo)) {
               # error: invalid or expired ticket: FAULT
               die SOAP::Failt
                ->faultcode('Server.Custom')
                ->faultstring('Authentication failed');
           }
       }
       
       # We've successfully gotten passed the authentication.
       # Let's do some work.
	   return VUser::SOAP::run_tasks($authinfo->{'username'},
	                                 $authinfo->{'ip'},
	                                 $keyword, $action, @params);
    } else {
	   return;
    }
}

1;

__END__

=head1 NAME

VUser::SOAP::Dispatcher - Dispatch SOAP functions

=head1 DESCRIPTION

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