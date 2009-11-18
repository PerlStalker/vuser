use VUser::Google::Groups::V2_0;
use warnings;
use strict;

our $VERSION = '0.2.0';

use Moose;
extends 'VUser::Google::Groups';

has '+base_url' => (default => 'https://apps-api.google.com/a/feeds/group/2.0/');

#### Methods ####
sub CreateGroup {
}

sub UpdateGroup {
}

sub RetrieveGroup {
}

sub RetrieveAllGroupsInDomain {
}

sub RetrieveAllGroupsForMember {
}

sub DeleteGroup {
}

sub AddMemberToGroup {
}

sub RetrieveAllMembersOfGroup {
}

sub RetrieveMemberOfGroup {
}

sub RemoveMemberOfGroup {
}

sub AddOwnerToGroup {
}

sub RetrieveAllOwnersOfGroup {
}

sub RemoveOwnerFromGroup {
}


1;
