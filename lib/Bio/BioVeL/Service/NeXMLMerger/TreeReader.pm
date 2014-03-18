package Bio::BioVeL::Service::NeXMLMerger::TreeReader;
use strict;
use warnings;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Util::CONSTANT ':objecttypes';
use Bio::BioVeL::Service::NeXMLMerger::Reader;
use base 'Bio::BioVeL::Service::NeXMLMerger::Reader';

=over

=item read_trees

This method, which may or may not be overrided by the child classes, is passed a readable
handle from which it reads a list of L<Bio::Phylo::Forest::Tree> objects.

=back

=cut

sub read_trees {
	my ( $self, $handle ) = @_;
	my $format = ref($self);
	$format =~ s/.+://;
	return @{
		parse(
			'-format' => $format,
			'-handle' => $handle,
			'-as_project' => 1,	
		)->get_items(_TREE_)
	};
}

1;
