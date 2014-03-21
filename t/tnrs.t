#!/usr/bin/perl
use strict;
use warnings;
use FindBin '$Bin';
use Test::More 'no_plan';
use Bio::BioVeL::AsynchronousService ':status';

my $names = "$Bin/../Examples/tnrs_names.txt";

BEGIN {
	use_ok('Bio::BioVeL::AsynchronousService::TNRS');
}


SKIP: {
	skip "environment flag TEST_SUPERSMART not set" unless $ENV{'TEST_SUPERSMART'};
	@ARGV = ( '-names' => $names );
	my $tnrs  = Bio::BioVeL::AsynchronousService::TNRS->new;
	my $jobid = $tnrs->jobid;

	while( $tnrs->update ne DONE ) {
		ok( $tnrs->status eq RUNNING, 'still running' );
		sleep 5;
		$tnrs = Bio::BioVeL::AsynchronousService::TNRS->new( 'jobid' => $jobid );
	}

	ok( -e $tnrs->response_location, 'output location exists' );

}