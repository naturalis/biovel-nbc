package Bio::BioVeL::Service::NeXMLMerger::MetaReader::tsv;
use base Bio::BioVeL::Service::NeXMLMerger::MetaReader;

=item read_meta

Function to read meta data from a table encoded in a tab separated 
text file (argument is the file handle). Returns array of hashes with 
key/value pairs representing metadata for taxa, where the keys are always
the header of the table. Caution: This function assumes that the 
input table has a header.

=cut

sub read_meta {
    my ($self, $fh) = @_;
    my @result = ();
    my $separator = '\t';
    
    # get header
    my @header = split( $separator, <$fh> );
    # get rows
    while (<$fh>){
	chomp;
	my @info = split( $separator );
	my %h;
	@h{@header} = @info;
	push @result, \%h;
    }
    return @result;
}

1;
