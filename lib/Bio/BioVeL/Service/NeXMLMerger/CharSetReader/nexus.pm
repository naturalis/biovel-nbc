package Bio::BioVeL::Service::NeXMLMerger::CharSeyReader::nexus;

use strict;
use warnings;

use Data::Dumper;

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

sub readCharset{
	my $line = shift;
	my $register = shift;

	$line =~ s/^charset//; #remove starting charset
	$line =~ s/;//; #remove semi column
	my @tokens = split(/\s|=/,$line);
	my @data;
	my $name ="";
	foreach my $token (@tokens) {
		if (length($token) > 0){
			if ($name eq ""){
				$name = $token;
			} else {
				my %newData = readToken($token, $register);
				push (@data, \%newData);
			}
		}
	}
	my %result = (
	    name => $name,
	    data => [@data],
	);
	return %result;
}

sub readNexus {
	my $fileName = shift;
	open(my $in,  "<",  $fileName)  or die "Can't open input.txt: $!";

	my %register;
	my $lineNumber = 0;
	while (my $line  = <$in>) { # assigns each line in turn to $line
		$lineNumber ++;	
		if ($line =~ /^charset/){
			eval {
				my %data = readCharset($line, \%register);
				my $name = $data{name};
				$register{$name} = \%data;
			};
			if ($@) {
				die "Error reading line number: " . $lineNumber . " " . $@;
			}
		}
	}

	close $in or die "$in: $!";
	return %register
}

1;

