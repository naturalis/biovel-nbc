package Bio::BioVeL::Service::NeXMLExtractor;
use strict;
use warnings;
use Bio::Phylo::IO qw (parse unparse);
use Bio::Phylo::Util::CONSTANT ':objecttypes';

use base 'Bio::BioVeL::Service';

sub new {

    my $self = shift->SUPER::new(
	'parameters' => [
	    'nexml',          # input
	    'objects',        # Taxa|Trees|Matrices
	    'treeformat',     # NEXUS|Newick|PhyloXML|NeXML
	    'dataformat',     # NEXUS|PHYLIP|FASTA|Stockholm
	    'metaformat',     # tsv|JSON|csv
	],
	@_,
	);	
    my $n = $self->nexml;
    return $self;
}

sub response_header { "Content-type: text/plain\n\n" }


sub response_body {
    my $self = shift;
    my $result;
    my $log = $self->logger;
    my $location = $self->nexml;
    
    if (! $location ) {
	$log -> info("no nexml file given; nothing to do");
	return;
    } 
   
    my $fh = $self->get_handle( $location );
    
    my $project = parse(
	'-handle'       => $fh,
	'-format'     => 'nexml',
	'-as_project' => 1
	);

    my @objects = @{$self->objects};

    # get alignments !! Stockholm format not implemented yet !!
    if ( grep "Matrices", @objects ) {
	$log->info("extracting alignments");
	my @matrices = @{ $project->get_items( _MATRIX_ ) };
	for my $matrix ( @matrices ){
	    $result .= unparse (
		'-format' => lc $self->dataformat,
		'-phylo' => $matrix,
		);
	}
    }
    # get trees
    if ( grep "Trees", @objects ){
	$log->info("extracting trees");
	my @trees = @{ $project->get_items( _TREE_ ) };
	for my $tree ( @trees ){
	    $result .= unparse (
		'-format' => lc $self->treeformat,
		'-phylo' => $tree,
		);
	}
    }
    # get taxa
    if ( grep "Taxa", @objects ){
	$log->info("extracting taxa");
	my @taxa = @{$project->get_items( _TAXA_ )};
	# nexus format seems to be the only supported one right now
	for my $t( @taxa ){
	    $result .= $t->to_nexus
	}
    }
    return $result;    
}

1;
