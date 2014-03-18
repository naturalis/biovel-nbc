package Bio::BioVeL::Service::NeXMLMerger::MetaReader::json;
use base Bio::BioVeL::Service::NeXMLMerger::MetaReader;
use JSON;


sub read_meta {
    my ($self, $fh) = @_;
    my @result = ();
    
    my $json;
    { 
	local $/;
	$json=<$fh>;
    }
    my $data = decode_json($json);
    if ( $data ) {
	@result = @{ $data };
    }
    
    return @result;
}

1;


