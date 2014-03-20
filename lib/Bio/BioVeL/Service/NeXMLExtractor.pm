package Bio::BioVeL::Service::NeXMLExtractor;
use strict;
use warnings;
use Bio::AlignIO;
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
    my $log      = $self->logger;
    my $location = $self->nexml;
    my $object   = $self->object;
    
    if ( not $location or not $object ) {
		$log->info("no nexml file or no object to extract given; nothing to do");
		return;
    } 
    
    # read the input
    my $project = parse(
		'-handle'     => $self->get_handle( $location ),
		'-format'     => 'nexml',
		'-as_project' => 1,
	);
    
    # get alignments
    if ( $object eq "Matrices" ) {
		my $format = $self->dataformat || 'FASTA';
		my @matrices = @{ $project->get_items( _MATRIX_ ) };
		$log->info("extracting ".scalar(@matrices)." alignment(s) as $format");
		
		# serialize output as stockholm, using bioperl's Bio::AlignIO
		if ( $format =~ /stockholm/i ) {
			my $virtual_file;
			open my $fh, '>', \$virtual_file; # see perldoc -f open
			my $writer = Bio::AlignIO->new(
				'-format' => 'stockholm',
				'-fh'     => $fh,
			);
			$writer->write_aln($_) for @matrices;
			$result .= $virtual_file;
		}
		
		# use Bio::Phylo's unparse()
		else {		
			for my $matrix ( @matrices ){
				$result .= unparse (
					'-format' => $format,
					'-phylo'  => $matrix,
				);
			}
		}
    }
    
    # get trees
    if ( $object eq "Trees" ){
		my $format = $self->treeformat || "Newick";
		my @trees = @{ $project->get_items( _TREE_ ) };
		$log->info("extracting ".scalar(@matrices)." tree(s) as $format");
		for my $tree ( @trees ){
			$result .= unparse (
				'-format' => $format,
				'-phylo'  => $tree,
			);
		}
    }
    
    # get taxa
    if ( $object eq "Taxa" ){
		my @taxa = @{ $project->get_items( _TAXA_ ) };
		$log->info("extracting ".scalar(@taxa)." taxa blocks as NEXUS");
		
		# nexus format seems to be the only supported one right now
		for my $t( @taxa ){
			$result .= $t->to_nexus
		}
    }
    
    return $result;    
}

1;
