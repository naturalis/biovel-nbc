package Bio::BioVeL::Service::NeXMLMerger::MetaReader::json;
use base Bio::BioVeL::Service::NeXMLMerger::MetaReader;
use JSON;

=item read_meta

Function to read meta data from a json file handle. Returns array
of hashes with key/value pairs representing metadata for 
taxa.

=cut
 
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
