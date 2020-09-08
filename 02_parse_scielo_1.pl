#!/usr/bin/env perl

use strict;
use warnings;
use File::Find;
use Data::Dumper;
use HTML::TreeBuilder;
use LWP::UserAgent;
use Cwd;

my $curr_dir = &cwd();
my $base_url  = 'http://www.scielo.br/scieloOrg/php/articleXML.php?pid=';
my @file_list = ();

find( \&process , "$curr_dir/html" );

my $agent    = LWP::UserAgent->new();
my $response = undef;
my $counter  = 0;

open( my $rec_list , '>' , 'lista_artigos.csv' );
foreach my $file (sort @file_list){

   my $parser  = HTML::TreeBuilder->new_from_file( $file );
   my $form    = ($parser->look_down('_tag', 'form' ))[0];
   my @centers = $form->look_down('_tag' , 'center');
   my %pids    = ();
   
   #Remove the slices we don't need
   shift( @centers );
   shift( @centers );

   pop( @centers );
   pop( @centers );
   pop( @centers );
   pop( @centers );
   pop( @centers );
   pop( @centers );

   foreach my $center (@centers){
      my $table = ($center->look_down('_tag','table'))[2];
      next unless( $table );
      
      my @links = $table->look_down('_tag','a');
      my $font  = ($table->look_down('_tag','font'))[0];
      my $pid   = "";
      my $div   = $font->look_down('_tag','div');

      #$div->delete();

      #print $font->as_text(),"\n";

      foreach my $link (@links){
        #print $link->attr('href'),"\n";
        $pid = $1 if($link->attr('href') && $link->attr('href') =~ /pid=(.+?)&/);
        $pid = '**SEM PID**' unless( $pid );
        if( $pid ){
           $div->delete() if ($div);
           print $rec_list "$pid\t",$font->as_text(),"\n";;

           if($pid ne '**SEM PID**'){

            unless( -f "$curr_dir/xml/$pid.xml" ){
               do{
                    $response = $agent->get("$base_url$pid&lang=en");
                    if($response->is_success()){
                       open( my $xml , '>' , "$curr_dir/xml/$pid.xml" );
                       print $xml $response->content();
                       close( $xml );
                    }else{ print $response->status_line, "\n"; };
                    sleep(2);

               }while( $response->is_error );
             };

           };
           $counter++;
           print "Got $counter\n";
           last;
        };
      };
   };
#   exit(0);

   $parser->delete();
};
close( $rec_list );
exit(0);

sub process{
   my $file_and_path = $File::Find::name;

   if( -f $file_and_path ){
     push( @file_list , $file_and_path );
   };
};
