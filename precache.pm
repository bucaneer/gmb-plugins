# Gmusicbrowser: Copyright (C) 2005-2015 Quentin Sculo <squentin@free.fr>
# Precache plugin: Copyright (C) 2015 Justas Lavišius <bucaneer@gmail.com>
#
# This file is part of Gmusicbrowser.
# Gmusicbrowser is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3, as
# published by the Free Software Foundation

=gmbplugin PRECACHE
name	Cache next song
title	Cache next song
desc	Caches next song in the playlist into virtual memory.
req		exec(/vmtouch)
=cut

package GMB::Plugin::PRECACHE;
use strict;
use utf8;
use warnings;
use POSIX ':sys_wait_h';

use constant
{	OPT	=> 'PLUGIN_PRECACHE_',
};

::SetDefaultOptions(OPT, 'cachesize'=>5, 'usepage'=>1, 'cmd'=>'vmtouch', 'args'=>'-qlt');
my $watcher;
my $curfile;
my $pid;
my $pagemode;
my @deathlist;

sub precache
{	return if $curfile && $::NextFileToPlay && $::NextFileToPlay eq $curfile;
	$curfile = $::NextFileToPlay;
	kill_pid();
	return unless $curfile;
	
	my $size = $::Options{OPT.'cachesize'};
	my @cmd = split(/ /, $::Options{OPT.'cmd'});
	push @cmd, ("-p", "${size}M") if $pagemode && $::Options{OPT.'usepage'};
	push @cmd, (split(/ /, $::Options{OPT.'args'}), $curfile);
	$pid=fork;
	if ($pid==0)
	{	exec @cmd or print STDERR "PRECACHE: couldn't exec: $!\n";
	}
	print "PRECACHE: Cached $size MB of $curfile\n" if $::debug;
}

sub check_pagemode
{	for (qx($::Options{OPT.'cmd'} 2>&1))
	{	if (m/^vmtouch v(\d+)\.(\d+).(\d+)/ && ($1 > 1 || $2 > 0 || $3 >= 1))
		{	return 1;
		}
	}
	return 0;
}

sub kill_wait
{	waitpid(-1,WNOHANG);
	@deathlist = grep kill(0,$_), @deathlist;
	return 0 unless @deathlist;
	kill 'KILL' => @deathlist;
}

sub kill_pid
{	return unless $pid;
	kill 'INT', $pid;
	push @deathlist, $pid;
	Glib::Timeout->add(100, \&kill_wait);
	undef $pid;
}

sub Start
{	$watcher = {};
	$pagemode = check_pagemode();
	::Watch($watcher,'NextSongs', \&precache);
	::Watch($watcher, 'Quit', \&kill_pid);
}

sub Stop
{	::UnWatch($watcher,'NextSongs');
	::UnWatch($watcher, 'Quit');
	kill_pid();
}

sub prefbox {
	my $vbox=Gtk2::VBox->new;
	my $cmd = ::NewPrefEntry(OPT.'cmd',_"vmtouch executable:");
	my $args = ::NewPrefEntry(OPT.'args',_"vmtouch options:");
	my $vbox_page=Gtk2::VBox->new;
	my $spin_size = ::NewPrefSpinButton(OPT.'cachesize',1,500, step=>1, page=>5, text=>_"Cache size (MB): ");
	my ($radio_full, $radio_page) = ::NewPrefRadio(OPT.'usepage', 
		[_"Cache entire file" => 0, _"Cache start of file (recommended)" => 1],
		cb=>sub{$spin_size->set_sensitive($::Options{OPT.'usepage'})});
	$radio_page->set_tooltip_text(_"Requires vmtouch v1.0.1 or newer");
	$spin_size->set_sensitive($::Options{OPT.'usepage'});
	$vbox_page->pack_start($_,::FALSE,::FALSE,2) for $radio_page, $spin_size;
	$vbox_page->set_sensitive($pagemode);
	
	$vbox->pack_start($_,::FALSE,::FALSE,2)
		for $cmd, $args, Gtk2::HSeparator->new, $radio_full, $vbox_page;
	return $vbox;
}

1
