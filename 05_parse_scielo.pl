#!/usr/bin/env perl

use strict;
use warnings;
use File::Find;
use Data::Dumper;
use XML::LibXML;
use XML::Simple;
use Cwd;

my @file_list = ();
my $head      = 0;
my $curr_dir  = &cwd();

find( \&process , "$curr_dir/xml" );

my $counter  = 0;

open( my $target , '>' , 'registros_scielo.csv' );
foreach my $file (sort @file_list){
   print "Processing $file\n"; 
   my $parser = XML::LibXML->new();
   my $doc    = ($parser->parse_file( $file )->findnodes('//front'))[0];

   my $issn               = get_content($doc , '//journal-meta/issn',0);
   my $journal_title      = get_content($doc , '//journal-meta/journal-title',0);
   my $journal_title_abbr = get_content($doc , '//journal-meta/abbrev-journal-title',0);
   my $publisher          = get_content($doc , '//journal-meta/publisher/publisher-name',0);
   my $id                 = get_content($doc , '//article-meta/article-id',0);
   my $doi                = get_content($doc , '//article-meta/article-id',1);
   my $lang               = "";

   my $year               = get_content($doc , '//article-meta/pub-date/year',0);
   my $month              = get_content($doc , '//article-meta/pub-date/month',0);
   my $day                = get_content($doc , '//article-meta/pub-date/day',0);
 
   my $vol                = get_content($doc , '//article-meta/volume',0);
   my $num                = get_content($doc , '//article-meta/numero',0);
   my $pages              = get_content($doc , '//article-meta/fpage',0)
                            ."-".
                            get_content($doc , '//article-meta/lpage',0);
    
   my $title              = get_content($doc , '//article-meta/title-group/article-title',0);
   my $title_alt          = get_content($doc , '//article-meta/title-group/article-title',1);

   my $authors            = "";
   my $affiliations       = "";
   my $subjects           = get_content($doc , '//article-meta/kwd-group/kwd');

   my $abstract           = get_content($doc , '//article-meta/abstract',0);

   my @contrib_group      = $doc->findnodes( '//article-meta/contrib-group/contrib' );
   my @aff_group          = $doc->findnodes( '//article-meta/aff' );

   my $uri                = "";


   foreach my $contrib ( @contrib_group ){
      if ($contrib->getAttribute("contrib-type") eq 'author'){
         my  $surname = ($contrib->getElementsByTagName('surname'))[0]->textContent()
                           if( $contrib->getElementsByTagName('surname') );

         my  $name    = ($contrib->getElementsByTagName('given-names'))[0]->textContent()
                           if( $contrib->getElementsByTagName('given-names') );
         $authors .= "$surname";
         $authors .= ", $name" if( $name );
         $authors .= "; ";
      };
   };


   foreach my $aff ( @aff_group ){
      my $inst = trim(($aff->getElementsByTagName('institution'))[0]->textContent())
                    if $aff->getElementsByTagName('institution');
     
      my $addr = trim(($aff->getElementsByTagName('addr-line'))[0]->textContent())
                    if $aff->getElementsByTagName('addr-line');

      my $count = trim(($aff->getElementsByTagName('country'))[0]->textContent())
                    if $aff->getElementsByTagName('country');

      $inst  =~ s/^\s*,\s*//;
      $inst .= ", $addr"  if $addr;
      $inst .= ", $count" if $count;

      $affiliations .= "; $inst";
   };
  
   foreach my $element ($doc->findnodes('//article-meta/self-uri')){
      $uri = $element->getAttribute('xlink:href');
      last if( $uri =~ /sci_pdf/ );
   };

   for( ($doc->findnodes('//article-meta/title-group/article-title'))[0]->getAttribute('xml:lang') ){
       /pt/ && do{ $lang = "Por."; last;};
       /en/ && do{ $lang = "Ing."; last;};
       /es/ && do{ $lang = "Esp."; last;};
   };

   $affiliations =~ s/^; //;
   $authors =~ s/; $//;
   $pages   = "" if($pages eq '-');

   $day = '01' if( $day eq '00');

   $journal_title = trim( $journal_title );

   $journal_title .= " vol. $vol" if($vol);
   $journal_title .= " n. $num" if($num);

  # print "$affiliations\n";
  # print "$title\t$title_alt\t$subjects\t$year\t$month\t$day\n";

   if( ! $head ){
   print $target "dc.id\t";
   print $target "dc.type\t";
   print $target "dc.title\t";
   print $target "dc.title.alternative\t";
   print $target "dc.language\t";

   print $target "dc.date\t";
   print $target "dc.description.extent\t";
   print $target "dc.publisher\t";
   print $target "dc.publisher.country\t";
 
   print $target "dc.creator\t";
   print $target "dc.description.affiliation\t";
   print $target "dc.contributor.researchGroup\t";

   print $target "dc.description.abstract\t";
   print $target "dc.subject\t";
   print $target "dc.subject.descriptor\t";

   print $target "dc.source.jounal\t";
   print $target "dc.source.issn\t";
   print $target "dc.relation.isPartOf\t";

   print $target "dc.description.funder\t";
   print $target "dc.description.funderId\t";

   print $target "dc.rights.license\t";
   print $target "dc.rights.rightsHolder\t";
   print $target "dc.rights.accessRights\t";

   print $target "dc.identifier\t";
   print $target "dc.identifier.doi\t";
   print $target "dc.source\n";

   $head = 1;
   }

   print $target "$id\t";
   print $target "Article\t";
   print $target "$title\t";
   print $target "$title_alt\t";
   print $target "$lang\t";

   print $target "$year-$month-$day\t";
   print $target "$pages\t";
   print $target "$publisher\t";
   print $target "\t";

   print $target "$authors\t";
   print $target "$affiliations\t";
   print $target "\t";

   print $target "$abstract\t";
   print $target "$subjects\t";
   print $target "\t";
  
   print $target "$journal_title\t";
   print $target "$issn\t";
   print $target "\t";

   print $target "\t";
   print $target "\t";

   print $target "\t";
   print $target "\t";
   print $target "\t";

   print $target "$uri\t";
   print $target "$doi\t";
   print $target "DSPACE\n";
};


exit(0);

#############################################################################

sub get_content{
  my $document = shift;
  my $path     = shift;
  my $index    = shift;
  my $result   = "";

  if( defined $index ){
    if( ($document->findnodes($path))[$index] ){
       $result = ($document->findnodes($path))[$index]->textContent();
    };
  }else{
 
    foreach my $element ($document->findnodes($path)){
      $result .= "; ".$element->textContent();
    };
  };
  
  $result =~ s/^; //;

  return( $result ); 
}
#############################################################################
sub process{
   my $file_and_path = $File::Find::name;

   if( -f $file_and_path ){
     push( @file_list , $file_and_path );
   };
};

sub trim{
   my $str = shift;

   return("") unless defined $str;

   $str =~ s/^\s+//;
   $str =~ s/\s+$//;

   return( $str );
};
