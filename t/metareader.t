#!/usr/bin/perl
use strict;
use warnings;
use FindBin '$Bin';
use Test::More 'no_plan';

use_ok ( 'Bio::BioVeL::Service::NeXMLMerger::MetaReader' );


my $metaformat = 'tsv';

my $reader = Bio::BioVeL::Service::NeXMLMerger::MetaReader->new( 'tsv' );

isa_ok( $reader, 'Bio::BioVeL::Service::NeXMLMerger::MetaReader::tsv' );

open my $fh, '<', "$Bin/../Examples/TaxaMetadataExample.tsv" or die $!; 
my $f = $reader->read_meta( $fh );
isa_ok( $f, 'Text::CSV' );