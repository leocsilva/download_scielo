#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use LWP::UserAgent;
use Cwd;

my $base_url  = 'http://www.scielo.br/scielo.php?script=sci_pdf&pid=';
my @file_list = ();
my $curr_dir  = &cwd();

my $agent    = LWP::UserAgent->new();
my $response = undef;
my $counter  = 0;

open( my $rec_list , '<' , 'lista_artigos.csv' );
while( my $line = <$rec_list> ) {
   chomp( $line );
   
   my ($pid, $art) = split(/\t/ , $line);

   if($pid ne '**SEM PID**'){

      unless( -f "$curr_dir/html_pdf/$pid.html" ){
          do{
               $response = $agent->get("$base_url$pid&lng=en&nrm=iso&tlng=en");
               if($response->is_success()){
                  open( my $target , '>' , "$curr_dir/html_pdf/$pid.html" );
                  print $target $response->content();
                  close( $target );
               }else{ print $response->status_line, "\n"; };
               sleep(2);

          }while( $response->is_error && $response->status_line !~ /^404/ );
      };
    };
   $counter++;
   print "Got $counter\n";
};
close( $rec_list );
exit(0);

