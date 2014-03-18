package Bio::BioVeL::Service::NeXMLMerger::TreeReader;
use strict;
use warnings;
use Bio::BioVeL::Service::NeXMLMerger::Reader;
use base 'Bio::BioVeL::Service::NeXMLMerger::Reader';

=over

=item read_tree

This abstract method, which is implemented by the child classes, is passed a readable
handle from which it reads a list of L<Bio::Phylo::Forest::Tree> objects.

=back

=cut

sub read_tree {
	my ( $self, $handle ) = @_;
	die "Implement me!";
}

1;
