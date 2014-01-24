#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Temp 'tempfile';
use Bio::Phylo::IO qw'parse_tree unparse parse_matrix';
use Bio::Phylo::Project;

# seq-gen parameters
my %s = (
	'kappa'  => undef,
	'alpha'  => undef,
	'gamma'  => undef,
	'codons' => [],
	'pinvar' => 0.0,
	'length' => 1000,
	'model'  => 'GTR',
	'rates'  => [ 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 ],
	'bases'  => [ 0.25, 0.25, 0.25, 0.25 ],
);

# mapping to command line arguments
my %map = (
	'kappa'  => '-t',
	'alpha'  => '-a',
	'gamma'  => '-g',
	'codons' => '-c',
	'pinvar' => '-i',
	'length' => '-l',
	'model'  => '-m',
	'rates'  => '-r',
	'bases'  => '-f',
);

# wrapper parameters
my $format    = 'nexml';
my $outformat = 'nexml';
my $treefile;
GetOptions(
	'kappa=f'     => \$s{'kappa'},
	'alpha=f'     => \$s{'alpha'},
	'gamma=i'     => \$s{'gamma'},
	'codons=f{3}' => \$s{'codons'},
	'pinvar=f'    => \$s{'pinvar'},
	'length=i'    => \$s{'length'},
	'model=s'     => \$s{'model'},
	'rates=f{6}'  => \$s{'rates'},
	'bases=f{4}'  => \$s{'bases'},
	'format=s'    => \$format,
	'outformat=s' => \$outformat,
	'tree=s'      => \$treefile,
);

# read/write the first (and only?) in tree
my ( $fh, $filename ) = tempfile();
print $fh parse_tree(
	'-file'       => $treefile,
	'-format'     => $format,
	'-as_project' => 1,
)->to_newick;

# build the command line arguments
my @args = qw( seq-gen -or -q );
for my $key ( keys %map ) {
	my $val = $s{$key};
	if ( defined $val ) {
		if ( ref($val) && @{ $val } ) {
			push @args, $map{$key}, @{ $val };
		}
		elsif ( not ref $val ) {
			push @args, $map{$key} . $val;
		}
	}
}
push @args, $filename;

# run the command
my $phylip = `@args`;

# parse the output
my $matrix = parse_matrix(
	'-format' => 'phylip',
	'-type'   => 'dna',
	'-string' => $phylip,
	'-as_project' => 1,
);

# wrap inside a project
my $taxa = $matrix->make_taxa;
my $proj = Bio::Phylo::Project->new;
$proj->insert($taxa);
$proj->insert($matrix);

# unparse to stdout
print unparse(
	'-format' => $outformat,
	'-phylo'  => $proj,
);