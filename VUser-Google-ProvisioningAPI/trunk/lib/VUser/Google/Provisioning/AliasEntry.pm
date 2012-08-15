package VUser::Google::Provisioning::AliasEntry;
use warnings;
use strict;

our $VERSION = '0.1.0';

use Moose;

has 'id'         => (is => 'rw', 'isa' => 'Str');
has 'UserEmail'  => (is => 'rw', 'isa' => 'Str');
has 'AliasEmail' => (is => 'rw', 'isa' => 'Str');

sub as_hash {
    my $self = shift;

    my %hash = (
	userEmail  => $self->UserEmail,
	aliasEmail => $self->AliasEmail
    );

    return %hash;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
