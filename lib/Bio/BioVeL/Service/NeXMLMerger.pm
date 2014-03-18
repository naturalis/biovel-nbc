package Bio::BioVeL::Service::NeXMLMerger;
use strict;
use warnings;
use Bio::BioVeL::Service;
use Bio::BioVeL::Service::NeXMLMerger::DataReader;
use Bio::BioVeL::Service::NeXMLMerger::TreeReader;
use Bio::BioVeL::Service::NeXMLMerger::MetaReader;
use Bio::BioVeL::Service::NeXMLMerger::CharsetReader;
use base 'Bio::BioVeL::Service';

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	
	# instantiate data reader
	my $dataformat = $self->get_param('dataformat');
	$self->data_reader(Bio::BioVeL::Service::NeXMLMerger::DataReader->new($dataformat));
	
	# instantiate tree reader
	my $treeformat = $self->get_param('treeformat');
	$self->tree_reader(Bio::BioVeL::Service::NeXMLMerger::TreeReader->new($treeformat));
	
	# instantiate meta reader
	my $metaformat = $self->get_param('metaformat');
	$self->meta_reader( Bio::BioVeL::Service::NeXMLMerger::MetaReader->new($metaformat));
	
	# instante charset reader
	my $charsetformat = $self->get_param('charsetformat');
	$self->charset_reader(Bio::BioVeL::Service::NeXMLMerger::CharsetReader->new($charsetformat));
	return $self;
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