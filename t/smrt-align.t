#!/usr/bin/perl
use strict;
use warnings;
use FindBin '$Bin';
use Test::More 'no_plan';
use Bio::BioVeL::AsynchronousService ':status';

my $taxa = "https://raw.githubusercontent.com/naturalis/biovel-nbc/master/Examples/taxa_felidae_small.tsv";;

BEGIN {
	use_ok('Bio::BioVeL::AsynchronousService::SMRT');
}

eval "require Bio::SUPERSMART::App::smrt::Command::Align"; 

SKIP: {
	skip "environment flag TEST_SUPERSMART not set" unless $ENV{'TEST_SUPERSMART'};

	# invoke service with primate species table
	@ARGV = ('i' => $taxa, 'command' => 'Align', 'outfile' => 'alignments.txt' );
	my $smrt  = Bio::BioVeL::AsynchronousService::SMRT->new(@ARGV);
	isa_ok ( $smrt,  'Bio::BioVeL::AsynchronousService::SMRT' );
	my $jobid = $smrt->jobid;

	while ( $smrt->status ne DONE ){
		sleep(20);		
		$smrt = Bio::BioVeL::AsynchronousService::SMRT->new( 'jobid' => $jobid );
		$smrt->update;
	}

	ok( -e $smrt->response_location, 'output location exists' );
	ok( -s $smrt->response_location, 'output file not empty' );

	my $rb = $smrt->response_body();
	print $rb;
	ok ( length($rb) > 0, 'response body not empty');
}

# in browser:
#http://localhost/biovel-supersmart?service=SMRT&command=Align&infile=https://raw.githubusercontent.com/naturalis/biovel-nbc/master/Examples/taxa_felidae_small.tsv