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
			'treeformat'
			'trees',
			'metaformat',
			'meta',
			'charsetformat',
			'charsets',			
		],
	);	
	return $self;
}

sub response_header { "Content-type: application/xml\n\n" }

sub response_body {
	my $self = shift;
	
	my $project = $fac->create_project;
	my $taxa = $fac->create_taxa;	
	my ( @taxa, @matrices, $forest );
	
	# parse character data reader, if any
	if ( my $f = $self->dataformat ) {
		$log->info("instantiating a $f data reader");
		my $r = Bio::BioVeL::Service::NeXMLMerger::DataReader->new($f);
		@matrices = $r->read_data( $self->get_handle( $self->data ) );
		push @taxa, $_->make_taxa for @matrices;
		$project->insert($_) for @matrices;
	}
	
	# instantiate tree reader
	if ( my $f = $self->treeformat ) {
		$log->info("instantiating a $f tree reader");
		my $r = Bio::BioVeL::Service::NeXMLMerger::TreeReader->new($f);
		my @trees = $r->read_trees( $self->get_handle( $self->trees ) );
		$forest = $fac->create_forest;
		$forest->insert($_) for @trees;
		push @taxa, $forest->make_taxa;
		$project->insert($forest);
	}	
	my $merged = $taxa->merge_by_name(@taxa);
	$_->set_taxa($merged) for @matrices;
	$forest->set_taxa($merged) if $forest;
	$project->insert($taxa);
	
	# instantiate meta reader
	if ( my $f = $self->metaformat ) {
		$log->info("instantiating a $f metadata reader");
		my $r = Bio::BioVeL::Service::NeXMLMerger::MetaReader->new($f);
		my @meta = $r->read_meta( $self->get_handle( $self->meta ) );
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
	
	# instante charset reader
	if ( my $f = $self->charsetformat ) {
		$log->info("instantiating a $f charset reader");
		my $r = Bio::BioVeL::Service::NeXMLMerger::CharsetReader->new($f);
		my @sets = $r->read_charsets( $self->get_handle( $self->charsets ) );
	}
	
	return $project->to_xml;
}

1;