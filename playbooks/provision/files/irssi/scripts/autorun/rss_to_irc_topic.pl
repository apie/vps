# Format items in an RSS feed for use in an IRC channel topic. E.g:
# ma 18jun Hackatrain| ma 18jun UT Educational Award Ceremony| wo 20jun Lunchlezing Ricardo Rail
#
# Author: Apie
# Licence: MIT
use strict;
use warnings;
use 5.010;

use XML::FeedPP;
use File::Fetch;
use Date::Parse;
use POSIX;
use open ( ":encoding(UTF-8)", ":std" );
use vars qw($VERSION %IRSSI);
use Irssi;
($VERSION) = 1;
%IRSSI = (
  authors     => 'Apie',
  contact     => 'apie@ircnet',
  name        => 'rss_to_irc_topic',
  description => 'Format items in an RSS feed for use in an IRC channel topic. E.g: Mon 16Oct MasterCLASS Soldering Course| Tue 17Oct Lunchlecture Witteveen+Bos| Wed 18Oct Drinklecture 3T| Fri 20Oct VriMiBo (friday afternoon drink)| Thu 26Oct German Theme Drink| Fri 10Nov VriMiBo (friday afternoon drink)| Mon 13Nov Beckhoff Motion Worksh',
  license     => 'GPL',
  url         => 'https://gist.github.com/apie',
  changed     => '20231016',
);

Irssi::print("(rss_to_irc_topic.pl)");

my $url = 'https://scapiens.scintilla.utwente.nl/events/all.rss';
my $chan = '#scintilla';

my $ff = File::Fetch->new(uri => $url);
my $where = $ff->fetch( to => '/tmp' );

my $feed = XML::FeedPP->new($where, utf8_flag => 1 );
my $feed_title = $feed->title();
my @vals = ();
# Assume the feed is sorted on date and that there are no old items in the feed
foreach my $i ( $feed->get_item() ) { 
   my $title = $i->title();
   my $datestr = $i->pubDate();
   my @date = strptime($datestr);
   my $d = POSIX::strftime("%a %e%b", @date);
   $d =~ s/  / /;  # Remove double space from date
   push(@vals, join(' ', $d, $title));
}


my $server = Irssi::active_server();
my $channel = $server->channel_find($chan);
my $topic = $channel->{topic};
#truncate newtopic to 255 chars
my $newtopic = substr(join('| ', @vals), 0, 255);
if ($newtopic eq $topic) {
		Irssi::print(sprintf "rss_to_irc_topic: %s: The topic wouldn't be changed.", $chan);
		return;
}
$server->command(sprintf "TOPIC %s %s", $chan, $newtopic);
Irssi::print(sprintf "New topic for %s:", $chan);
Irssi::print($newtopic);

