#!/usr/bin/perl
use strict;
use warnings;
use FindBin '$Bin';
use Test::More 'no_plan';

BEGIN { use_ok('Bio::BioVeL::Service::NeXMLMerger') }

my $data = "$Bin/../Examples/TaxaDataExample.nex";
my $tree = "$Bin/../Examples/TaxaTreeExample.dnd";
my $meta = "$Bin/../Examples/TaxaMetadataExample.json";
my $sets = "$Bin/../Examples/Nexus_MultiplePartitions.nex";

@ARGV = (
	'-data'          => $data,
	'-trees'         => $tree,
	'-meta'          => $meta,
	'-charsets'      => $sets,
	'-dataformat'    => 'nexus',
	'-treeformat'    => 'newick',
	'-metaformat'    => 'json',
	'-charsetformat' => 'nexus',
);

my $merger = new_ok('Bio::BioVeL::Service::NeXMLMerger');
ok( $merger->response_body );

# equivalent call in browser:
# http://biovel.naturalis.nl/biovel?service=NeXMLMerger
#    &data=https://raw.githubusercontent.com/naturalis/biovel-nbc/master/Examples/TaxaDataExample.nex
#    &trees=https://raw.githubusercontent.com/naturalis/biovel-nbc/master/Examples/TaxaTreeExample.dnd
#    &meta=https://raw.githubusercontent.com/naturalis/biovel-nbc/master/Examples/TaxaMetadataExample.json
#    &charsets=https://raw.githubusercontent.com/naturalis/biovel-nbc/master/Examples/Nexus_MultiplePartitions.nex
#    &treeformat=newick
#    &metaformat=json
#    &charsetformat=nexus
#    &dataformat=nexus
