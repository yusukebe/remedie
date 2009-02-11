#!/usr/bin/perl
# author: Yusuke Wada
use strict;
use warnings;
use WebService::Simple;
use YAML;

my $channel_id = shift || '6212';
my $woopie = WebService::Simple->new(
    base_url        => "http://www.woopie.jp/api/getChannelVideos",
    response_parser => 'JSON',
);

my $res = $woopie->get( { id => $channel_id, count => 99, start => 0 } );
my @entries;
for my $video ( @{ $res->parse_response } ) {
    my $entry = {
        title         => $video->{title},
        author        => $video->{author},
        body          => $video->{content},
        link          => $video->{surl},
        "enclosure" => { "thumbnail" => { url => $video->{purl} }, },
    };
    push( @entries, $entry );
}

print Dump {
    title => "woopie.jp channel: $channel_id",
    link  => "http://www.woopie.jp/channel/watch/$channel_id",
    entry => \@entries
};

__END__

 usage:
   script: root/plugins/woopie.jp/channel_script.pl channel_id


