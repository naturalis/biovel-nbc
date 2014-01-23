#!/usr/bin/perl
BEGIN { 
	use File::Temp 'tempdir';
	$ENV{'BIOVEL_JOB_DIR'} = tempdir()
}
BEGIN {
	use Test::More 'no_plan';
	use strict;
	use warnings;
	use Data::Dumper;
	use Bio::BioVeL::Job;
}

{

	# initialize a new job
	my $j1 = Bio::BioVeL::Job->new(
		'mail'      => 'rutgeraldo@gmail.com',
		'NAME'      => 'ls',
		'arguments' => '-hal',
		'sessionId' => 'foo',
	);

	# clone the job by its process id
	my $j2 = Bio::BioVeL::Job->new( 'IdJob' => $j1->id );

	# both aliases are now launching
	ok( $j1->status == LAUNCHING );
	ok( $j2->status == LAUNCHING );

	# when one is run, the other should show success
	ok( $j1->run == SUCCESS );
	ok( $j2->status == SUCCESS );
}