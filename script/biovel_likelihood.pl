#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Temp 'tempfile';
use Bio::Phylo::IO qw'parse unparse';
use Bio::Phylo::Util::CONSTANT qw':objecttypes :namespaces';

# process command line arguments
my $file;
GetOptions( 'file=s' => \$file );
my $project = parse(
	'-format'     => 'nexml',
	'-file'       => $file,
	'-as_project' => 1,
);

# mapping to command line arguments
my %map = (
	'kappa'  => '-t',
	'alpha'  => '-a',
	'gamma'  => '-c',
	'pinvar' => '-v',
	'name'   => '-m',
	'rates'  => '-r', # XXX
	'bases'  => '-f', #
#	'codons' => '-c', #	
);
my %vector = (
	'rates'  => [ qw[rAC rAG rAT rCG rCT rGT] ],
	'bases'  => [ qw[fA fC fG fT] ],
#	'codons' => [ qw[r1 r2 r3] ],
);


my @args = (
	'phyml',
	'--sequential',
	'--datatype' => 'nt',
);

# traverse the model
my $pre = $project->get_prefix_for_namespace(_NS_BIOVEL_);
my ($model) = @{ $project->get_meta( $pre . ':model' ) };
for my $key ( keys %map ) {

	# annotation values are scalar
	if ( not $vector{$key} ) {
		my $val = $model->get_meta_object( $pre . ':' . $key );
		if ( defined $val and $val !~ /^$/ ) {
			push @args, $map{$key} . $val;
		}
	}
	
	# annotation values are ordered lists
	else {
		my ($parent) = @{ $model->get_meta( $pre . ':' . $key ) };
		my @values   = grep { $_ !~ /^$/ } 
		               map { $parent->get_meta_object( $pre . ':' . $_ ) } 
		               @{ $vector{$key} };
		push @args, $map{$key}, @values if @values;
	}
}

# write the first (and only?) tree
my ( $fh, $filename ) = tempfile();
my ($tree) = @{ $project->get_items(_TREE_) };
print $fh $tree->to_newick;
push @args, $filename;

# run the command
my $phylip = `@args`;

# parse the output
my ($matrix) = @{ parse(
	'-format'     => 'phylip',
	'-type'       => 'dna',
	'-string'     => $phylip,
	'-as_project' => 1,
)->get_items(_MATRIX_) };

# wrap inside a project
my ($taxa) = @{ $project->get_items(_TAXA_) };
$matrix->set_taxa($taxa);
$project->insert($matrix);
print $project->to_xml;