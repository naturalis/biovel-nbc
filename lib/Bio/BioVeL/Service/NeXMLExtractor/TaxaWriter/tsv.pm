package Bio::BioVeL::Service::NeXMLExtractor::TaxaWriter::tsv;
use strict;
use warnings;

use Bio::BioVeL::Service::NeXMLExtractor::TaxaWriter;
use base 'Bio::BioVeL::Service::NeXMLExtractor::TaxaWriter';

=over

=item write_taxa

Writes taxon metadata information to a tsv file.  

=back

=cut

sub write_taxa {
        my ( $self, @taxa ) = @_;
		my @all_taxa = map { @{$_->get_entities} } @taxa;
		my @metainfo;
	 
		foreach my $taxon (@all_taxa) {	
			my $meta = $taxon->get_meta;
			my %h;
			my $id = $taxon->get_name;
			$h{"Taxon_ID"} = $id;
			for my $m  ( @{$meta} ) {
				my %mattr = %{ $m->get_attributes};
				$h{$mattr{"property"}} = $mattr{"content"};
			}
			push @metainfo, \%h;	
		}
		
		my $result;
		# loop over array of meta taxa information and assemble tsv table
		if (scalar (@metainfo) > 0) {
			# write table header
			$result .= join "\t", keys(%{$metainfo[0]});
			$result .= "\n";
			#write table rows
			for my $r (@metainfo){
				my %curr = %{$r};		
				$result .= join "\t", values(%curr);
				$result .= "\n";
			}
		}
		return $result;
}

1;
