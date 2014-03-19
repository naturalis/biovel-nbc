package Bio::BioVeL::Service::NeXMLMerger::CharSeyReader::utils;
use strict;
use warnings;

sub readToken{
	my $chunk = shift;
	my %register = %{shift()};
	if ($chunk =~ /\\/){
		my @tokens = split(/-|\\/,$chunk);
		if (@tokens != 3){
			die "Unexpected token " . $chunk . "\n"
		}
		my %result = (
		    start => $tokens[0],
		    end => $tokens[1],
		    phase => $tokens[2],
		);
		return %result;
		#return "three";
	} 
	if ($chunk =~ /-/){
		my @tokens = split(/-/,$chunk);
		if (@tokens != 2){
			die "Unexpected token " . $chunk . "\n"
		}
		my %result = (
		    start => $tokens[0],
		    end => $tokens[1],
		);
		return %result;
	} 
	if ($chunk =~ /^[+-]?\d+$/ ) {
		my %result = (
		    only => $chunk,
		);
		return %result;
	}
        my $ref = $register{$chunk};
	my %result = (
	    inner => $ref,
	);
	return %result;
}

1;