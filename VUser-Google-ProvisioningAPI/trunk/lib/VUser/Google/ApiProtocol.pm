package VUser::Google::ApiProtocol;
use warnings;
use strict;

use Moose;

our $VERSION = '0.5.0';

## Members
# The Google hosted domain we are accessing
has 'domain' => (is => 'rw');

# The admin account
has 'admin' => (is => 'rw');

# Admin password
has 'password' => (is => 'rw');

# Turn on deugging
has 'debug' => (is => 'rw', default => 0);

# If set, will force re-authentication
has 'refresh_token' => (is => 'rw',
			isa => 'Bool',
			default => 0,
			#init_arg => undef
			);

# The authentication token returned from Google
has 'authtoken' => (is => 'rw',
		    writer => '_set_authtoken',
		    #init_arg => undef
		    );

# Time when auth happened; only valid for 24 hours
# Unix timestamp
has 'authtime' => (is => 'rw',
		   default => 0,
		   writer => '_set_authtime',
		   #init_arg => undef
		   );

# the last http content posted from Google
has 'request_content' => (is => 'rw',
			  writer => '_set_request_content',
			  #init_arg => undef
			  );

# The http headers of the last reply
has 'reply_headers' => (is => 'rw',
			writer => '_set_reply_headers',
			#init_arg => undef
			);

# The http content of the last reply
has 'reply_content' => (is => 'rw',
			writer => '_set_reply_content',
			#init_arg => undef
			);

# The resulting hash from the last reply data as parsed
# by XML::Simple
has 'result' => (is => 'rw',
		 isa => 'HashRef',
		 writer => '_set_result',
		 #init_arg => undef
		 );

# Some API statistics
has 'stats' => (is => 'rw',
		isa => 'HashRef',
		default => sub { {ctime => time(), # object creation time
				  rtime => 0,      # time of last request
				  requests => 0,   # number of API requests made
				  success => 0,    # number of successes
				  logins => 0      # number of authentications
				  };
			     },
		writer => '_set_stats',
		#init_arg => undef
		);

has 'useragent' => (is => 'ro',
		    lazy => 1,
		    builder => '_build_useragent'
		    );

has 'version' => (is => 'ro',
		  builder => '_build_version'
		  );

## Methods
sub _build_useragent {
    my $self = shift;
    return ref($self).'/'.$self->version();
}

sub _build_version {
    my $self = shift;
    my $class = ref($self);
    my $ver;
    no strict 'refs';
    # There has got to be cleaner way to do this.
    $ver = eval { ${ $class."::VERSION" } };
    $ver = $VERSION if $@;
    return $ver;
}

sub Login {}

sub IsAuthenticated {}

#generic request routine that handles most functionality
#requires 3 arguments: Method, URL, Body
#Method is the HTTP method to use. ('GET', 'POST', etc)
#URL is the API URL to talk to.
#Body is the xml specific to the action.
# This is not used on 'GET' or 'DELETE' requests.
sub Request {}

#print out debugging to STDERR if debug is set
sub dprint
{
    my $self = shift;
    my $text = shift;
    my @args = @_;
    if( $self->debug and defined ($text) ) {
	print STDERR sprintf ("$text\n", @args);
    }
}

no Moose;

1;

__END__
