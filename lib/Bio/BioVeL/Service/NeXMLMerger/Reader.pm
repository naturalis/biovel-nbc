package Bio::BioVeL::Service::NeXMLMerger::Reader;
use strict;
use warnings;
use Bio::BioVeL::Service;
use base 'Bio::BioVeL::Service';

sub new {
	my ( $class, $type ) = @_;
	
	# $class will be something like Bio::BioVeL::Service::NeXMLMerger::DataReader
	# $type will be something like FASTA
	my $subclass = $class . '::'. lc $type;
	eval "require $subclass";
	return bless {}, $subclass;
}

1;