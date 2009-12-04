package Test::VUser::Google::Groups::V2_0;
use warnings;
use strict;

use Test::Most;
use base 'Test::VUser::Google::Groups';

sub CreateGroup : Tests(4) {
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

    ## Clean up
    can_ok $api, 'DeleteGroup';
    ok $api->DeleteGroup($group),
	'... and delete suceeded';
}

1;
