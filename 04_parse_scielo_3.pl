#!/usr/bin/env perl

use strict;
use warnings;
use File::Find;
use Data::Dumper;
use HTML::TreeBuilder;
use LWP::UserAgent;
use Cwd;

my @file_list = ();
my $curr_dir  = &cwd();

find( \&process , "$curr_dir/html_pdf" );

my $agent    = LWP::UserAgent->new();
my $response = undef;
my $counter  = 0;

open( my $wget , '>' , "$curr_dir/wget_list.sh" );

foreach my $file (sort @file_list){
   print "Processing $file\n";
   my $parser  = HTML::TreeBuilder->new_from_file( $file );
   my $title   = ($parser->look_down('_tag' , 'title'))->as_text();
   my @meta    = $parser->look_down('_tag' , 'meta');
   my $script  = ($parser->look_down('_tag' , 'script'))[0];
   my $id = $1 if ( $title =~ /ID(.+)$/);

   #for some we don't have the pdf
   next if( $title eq 'SciELO Error' );

   if( $id ){
     print "Got ID $id\n";
     my $script_text = $script->as_HTML();

     my $link = $1 if( $script_text =~ /(http:\/\/.+?\.pdf)/i );
     
     print $wget qq{/usr/bin/wget -c -t0 "$link" -O "$curr_dir/pdf/$id.pdf" -a $curr_dir/wget.log\n}
            unless( -f "$curr_dir/pdf/$id.pdf" )
   };

#   foreach my $tag ( @meta ){
#     if( $tag->attr('name') && $tag->attr('name') eq 'added' ){
#       my $pdf = $tag->attr('content');
#          $pdf =~ s/^.+?URL=//;
#       print $wget qq{/usr/bin/wget -c -t0 "$pdf" -O "/data/wok/scielo_unicamp/pdf/$id.pdf" -a /data/wok/scielo_unicamp/wget.log\n}
#         unless ( -f "/data/wok/scielo_unicamp/pdf/$id.pdf" );
#       
#     };
#   };
   
   $parser->delete();
};

close( $wget );
exit(0);

sub process{
   my $file_and_path = $File::Find::name;

   if( -f $file_and_path ){
     push( @file_list , $file_and_path );
   };
};
