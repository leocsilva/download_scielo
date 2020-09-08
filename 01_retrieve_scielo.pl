#!/usr/bin/env perl
##################################################################
#
# Description : Harvest records from Scielo
#
# Author      : Oberdan Luiz May
#
# Start date  : 2013-06-10
#
#################################################################
use strict;
use warnings;
use Cwd;
use Data::Dumper;
use LWP::UserAgent;
use URI::QueryParam;
use HTML::TreeBuilder;

my $agent    = LWP::UserAgent->new();
my $response = undef;
my $doc      = undef;

my $from     = 1;
my $counter  = '00001';

my %form     = (  'IsisScript'       => 'iah/iah.xis',
                  'environment'      => '^d/iah/^c/var/www/scielo_br/cgi-bin/iah/^b/var/www/scielo_br/bases/^mOFF^siah/iah.xis^v2.4',
                  'availableFormats' => ['niso.pft^pISO 690^eISO 690^iISO 690',
                                         'nabn.pft^pABNT NBR 6023/89^eABNT NBR 6023/89^iABNT NBR 6023/89',
                                         '^nvan.pft^pVancouver^eVancouver^iVancouver',
                                         '^nDEFAULT^fiso.pft'],
                  'apperance'        => '^cwhite^i^tblack^lblue^b#B0C2D5^esuporte.aplicacao@scielo.org^rON^mON',
                  'helpInfo'         => '^nNOTE FORM F^vnota_form1_scielo.htm',
                  'gizmoDecod'       => '',
                  'avaibleForms'     => 'B,F',
                  'logoImage'        => 'scielog.gif',
                  'logoURL'          => 'www.scielo.br',
                  'headerImage'      => '^ponlinep.gif^eonlinee.gif^ionlinei.gif',
                  'headerURL'        => 'www.scielo.br',
                  'form'             => 'B',
                  'pathImages'       => '/iah/I/image/',
                  'navBar'           => 'OFF',
                  'isisFrom'         => 1,
                  'hits'             => 10,
                  'format'           => 'iso.pft',
                  'lang'             => 'i',
                  'user'             => 'GUEST',
                  'baseFeatures'     => '^k_KEY^eON',
                  'nextAction'       => 'search',
                  'base'             => 'article^dlibrary',
                  'conectSearch'     => ['init','and','and'],
                  'exprSearch'       => ['UNIVERSIDADE ESTADUAL PAULISTA JULIO DE MESQUITA FILHO','2014',''],
                  'indexSearch'      => ['^nOr^pAfiliação - Organização^eAfiliación - Organización^iAffiliation - Organization^xOR ^yAFORG^mOR_^rCollection',
                                         '^nYr^pAno de publicação^eAño de publicación^iPublication year^xYR ^yPREINV^uYR_^mYR_^tshort',
                                         '^nTo^pTodos os índices^eTodos los indices^iAll indexes^d*^xTO ^yFULINV'],
                  ); 

my $curr_dir = &cwd();

while( $from <= 877 ){

   #$uri->query_form( %form );
                
   #print $uri->as_string(),"\n\n";

   print "Step $counter...\n";
                   
   $response = $agent->post('http://www.scielo.br/cgi-bin/wxis.exe/iah/' , \%form );

   if( $response->is_success() ){
     open( my $html_file , '>' , "$curr_dir/html/scielo_$counter.html" );
     print $html_file $response->content();
     close( $html_file );

     $from += 10;
     $counter++;
     $form{'isisFrom'} = $from;

   }else { print $response->content() };
  
   sleep(5);

}
#$print Dumper( $uri );

exit(0);
