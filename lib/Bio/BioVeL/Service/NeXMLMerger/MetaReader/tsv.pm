package Bio::BioVeL::Service::NeXMLMerger::MetaReader::tsv;
use base Bio::BioVeL::Service::NeXMLMerger::MetaReader;

use Text::CSV;

sub read_meta {
    my ($self, $fh) = @_;
    my $separator = '\t';
    my @rows;
    
    my $tsv = Text::CSV->new ( { sep_char => '\t',
				 binary => 1} ); 
    
    while (my $line = $tsv->getline( $fh )) {
	chomp $line;
	if ($tsv->parse($line)) {
	    my @fields = $tsv->fields();    
	} else {
	    warn "Line could not be parsed: $line\n";
	}
    }
    return $tsv;
}

1;
