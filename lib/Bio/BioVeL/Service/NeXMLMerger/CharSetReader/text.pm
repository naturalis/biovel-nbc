package Bio::BioVeL::Service::NeXMLMerger::CharSeyReader::text;

use strict;
use warnings;

use Bio::BioVeL::Christian::utils;

sub readDomainLine{
	my $line = shift;
	my $register = shift;

	$line =~ s/;//; #remove semi column
	my @tokens = split(/\s|=/,$line);
	my $name;
	my $pos;
	if ($tokens[0] =~ /pos\d$/){
		my @nameTokens = split(/pos/,$tokens[0]);
		$name = $nameTokens[0];
		$pos = $nameTokens[1];
	} else{
		$name = $tokens[0];
		$pos = 0;
	}
	my %data;
	foreach my $token (@tokens[1..$#tokens]) {
		if (length($token) > 0){
			if (%data){
				die "Second data token found\n";
			} else {
				%data = Bio::BioVeL::Christian::utils::readToken($token, $register);
			}
		}
	}
	unless (%data){
		die "No data token found\n";
	}
	my %result = (
	    name => $name,
	    pos => $pos,
	    data => \%data,
	);
	return %result;
}

sub readDomainReport {
	my $fileName = shift;
	open(my $in,  "<",  $fileName)  or die "Can't open input.txt: $!";

	my %register;
	my $lineNumber = 0;
	while (my $line  = <$in>) { # assigns each line in turn to $line
		$lineNumber ++;	
		eval {
			my %data = readDomainLine($line, \%register);
			my $name = $data{name};
			my $pos = $data{pos};
			my $entry = $register{$name};
			my @dataArray;
			if ($entry){
				my %entryHash = %{$entry};
				my $dataArray = $entryHash{data};
				@dataArray = @{$dataArray};
				$dataArray[$pos] = $data{data};
			} else {
				@dataArray = [];
				$dataArray[$pos] = $data{data};
			}
			my %newEntryHash = (
    				name => $name,
    				data => \@dataArray,
			);			
			$register{$name} = \%newEntryHash;
		};
		if ($@) {
			die "Error reading line number: " . $lineNumber . " " . $@;
		}
	}

	close $in or die "$in: $!";
	return %register
}

1;