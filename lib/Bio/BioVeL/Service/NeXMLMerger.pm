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

my $fac = Bio::Phylo::Factory->new;

sub new {
	my $self = shift->SUPER::new(@_);
	
	# instantiate data reader
	my $dataformat = lc $self->get_param('dataformat');
	$self->data_reader(Bio::BioVeL::Service::NeXMLMerger::DataReader->new($dataformat));
	
	# instantiate tree reader
	my $treeformat = lc $self->get_param('treeformat');
	$self->tree_reader(Bio::BioVeL::Service::NeXMLMerger::TreeReader->new($treeformat));
	
	# instantiate meta reader
	my $metaformat = lc $self->get_param('metaformat');
	$self->meta_reader( Bio::BioVeL::Service::NeXMLMerger::MetaReader->new($metaformat));
	
	# instante charset reader
	my $charsetformat = lc $self->get_param('charsetformat');
	$self->charset_reader(Bio::BioVeL::Service::NeXMLMerger::CharsetReader->new($charsetformat));
	return $self;
}

sub response_header { "Content-type: application/xml\n\n" }

sub response_body {
	my $self = shift;
	
	my $project = $fac->create_project;
	my @matrices = $self->data_reader->read_data( $self->get_handle('data') );
	my @trees = $self->tree_reader->read_trees( $self->get_handle('tree') );
	my @meta = $self->meta_reader->read_meta( $self->get_handle('meta') );
	my @charsets = $self->charset_reader->read_charsets( $self->get_handle('sets') );
}

sub data_reader {
	my $self = shift;
	$self->{'data_reader'} = shift if @_;
	return $self->{'data_reader'};
}

sub tree_reader {
	my $self = shift;
	$self->{'tree_reader'} = shift if @_;
	return $self->{'tree_reader'};
}

sub meta_reader {
	my $self = shift;
	$self->{'meta_reader'} = shift if @_;
	return $self->{'meta_reader'};
}

sub charset_reader {
	my $self = shift;
	$self->{'charset_reader'} = shift if @_;
	return $self->{'charset_reader'};
}

1;