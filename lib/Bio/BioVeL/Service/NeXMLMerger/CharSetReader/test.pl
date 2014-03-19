use strict;
use warnings;

use Data::Dumper;

use Bio::BioVeL::Service::NeXMLMerger::CharSetReader::nexus;
use Bio::BioVeL::Service::NeXMLMerger::CharSetReader::text;

my %result = Bio::BioVeL::Service::NeXMLMerger::CharSeyReader::nexus::readNexus("C:/Biovel/hackathon/Examples/Nexus_MultiplePartitions.nex"); 
my $example = $result{"CDS_secondPos"};
print Dumper $example;

%result = Bio::BioVeL::Service::NeXMLMerger::CharSeyReader::text::readDomainReport("C:/Biovel/hackathon/Examples/DomainReport.txt"); 
$example = $result{"2_COX1"};
print Dumper $example;
