#!/usr/bin/perl
use strict;
use warnings;
use FindBin '$Bin';
use Test::More 'no_plan';

use_ok ( 'Bio::BioVeL::Service::NeXMLExtractor' );

$SIG{__DIE__} = sub {die (shift); }; #do not print exceptions etc (to browser)


# extract trees in nexus format
my $nexml = "$Bin/../Examples/treebase-record.xml";

@ARGV = (
    '-nexml'      => $nexml,
    '-object'     => 'Trees',
    '-treeformat' => 'newick',
    '-dataformat' => 'nexus'
);


my $extractor = new_ok ('Bio::BioVeL::Service::NeXMLExtractor');
ok( my $res = $extractor->response_body );

# extract charset data in nexus format
$nexml = "$Bin/../Examples/merge.xml";

@ARGV = (
    '-nexml'      => $nexml,
    '-object'     => 'Charsets',
    '-charsetformat' => 'nexus'
);

#call in browser:
#http://biovel.naturalis.nl/biovel?service=NeXMLExtractor&nexml=https://raw.githubusercontent.com/naturalis/biovel-nbc/master/Examples/merge.xml&charsetformat=nexus&object=Charsets
$extractor = new_ok ('Bio::BioVeL::Service::NeXMLExtractor');
ok( $res = $extractor->response_body );

# extract taxa data
@ARGV = (
    '-nexml'      => $nexml,
    '-object'     => 'Taxa',
    '-dataformat' => 'tsv'
);
#call in browser:
#http://biovel.naturalis.nl/biovel?service=NeXMLExtractor&nexml=https://raw.githubusercontent.com/naturalis/biovel-nbc/master/Examples/merge.xml&dataformat=tsv&object=Taxa
$extractor = new_ok ('Bio::BioVeL::Service::NeXMLExtractor');
ok( $res = $extractor->response_body );


# test service response with nexml file over https
$nexml = "https://raw.githubusercontent.com/naturalis/biovel-nbc/master/Examples/merge.xml";
@ARGV = (
    '-nexml'      => $nexml,
    '-object'     => 'Charsets',
    '-dataformat' => 'json'
);
$extractor = new_ok ('Bio::BioVeL::Service::NeXMLExtractor');
ok ( $res = $extractor->response_body );


# test if the row ids of a matrix are correctly exported to nexus format
$nexml = "https://raw.githubusercontent.com/naturalis/biovel-nbc/master/Examples/treebase-record.xml";
@ARGV = (
	'-nexml'		=> $nexml,
	'-object'   	=> 'Matrices',
	'-dataformat' 	=> 'nexus'
);
# call in browser:
# http://biovel.naturalis.nl/biovel?service=NeXMLExtractor&nexml=https://raw.githubusercontent.com/naturalis/biovel-nbc/master/Examples/treebase-record.xml&object=Matrices&dataformat=nexus
$extractor = new_ok ('Bio::BioVeL::Service::NeXMLExtractor');
ok ( $res = $extractor->response_body );
# check if result matrix is labeled a real taxon name (and not the eternal id) 
ok ( $res=~m/Grifola/, "found taxon name in extracted matrix in nexus format");

# test extracting matrix in phylip format with test data stored on different server
$nexml = "http://biovel.naturalis.nl/exampledata/test.xml";
@ARGV = (
	'-nexml'		=> $nexml,
	'-object'   	=> 'Matrices',
	'-dataformat' 	=> 'phylip'
);
$extractor = new_ok ('Bio::BioVeL::Service::NeXMLExtractor');
ok ( $res = $extractor->response_body );
