#!/usr/bin/perl
use strict;
use warnings;
use FindBin '$Bin';
use Test::More 'no_plan';

use_ok ( 'Bio::BioVeL::Service::NeXMLExtractor' );

my $nexml = "$Bin/../Examples/treebase-record.xml";

@ARGV = (
    '-nexml'  => $nexml,
    '-object' => 'Matrices',
    '-treeformat' => 'newick',
    '-dataformat' => 'FASTA'
    );

my $extractor = new_ok ('Bio::BioVeL::Service::NeXMLExtractor');

ok( my $res = $extractor->response_body );



