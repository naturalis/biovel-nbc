package Bio::BioVeL::Service::NeXMLExtractor::CharSetWriter;
use strict;
use warnings;
use Bio::BioVeL::Service::NeXMLExtractor::Writer;
use base 'Bio::BioVeL::Service::NeXMLExtractor::Writer';

=over

=item write_charsets

This abstract method, which is implemented by the child classes, is passed an array
of hash references including the character set information which will be written to file. 
Each has reference has the following form:
{		'start' => <start coordinate>, 
		'end'   => <end coordinate>,  
		'phase' => <steps to the next site in set>, 
		'ref'   => <name of character set>, 
}

=back

=cut

sub write_charsets {
	my ( $self, $charsets ) = @_;
	die "Implement me!";
}

1;
