use strict;
use warnings;

package VUser::Util;

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

sub add_line_to_file
{
    my ($file, $line) = @_[0,1];

    open (FILE, ">>$file") or die "Can't open $file: $!\n";
    print FILE "$line\n";
    close FILE;
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

1;
