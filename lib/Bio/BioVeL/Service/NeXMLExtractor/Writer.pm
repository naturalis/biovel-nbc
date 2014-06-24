package Bio::BioVeL::Service::NeXMLExtractor::Writer;
use strict;
use warnings;
use Bio::BioVeL::Service;
use base 'Bio::BioVeL::Service';

=head1 NAME

Bio::BioVeL::Service::NeXMLExtractor::Writer - base class for file writers

=head1 DESCRIPTION

All other *Writer classes inside the Bio::BioVeL::Service::NeXMLExtractor namespace will inherit
from this class. These child classes are used by the extractor to write objects, metadata or
characters sets in formats such as fasta, phylip, json or nexus.

=head1 METHODS

=over

=item new

The constructor, which is executed when any of the child classes is instantiated, requires
a single argument whose lower case value (e.g. C<nexus>, C<text>) is used to construct,
load, and instantiate the concrete child reader class.

=back

=cut


sub new {
	my ( $class, $type ) = @_;
	
	# $class will be something like Bio::BioVeL::Service::NeXMLExtractor::CharSetWriter
	# $type will be something like JSON
	my $subclass = $class . '::'. lc $type;
	eval "require $subclass";
	return bless {}, $subclass;
}

1;
