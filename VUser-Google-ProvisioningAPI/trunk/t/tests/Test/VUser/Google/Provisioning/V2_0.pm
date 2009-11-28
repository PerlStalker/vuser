package Test::VUser::Google::Provisioning::V2_0;
use warnings;
use strict;

use Test::Most;
use base 'Test::VUser::Google::Provisioning';

sub CreateUser : Tests(12) {
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

    ## Retrieve Test
    can_ok $api, 'RetrieveUser';
    $res = $api->RetrieveUser($user);
    isa_ok $res, 'VUser::Google::Provisioning::UserEntry',
	'... and the account was retrieved';

    is $res->GivenName, 'Test',
	'... and retrieved given name matches';

    is $res->FamilyName, 'User',
	'... and retrieved family name matches';

  TODO: {
	local $TODO = 'How to check if quota updates are disabled?';
	is $res->Quota, '2048',
	    '... and retrieved quota matches';
    }

    is $res->ChangePasswordAtNextLogin, 1,
	'... and retrieved change pw matches';

    ## clean up
    can_ok $api, 'DeleteUser';
    my $rc = $api->DeleteUser($res->UserName);
    is $rc, 1, '... and delete reports successful';

    $res = $api->RetrieveUser($user);
    ok !defined $res,
	'... and there\'s nothing to retrieve';
}

sub RetrieveUsers : Tests(5) {
    my $test = shift;
    my $class = $test->class;

    my $api = $class->new(google => $test->create_google);

    can_ok $api, 'RetrieveUsers';

    can_ok $api, 'RetrieveAllUsers';

    my $num_users = 110;

    ## Create 110 test users
    note "Creating $num_users test users. This will take a while.";
    my $user = $test->get_test_user;
    foreach my $i (1 .. $num_users) {
	my $res = $api->CreateUser(
	    userName   => $user.".$i",
	    givenName  => 'Test',
	    familyName => 'User',
	    password   => 'testing',
	    quota      => 2048,
	    changePasswordAtNextLogin => 1,
	);
    }

    ## Fetch first page of users
    my %results = $api->RetrieveUsers;
    is @{ $results{'entries'} }, 100,
	'... and we have 100 users';
    my $next = $results{next};


    ## Fetch second page of users
    %results = $api->RetrieveUsers($next);
    is $results{'entries'}[0]->UserName, $next,
	'... and the first result of the second page is the "next" from the first page';

    ## Retrieve all users
    my @entries = $api->RetrieveAllUsers;
  TODO: {
	local $TODO = 'How many users already existed?';
	ok @entries >= $num_users+1,
	    '... and there are the expected number of users';
    }

    ## Delete test users
    note "Deleting $num_users test users. This will also take a while.";
    foreach my $i (1 .. $num_users) {
	my $rc = $api->DeleteUser($user.".$i");
    }
}

1;
