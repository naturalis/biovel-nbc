package Bio::BioVeL::Service::NeXMLMerger::DataReader;
use strict;
use warnings;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Util::CONSTANT ':objecttypes';
use Bio::BioVeL::Service::NeXMLMerger::Reader;
use base 'Bio::BioVeL::Service::NeXMLMerger::Reader';

=over

=item read_data

This abstract method, which may or may not be overrided by the child classes, is passed a 
readable handle from which it reads a list of L<Bio::Phylo::Matrices::Matrix> objects.

=back

=cut

sub read_data {
	my ( $self, $handle, $type ) = @_;
	my $format = ref($self);
	$format =~ s/.+://;
	return @{ 
		parse(
			'-format' => $format,
			'-handle' => $handle,
			'-as_project' => 1,
			'-type' => ( $type || 'dna' ),
		)->get_items(_MATRIX_)
	};

}

1;
