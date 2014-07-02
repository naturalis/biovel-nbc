package Bio::BioVeL::Service::NeXMLExtractor::TaxaWriter;
use strict;
use warnings;
use Bio::BioVeL::Service::NeXMLExtractor::Writer;
use base 'Bio::BioVeL::Service::NeXMLExtractor::Writer';

=over

=item write_taxa

This abstract method, which is implemented by the child classes, is passed an array of taxa

=back

=cut

sub write_taxa {
	my ( $self, @taxa ) = @_;
	die "Implement me!";
}

1; 
