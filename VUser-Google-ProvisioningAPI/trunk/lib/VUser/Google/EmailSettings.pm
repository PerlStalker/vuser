package VUser::Google::EmailSettings;
use warnings;
use strict;

# Copyright (C) 2009 Randy Smith, perlstalker at vuser dot org

our $VERSION = '0.1.0';

use Moose;

## Members
# Provisioning API
has 'user' => (is => 'rw',
	       required => 1,
	       isa => 'Str'
	       );

has 'google' => (is => 'rw',
		 isa => 'VUser::Google::ApiProtocol',
		 required => 1
		 );

has 'base_url' => (is => 'rw', isa => 'Str');

# Turn on deugging
has 'debug' => (is => 'rw', default => 0);

## Methods
sub CreateLabel {
}

sub CreateFilter {
}

sub CreateSendAsAlias {
}

sub UpdateWebClip {
}

sub UpdateForwarding {
}

sub UpdatePOP {
}

sub UpdateIMAP {
}

sub UpdateVacationResponder {
}

sub UpdateSignature {
}

sub UpdateLanguage {
}

sub UpdateGeneral {
}

## Util
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


no Moose; # Clean up after the moose.

1;

__END__

=head1 NAME

VUser::Google::ProvisioningAPI::EmailSettings - Manage user email settings in Google Apps for Your Domain.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=over 4

=item Google Email Settings API

http://code.google.com/apis/apps/email_settings/developers_guide_protocol.html

=back

=head1 BUGS

Report bugs at http://code.google.com/p/vuser/issues/list.

=head1 AUTHOR

Randy Smith, perlstalker at vuser dot net

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

If you make useful modification, kindly consider emailing then to me for inclusion in a future version of this module.

=cut
