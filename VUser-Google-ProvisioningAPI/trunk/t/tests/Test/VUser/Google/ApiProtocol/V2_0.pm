package Test::VUser::Google::ApiProtocol::V2_0;
use warnings;
use strict;

use Test::Most;
use base 'Test::VUser::Google::Provisioning';

use vars qw($SKIP_LONG_TESTS);

sub Login : Tests(2) {
    my $test  = shift;
    my $class = $test->class;

    my $google = $test->create_google;
    can_ok $google, 'Login';

    ok $google->Login, '... and login succeeded';
}

1;
