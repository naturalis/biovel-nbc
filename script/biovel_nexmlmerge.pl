#!/usr/bin/perl
use strict;
use warnings;
use Bio::BioVeL::Service::NeXMLMerger;
my $merger = Bio::BioVeL::Service::NeXMLMerger->new;
print $merger->response_header;
print $merger->response_body;