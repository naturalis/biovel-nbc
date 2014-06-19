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
    '-object'     => 'Charset',
    '-dataformat' => 'nexus'
);

$extractor = new_ok ('Bio::BioVeL::Service::NeXMLExtractor');
ok( my $res = $extractor->response_body );
