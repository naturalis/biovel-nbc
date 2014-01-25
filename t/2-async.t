#!/usr/bin/perl
BEGIN { 
	use File::Temp 'tempdir';
	$ENV{'BIOVEL_JOB_DIR'} = tempdir( 'CLEANUP' => 1 )
}
BEGIN {
	use Test::More 'no_plan';
	use strict;
	use warnings;
	use Bio::BioVeL::Job;
}
BEGIN {
	package Bio::BioVeL::Job::top;
	use base 'Bio::BioVeL::Job';
	sub name { 'top' }
}
{
	package main;
	
	# initialize a new job
	my $j1 = Bio::BioVeL::Job->new(
		'mail'      => 'rutgeraldo@gmail.com',
		'NAME'      => 'top',
		'arguments' => '',
		'sessionId' => 'foo',
	);

	# clone the job by its process id
	my $j2 = Bio::BioVeL::Job->new( 'IdJob' => $j1->id );

	# both aliases are now launching
	ok( $j1->status == LAUNCHING );
	ok( $j2->status == LAUNCHING );

	# launch process, await result
	$j1->run;
	sleep(1) while $j1->status == RUNNING;
	ok( $j1->status == SUCCESS );
	ok( $j2->status == SUCCESS );
}