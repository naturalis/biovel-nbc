package Bio::BioVeL::Service::NeXMLMerger::MetaReader::tsv;
use base Bio::BioVeL::Service::NeXMLMerger::MetaReader;

sub read_meta {
    my ($self, $fh) = @_;
    my @result = ();
    my $separator = '\t';
    
    # get header
    my @header = split( $separator, <$fh> );
    print "Length header : ".scalar(@header)."\n";
    # get rows
    while (<$fh>){
	chomp;
	my @info = split( $separator );
	my %h;
	@h{@header} = @info;
	push @result, \%h;
	print "Length result : ".scalar(@result)."\n";
    }
    return @result;
}

1;
