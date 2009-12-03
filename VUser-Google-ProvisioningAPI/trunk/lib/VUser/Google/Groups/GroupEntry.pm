package VUser::Google::Groups::GroupEntry;
use warnings;
use strict;

our $VERSION = '0.2.0';

use Moose;

has 'GroupId'         => (is => 'rw', isa => 'Str');
has 'GroupName'       => (is => 'rw', isa => 'Str');
has 'Description'     => (is => 'rw', isa => 'Str');
has 'emailPermission' => (is => 'rw', isa => 'Str');

sub as_hash {
    my $self = shift;

    my %hash = (
	groupId         => $self->GroupId,
	groupName       => $self->GroupName,
	description     => $self->Description,
	emailPermission => $self->EmailPermission,
    );

    return %hash;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
