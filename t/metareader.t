#!/usr/bin/perl
use strict;
use warnings;
use FindBin '$Bin';
use Test::More 'no_plan';

use_ok ( 'Bio::BioVeL::Service::NeXMLMerger::MetaReader' );


my $metaformat = 'tsv';

my $reader = Bio::BioVeL::Service::NeXMLMerger::MetaReader->new( 'tsv' );

isa_ok( $reader, 'Bio::BioVeL::Service::NeXMLMerger::MetaReader::tsv' );

open my $fh, '<', "$Bin/../Examples/TaxaMetadataExample" or die $!; 
my @rows = $reader->read_meta( $fh );

cmp_ok ( scalar(@rows), '==',  6, "number of rows in table" );

cmp_ok ( $rows[2]{'TaxonID'}, "eq", "Tax3", "right row" );
