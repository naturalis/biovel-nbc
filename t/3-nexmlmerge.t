#!/usr/bin/perl
BEGIN { 
	use FindBin qw($Bin);
	use File::Temp 'tempdir';
	$ENV{'BIOVEL_JOB_DIR'} = tempdir( 'CLEANUP' => 1 );
	$ENV{'PATH'} .= ':' . $Bin . '/../script';
}
BEGIN {
	use Test::More 'no_plan';
	use strict;
	use warnings;
	use JSON;
	use MIME::Base64;
	use Bio::BioVeL::Job;
	use Bio::BioVeL::JobArgs;
}

{
	my $args = {
		'xmlns'      => { 'bv' => 'http://biovel.eu/terms#' },
		'treeformat' => 'newick',
		'dataformat' => 'fasta',
		'datatype'   => 'dna',
		'data'       => 'file://' . $Bin . '/data/data.fa',
		'tree'       => 'file://' . $Bin . '/data/tree.dnd',
		'meta'       => 'file://' . $Bin . '/data/meta.json',
	};
	my $encoded = encode_base64(encode_json($args));

	# initialize a new job
	my $j1 = Bio::BioVeL::Job->new(
		'mail'      => 'rutgeraldo@gmail.com',
		'NAME'      => 'nexmlmerge',
		'sessionId' => 'foo',
	);
	$j1->arguments(Bio::BioVeL::JobArgs->new($encoded,$j1));
	ok( $j1->status == LAUNCHING );

	# launch process, await result
	$j1->run;
	sleep(1) while $j1->status == RUNNING;
	ok( $j1->status == SUCCESS );
}