package VUser::Google::EmailSettings::V2_0;
use warnings;
use strict;

# Copyright (C) 2009 Randy Smith, perlstalker at vuser dot org

our $VERSION = '0.1.0';

use Moose;
extends 'VUser::Google::EmailSettings';

# BUG: This should work but doesn't seem to. WTF?
#has '+google' => (isa => 'VUser::Google::ApiProtocol::V2_0');
has '+base_url' => (default => 'https://apps-apis.google.com/a/feeds/emailsettings/2.0/');

## Methods
# Constructor
sub BUILD {}

override 'CreateLabel' => sub {
    my $self = shift;
    my $label = shift;

    $self->google()->Login();
    my $url = $self->base_url().$self->google()->domain().'/'.$self->user().'/label';

    my $post = "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<atom:entry xmlns:atom=\"http://www.w3.org/2005/Atom\" xmlns:apps=\"http://schemas.google.com/apps/2006\">
    <apps:property name=\"label\" value=\"$label\" />
</atom:entry>";

    return $self->google->Request('POST', $url, $post);
};

override 'CreateFilter' => sub {
    my $self = shift;
    my $criteria = shift;
    my $actions = shift;

    $self->google()->Login();
    my $url = $self->base_url().$self->google->domain().'/'.$self->user().'/filter';
    my $post = '<?xml version="1.0" encoding="utf-8"?>
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:apps="http://schemas.google.com/apps/2006">';

    ## Add criteria
    if (defined $criteria->{hasAttachment}) {
	$criteria->{hasAttachment} = $criteria->{hasAttachment}? 'true':'false';
    }

    foreach my $crit qw(from to subject hasTheWord doesNotHaveTheWord hasAttachment) {
	if (defined $criteria->{$crit}) {
	    $post .= sprintf ("<apps:property name=\"%s\" value=\"%s\" />",
			      $crit, $criteria->{$crit});
	}
    }

    ## Add actions
    foreach my $act qw(shouldMarkAsRead shouldArchive) {
	$actions->{$act} = $criteria->{$act}? 'true':'false';
    }

    foreach my $act qw(label shouldMarkAsRead shouldArchive) {
	if (defined $actions->{$act}) {
	    $post .= sprintf ("<apps:property name=\"%s\" value=\"%s\" />",
			      $act, $actions->{$act});
	}
    }

    $post .= '</atom:entry>';

    return $self->google->Request('POST', $url, $post);
};

override 'CreateSendAsAlias' => sub {
    my $self = shift;
    my $name = shift;
    my $address = shift;
    my $reply_to = shift;
    my $make_default = shift;

    $self->google()->Login();
    my $url = $self->base_url().$self->google->domain().'/'.$self->user().'/sendas';
    my $post = '<?xml version="1.0" encoding="utf-8"?>
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:apps="http://schemas.google.com/apps/2006">';

    $post .= "<apps:property name='name' value='$name' />";
    $post .= "<apps:property name='address' value='$address' />";

    if (defined $reply_to) {
	$post .= "<apps:property name='replyTo' value='$reply_to' />";
    }

    if (defined $make_default) {
	$post .= sprintf("<apps:property name='makeDefault' value='%s' />",
			 $make_default? 'true' : 'false'
			 );
    }

    $post .= '</atom:entry>';

    return $self->google->Request('POST', $url, $post);

};

override 'UpdateForwarding' => sub {};
override 'UpdatePOP' => sub {};
override 'UpdateIMAP' => sub {};
override 'UpdateVacationResponder' => sub {};
override 'UpdateSignature' => sub {};
override 'UpdateLanguage' => sub {};
override 'UpdateGeneral' => sub {};

no Moose;
1;

__END__

=head1 NAME

VUser::Google::EmailSettings::V2_0 -


