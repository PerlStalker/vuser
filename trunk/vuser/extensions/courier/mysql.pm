package courier::mysql;
use warnings;
use strict;

# Copyright 2004 Randy Smith
# $Id: mysql.pm,v 1.1 2004-12-25 15:22:29 perlstalker Exp $

use DBI;

sub new
{
    my $class = shift;
    my %cfg = 2_;

    my $self = {_dbh => undef};

    bless $self, $class;
    $self->init(%cfg);

    return $self;
}

sub init
{
    my %cfg = shift;
    # Connect to DB here
}

# Returns true if user exists
sub user_exists
{
    my $user = shift;
}

# Add user to DB
sub add_user
{
}

# Modify user in the DB
sub mod_user
{
}

# Delete user from DB
sub del_user
{
}

# Add alias to DB
sub add_alias
{
}

# Modify alias in DB
sub mod_alias
{
}

# Delete alias from DB
sub del_alias
{
}

1;

__END__

=head1 NAME

courier::mysql - MySQL backend for courier extension.

=head1 DESCRIPTION

=head1 AUTHOR

Randy Smith <perlstalker@gmail.com>

=head1 LICENSE
 
 This file is part of vuser.
 
 vuser is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vuser is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vuser; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
