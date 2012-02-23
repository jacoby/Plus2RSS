#!/usr/bin/env perl

use 5.010 ;
use strict ;
use Carp ;
use Data::Dumper ;
use Getopt::Long ;
use IO::Interactive qw{ interactive } ;
use JSON ;
use LWP::UserAgent ;
use LWP::Protocol::https ;
use XML::Parser ;
use XML::RSS ;
use YAML qw{ LoadFile DumpFile } ;
use subs qw{ webGet handle_plus } ;

my $debug = 0 ;
my $config = config() ;
handle_plus( $config ) ;
exit ;

# ========= ========= ========= ========= ========= ========= =========
# give it a URL, get back the download
# --------- --------- --------- --------- --------- --------- ---------
sub handle_plus {
    my ( $config ) = shift ;
    my $api_base_url =  'https://www.googleapis.com/plus/v1/' ;
    my $dispatch = {
        get_activities => 'people/USER_ID/activities/public' ,
        } ;
    my $api_url = $api_base_url .
        $dispatch->{ get_activities } .
        '?key=' . $config->{ google_api_key } .
        '&alt=json'
        ;
    my $user_id = $config->{ google_user_id } ;
    $api_url =~ s/USER_ID/$user_id/ ;

    my $data = webGet $api_url ;
    my $json = decode_json $data ;
    my $output_feed = XML::RSS->new( version=> '2.0' ) ;
    $output_feed->channel(
        title => $json->{ title } ,
        link  => $json->{ selfLink } ,
        description  => 'From my made-myself Plus2RSS Feed',
        ) ;
    my $items = $json->{ items } ;
    for my $item ( @$items ) {
        my $title = $item->{ title } ;
        my $desc = $item->{ object }->{ content } ;
        my $link = $item->{ url } ;
        my $pubDate = $item->{ published } ;
        $output_feed->add_item(
            title => $title ,
            link => $link ,
            description => $desc ,
            pubDate => $pubDate ,
            ) ;
        }
    say $output_feed->as_string ;
    }
# --------- --------- --------- --------- --------- --------- ---------

# ========= ========= ========= ========= ========= ========= =========
# give it a URL, get back the download
# --------- --------- --------- --------- --------- --------- ---------
sub webGet {
  my $url = shift ;
  my $agent         = new LWP::UserAgent ;
     #$agent->timeout(60) ;
  my $request       = new HTTP::Request('GET',$url) ;
  my $response      = $agent->request($request) ;
  my $status = $response->as_string ;
  $debug and print qq(<getting url="$url">\n) ;
  if ( $response->is_success ) {
    my $content =  $response->content ;
    $debug and print qq(<get result="success">\n) ;
    $debug and print qq(<get result="$status">\n) ;
    return $content ;
    }
  else {
    $debug and print qq(<get result="$status">\n) ;
    return undef ;
    }
  }
# --------- --------- --------- --------- --------- --------- ---------

# ========= ========= ========= ========= ========= ========= =========
# handle configuration
# --------- --------- --------- --------- --------- --------- ---------
sub config {
    my $config_file = $ENV{ HOME } . '/.plus2rss.yml' ;
    my $config ;
    if ( $config_file && -f $config_file ) {
        $config = LoadFile( $config_file ) ;
        }
    return $config ;
    }
# --------- --------- --------- --------- --------- --------- ---------
