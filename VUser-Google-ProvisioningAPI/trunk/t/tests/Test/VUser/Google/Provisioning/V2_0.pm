package Test::VUser::Google::Provisioning::V2_0;
use warnings;
use strict;

use Test::Most;
use base 'Test::VUser::Google::Provisioning';

sub CreateUser : Tests(3) {
    my $test = shift;
    my $class = $test->class;

    my $api = $class->new(google => $test->create_google);
    can_ok $api, 'CreateUser';

    my $user = $test->get_test_user;

    my $res = $api->CreateUser(
	userName   => $user,
	givenName  => 'Test',
	familyName => 'User',
	password   => 'testing',
	quota      => 2048,
	changePasswordAtNextLogin => 1,
    );

    isa_ok $res, 'VUser::Google::Provisioning::UserEntry',
	'... and the account was created';

    is $res->UserName, $user, "... and the username is $user";

    # clean up
    $api->DeleteUser($res->UserName);
}

1;
