package Bio::BioVeL::Service::NeXMLMerger;
use strict;
use warnings;
use Scalar::Util 'looks_like_number';
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
					$log->info("object $key => $id has type constant $type");

					# fetch all the objects of that type					
					my @objects = @{ $project->get_items($type) };
					$log->info("found ".scalar(@objects)." with constant type $type");
					my $obj; # the one we want
					
					# pick the one by its 1-based (!!!!!) index
					if ( looks_like_number $id ) {
						$obj = $objects[ $id - 1 ];
					}					
					# grep the one with the provided name
					else {
						no warnings 'uninitialized';
						($obj) = grep { $_->get_name eq $id } @objects;
					}
					
					$log->info("going to annotate object $obj");
					for my $predicate ( keys %{ $m } ) {
						$obj->add_meta(
							$fac->create_meta( '-triple' => { 
								"biovel:$predicate" => $m->{$predicate} 
							} )
						);
					}
				}
			}
		}
	}	
}

sub _attach_charsets {
	my ( $self, $project ) = @_;
	my $log = $self->logger;

	# parse charsets, if any
	if ( my $f = $self->charsetformat ) {
		$log->info("instantiating a $f charset reader");
		my $r = Bio::BioVeL::Service::NeXMLMerger::CharsetReader->new($f);
		
		# read the character sets
		my $location = $self->charsets;
		$log->info("going to read charsets from $location");		
		my %sets = $r->read_charsets( $self->get_handle($location) );
		
		# pre-process the focal character block
		my ($matrix) = @{ $project->get_items(_MATRIX_) };
		my $characters = $matrix->get_characters;
		my @sets = @{ $characters->get_sets };
		$characters->remove_set($_) for @sets;
		
		# attach the sets
		for my $set_name ( keys %sets ) {
			my $set_obj = $fac->create_set( '-name' => $set_name );
			$characters->add_set($set_obj);
			
			# iterate over coordinate ranges
			for my $range ( @{ $sets{$set_name} } ) {
			
				# convert to 0-based indices
				my $start = $range->{'start'} - 1;
				my $end   = $range->{'end'} ? $range->{'end'} - 1 : $start;
				my $phase = $range->{'phase'} || 1;				
				for ( my $i = $start; $i <= $end; $i += $phase ) {
					my $char = $characters->get_by_index($i);
					$characters->add_to_set($char,$set_obj);
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
	$project->insert($merged);
	
	# attach the metadata
	$self->_attach_metadata($project);
		
	# attach the character sets
	$self->_attach_charsets($project);
	
	return $project->to_xml( '-compact' => 1 );
}

1;