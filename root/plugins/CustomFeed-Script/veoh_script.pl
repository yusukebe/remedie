#!/usr/bin/perl

use strict;
use warnings;
use Encode::JavaScript::UCS;
use Encode;
use LWP::UserAgent;
use URI;
use YAML;
use Web::Scraper;
use Perl6::Say;

my $query = shift || "haruhi";
my $uri = URI->new("http://www.veoh.com/dwr/exec/ajaxMethodHandler.solrSearch.dwr");
my $ua = LWP::UserAgent->new;
$uri->query_form(%{param()});
my $res = $ua->get($uri);
die unless $res->is_success;

my $html = $res->content;
$html =  decode("JavaScript-UCS", $html);

if($html =~ /s4="(.+?)";s0/){
    $html = $1;
    $html =~ s/\\\"/\"/g;
}

my $scraper = scraper {
    process "a.vTitle", "title[]" => 'TEXT';
    process "a.vTitle", "link[]" => '@href';
    process "img.vThumb", "thumb[]" => '@src';
    result "title", "link", "thumb";
};

$res = $scraper->scrape($html);

my @entries;
my $count = 0;
for my $title ( @{ $res->{title} } ) {
    if ( $res->{link}[$count] =~ m!/videos/(.+?)\?! ) {
        my $video_id  = $1;
        my $permalink = "http://www.veoh.com/videos/$video_id";
        my $embed_url =
"http://www.veoh.com/veohplayer.swf?permalinkId=$video_id&id=anonymous&player=videodetailsembedded&videoAutoPlay=1";
	my $thumb_url = $res->{thumb}[$count];
        my $enclosure = [
            { url => $thumb_url, type => 'image/jpg'  },
            { url => $embed_url, type => "application/x-shockwave-flash" },
        ];
        push( @entries,
            { title => Encode::encode("utf8",$title), link => $permalink,
	      enclosure => $enclosure } );
    }
    $count++;
}

print Dump {
    title => "Search Results for: \"$query\" | Veoh Video Network",
    link  => "http://www.veoh.com/search.html?type=v&search=$query",
    entry => \@entries
};

sub param {
    my %param;
    my @p = qw{
callCount=1
c0-scriptName=ajaxMethodHandler
c0-methodName=solrSearch
c0-id=dummy
c0-param0=string:
c0-param1=string:v
c0-param2=string:searchResultsHolder
c0-param3=string:%2FWEB-INF%2Fpages%2Fsnippets%2FajaxSearch.jsp
c0-param4=number:20
c0-param5=boolean:true
c0-param6=string:mr
c0-param7=string:a
c0-param8=number:0
c0-param9=null:null
c0-param10=string:
c0-param11=string:
c0-param12=string:
c0-param13=number:0
c0-param14=string:thumb
c0-param15=string:dummy
c0-param16=boolean:false
c0-param17=number:-1
c0-param18=number:-1
xml=true
};
    for my $p (@p) {
        $p =~ /(.+)=(.+)/;
        $param{$1} = $2;
        $param{$1} = "string:$query" if ( $1 eq "c0-param0" );
    }
    return \%param;
}

