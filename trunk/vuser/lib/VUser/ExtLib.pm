package VUser::ExtLib;
use warnings;
use strict;

# Copyright 2004 Randy Smith
# $Id: ExtLib.pm,v 1.2 2005-02-09 05:09:58 perlstalker Exp $

sub add_line_to_file
{
    my ($file, $line) = @_[0,1];

    open (FILE, ">>$file") or die "Can't open $file: $!\n";
    print FILE "$line\n";
    close FILE;
}

sub chown_ug
{
    my ($user, $group, @files) = @_;
    my $uid = (getpwnam($user))[2];	# Get the numerical user ID
    my $gid = (getgrnam($group))[2];	# Get the numerical group ID
    return chown $uid, $gid, @files;
}

sub del_line_from_file
{
    my ($file, $line) = @_[0,1];

    while (-e "$file.tmp") { sleep(rand(int 3)); }

    open (FILE, $file) or die "Can't open $file: $!\n";
    open (TMP, ">$file.tmp") or die "Can't open $file.tmp: $!\n";
    while (<FILE>)
    {
	chomp;
	print TMP "$_\n" unless /^\Q$line\E$/;
    }
    close FILE;
    close TMP;

    rename ("$file.tmp", $file) or die "Can't rename $file.tmp to $file: $!\n";
}

sub generate_password
{
    my $len = shift || 10;
    my @valid = @_;
    unless (@valid) {
	@valid = (0..9, 'a'..'z', 'A'..'Z', '@', '#', '%', '^', '*');
    }

    my $password = '';
    for (1 .. $len) {
	$password .= $valid[int (rand $#valid)];
    }
    return $password;
}

sub mkdir_p
{
    my ($dir, $mode, $uid, $gid) = @_;
    $dir =~ s/\/$//;

    if( -e "$dir" )
    {
	return 1;
    }

    my $parent = $dir;
    $parent =~ s/\/[^\/]*$//;

    if( !$parent ) { return 0; }
    else 
    { 
	return mkdir_p( $parent, $mode, $uid, $gid ) 
	    && mkdir( $dir ) 
	    && chown( $uid, $gid, $dir );
    }
}

sub repl_line_in_file
{
    my ($file, $oline, $nline) = @_[0..2];

    while (-e "$file.tmp") { sleep(rand(int 3)); }

    open (FILE, $file) or die "Can't open $file: $!\n";
    open (TMP, ">$file.tmp") or die "Can't open $file.tmp: $!\n";
    while (<FILE>)
    {
	chomp;
	if (/^\Q$oline\E$/)
	{
	    print TMP "$nline\n";
	}
	else
	{
	    print TMP "$_\n";
	}
	
    }
    close FILE;
    close TMP;

    rename "$file.tmp", $file or die "Can't rename $file.tmp to $file: $!\n";
}

sub run_scripts_in_dir
{
    my $dir = shift;
    my @args = @_;

    opendir (DIR, $dir) or die "Unable to open directory $dir: $!\n";

    my @scripts = ();
    # Get all executable files (not directories) in the directory
    @scripts = grep { not -d "$dir/$_" and -x _ } readdir DIR;

    closedir DIR;

    foreach my $script (@scripts) {
	system ("$dir/$script", @args);
    }
}

sub strip_ws
{
    my $string = shift;
    $string =~ s/^\s*(.*?)\s*$/$1/;
    return $string;
}

1;

__END__

=head1 NAME

ExtLib - common functions for use by Extensions.

=head1 DESCRIPTION

=head1 Functions

=head2 add_line_to_file ($file, $line)

Append a line to a text file.

=head2 chown_ug ($user, $group, @files)

Change ownership of a list of files using symbolic user and group names.

=head2 del_line_from_file ($file, $line)

Delete a given line from a text file.

=head2 generate_password ([$length [, @valid]])

Generate a random password of given length (or 10 if not supplied).
The password will use the characters from I<@valid> or, if not supplied,
the characters from the following list:

 (0..9, 'a'..'z', 'A'..'Z', '@', '#', '%', '^', '*')

=head2 mkdir_p ($dir, $mode, $uid, $gid)

Make a directory and any missing parents. Similar to 'mkdir -p'.

=head2 repl_line_in_file ($file, $old_line, $new_line)

Replace a given line in a text file with another line.

=head2 run_scripts_in_dir ($dir[, @args])

Run all executable files in a given dir with the given command line arguments.
Does not recurse into sub directories.

=head2 strip_ws ($string)

Remove leading and trailing white space.

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
