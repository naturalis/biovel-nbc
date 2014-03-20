package Bio::BioVeL::Service::NeXMLMerger::CharSetReader::nexus;
use strict;
use warnings;
use Bio::BioVeL::Service::NeXMLMerger::CharSetReader::text;
use base 'Bio::BioVeL::Service::NeXMLMerger::CharSetReader::text';

sub read_charsets {
	my ( $self, $handle ) = @_;
	my $line = 1;
	my %result;
	while(<$handle>) {
		chomp;
		if ( /^\s*charset\s+(.+)$/ ) {
			my $charset = $1;
			my ( $name, $ranges ) = $self->read_charset( $charset, $line );
			$result{$name} = $ranges if $name and $ranges;
		}
		$line++;	
	}
	return $self->resolve_references(%result);
}

1;

