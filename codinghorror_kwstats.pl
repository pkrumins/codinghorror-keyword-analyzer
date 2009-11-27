#!/usr/bin/perl 
#
# Peteris Krumins (peter@catonmat.net), 2008
# http://www.catonmat.net  --  good coders code, great reuse
#
# Access codinghorror.com traffic statistics and
# extract a few pages of latest search queries/keywords
#
# Released under GNU GPL
#
# 2008.04.08: Version 1.0
#

#
# run it as 'perl codinghorror_kwstats.pl [-nodb] [number of pages to extract]'
# -nodb specifies not to insert keywords in database, just print them to stdout
#

use strict;
use warnings;

use DBI;
use WWW::Mechanize;
use HTML::TreeBuilder;
use Date::Parse;

# URL to publicly available codinghorror's statcounter stats
my $login_url = 'http://my.statcounter.com/project/standard/stats.php?project_id=2600027&guest=1';

# Query used to INSERT a new keyword in the database
my $insert_query = 'INSERT OR IGNORE INTO queries (query, unix_date, human_date) VALUES (?, ?, ?)';

# Path to SQLite database
my $db_path = 'codinghorror.db';

# Insert queries in database or not? Default, yes.
my $do_db = 1;

# Number of pages of keywords to extract. Default 1.
my $pages = 1;

for (@ARGV) {
    $pages = $_ if /^\d+$/;
    $do_db = 0 if /-nodb/;
}

my $dbh;
$dbh = DBI->connect("dbi:SQLite:$db_path", '', '', { RaiseError => 1 }) if $do_db;

my $mech = WWW::Mechanize->new();
my $login_req = $mech->get($login_url);

unless ($mech->success) {
    print STDERR "Failed getting $login_url:\n";
    print STDERR $login_req->message, "\n";
    exit 1;
}

unless ($mech->content =~ /Coding Horror/i) {
    # Could not access Coding Horror's stats
    print STDERR "Failed accessing Coding Horror stats\n";
    exit 1;
}

my $kw_req = $mech->follow_link(text => 'Recent Keyword Activity');
unless ($mech->success) {
    print STDERR "Couldn't find 'Recent Keyword Activity' link";
    print $kw_req->message, "\n";
    exit 1;
}

for my $page (1..$pages) {
    my $tree = HTML::TreeBuilder->new_from_content($mech->content);
    my $td_main_panel = $tree->look_down('_tag' => 'td', 'class' => 'mainPanel');
    unless ($td_main_panel) {
        print STDERR "Unable to find '<td class=mainPanel>'";
        exit 1;
    }
    my $table = $td_main_panel->look_down('_tag' => 'table', 'class' => 'standard');
    unless ($table) {
        print STDERR "Unable to find 'table' tag";
        exit 1;
    }
    my @trs = $table->look_down('_tag' => 'tr');
    my $idx = 0;
    for my $tr (@trs) {
        next unless $idx++;
        my @tds = $tr->look_down('_tag' => 'td');
        unless (@tds == 6) {
            print STDERR "<td> count was not 6!\n";
            next;
        }
        my ($date, $time, $query) = map { $_->as_text } (@tds[1..2], $tds[4]);
        next unless $query;
        my $year = (localtime)[5] + 1900;
        my $ydt = "$date $year $time";
        my $unix_date = str2time($ydt);
        print "$date $year $time: $query\n";
        $dbh->do($insert_query, undef, $query, $unix_date, $ydt) if $do_db;
    }
    if ($page != $pages) {
        my $page_req = $mech->follow_link(text => $page + 1);
        unless ($page_req) {
            print STDERR "Couldn't find page ", $page + 1, " of keywords", "\n";
            exit 1;
        }
    }
}

#Given an HTML page ($content), finds <a href='...'> having $anchortext
#--- Not used as WWW::Mechanize has follow_link method
#sub find_link {
#    my ($content, $anchortext) = @_;
#    my $tree = tree($content);
#    $a = $tree->look_down('_tag' => 'a', sub { $_[0]->as_text =~ m/$anchortext/i });
#    return $a->attr('href') if $a;
#    return undef;
#}
#
#Given an HTML page, constructs an HTML::TreeBuilder from $content
#--- Also not used anymore
#sub tree {
#    my $content = shift;
#    my $tree = HTML::TreeBuilder->new_from_content($content);
#    return $tree
#}

