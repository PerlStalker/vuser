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
	die "Error creating user: ".$self->google->result->{'reason'}."\n";
    }
}

sub RetrieveUser {
    my $self = shift;
    my $username = shift;

    my $url = $self->base_url.$self->google->domain.'/user/2.0/'.$username;

    if ($self->google->Request('GET', $url)) {
	return $self->_build_user_entry($self->google->result);
    }
    else {
	if ($self->google->result->{'reason'} =~ 'EntityDoesNotExist') {
	    return undef;
	}
	else {
	    die "Error retrieving user: ".$self->google->result->{'reason'}."\n";
	}
    }
}

# Retrieve one page of users.
# How to return the next page?
# Returns (
#   entries => \@entries, # list of UserEntry objects
#   next    => $next      # the next username if another page exists
#                         # undef otherwise
#   )
sub RetrieveUsers {
    my $self       = shift;
    my $start_user = shift;

    my @entries = ();
    my $next_user;

    my $url = $self->base_url.$self->google->domain.'/user/2.0';
    if ($start_user) {
	$url .= "?startUsername=$start_user";
    }

    if ($self->google->Request('GET', $url)) {
	foreach my $entry (@{ $self->google->result->{'entry'} }) {
	    ## Create UserEntry object
	    my $user = $self->_build_user_entry($entry);
	    push @entries, $user;
	}
    }
    else {
	## There was an error
	die "Error fetching users: ".$self->google->result->{'reason'}."\n";
    }

    # Look for the a link tag that says there should be more results
    # A link tag with rel=next means there is another page
    foreach my $link (@{ $self->google->result->{'link'} }) {
	if ($link->{'rel'} eq 'next') {
	    $url = $link->{'href'};
	    if ($url =~ /startUsername=([^\"]+)/) {
		$next_user = $1;
	    }
	}
    }

    return ( entries => \@entries, next => $next_user );
}

# Alias for RetrieveUsers
sub RetrievePageOfUsers {
    $_[0]->RetrieveUsers(@_);
}

# Returns a list of UserEntry objects
sub RetrieveAllUsers {
    my $self = shift;

    my @entries = ();
    my $next;

    my %results;

    eval {
	%results = $self->RetrieveUsers;
	push @entries, @{ $results{'entries'} };
	$next = $results{'next'};
    };
    die $@ if $@;

    while ($next) {
	eval {
	    %results = $self->RetrieveUsers($next);
	    push @entries, @{ $results{'entries'} };
	    $next = $results{'next'};
	};
	die $@ if $@;
    }

    return @entries;
}

# %options
#   userName*
#   givenName
#   familyName
#   password
#   hashFunctioName (SHA-1|MD5)
#   suspended       (bool)
#   quota           (in MB)
#   changePasswordAtNextLogin (bool)
sub UpdateUser {
    my $self = shift;

    my %options = ();

    if (ref $_[0]
	    and $_[0]->isa('VUser::Google::Provisioning::UserEntry')) {
	%options = $_[0]->as_hash;
    }
    else {
	%options = @_;
    }

    die "Can't update user: userName not set\n" unless $options{'userName'};

    my $url = $self->base_url.$self->google->domain
	."/user/2.0/$options{userName}";

    my $post = '<?xml version="1.0" encoding="UTF-8"?>
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom"
  xmlns:apps="http://schemas.google.com/apps/2006">
    <atom:category scheme="http://schemas.google.com/g/2005#kind" 
        term="http://schemas.google.com/apps/2006#user"/>
';

    ## update user info (login tag)
    if ($options{password}
	    or defined $options{suspended}
            or defined $options{changePasswordAtNextLogin}
	) {
	$post .= '<apps:login';

	if (defined $options{password}) {
	    $post .= ' password="';
	    $post .= $self->_escape_quotes($options{'password'});
	    $post .= '"';

	    if (defined $options{hashFunctionName}) {
		$post .= ' hashFunctionName="';
		$post .= $options{hashFunctionName};
		$post .= '"';
	    }
	}

	if (defined $options{suspended}) {
	    $post .= ' suspended="'.$self->_as_bool($options{suspended}).'"';
	}

	if (defined $options{changePasswordAtNextLogin}) {
	    $post .= ' changePasswordAtNextLogin="'
		.$self->_as_bool($options{changePasswordAtNextLogin}).'"';
	}

	$post .= '/>';
    }

    ## Quota
    if ($options{quota}) {
	$post .= "<apps:quota limit=\"$options{quota}\"/>";
    }

    ## Name
    if ($options{givenName} or $options{familyName}) {
	$post .= '<apps:name';
	$post .= " familyName=\"$options{familyName}\"" if $options{familyName};
	$post .= " givenName=\"$options{givenName}\"" if $options{givenName};
	$post .= '/>';
    }

    $post .= '</atom:entry>';

    if ($self->google->Request('PUT', $url, $post)) {
	$self->dprint('Updated user');
	my $entry = $self->_build_user_entry($self->google->result);
	return $entry;
    }
    else {
	die "Error updating user: ".$self->google->result->{'reason'}."\n";
    }
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
    my $self          = shift;
    my $username      = shift;
    my $password      = shift;
    my $hash_function = shift;

    if (not $username or not $password) {
	die "Can't change password: username or password not set.\n";
    }

    my $entry = $self->UpdateUser(
	userName         => $username,
	password         => $password,
	hashFunctionName => $hash_function,
    );

    return $entry;
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
