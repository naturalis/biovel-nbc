package Bio::BioVeL::Service::NeXMLExtractor;
use strict;
use warnings;
use Bio::Phylo::IO qw (parse unparse);
use Bio::Phylo::Util::CONSTANT ':objecttypes';
use Bio::BioVeL::Service;
use base 'Bio::BioVeL::Service';

sub new {
    my $self = shift->SUPER::new(
	'parameters' => [
	    'nexml',       # input 
	    'object',      # Taxa|Trees|Matrices
	    'treeformat',  # NEXUS|Newick|PhyloXML|NeXML
	    'dataformat',  # NEXUS|PHYLIP|FASTA|Stockholm 
	    'metaformat',  # tsv|JSON|csv
	],
	@_,
	);	
    return $self;
}

sub response_header { "Content-type: text/plain\n\n" }

sub response_body {
    my $self = shift;
    my $result;
    my $log = $self->logger;
    my $location = $self->nexml;
    my $object = $self->object;
    
    if (! $location  | ! $object) {
	$log -> info("no nexml file or no object to extract given; nothing to do");
	return;
    } 
   
    my $fh = $self->get_handle( $location );
    
    my $project = parse(
	'-handle'       => $fh,
	'-format'     => 'nexml',
	'-as_project' => 1
	);
    
    # get alignments !! Stockholm format not implemented yet !!
    if ( $object eq "Matrices" ) {
	$log->info("extracting alignments");
	my $format = $self->dataformat | 'FASTA';
	my @matrices = @{ $project->get_items( _MATRIX_ ) };
	for my $matrix ( @matrices ){
	    $result .= unparse (
		'-format' => lc $format,
		'-phylo' => $matrix,
		);
	}
    }
    # get trees
    if ( $object eq "Trees" ){
	my $format = $self->treeformat | "Newick";
	$log->info("extracting trees");
	my @trees = @{ $project->get_items( _TREE_ ) };
	for my $tree ( @trees ){
	    $result .= unparse (
		'-format' => lc $format,
		'-phylo' => $tree,
		);
	}
    }
    # get taxa
    if ( $object eq "Taxa"){
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
