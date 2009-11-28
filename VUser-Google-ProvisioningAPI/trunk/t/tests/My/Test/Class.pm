package My::Test::Class;
use warnings;
use strict;

use Test::Most;
use base qw(Test::Class Class::Data::Inheritable);

BEGIN {
    __PACKAGE__->mk_classdata('class');
}

INIT {
    Test::Class->runtests;
}

sub startup : Tests( startup => 1 ) {
    my $test = shift;
    ( my $class = ref $test ) =~ s/^Test:://;
    return ok 1, "$class loaded" if $class eq __PACKAGE__;
    use_ok $class or die;
    $test->class($class);
}

sub create_google {
    use VUser::Google::ApiProtocol::V2_0;
    my $google = VUser::Google::ApiProtocol::V2_0->new(
	domain => $ENV{GAPPS_DOMAIN},
	admin  => $ENV{GAPPS_ADMIN},
	password => $ENV{GAPPS_PASSWD},
	debug => 1
    );

    return $google;
}

1;
