package Bio::BioVeL::Service::NeXMLMerger;
use strict;
use warnings;
use Bio::Phylo::Factory;
use Bio::BioVeL::Service;
use Bio::BioVeL::Service::NeXMLMerger::DataReader;
use Bio::BioVeL::Service::NeXMLMerger::TreeReader;
use Bio::BioVeL::Service::NeXMLMerger::MetaReader;
use Bio::BioVeL::Service::NeXMLMerger::CharsetReader;
use base 'Bio::BioVeL::Service';

my $ns  = 'http://biovel.eu/terms#';
my $fac = Bio::Phylo::Factory->new;

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

sub response_body {
	my $self = shift;
	my $log = $self->logger;
	
	my $project = $fac->create_project;
	my $taxa = $fac->create_taxa;	
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
	
	# parse metadata, if any
	if ( my $f = $self->metaformat ) {
		$log->info("instantiating a $f metadata reader");
		my $r = Bio::BioVeL::Service::NeXMLMerger::MetaReader->new($f);
		
		# read the metadata
		my $location = $self->meta;
		$log->info("going to read metadata from $location");
		my @meta = $r->read_meta( $self->get_handle($location) );
		
		# attach metadata to taxa
		$taxa->set_namespaces( 'biovel' => $ns );
		for my $m ( @meta ) {
			my $taxon = delete $m->{'taxon'};
			if ( my $obj = $taxa->get_by_name($taxon) ) {
				for my $key ( keys %{ $m } ) {
					$obj->add_meta(
						$fac->create_meta( '-triple' => { "biovel:$key" => $m->{$key} } )
					);
				}
			}
		}
	}
	
	# parse charsets, if any
	if ( my $f = $self->charsetformat ) {
		$log->info("instantiating a $f charset reader");
		my $r = Bio::BioVeL::Service::NeXMLMerger::CharsetReader->new($f);
		
		# read the character sets
		my $location = $self->charsets;
		$log->info("going to read charsets from $location");		
		my @sets = $r->read_charsets( $self->get_handle($location) );
	}
	
	return $project->to_xml;
}

1;