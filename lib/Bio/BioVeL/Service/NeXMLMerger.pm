package Bio::BioVeL::Service::NeXMLMerger;
use strict;
use warnings;
use Bio::Phylo::Factory;
use Bio::BioVeL::Service;
use Bio::BioVeL::Service::NeXMLMerger::DataReader;
use Bio::BioVeL::Service::NeXMLMerger::TreeReader;
use Bio::BioVeL::Service::NeXMLMerger::MetaReader;
use Bio::BioVeL::Service::NeXMLMerger::CharsetReader;
use Bio::Phylo::Util::CONSTANT ':objecttypes';
use base 'Bio::BioVeL::Service';

my $ns  = 'http://biovel.eu/terms#';
my $fac = Bio::Phylo::Factory->new;
my %typemap = (
	'TaxonID'     => _TAXON_,
	'NodeID'      => _NODE_,
	'TreeID'      => _TREE_,
	'AlignmentID' => _MATRIX_,
	'SiteID'      => _CHARACTER_,
	'CharacterID' => _CHARACTER_,
	'MatrixID'    => _MATRIX_,
);

sub new {
	my $self = shift->SUPER::new(
		'parameters' => [
			'dataformat',
			'datatype',
			'data',
			'treeformat',
			'trees',
			'metaformat',
			'meta',
			'charsetformat',
			'charsets',			
		],
		@_,
	);	
	return $self;
}

sub response_header { "Content-type: application/xml\n\n" }

sub _attach_metadata {
	my ( $self, $project ) = @_;
	my $log = $self->logger;
	
	# parse metadata, if any
	if ( my $f = $self->metaformat ) {
		$log->info("instantiating a $f metadata reader");
		my $r = Bio::BioVeL::Service::NeXMLMerger::MetaReader->new($f);
		
		# read the metadata
		my $location = $self->meta;
		$log->info("going to read metadata from $location");
		my @meta = $r->read_meta( $self->get_handle($location) );
		
		# attach metadata to taxa
		$project->set_namespaces( 'biovel' => $ns );
		for my $m ( @meta ) {
			for my $key ( keys %typemap ) {
			
				# the annotation hash should contain TaxonID or NodeID, or ...
				if ( my $id = delete $m->{$key} ) {
					my $type = $typemap{$key};
					
					no warnings 'uninitialized';
					my ($obj) = grep { $_->get_name eq $id } @{ $project->get_items($type) };
					$log->info("going to annotate object $obj");
					for my $predicate ( keys %{ $m } ) {
						$obj->add_meta(
							$fac->create_meta( '-triple' => { "biovel:$predicate" => $m->{$key} } )
						);
					}
				}
			}
		}
	}	
}

sub response_body {
	my $self    = shift;
	my $log     = $self->logger;	
	my $project = $fac->create_project;
	my $taxa    = $fac->create_taxa;	
	my ( @taxa, @matrices, $forest );
	
	# parse character data reader, if any
	if ( my $f = $self->dataformat ) {
		$log->info("instantiating a $f data reader");
		my $r = Bio::BioVeL::Service::NeXMLMerger::DataReader->new($f);
		
		# read the data
		my $location = $self->data;
		$log->info("going to read data from $location");
		@matrices = $r->read_data( $self->get_handle($location) );
		
		# create taxa blocks, add to project
		push @taxa, $_->make_taxa for @matrices;
		$project->insert($_) for @matrices;
	}
	
	# parse tree data, if any
	if ( my $f = $self->treeformat ) {
		$log->info("instantiating a $f tree reader");
		my $r = Bio::BioVeL::Service::NeXMLMerger::TreeReader->new($f);
		
		# read the trees
		my $location = $self->trees;
		$log->info("going to read trees from $location");
		my @trees = $r->read_trees( $self->get_handle($location) );
		
		# merge into forest, create corresponding taxa block, add to project
		$forest = $fac->create_forest;
		$forest->insert($_) for @trees;
		push @taxa, $forest->make_taxa;
		$project->insert($forest);
	}	
	my $merged = $taxa->merge_by_name(@taxa);
	$_->set_taxa($merged) for @matrices;
	$forest->set_taxa($merged) if $forest;
	$project->insert($taxa);
	
	# attach the metadata
	$self->_attach_metadata($project);
		
	# parse charsets, if any
	if ( my $f = $self->charsetformat ) {
		$log->info("instantiating a $f charset reader");
		my $r = Bio::BioVeL::Service::NeXMLMerger::CharsetReader->new($f);
		
		# read the character sets
		my $location = $self->charsets;
		$log->info("going to read charsets from $location");		
		my @sets = $r->read_charsets( $self->get_handle($location) );
	}
	
	return $project->to_xml( '-compact' => 1 );
}

1;