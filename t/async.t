#!/usr/bin/perl
use strict;
use warnings;
use File::Temp 'tempdir';
use Test::More 'no_plan';
use Scalar::Util 'looks_like_number';

BEGIN { use_ok('Bio::BioVeL::AsynchronousService::Mock') }

my $tempdir = tempdir();

Bio::BioVeL::AsynchronousService::Mock->workdir( $tempdir );
ok( $tempdir eq Bio::BioVeL::AsynchronousService::Mock->workdir );

my $new = Bio::BioVeL::AsynchronousService::Mock->new;
isa_ok( $new, 'Bio::BioVeL::AsynchronousService' );

ok( looks_like_number $new->timestamp );

ok( $new->status eq Bio::BioVeL::AsynchronousService::RUNNING );