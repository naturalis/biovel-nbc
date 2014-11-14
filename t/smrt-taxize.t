#!/usr/bin/perl
use strict;
use warnings;
use FindBin '$Bin';
use Test::More 'no_plan';
use Bio::BioVeL::AsynchronousService ':status';

my $names = "https://raw.githubusercontent.com/naturalis/supersmart/master/t/testdata/root-taxon.txt";;

BEGIN {
	use_ok('Bio::BioVeL::AsynchronousService::SMRT');
}

eval "require Bio::SUPERSMART::App::smrt::Command::Taxize"; 

SKIP: {
	skip "environment flag TEST_SUPERSMART not set" unless $ENV{'TEST_SUPERSMART'};

	# invoke service with root taxon Felidae, mix full-word and one-letter options
	@ARGV = ('infile' => $names, 'command' => 'Taxize', 'outfile' => 'myspecies.tsv', 'e' => 'Species' );
	my $smrt  = Bio::BioVeL::AsynchronousService::SMRT->new(@ARGV);
	my $jobid = $smrt->jobid;

	while ( $smrt->status ne DONE ){
		sleep(1);		
		$smrt = Bio::BioVeL::AsynchronousService::SMRT->new( 'jobid' => $jobid );
		$smrt->update;
	}


	ok( -e $smrt->response_location, 'output location exists' );
	my $rb = $smrt->response_body();

	ok ( length($rb) > 0, 'response body not empty');
}

