package VUser::ExtLib;
use warnings;
use strict;

# Copyright 2004 Randy Smith
# $Id: ExtLib.pm,v 1.14 2005-10-28 04:27:29 perlstalker Exp $

our $VERSION = "0.2.0";

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = (); # Export nothing by default
our @EXPORT_OK = qw(add_line_to_file chown_ug check_bool
		    del_line_from_file edit_warning
		    generate_password mkdir_p repl_line_in_file
		    rm_r run_scripts_in_dir strip_ws touch
		    );
our %EXPORT_TAGS = (
		    config => [qw(check_bool strip_ws)],
		    files => [qw(add_line_to_file chown_ug
				 del_line_from_file
				 repl_line_in_file
				 rm_r mkdir_p touch)]
		    );

sub version { $VERSION };

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

sub check_bool
{
    my $bool = shift;

    return 0 unless (defined $bool);

    $bool = strip_ws($bool);
    if ($bool =~ /^(1|yes|true|ok(?:ay)?|sure|I guess so|of course)$/i) {
	return 1;
    } else {
	return 0;
    }
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

sub edit_warning
{
    my $comment_char = shift || '#';

    my $warning = "$comment_char This file was written by vuser on ".scalar(localtime)."\n";
    $warning .= "$comment_char DO NOT EDIT THIS FILE. Manual changes to this file will be lost.\n\n";
    return $warning;
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

# TODO: It may be possible to use File::Path::mkpath here to create the path
# but we would still have to chown the created files.
# Perhaps something like: for $dir (mkpath($path)) { chown($uid, $gid, $dir); }
sub mkdir_p
{
    my ($dir, $mode, $user, $group) = @_;
    $dir =~ s!/$!!;

    # If user is a uid, use it, otherwise it must be a
    # name. We'll get the id from the system.
    my $uid = ($user =~ /^\d+$/ ? $user : getpwnam($user));
    my $gid = ($group =~ /^\d+$/ ? $group : getgrnam($group));

    die "Unknown user '$user'" if not defined $uid;
    die "Unknown group '$group'" if not defined $gid;

    if( -e "$dir" )
    {
	return 1;
    }

    my $parent = $dir;
    $parent =~ s!/[^/]*$!!;

    if( !$parent ) { return 0; }
    else 
    { 
	return mkdir_p( $parent, $mode, $uid, $gid ) 
	    && mkdir( $dir ) 
	    && chown( $uid, $gid, $dir );
    }
}

sub mvdir
{
    my ($old_dir, $new_dir, $safe) = @_[0..2];

    use File::Path;
    die "Directory already exists: $new_dir\n" if ($safe and -e $new_dir);

    eval { mkpath($new_dir); };
    if ($@) {
	print "Can't create dir: $new_dir: $@\n";
    }

    rename( $old_dir, $new_dir) or die "Can't rename $old_dir to $new_dir: $!\n";
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

# TODO: replace the contents with a call to File::Path::rmtree
sub rm_r
{
    my $dir = shift;

    die "No directory specified\n" unless $dir;

    opendir (DIR, $dir) or die "Unable to open $dir: $!";

    my @files = grep { ! /^\.\.?$/; } readdir DIR;
    foreach my $file (@files) {
	if (-d "$dir/$file") {
	    eval { rm_r("$dir/$file"); };
	    die "$@" if $@;
	} else {
	    unlink "$dir/$file" or die "Unable to delete $dir/$file: $!";
	}
    }

    closedir DIR;

    rmdir $dir or die "Unable to delete dir: $!";
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
    return $string unless defined $string;
    $string =~ s/^\s*(.*?)\s*$/$1/;
    return $string;
}

sub touch
{
    my $file = shift;
    my $time = shift || time();

    unless (-e $file) {
	open (FILE, ">>$file") or die "Unable to open $file: $!\n";
	close FILE;
    }
    utime($time, $time, $file) or die "Unable to change time on $file: $!\n";
}

1;

__END__

=head1 NAME

ExtLib - common functions for use by Extensions.

=head1 DESCRIPTION

=head1 Functions

=head2 add_line_to_file ($file, $line)

Append a line to a text file.

=head2 check_bool ($bool)

Check if a string is a true value such as 1, true or yes. The match is
not case sensitive. I<check_bool()> is useful for checking true values from
the configuration file.

=head2 chown_ug ($user, $group, @files)

Change ownership of a list of files using symbolic user and group names.

=head2 del_line_from_file ($file, $line)

Delete a given line from a text file.

=head2 edit_warning ($comment_char)

Returns a warning message that can be put in generated config file.
It takes an optional string so that you can change the comment string.
If not defined, it will use '#' by default.

=head2 generate_password ([$length [, @valid]])

Generate a random password of given length (or 10 if not supplied).
The password will use the characters from I<@valid> or, if not supplied,
the characters from the following list:

 (0..9, 'a'..'z', 'A'..'Z', '@', '#', '%', '^', '*')

=head2 mkdir_p ($dir, $mode, $uid, $gid)

Make a directory and any missing parents. Similar to 'mkdir -p'.

=head2 repl_line_in_file ($file, $old_line, $new_line)

Replace a given line in a text file with another line.

=head2 rm_r ($dir)

Recursively delete all files in a given directory, including the directory.

=head2 run_scripts_in_dir ($dir[, @args])

Run all executable files in a given dir with the given command line arguments.
Does not recurse into sub directories.

=head2 strip_ws ($string)

Remove leading and trailing white space.

=head2 touch ($file, $time)

Change the atime and mtime of file to $time or the current time if $time
is not defined.

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
