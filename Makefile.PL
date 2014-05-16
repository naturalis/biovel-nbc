#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'          => 'Bio::BioVeL',
	'ABSTRACT_FROM' => 'lib/Bio/BioVeL.pm',
	'VERSION_FROM'  => 'lib/Bio/BioVeL.pm',
	'AUTHOR'        => 'Rutger Vos <rutger.vos@naturalis.nl>',
	'PREREQ_PM'     => { 	
		'YAML'               => 0,
		'LWP::UserAgent'     => 0,
		'Apache2::Request'   => 0,
		'Bio::Phylo'         => 0,
		'Proc::ProcessTable' => 0,		
		# 'mod_perl'    => 0,		
		# 'BioPerl'     => 0, # suggested for stockholm format
	},
);
