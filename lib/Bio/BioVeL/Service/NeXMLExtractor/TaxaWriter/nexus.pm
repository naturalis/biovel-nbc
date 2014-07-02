package Bio::BioVeL::Service::NeXMLExtractor::TaxaWriter::nexus;
use strict;
use warnings;

use Bio::BioVeL::Service::NeXMLExtractor::TaxaWriter;
use base 'Bio::BioVeL::Service::NeXMLExtractor::TaxaWriter';

=over

=item write_taxa

Writes taxon definitions to a NEXUS string.  

=back

=cut

sub write_taxa {
        my ( $self, @taxa ) = @_;
        my $result;
        for my $t( @taxa ){
                $result .= $t->to_nexus
        }
        return $result;
}

1;
