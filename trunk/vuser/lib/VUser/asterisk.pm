package VUser::asterisk;
use warnings;
use strict;

# Copyright 2004 Randy Smith
# $Id: asterisk.pm,v 1.17 2005-02-25 04:39:26 perlstalker Exp $

use vars qw(@ISA);

our $REVISION = (split (' ', '$Revision: 1.17 $'))[1];
our $VERSION = $main::VERSION;

use VUser::Extension;
push @ISA, 'VUser::Extension';

my %backends = ('sip' => undef,
		'iax' => undef,
		'vm'  => undef,
		'ext' => undef
		);

sub config_sample
{
    my $fh;
    my $cfg = shift;
    my $opts = shift;

    if (defined $opts->{file}) {
	open ($fh, ">".$opts->{file})
	    or die "Can't open '".$opts->{file}."': $!\n";
    } else {
	$fh = \*STDOUT;
    }

    print $fh <<'CONFIG';
[Extension_asterisk]
# Enable asterisk extension
enable=yes

# The location of the asterisk config files.
etc=/etc/asterisk

# The default context for things.
default context=asterisk

# The name of the file to write for SIP friends.
# I recommend writting to some place other than sip.conf and including that
# file from sip.conf.
sip.conf=sip.vuser

# SIP database info.
# dbtype may be mysql, pg or none. Not all options are used in all cases.
sip_dbtype=mysql
sip_dbuser=asterisk
sip_dbpass=secret
sip_dbhost=localhost
sip_dbname=asterisk
sip_dbport=3306

# The name of the file to write for IAX friends.
# I recommend writting to some place other than iax.conf and including that
# file from iax.conf.
iax.conf=iax.vuser

# IAX database info.
iax_dbtype=mysql
iax_dbuser=asterisk
iax_dbpass=secret
iax_dbhost=localhost
iax_dbname=asterisk
iax_dbport=3306

# The name of the file to write for IAX friends.
# I recommend writting to some place other than voicemail.conf and including
# that file from voicemail.conf.
voicemail.conf=vm.vuser

# IAX database info.
vm_dbtype=mysql
vm_dbuser=asterisk
vm_dbpass=secret
vm_dbhost=localhost
vm_dbname=asterisk
vm_dbport=3306

# The location of the voicemail spool
vm spool=/var/spool/asterisk/voicemail
vm sounds=/var/lib/asterisk/sounds

# The user and group that owns the vm spool
vm user=root
vm group=root

# The name of the file to write extension data to.
extensions.conf=extensions.vuser

# Extension database info.
ext_dbtype=mysql
ext_dbuser=asterisk
ext_dbpass=secret
ext_dbhost=localhost
ext_dbname=asterisk
ext_dbport=3306

CONFIG

    if (defined $opts->{file}) {
	close CONF;
    }
}

sub init
{
    my $eh = shift;
    my %cfg = @_;

    return unless VUser::ExtLib::check_bool($cfg{Extension_asterisk}{enable});

    foreach my $backend (keys %backends) {
	my $type = $cfg{Extension_asterisk}{$backend.'_dbtype'};
	$type =~ s/^\s*(\S+)\s*$/$1/; # Strip whitespace

	if ($type eq 'mysql') {
	    require VUser::asterisk::mysql;
	    $backends{$backend} = new VUser::asterisk::mysql($backend, %cfg);
	} elsif ($type eq 'none') {
	} else {
	    die "Unsupported asterisk backend '$type'.\n";
	}
    }

    # Config
    $eh->register_task('config', 'sample', \&config_sample);

    # SIP
    $eh->register_keyword('sip');

    # SIP-add
    $eh->register_action('sip', 'add');
    $eh->register_option('sip', 'add', 'name', '=s', 1);
    $eh->register_option('sip', 'add', 'username', '=s');
    $eh->register_option('sip', 'add', 'secret', '=s');
    $eh->register_option('sip', 'add', 'context', '=s');
    $eh->register_option('sip', 'add', 'ipaddr', '=s');
    $eh->register_option('sip', 'add', 'port', '=i');
    $eh->register_option('sip', 'add', 'regseconds', '=i');
    $eh->register_option('sip', 'add', 'callerid', '=s');
    $eh->register_option('sip', 'add', 'restrictcid', '');
    $eh->register_option('sip', 'add', 'mailbox', '=s');
    $eh->register_task('sip', 'add', \&sip_add, 0);

    # SIP-del
    $eh->register_action('sip', 'del');
    $eh->register_option('sip', 'del', 'name', '=s', 1);
    $eh->register_option('sip', 'del', 'context', '=s');
    $eh->register_task('sip', 'del', \&sip_del, 0);

    # SIP-mod
    $eh->register_action('sip', 'mod');
    $eh->register_option('sip', 'mod', 'name', '=s', 1);
    $eh->register_option('sip', 'mod', 'username', '=s');
    $eh->register_option('sip', 'mod', 'secret', '=s');
    $eh->register_option('sip', 'mod', 'context', '=s');
    $eh->register_option('sip', 'mod', 'ipaddr', '=s');
    $eh->register_option('sip', 'mod', 'port', '=i');
    $eh->register_option('sip', 'mod', 'regseconds', '=i');
    $eh->register_option('sip', 'mod', 'callerid', '=s');
    $eh->register_option('sip', 'mod', 'restrictcid', '');
    $eh->register_option('sip', 'mod', 'mailbox', '=s');
    $eh->register_option('sip', 'mod', 'newname', '=s');
    $eh->register_option('sip', 'mod', 'newcontext', '=s');
    $eh->register_task('sip', 'mod', \&sip_mod, 0);

    # SIP-show
    $eh->register_action('sip', 'show');
    $eh->register_option('sip', 'show', 'name', '=s');
    $eh->register_option('sip', 'show', 'context', '=s');
    $eh->register_option('sip', 'show', 'pretty', '');
    $eh->register_task('sip', 'show', \&sip_show, 0);

    # IAX
    $eh->register_keyword('iax');
    $eh->register_action('iax', 'add');
    $eh->register_action('iax', 'del');
    $eh->register_action('iax', 'mod');

    # Extensions
    $eh->register_keyword('ext');

    # Ext-add
    $eh->register_action('ext', 'add');
    $eh->register_option('ext', 'add', 'context', '=s');
    $eh->register_option('ext', 'add', 'extension', '=s', 1);
    $eh->register_option('ext', 'add', 'priority', '=i');
    $eh->register_option('ext', 'add', 'application', '=s');
    $eh->register_option('ext', 'add', 'args', '=s');
    $eh->register_option('ext', 'add', 'descr', '=s');
    $eh->register_option('ext', 'add', 'flags', '=i');
    $eh->register_task('ext', 'add', \&ext_add, 0);
    
    # Ext-del
    $eh->register_action('ext', 'del');
    $eh->register_option('ext', 'del', 'context', '=s');   # optional
    $eh->register_option('ext', 'del', 'extension', '=s', 1); # required
    $eh->register_option('ext', 'del', 'priority', '=i');  # optional
    $eh->register_task('ext', 'del', \&ext_del, 0);

    # Ext-mod
    $eh->register_action('ext', 'mod');
    $eh->register_option('ext', 'mod', 'context', '=s');
    $eh->register_option('ext', 'mod', 'extension', '=s', 1);
    $eh->register_option('ext', 'mod', 'priority', '=i');
    $eh->register_option('ext', 'mod', 'application', '=s');
    $eh->register_option('ext', 'mod', 'args', '=s');
    $eh->register_option('ext', 'mod', 'descr', '=s');
    $eh->register_option('ext', 'mod', 'flags', '=i');
    $eh->register_option('ext', 'mod', 'newcontext', '=s');
    $eh->register_option('ext', 'mod', 'newext', '=s');
    $eh->register_option('ext', 'mod', 'newpriority', '=i');
    $eh->register_task('ext', 'mod', \&ext_mod, 0);

    # Ext-show
    $eh->register_action('ext', 'show');
    $eh->register_option('ext', 'show', 'extension', '=s');
    $eh->register_option('ext', 'show', 'context', '=s');
    $eh->register_option('ext', 'show', 'priority', '=i');
    $eh->register_option('ext', 'show', 'pretty', '');
    $eh->register_task('ext', 'show', \&ext_show, 0);

    # Voice mail
    $eh->register_keyword('vm');

    # VM-add
    $eh->register_action('vm', 'add');
    $eh->register_option('vm', 'add', 'context', '=s');
    $eh->register_option('vm', 'add', 'mailbox', '=s', 1);
    $eh->register_option('vm', 'add', 'password', '=s');
    $eh->register_option('vm', 'add', 'fullname', '=s');
    $eh->register_option('vm', 'add', 'email', '=s');
    $eh->register_option('vm', 'add', 'pager', '=s');
    $eh->register_option('vm', 'add', 'options', '=s');
    $eh->register_task('vm', 'add', \&vm_add, 0);
    $eh->register_task('vm', 'add', \&vm_create_box, 10);

    # VM-del
    $eh->register_action('vm', 'del');
    $eh->register_option('vm', 'del', 'context', '=s');
    $eh->register_option('vm', 'del', 'mailbox', '=s', 1);
    $eh->register_task('vm', 'del', \&vm_del, 0);
    $eh->register_task('vm', 'del', \&vm_rm_box, 10);

    # VM-mod
    $eh->register_action('vm', 'mod');
    $eh->register_option('vm', 'mod', 'context', '=s');
    $eh->register_option('vm', 'mod', 'mailbox', '=s', 1);
    $eh->register_option('vm', 'mod', 'password', '=s');
    $eh->register_option('vm', 'mod', 'fullname', '=s');
    $eh->register_option('vm', 'mod', 'email', '=s');
    $eh->register_option('vm', 'mod', 'pager', '=s');
    $eh->register_option('vm', 'mod', 'options', '=s');
    $eh->register_option('vm', 'mod', 'newmailbox', '=s');
    $eh->register_option('vm', 'mod', 'newcontext', '=s');
    $eh->register_task('vm', 'mod', \&vm_mod, 0);

    # VM-show
    $eh->register_action('vm', 'show');
    $eh->register_option('vm', 'show', 'mailbox', '=s');
    $eh->register_option('vm', 'show', 'context', '=s');
    $eh->register_option('vm', 'show', 'pretty', '');
    $eh->register_task('vm', 'show', \&vm_show, 0);

    # Asterisk control
    $eh->register_keyword('asterisk');
    $eh->register_action('asterisk', 'write');   # force a write
    $eh->register_task('asterisk', 'write', \&asterisk_write);

    $eh->register_action('asterisk', 'restart'); # force a restart
}

sub unload { }

sub sip_add
{
    my $cfg = shift;
    my $opts = shift;

    # It may seem silly to copy all the options from $opts to %user but
    # this will give me an opportunity to sanitize the values if I choose
    # and not give more information to the backend than is needed.
    # I also want to avoid building a dependance on Getopt::Long by
    # the backends which, really, have no need to even know that we're
    # using Getopt::Long. In fact, we may not be using Getopt::Long if
    # I ever get around to building a web version of vuser.
    my %user = ();
    for my $item qw(name username secret context ipaddr port
		    regseconds callerid restrictcid mailbox) {
	$user{$item} = $opts->{$item};
    }

    $user{context} = VUser::ExtLib::strip_ws($cfg->{Extension_asterisk}{'default context'}) unless $user{context};

    $user{secret} = VUser::ExtLib::generate_password unless $user{secret};
    $user{regseconds} = 0 if not defined $user{regseconds};
    $user{restrictcid} = 1 if not defined $user{restrictcid};
    $user{port} = 0 unless defined $user{port};
    $user{callerid} = '' unless defined $user{callerid};
    $user{mailbox} = '' unless defined $user{mailbox};
    $user{ipaddr} = 'dynamic' unless defined $user{ipaddr};

    if ($backends{sip}->sip_exists($user{name}, $user{context})) {
	die "Can't add SIP user $user{name}\@$user{context}: User exists\n";
    }

    $backends{sip}->sip_add(%user);
}

sub sip_del
{
    my $cfg = shift;
    my $opts = shift;

    my %user = ();
    $user{name} = $opts->{name};
    $user{context} = $opts->{context};

    $user{context} = VUser::ExtLib::strip_ws($cfg->{Extension_asterisk}{'default context'}) unless $user{context};

    $backends{sip}->sip_del(%user);
}

sub sip_mod
{
    my $cfg = shift;
    my $opts = shift;

    my %user = ();
    for my $item qw(name username secret context ipaddr port
		    regseconds callerid restrictcid mailbox
		    newname newcontext
		    ) {
	$user{$item} = $opts->{$item};
    }

    $user{context} = VUser::ExtLib::strip_ws($cfg->{Extension_asterisk}{'default context'}) unless $user{context};

    if ($user{newcontext} or $user{newname}) {
	my ($nname, $ncontext) = ($user{name}, $user{context});
	$nname = $user{newname} if $user{newname};
	$ncontext = $user{newcontext} if $user{newcontext};
	if ($backends{sip}->sip_exists($nname, $ncontext)) {
	    die "Can't raname SIP user from $user{name}\@$user{context} to $nname\@$ncontext: SIP user exists\n";
	}
    }

    $backends{sip}->sip_mod(%user);
}

sub sip_show
{
    my $cfg = shift;
    my $opts = shift;

    my $name = '%';
    my $context = '%';
    my $pretty = 0;

    $name = $opts->{name} if defined($opts->{name});
    $context = $opts->{context} if defined($opts->{context});
    $pretty = 1 if defined ($opts->{pretty});

    my @users = $backends{sip}->sip_get($name, $context);

    foreach my $user (@users) {
	if ($pretty) {
	    printf(  "       Name: %20s Context: %20s\n"
		     ."     Secret: %20s  VM Box: %20s\n"
		     ."%1s Caller ID: %s\n"
		     ." IP Address: %20s    Port: %5s Reg. Sec: %s\n"
		     , $user->{name}, $user->{context},
		     $user->{secret}, $user->{mailbox},
		     $user->{restrictcid}? '*' : ' ', $user->{callerid},
		     $user->{ipaddr}, $user->{port}, $user->{regseconds}
		     );
	} else {
	    print(join (':', map { $_ = '' unless defined $_; $_; }	
			@{$user}{qw(name context username secret ipaddr
				    port regseconds callerid restrictcid
				    mailbox)}
			)
		  );
	    print "\n";
	}
    }
}

sub sip_write
{
    my $cfg = shift;
    my $opts = shift;

    my @users = $backends{sip}->sip_get('%', '%');

    unless (open (CONF, '>'.$cfg->{Extension_asterisk}{etc}.'/'
		  .$cfg->{Extension_asterisk}{'sip.conf'})
	    ) {
	die "Can't open ".$cfg->{Extension_asterisk}{etc}.'/'
	  .$cfg->{Extension_asterisk}{'sip.conf'}.": $!\n";
    }

    print CONF VUser::ExtLib::edit_warning(';');

    foreach my $user (@users) {
	print CONF '['.$user->{name}."]\n";
	print CONF "type=friend\n";
	print CONF "username=".$user->{username}."\n" if $user->{username};
	print CONF "secret=".$user->{secret}."\n" if $user->{secret};

	my $context = $user->{context};
	$context = $cfg->{Extension_asterisk}{'default context'} unless $context;
	print CONF "context=$context\n";

	print CONF "ipaddr=".$user->{ipaddr}."\n" if $user->{ipaddr};
	print CONF 'port='.$user->{port}."\n" if $user->{port};
	print CONF 'regseconds='.$user->{regseconds}."\n" if $user->{regseconds};
	print CONF 'callerid='.$user->{callerid}."\n" if $user->{callerid};

	# restrictcid can be 0
	print CONF 'restrictcid='.$user->{restrictcid}."\n" if defined $user->{restrictcid};
	print CONF 'mailbox='.$user->{mailbox}."\n" if $user->{mailbox};
	print CONF "\n";
    }

    close CONF;
}

sub iax_add {}
sub iax_del {}
sub iax_mod {}
sub iax_write {}

sub ext_add
{
    my $cfg = shift;
    my $opts = shift;

    my %ext = ();
    for my $item qw(context extension priority application args descr flags) {
	$ext{$item} = $opts->{$item};
    }

    $ext{context} = VUser::ExtLib::strip_ws($cfg->{Extension_asterisk}{'default context'}) unless $ext{context};
    $ext{flags} = 1 unless defined $ext{flags};
    $ext{application} = '' unless defined $ext{application};

    $ext{priority} = 1 unless defined $ext{priority} and $ext{priority} >= 1;

    if ($backends{ext}->ext_exists($ext{extension},
				  $ext{context},
				  $ext{priority})) {
	die "Can't add extension $ext{name}\@$ext{context} ($ext{priority}: Extension exists\n";
    }

    $backends{ext}->ext_add(%ext);
}

sub ext_del
{
    my $cfg = shift;
    my $opts = shift;

    my %ext = ();
    $ext{extension} = $opts->{extension};
    $ext{context} = $opts->{context};
    $ext{priority} = $opts->{priority};

    $ext{context} = VUser::ExtLib::strip_ws($cfg->{Extension_asterisk}{'default context'}) unless $ext{context};
    $ext{priority} = 1 unless defined $ext{priority};

    $backends{sip}->ext_del(%ext);
}

sub ext_mod
{
    my $cfg = shift;
    my $opts = shift;

    my %ext = ();
    for my $item qw(context extension priority application args descr flags
		    newextension newcontext newpriority
		    ) {
	$ext{$item} = $opts->{$item};
    }

    $ext{context} = VUser::ExtLib::strip_ws($cfg->{Extension_asterisk}{'default context'}) unless $ext{context};
    $ext{flags} = 1 unless defined $ext{flags};

    if ($ext{newcontext} or $ext{newextension} or $ext{newpriority}) {
	my ($next, $ncontext) = ($ext{extension}, $ext{context});
	$next = $ext{newextension} if $ext{newextension};
	$ncontext = $ext{newcontext} if $ext{newcontext};
	my $npriority = $ext{newpriority} if $ext{newpriority};

	if ($backends{ext}->ext_exists($next, $ncontext, $npriority)) {
	    die "Can't raname extension from $ext{extension}\@$ext{context} ($ext{priority} to $next\@$ncontext ($npriority): Extension exists\n";
	}
    }

    $backends{sip}->ext_mod(%ext);
}

sub ext_show
{
    my $cfg = shift;
    my $opts = shift;

    my $ext = '%';
    my $context = '%';
    my $priority = '%';
    my $pretty = 0;

    $ext = $opts->{extension} if defined($opts->{extension});
    $context = $opts->{context} if defined($opts->{context});
    $priority = $opts->{priority} if defined($opts->{priority});
    $pretty = 1 if defined ($opts->{pretty});

    my @exts = $backends{ext}->ext_get($ext, $context, $priority);

    if ($pretty) {
	# TODO: Fill this in later
    } else {
	foreach my $exten (@exts) {
	    print( join (':', map { $_ = '' unless defined $_; $_; }
			 @{$exten}{qw(extension context priority
				      application args descr flags)}
			 )
		   );
	    print "\n";
	}
    }
}

sub ext_write
{
    my $cfg = shift;
    my $opts = shift;

    my %exts;
    foreach my $ext ($backends{ext}->ext_get('%', '%', '%'))
    {
	if (not exists $exts{$ext->{context}}) {
	    $exts{$ext->{context}} = [];
	}

	push @{$exts{$ext->{context}}}, $ext;
    }


    unless (open (CONF, '>'.$cfg->{Extension_asterisk}{etc}.'/'
		  .$cfg->{Extension_asterisk}{'extensions.conf'})
	    ) {
	die "Can't open ".$cfg->{Extension_asterisk}{etc}.'/'
	  .$cfg->{Extension_asterisk}{'extentions.conf'}.": $!\n";
    }

    print CONF VUser::ExtLib::edit_warning(';');

    foreach my $context (keys %exts) {
	print CONF "[$context]\n";
	foreach my $ext (@{$exts{$context}}) {
	    next if $ext->{flags} == 0;
	    print CONF 'exten => '.$ext->{extension};
	    print CONF ','.$ext->{priority};
	    print CONF ','.$ext->{application};
	    print CONF '('.$ext->{args}.')' if defined $ext->{args};
	    print CONF "\t" unless defined $ext->{args};
	    print CONF "\t; ".$ext->{descr} if defined $ext->{descr};
	    print CONF "\n";
	}
	print CONF "\n";
    }

    close CONF;
}

sub vm_add
{
    my $cfg = shift;
    my $opts = shift;

    my %box = ();
    for my $item qw(context mailbox password fullname email pager options) {
	$box{$item} = $opts->{$item};
    }

    $box{context} = VUser::ExtLib::strip_ws($cfg->{Extension_asterisk}{'default context'}) unless $box{context};
    $box{password} = VUser::ExtLib::generate_password(4, (0..9))
	unless $box{password};
    $box{email} = '' unless $box{email};
    $box{pager} = '' unless $box{pager};
    $box{options} = '' unless $box{options};
    $box{fullname} = '' unless $box{fullname};

    if ($backends{vm}->vm_exists($box{mailbox}, $box{context})) {
	die "Can't add VM box $box{mailbox}\@$box{context}: VM box exists\n";
    }

    $backends{vm}->vm_add(%box);
}

sub vm_create_box
{
    my $cfg = shift;
    my $opts = shift;

    my $spool = VUser::ExtLib::strip_ws($cfg->{Extension_asterisk}{'vm spool'});
    my $sounds = VUser::ExtLib::strip_ws($cfg->{Extension_asterisk}{'vm sounds'});
    my $vm_user = VUser::ExtLib::strip_ws($cfg->{Extension_asterisk}{'vm user'});
    my $vm_group = VUser::ExtLib::strip_ws($cfg->{Extension_asterisk}{'vm group'});

    my %box = ();
    for my $item qw(context mailbox password fullname email pager options) {
	$box{$item} = $opts->{$item};
    }

    $box{context} = VUser::ExtLib::strip_ws($cfg->{Extension_asterisk}{'default context'}) unless $box{context};

    VUser::ExtLib::mkdir_p ("$spool/$box{context}/$box{mailbox}",
			    0755, $vm_user, $vm_group);

    # Adapted from addmailbox from the asterisk package
    `cat $sounds/vm-theperson.gsm > $spool/$box{context}/$box{mailbox}/unavail.gsm`;
    `cat $sounds/vm-theperson.gsm > $spool/$box{context}/$box{mailbox}/busy.gsm`;
    `cat $sounds/vm-extension.gsm > $spool/$box{context}/$box{mailbox}/greet.gsm`;
    my @nums = split '', $box{mailbox};
    foreach my $num (@nums) {
	`cat $sounds/digits/$num.gsm >> $spool/$box{context}/$box{mailbox}/unavail.gsm`;
	`cat $sounds/digits/$num.gsm >> $spool/$box{context}/$box{mailbox}/busy.gsm`;
	`cat $sounds/digits/$num.gsm >> $spool/$box{context}/$box{mailbox}/greet.gsm`;
    }
    `cat $sounds/vm-isunavail.gsm >> $spool/$box{context}/$box{mailbox}/unavail.gsm`;
    `cat $sounds/vm-isonphone.gsm >> $spool/$box{context}/$box{mailbox}/busy.gsm`;
}

sub vm_del
{
    my $cfg = shift;
    my $opts = shift;

    my %box = ();
    for my $item qw(context mailbox password fullname email pager options) {
	$box{$item} = $opts->{$item};
    }

    $box{context} = VUser::ExtLib::strip_ws($cfg->{Extension_asterisk}{'default context'}) unless $box{context};

    $backends{vm}->vm_del(%box);
}

sub vm_rm_box
{
    my $cfg = shift;
    my $opts = shift;

    my $spool = VUser::ExtLib::strip_ws($cfg->{Extension_asterisk}{'vm spool'});
    my %box = ();
    for my $item qw(context mailbox password fullname email pager options) {
	$box{$item} = $opts->{$item};
    }

    $box{context} = VUser::ExtLib::strip_ws($cfg->{Extension_asterisk}{'default context'}) unless $box{context};

    eval { VUser::ExtLib::rm_r("$spool/$box{context}/$box{mailbox}") };
    die "$@\n" if $@;
}

sub vm_mod
{
    my $cfg = shift;
    my $opts = shift;

    my %box = ();
    for my $item qw(context mailbox password fullname email pager options
		    newcontext newmailbox) {
	$box{$item} = $opts->{$item};
    }

    $box{context} = VUser::ExtLib::strip_ws($cfg->{Extension_asterisk}{'default context'}) unless $box{context};

    if ($box{newcontext} or $box{newmailbox}) {
	my ($nbox, $ncontext) = ($box{mailbox}, $box{context});
	$nbox = $box{newmailbox} if $box{newmailbox};
	$ncontext = $box{newcontext} if $box{newcontext};
	if ($backends{vm}->ext_exists($nbox, $ncontext)) {
	    die "Can't raname VM box from $box{mailbox}\@$box{context} to $nbox\@$ncontext: VM box exists\n";
	}

	# We need to rename the mailbox.
	my $spool = VUser::ExtLib::strip_ws($cfg->{Extension_asterisk}{'vm spool'});
	my $vm_user = VUser::ExtLib::strip_ws($cfg->{Extension_asterisk}{'vm user'});
	my $vm_group = VUser::ExtLib::strip_ws($cfg->{Extension_asterisk}{'vm group'});

	VUser::ExtLib::mkdir_p("$spool/$ncontext", 0755, $vm_user, $vm_group);
	if ($box{mailbox} ne $nbox) {
	    rename("$spool/$box{context}/$box{mailbox}",
		   "$spool/$ncontext/$nbox") or
		       die "Unable to move vm dir: $!\n";
	}
    }

    $backends{vm}->vm_mod(%box);

}

sub vm_show
{
    my $cfg = shift;
    my $opts = shift;

    my $box = '%';
    my $context = '%';
    my $pretty = 0;

    $box = $opts->{mailbox} if defined $opts->{mailbox};
    $context = $opts->{context} if defined($opts->{context});
    $pretty = 1 if defined $opts->{pretty};

    my @boxes = $backends{vm}->vm_get($box, $context);

    if ($pretty) {
	# TODO: fill this in
    } else {
	foreach my $vmbox (@boxes) {
	    print(join (':', map { $_ = '' unless defined $_; $_;}
			@{$vmbox}{qw(mailbox context password fullname
				     email pager options stamp)}
			)
		  );
	    print "\n";
	}
    }
}

sub vm_write
{
    my $cfg = shift;
    my $opts = shift;

    my %vms;
    foreach my $vm ($backends{vm}->vm_get('%', '%'))
    {
	if (not exists $vms{$vm->{context}}) {
	    $vms{$vm->{context}} = [];
	}

	push @{$vms{$vm->{context}}}, $vm;
    }

    unless (open (CONF, '>'.$cfg->{Extension_asterisk}{etc}.'/'
		  .$cfg->{Extension_asterisk}{'voicemail.conf'})
	    ) {
	die "Can't open ".$cfg->{Extension_asterisk}{etc}.'/'
	  .$cfg->{Extension_asterisk}{'voicemail.conf'}.": $!\n";
    }

    print CONF VUser::ExtLib::edit_warning(';');

    foreach my $context (keys %vms) {
	print CONF "[$context]\n";
	foreach my $vm (@{$vms{$context}}) {
	    print CONF $vm->{mailbox}.' => '.$vm->{password};
	    print CONF ','.$vm->{fullname};
	    print CONF ','.$vm->{email};
	    print CONF ','.$vm->{pager};
	    print CONF ','.$vm->{options} if $vm->{options};
	    print CONF "\n";
	}
	print CONF "\n";
    }

    close CONF;
}

sub asterisk_write
{
    sip_write(@_);
#    iax_write(@_);
    ext_write(@_);
    vm_write(@_);
}

1;

__END__

=head1 NAME

asterisk - vuser asterisk support extension

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
