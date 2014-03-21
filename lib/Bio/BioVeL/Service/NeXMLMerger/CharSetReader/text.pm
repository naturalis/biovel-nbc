package Bio::BioVeL::Service::NeXMLMerger::CharSetReader::text;
use strict;
use warnings;
use Storable 'dclone';
use Bio::BioVeL::Service::NeXMLMerger::CharSetReader;
use base 'Bio::BioVeL::Service::NeXMLMerger::CharSetReader';

sub read_charsets {
	my ( $self, $handle ) = @_;
	my $line = 1;
	my %result;
	while(<$handle>) {
		chomp;
		my ( $name, $ranges ) = $self->read_charset( $_, $line ) if /\S/;
		$result{$name} = $ranges if $name and $ranges;
		$line++;
	}
	return $self->resolve_references(%result);
}

sub resolve_references {
	my ( $self, %charsets ) = @_;
	for my $set ( keys %charsets ) {
		my @resolved;
		my @ranges = @{ $charsets{$set} };
		for my $range ( @ranges ) {
			if ( my $ref = delete $range->{'ref'} ) {
				push @resolved, map { dclone($_) } @{ $charsets{$ref} };
			}
			else {
				push @resolved, $range;
			}
		}
		$charsets{$set} = \@resolved;
	}
	return %charsets;
}

sub read_charset {
	my ( $self, $string, $line ) = @_;
	my $log = $self->logger;
	
	# charset statement is name = ranges ;
	if ( $string =~ /^\s*(\S+?)\s*=\s*(.+?)\s*;\s*$/ ) {
		my ( $name, $ranges ) = ( $1, $2 );
		my @ranges;
		$log->debug("found charset name $name on line $line");
		
		# ranges are space separated
		for my $range ( split /\s+/, $ranges ) {
			$log->debug("parsing range $range");
		
			# initialize range data structure
			my %range = ( 
				'start' => undef, 
				'end'   => undef, 
				'phase' => undef,
				'ref'   => undef,
			);
			
			# range is a named reference
			if ( $range =~ /[a-z]/i ) {
				$range{'ref'} = $range;
			}
			
			# range has coordinates
			else {
				# number after / is phase
				if ( $range =~ /\\(\d+)$/ ) {
					$range{'phase'} = $1;
					$log->debug("phase of range $range is $range{phase}");
				}
			
				# number after - is end coordinate
				if ( $range =~ /-(\d+)/ ) {
					$range{'end'} = $1;
					$log->debug("end of range $range is $range{end}");
				}
			
				# first number is start coordinate
				if ( $range =~ /^(\d+)/ ) {
					$range{'start'} = $1;
					$log->debug("start of range $range is $range{start}");
				}
			}
			push @ranges, \%range;
		}
		return $name => \@ranges;
	}
	else {
		$log->warn("unreadable string on line $line: $string");
	}
}

1;

