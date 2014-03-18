package Bio::BioVeL::Service::NeXMLMerger::tsv;


sub read_tsv ($file, $separator) {
    my @rows;
    my $csv = Text::CSV->new ( { sep_char => $separator } ); 
    
    my $file = 'testtab.csv';
    
    open(my $data, '<', $file) or die "Could not open '$file' $!\n";
    while (my $line = <$data>) {
	chomp $line;
	if ($csv->parse($line)) {
	    my @fields = $csv->fields();    
	} else {
	    warn "Line could not be parsed: $line\n";
	}
    }
    return $csv;
}

1;
