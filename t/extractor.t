#!/usr/bin/perl
use strict;
use warnings;
use FindBin '$Bin';
use Test::More 'no_plan';

use_ok ( 'Bio::BioVeL::Service::NeXMLExtractor' );

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

# extract taxa in various formats
@ARGV = (
    '-nexml'      => $nexml,
    '-object'     => 'Taxa',
    '-dataformat' => 'tsv'
);

$extractor = new_ok ('Bio::BioVeL::Service::NeXMLExtractor');
ok( $res = $extractor->response_body );
print $res;

