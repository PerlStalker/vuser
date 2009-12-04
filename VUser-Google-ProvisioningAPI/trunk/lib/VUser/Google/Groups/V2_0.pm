package VUser::Google::Groups::V2_0;
use warnings;
use strict;

our $VERSION = '0.2.0';

use Moose;
extends 'VUser::Google::Groups';

use VUser::Google::Groups::GroupEntry;

has '+base_url' => (default => 'https://apps-apis.google.com/a/feeds/group/2.0/');

#### Methods ####
sub CreateGroup {
    my $self = shift;
    my %options = ();

    if (ref $_[0]
	    and $_[0]->isa('VUser::Google::Groups::GroupEntry')) {
	%options = $_[0]->as_hash;
    }
    else {
	%options = @_;
    }

    my $url = $self->base_url.$self->google->domain;

    my $post = '<?xml version="1.0" encoding="UTF-8"?>
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:apps="http://schemas.google.com/apps/2006" xmlns:gd="http://schemas.google.com/g/2005">';
    $post .= '<apps:property name="groupId" value="'
	.$options{groupId}.'"/>';
    $post .= '<apps:property name="groupName" value="'
	.$options{groupName}.'"/>';
    $post .= '<apps:property name="description" value="'
	.$options{description}.'"/>';
    $post .= '<apps:property name="emailPermission" value="'
	.$options{emailPermission}.'"/>';

    $post .= '</atom:entry>';


    if ($self->google->Request('POST', $url, $post)) {
	my $entry = $self->_build_group_entry($self->google->result);
	return $entry;
    }
    else {
	die "Unable to create group: ".$self->google->result->{'reason'}."\n";
    }
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
    my $self    = shift;
    my $groupId = shift;

    die "Cannot delete group: No group specified.\n" if not $groupId;

    my $url = $self->base_url.$self->google->domain."/$groupId";

    if ($self->google->Request('DELETE', $url)) {
	return 1;
    }
    else {
	die "Cannot delete group: ".$self->google->result->{'reason'};
    }
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

sub _build_group_entry {
    my $self = shift;
    my $xml  = shift;

    my $entry = VUser::Google::Groups::GroupEntry->new();

    foreach my $property (@{ $xml->{'apps:property'} }) {
	if ($property->{'name'} eq 'groupId') {
	    $entry->GroupId($property->{'value'});
	}
	elsif ($property->{'name'} eq 'groupName') {
	    $entry->GroupName($property->{'value'});
	}
	elsif ($property->{'name'} eq 'description') {
	    $entry->Description($property->{'value'});
	}
	elsif ($property->{'name'} eq 'emailPermission') {
	    $entry->EmailPermission($property->{'value'});
	}
    }

    return $entry;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
