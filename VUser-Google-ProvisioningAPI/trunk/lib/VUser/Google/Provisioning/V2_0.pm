package VUser::Google::Provisioning::V2_0;
use warnings;
use strict;

our $VERSION = '0.2.0';

use Moose;
extends 'VUser::Google::Provisioning';

use VUser::Google::Provisioning::UserEntry;

has '+base_url' => (default => 'https://apps-apis.google.com/a/feeds/');

#### Methods ####
## Users
#
# %options
#   userName*
#   givenName*
#   familyName*
#   password*
#   hashFunctioName (SHA-1|MD5)
#   suspended       (bool)
#   quota           (in MB)
#   changePasswordAtNextLogin (bool)
sub CreateUser {
    my $self    = shift;

    my %options = ();

    if (ref $_[0]
	    and $_[0]->isa('VUser::Google::Provisioning::UserEntry')) {
	%options = $_[0]->as_hash;
    }
    else {
	%options = @_;
    }

    $self->google()->Login();
    my $url = $self->base_url.$self->google->domain.'/user/2.0';

    my $post = '<?xml version="1.0" encoding="UTF-8"?>
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom"
  xmlns:apps="http://schemas.google.com/apps/2006">
    <atom:category scheme="http://schemas.google.com/g/2005#kind" 
        term="http://schemas.google.com/apps/2006#user"/>
';

    ## login
    $post .= '<apps:login ';
    $post .= " userName=\"$options{'userName'}\"";

    $post .= " password=\""
	.$self->_escape_quotes($options{'password'})."\"";

    if ($options{hashFunctionName}) {
	$post .= " hashFunctionName=\"$options{hashFunctionName}\"";
    }

    if ($options{suspended}) {
	$post .= ' suspended="'.$self->_as_bool($options{suspended}).'"';
    }

    if ($options{changePasswordAtNextLogin}) {
	$post .= ' changePasswordAtNextLogin="'
	    .$self->_as_bool($options{changePasswordAtNextLogin}).'"';
    }

    $post .= '/>';

    ## quota
    if ($options{quota}) {
	$post .= "<apps:quota limit=\"$options{quota}\"/>";
    }

    ## name
    $post .= '<apps:name';
    $post .= " familyName=\"$options{familyName}\"";
    $post .= " givenName=\"$options{givenName}\"";
    $post .= '/>';

    $post .= '</atom:entry>';

    if ($self->google->Request('POST', $url, $post)) {
	## build UserEntry
	$self->dprint('Created user');
	my $entry = $self->_build_user_entry($self->google->result);
	return $entry;
    }
    else {
	## ERROR!
	$self->dprint('CreateUser failed: '.$self->google->result->{reason});
	return undef;
    }
}

sub RetrieveUser {
    my $self = shift;
    my $username = shift;

    my $url = $self->base_url.$self->google->domain.'/user/2.0/'.$username;

    if ($self->google->Request('GET', $url)) {
	return $self->_build_user_entry($self->google->get_result);
    }
    else {
	return undef;
    }
}

sub RetrieveAllUsers {
}

sub UpdateUser {
}

sub RenameUser {
}

sub DeleteUser {
    my $self = shift;
    my $user;

    if (ref $_[0] and $_[0]->isa('VUser::Google::Provisioning::UserEntry')) {
	$user = $_[0]->UserName
    }
    else {
	$user = $_[0];
    }

    my $url = $self->base_url.$self->google->domain.'/user/2.0/'.$user;

    if ($self->google->Request('DELETE', $url)) {
	return 1;
    }
    else {
	return undef;
    }
}

sub ChangePassword {
}

## Nicknames
sub CreateNickname {
}

sub RetrieveNickname {
}

sub RetrieveAllNicknamesForUser {
}

sub RetrieveAllNicknamesInDomain {
}

sub DeleteNickname {
}

# Takes the parsed XML object
sub _build_user_entry {
    my $self = shift;
    my $xml  = shift;

    my $entry = VUser::Google::Provisioning::UserEntry->new();

    $entry->UserName($xml->{'apps:login'}[0]{'userName'});

    if ($xml->{'apps:login'}[0]{'suspended'}) {
	if ($xml->{'apps:login'}[0]{'suspended'} eq 'true') {
	    $entry->Suspended(1);
	}
	else {
	    $entry->Suspended(0);
	}
    }

    if ($xml->{'apps:login'}[0]{'changePasswordAtNextLogin'}) {
	if ($xml->{'apps:login'}[0]{'changePasswordAtNextLogin'} eq 'true') {
	    $entry->ChangePasswordAtNextLogin(1);
	}
	else {
	    $entry->ChangePasswordAtNextLogin(0);
	}
    }

    $entry->FamilyName($xml->{'apps:name'}[0]{'familyName'});
    $entry->GivenName($xml->{'apps:name'}[0]{'givenName'});
    $entry->Quota($xml->{'apps:quota'}[0]{'limit'});

    return $entry;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__
