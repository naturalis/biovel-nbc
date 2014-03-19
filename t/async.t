#!/usr/bin/perl
use strict;
use warnings;
use File::Temp 'tempdir';
use Test::More 'no_plan';
use Scalar::Util 'looks_like_number';
use Bio::BioVeL::AsynchronousService;

my $tempdir = tempdir();

Bio::BioVeL::AsynchronousService->workdir( $tempdir );
ok( $tempdir eq Bio::BioVeL::AsynchronousService->workdir );

warn "*** ERROR MESSAGE IS OK:\n";
my $new = Bio::BioVeL::AsynchronousService->new;
isa_ok( $new, 'Bio::BioVeL::AsynchronousService' );

ok( $new->status eq Bio::BioVeL::AsynchronousService::ERROR );
ok( $new->lasterr =~ /needs to be implemented/ );
ok( looks_like_number $new->timestamp );
