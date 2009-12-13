package Test::VUser::Google::Groups::V2_0;
use warnings;
use strict;

use Test::Most;
use base 'Test::VUser::Google::Groups';

sub CreateGroup : Tests(8) {
    my $test = shift;
    my $class = $test->class;

    my $api = $class->new(google => $test->create_google);
    can_ok $api, 'CreateGroup';

    my $group = $test->get_test_group;

    my $entry = $api->CreateGroup(
	groupId         => $group,
	groupName       => "test group $group",
	description     => 'test group descr',
	emailPermission => 'Domain',
    );

    isa_ok $entry, 'VUser::Google::Groups::GroupEntry',
	'... and the create succeeded';

    is $entry->GroupId, $group,
	'... and group id matches';

    is $entry->GroupName, "test group $group",
	'... and group name matches';

    is $entry->Description, 'test group descr',
	'... and description matches';

    is $entry->EmailPermission, 'Domain',
	'... and email permission matches';

    ## Clean up
    can_ok $api, 'DeleteGroup';
    ok $api->DeleteGroup($group),
	'... and delete suceeded';
}

sub RetrieveUser : Tests(6) {
    my $test = shift;
    my $class = $test->class;

    my $api = $class->new(google => $test->create_google);
    can_ok $api, 'UpdateGroup';

    my $group = $test->get_test_group;

    my $entry = $api->CreateGroup(
	groupId         => $group,
	groupName       => "test group $group",
	description     => 'test group descr',
	emailPermission => 'Domain',
    );

    my $new_entry = $api->RetrieveGroup($group);

    is $new_entry->GroupId, $group.'@'.$api->google->domain,
	'... and group id matches';

    is $new_entry->GroupName, "test group $group",
	'... and group name matches';

    is $new_entry->Description, 'test group descr',
	'... and description matches';

    is $new_entry->EmailPermission, 'Domain',
	'... and email permission matches';

    ok $api->DeleteGroup($group),
	'... and delete suceeded';
}

sub UpdateGroup : Tests(7) {
    my $test = shift;
    my $class = $test->class;

    my $api = $class->new(google => $test->create_google);
    can_ok $api, 'UpdateGroup';

    my $group = $test->get_test_group;

    my $entry = $api->CreateGroup(
	groupId         => $group,
	groupName       => "test group $group",
	description     => 'test group descr',
	emailPermission => 'Domain',
    );

    my $new_entry = $api->UpdateGroup(
	groupId         => $group,
	#newGroupId      => $group.'.new',
	groupName       => "test group $group.new",
	description     => 'test group descr new',
	emailPermission => 'Member',

    );


    # Can't rename groups
    #$entry = $api->RetrieveGroup($group);
    #ok !defined $entry,
    #	'... and the old group is gone';

    isa_ok $new_entry, 'VUser::Google::Groups::GroupEntry',
	'... and the create succeeded';

    # Can't rename group
    #is $new_entry->GroupId, $group.'.new' #.'@'.$api->google->domain,,
    #    '... and group id matches';

    is $new_entry->GroupName, "test group $group.new",
	'... and group name matches';

    is $new_entry->Description, 'test group descr new',
	'... and description matches';

    is $new_entry->EmailPermission, 'Member',
	'... and email permission matches';

    ok $api->DeleteGroup($group),
	'... and delete suceeded';
}

1;
