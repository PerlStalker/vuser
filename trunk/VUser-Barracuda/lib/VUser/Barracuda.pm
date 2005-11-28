package VUser::Barracuda;
use warnings;
use strict;

# Copyright 2005 Randy Smith <perlstalker@vuser.org>
# $Id: Barracuda.pm,v 1.1 2005-11-28 21:18:39 perlstalker Exp $

use vars ('@ISA');

use VUser::Log qw(:levels);
use VUser::ExtLib qw(strip_ws check_bool);
use VUser::Meta;
use VUser::ResultSet;
use VUser::Extension;
push @ISA, 'VUser::Extension';

our $REVISION = (split (' ', '$Revision: 1.1 $'))[1];
our $VERSION = '0.1.0';

use LWP::Simple;
use XML::Parser;

my $c_sec = 'Extension_Barracuda';
my $log;

sub version { return $VERSION; }
sub revision { return $REVISION; }

sub unload { return; }

sub debug { defined $main::DEBUG? $main::DEBUG : 0 }

my %meta = (
	    'variable' => VUser::Meta->new('name' => 'variable',
					   'type' => 'string',
					   'description' => 'Config variable'),
	    'value' => VUser::Meta->new('name' => 'value',
					'type' => 'string',
					'description' => 'Value for description'),
	    'variable2' => VUser::Meta->new('name' => 'variable2',
					    'type' => 'string',
					    'description' => 'Config variable'),
	    'value2' => VUser::Meta->new('name' => 'value2',
					 'type' => 'string',
					 'description' => 'Value for description'),
	    'account' => VUser::Meta->new('name' => 'account',
					  'type' => 'string',
					  'description' => 'Account to create or manage variables for'),
	    'row' => VUser::Meta->new('name' => 'row',
				      'type' => 'int',
				      'description' => 'A row inside a list variable')
	    
	    );

my @hosts = ();

sub init
{
    my $eh = shift;
    my %cfg = @_;

    $log = $main::log;

    @hosts = map { strip_ws($_) } split (/(\w\n)+/, $cfg{$c_sec}{'hosts'});

    # barracuda
    $eh->register_keyword('barracuda', 'Manage a Barracuda Spam Firewall');

    # barracuda-get
    $eh->register_action('barracuda', 'get',
			 'Get the value of config variables');
    $eh->register_option('barracuda', 'get', $meta{'variable'}, 'req');
    $eh->register_option('barracuda', 'get', $meta{'account'});
    $eh->register_task('barracuda', 'get', \&cuda_get);

    # barracuda-listvars
    $eh->register_action('barracuda', 'listvars',
			 'Get a list of possible variables');
    $eh->register_option('barracuda', 'listvars', $meta{'account'});

    # barracuda->listusers
    $eh->register_action('barracuda', 'listusers', 'Get the list of users');

    # barracuda-set
    $eh->register_action('barracuda', 'set', 'Set config variables');
    $eh->register_option('barracuda', 'set', $meta{'variable'}, 'req');
    $eh->register_option('barracuda', 'set', $meta{'value'}, 'req');
    $eh->register_option('barracuda', 'set', $meta{'account'});
    $eh->register_option('barracuda', 'set', $meta{'row'});
    $eh->register_task('barracuda', 'set', \&cuda_set);

    # barracuda-add
    $eh->register_action('barracuda', 'add', 'Add a value to a variable');
    $eh->register_option('barracuda', 'add', $meta{'variable'}, 'req');
    $eh->register_option('barracuda', 'add', $meta{'value'}, 'req');
    $eh->register_option('barracuda', 'add', $meta{'variable2'});
    $eh->register_option('barracuda', 'add', $meta{'value2'});
    $eh->register_option('barracuda', 'add', $meta{'account'});
    $eh->register_option('barracuda', 'add',
			 VUser::Meta->new('name' => 'create',
					  'type' => 'boolean',
					  'description' => 'Create the account if it does not exist'));
    $eh->register_task('barracuda', 'add', \&cuda_add);

    # barracuda-delete
    $eh->register_action('barracuda', 'delete', 'Delete a variable');
    $eh->register_option('barracuda', 'delete', $meta{'variable'}, 'req');
    $eh->register_option('barracuda', 'delete', $meta{'value'}, 'req');
    $eh->register_option('barracuda', 'delete', $meta{'variable2'});
    $eh->register_option('barracuda', 'delete', $meta{'value2'});
    $eh->register_option('barracuda', 'delete', $meta{'account'});
    $eh->register_option('barracuda', 'delete',
			 VUser::Meta->new('name' => 'remove',
					  'type' => 'boolean',
					  'description' => 'Remove the account sepcified'));
    $eh->register_task('barracuda', 'delete', \&cuda_del);

    # barrcuda-reload
    $eh->register_action('barracuda', 'reload', 'Reload the configuration');
    $eh->register_option('barracuda', 'reload', $meta{'account'});
    $eh->register_task('barracuda', 'reload', \&cuda_reload);

    if (check_bool($cfg{$c_sec}{'manage users'})) {
	# Add user tasks

	# email-add (account, password)
	$eh->register_task('email', 'add', \&email_add);

	# email-mod (account, password)
	$eh->register_task('email', 'mod', \&email_mod);

	# email-del (account)
	$eh->register_task('email', 'del', \&email_del);

	if (check_bool($cfg{$c_sec}{'auto-reload'})) {
	    # add task to reload config
	    $eh->register_task('email', 'add', \&cuda_reload);
	    $eh->register_task('email', 'mod', \&cuda_reload);
	    $eh->register_task('email', 'del', \&cuda_reload);
	}
    }

    if (check_bool($cfg{$c_sec}{'manage domains'})) {
	# add domain tasks

	# email-adddomain (domain)
	$eh->register_task('email', 'adddomain', \&email_adddomain);

	# email-deldomain (domain)
	$eh->register_task('email', 'deldomain', \&email_deldomain);

	# email-listdomains
	$eh->register_task('email', 'listdomains', \&list_domains);

	if (check_bool($cfg{$c_sec}{'auto-reload'})) {
	    # add task to reload config
	    $eh->register_task('email', 'adddomain', \&cuda_reload);
	    $eh->register_task('email', 'deldomain', \&cuda_reload);

	}
    }
}

sub cuda_get
{
    my ($cfg, $opts, $action, $eh) = @_;

    my %vars = ('variable' => $opts->{'variable'},
		);
    $vars{'account'} = $opts->{'account'} if $opts->{'account'};

    my %answers = do_command($cfg, 'get', %vars);

    my $rs = VUser::ResultSet->new();
    $rs->add_meta(VUser::Meta->new('name' => 'host',
				   'type' => 'string',
				   'description' => 'Host to check')
		  );
    $rs->add_meta($meta{'variable'});
    $rs->add_meta($meta{'value'});
    $rs->add_meta(VUser::Meta->new('name' => 'index',
				   'type' => 'int',
				   'description' => 'Index')
		  );

    foreach my $host (keys %answers) {
	foreach my $res (@{ $answers{$host} }) {
	    foreach my $value (@$res) {
		$rs->add_data([$host,
			       $value->{'var'},
			       $value->{'value'},
			       $value->{'index'}
			       ]);
	    }
	}
    }
    #use Data::Dumper; print Dumper $rs;
    return $rs;
}

sub cuda_listvars
{
    my ($cfg, $opts, $action, $eh) = @_;

    my %vars = ('list' => '1');
    $vars{'account'} = $opts->{'account'} if $opts->{'account'};

    my %answers = do_command($cfg, 'get', %vars);
    
    my $rs = VUser::ResultSet->new();
    $rs->add_meta(VUser::Meta->new('name' => 'host',
				   'type' => 'string',
				   'description' => 'Host to check')
		  );
    $rs->add_meta($meta{'variable'});

    foreach my $host (keys %answers) {
	foreach my $res (@{ $answers{$host} }) {
	    foreach my $value (@$res) {
		$rs->add_data([$host,
			       $value->{'var'},
			       ]);
	    }
	}
    }
    #use Data::Dumper; print Dumper $rs;
    return $rs;

}

sub cuda_set
{
    my ($cfg, $opts, $action, $eh) = @_;

    my %vars = (variable => $opts->{'variable'},
		value => $opts->{'value'}
		);
    $vars{account} = $opts->{'account'} if $opts->{'account'};
    $vars{row} = $opts->{'row'} if $opts->{'row'};

    my %answer = do_command($cfg, 'set', %vars);
    return undef;
}

sub cuda_add
{
    my ($cfg, $opts, $action, $eh) = @_;

    my %vars = (variable => $opts->{'variable'},
		value => $opts->{'value'}
		);

    $vars{account} = $opts->{'account'} if $opts->{'account'};
    $vars{variable2} = $opts->{'variable2'} if $opts->{'variable2'};
    $vars{value2} = $opts->{'value2'} if $opts->{'value2'};
    $vars{create} = 1 if $opts->{'create'};

    my %answer = do_command($cfg, 'add', %vars);
    return undef;

}

sub cuda_del
{
    my ($cfg, $opts, $action, $eh) = @_;

    my %vars = (variable => $opts->{'variable'},
		value => $opts->{'value'}
		);

    $vars{account} = $opts->{'account'} if $opts->{'account'};
    $vars{variable2} = $opts->{'variable2'} if $opts->{'variable2'};
    $vars{value2} = $opts->{'value2'} if $opts->{'value2'};
    $vars{remove} = 1 if $opts->{'remove'};

    my %answer = do_command($cfg, 'delete', %vars);
    return undef;
}

sub cuda_reload
{
    my ($cfg, $opts, $action, $eh) = @_;

    my %vars = ();
    $vars{'account'} = $opts->{'account'} if $opts->{'account'};

    my %answer = do_command($cfg, 'reload', %vars);
    return undef;
}

sub email_adddomain
{
    my ($cfg, $opts, $action, $eh) = @_;
    eval {
	$eh->run_tasks('barracuda', 'add', $cfg,
		       (variable => 'mta_relay_domain',
			value => $opts->{domain}
			)
		       );
    };
    die $@ if $@;
}

sub email_deldomain
{
   my ($cfg, $opts, $action, $eh) = @_;
    eval {
	$eh->run_tasks('barracuda', 'delete', $cfg,
		       (variable => 'mta_relay_domain',
			value => $opts->{domain}
			)
		       );
    };
    die $@ if $@;
}

sub do_command
{
    my $cfg = shift;
    my $cmd = shift; # get, set, add, search, delete, reload
    my %vars = @_;
    
    my $uri = '';
    $uri = "cgi-bin/config_${cmd}.cgi";

    my $query = '';
    while (my ($key, $value) = each %vars) {
	$query .= "\&$key=$value";
    }
    # Strip off the leading '&' I just added.
    # Ok, this is probably stupid and could be handled better in the
    # loop above. Oh, well.
    $query = substr $query, 1;

    my $parser = new XML::Parser(Style => 'Tree');

    my %answers = ();
    foreach my $host (@hosts) {
	$answers{$host} = [];
	my $clean_host = $host;
	$clean_host =~ s!/$!!;
	$log->log(LOG_DEBUG, 'Getting %s/%s?%s', $clean_host, $uri, $query);
	my $xml = get($clean_host.'/'.$uri.'?'.$query);
	my $tree = $parser->parse($xml);

	#use Data::Dumper; print Dumper $tree;

	# Now it's time to rip the data out of the tree.
	# Check for errors
	if ($tree->[1][1] eq 'Error') {
	    my $code = 200;
	    my $string;
	    my $branch = $tree->[1][4];
	    for my $i (0 .. $#{$branch}) {
		if ($branch->[$i] eq 'Code') {
		    $code = $branch->[$i+1][2];
		} elsif ($branch->[$i] eq 'String') {
		    $string = $branch->[$i+1][2];
		}
	    }
	    # Do something with the error code and string.
	    $log->log(LOG_NOTICE, "Error doing %s on %s: %d %s",
		      $cmd, $host, $code, $string);
	} else  {
	    #use Data::Dumper; print Dumper $tree;
	    my @results = parse_tree($tree->[1]);
	    push @{$answers{$host}}, \@results;
	}
    }
    #use Data::Dumper; print Dumper \%answers;
    return %answers;
}

sub parse_tree
{
    my $branch = shift; # list ref

    #use Data::Dumper; print Dumper $branch;

    # Note: I take a few short cuts here because I know how the Barracuda
    # returns responses. For example, it doesn't nest the data.
    my @results = ();
    for my $i (0..$#$branch) {
	if (ref ($branch->[$i+1]) eq 'ARRAY') {
	    my ($value, $index);
	    $value = $branch->[$i+1][2];
	    $value = strip_ws($value);
	    if (defined $value and $value =~ /^([^:]+):(.+)$/) {
		$value = $1;
		$index = $2;
	    }
	    my $res = { var => $branch->[$i],
			value => $value,
			index => $index };
	    push @results, $res;
	}
    }
    return @results;
}

1;

__END__

=head1 NAME

VUser::Barracuda - Manage users and domains on a Barracuda Spam Firewall.

=head1 REQUIRES

=over 4

=item *

LWP::Simple

=item *

XML::Parser

=back

=head1 DESCRIPTION

Manage users and domains on a Barracuda Spam Firewall.

=head1 DEVELOPMENT NOTES

These are random notes I made to help in the development. They may not
actually reflect what VUser::Barracuda is doing.

=head2 errors

$error{'code'} = barracuda error code
$error{'string'} = barracuda error string

=head2 get

barracuda-get should be able to get random variable names but should
have short cuts for specific things like domains and users.

 domain => mta_relay_domain

There should also be a shortcut to get the list of variables.

Paramters: variable*, list, list_users, account

Errors: 500, 501

Example: Get list of domains

 barracuda/cgi-bin/config_get.cgi?variable=mta_relay_domain

Example: Get list of variables

 config_get.cgi?list=1

Example: Get list of users

 config_get.cgi?list_users=1

Example: Setting a user's password

 config_get.cgi?account=user@domain&variable=user_password&value=password

=head2 set

Set existing variables.

Parameters: valiable*, value*, account, row

Errors: 800-804

=head2 add

Pramaters: variable*, value*, account, variable2, value2, create

Errors: 700-709

Example: Add domain

 config_add.cgi?variable=mta_relay_domain&value=newdomain.com

Example: Add User

 config_add.cgi?account=newuser@domain.com&create=1

=head2 delete

Delete a variable

Parameters: variable*, value*, account, variable2, value2, remove

Errors: 600-607

Example: Remove domain

 config_delete.cgi?variable=mta_relay_domain&value=domain.com

Example: Remove user

 config_delete.cgi?account=olduser@domain.com&remove=1

=head2 search

Returns a colon (:) separated value-row pair.

Paramaters: variable*, value*, account

Errors: 900-903

=head2 reload

Parameters: account

Errors: 101

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


