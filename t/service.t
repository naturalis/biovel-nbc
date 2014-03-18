#!/usr/bin/perl
use strict;
use warnings;
use Test::More 'no_plan';
use Data::Dumper;

BEGIN {
	use_ok('Bio::BioVeL::Service');
}

@ARGV = ( '-foo' => 'bar' );
my $service_cli = Bio::BioVeL::Service->new( 'parameters' => [ 'foo' ] );
ok( $service_cli->foo eq 'bar' );

@ARGV = ( '-baz' => 'bat' );
my $service_cgi = Bio::BioVeL::Service->new( 'parameters' => [ 'baz' ] );
ok( $service_cgi->baz eq 'bat' );
