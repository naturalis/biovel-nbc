package Bio::BioVeL::Service::NeXMLExtractor::CharSetWriter::nexus;
use strict;
use warnings;

use List::MoreUtils qw(uniq);

use Bio::BioVeL::Service::NeXMLExtractor::CharSetWriter;
use base 'Bio::BioVeL::Service::NeXMLExtractor::CharSetWriter';

=over

=item write_charsets

Writes character set definitions to a NEXUS file. The syntax is expected to be like what
is used inside C<mrbayes> blocks and inside C<sets> blocks, i.e.:

	charset <name> = <start coordinate>(-<end coordinate>)?(\<phase>)? ...;

That is, the definition starts with the C<charset> token, a name and an equals sign. Then,
one or more coordinate sets. Each coordinate set has a start coordinate, an optional end
coordinate (otherwise it's interpreted as a single site), and an optional phase statement,
e.g. for codon positions. Alternatively, instead of coordinates, names of other character 
sets may be used. The statement ends with a semicolon. 

=back

=cut

sub write_charsets {
        my ( $self, @charsets ) = @_;
        
        my @setnames = uniq map {${$_}{"ref"}} @charsets;
        
        my $str = "#nexus\n";
        $str .= "begin sets;\n";
        
        foreach my $name (@setnames) {
                $str .= "charset $name = ";
                my @sets = grep {${$_}{"ref"} eq $name} @charsets;
                foreach my $set (@sets) {
                        $str .= $set->{"start"} == $set->{"end"} ? $set->{"start"} : $set->{"start"} . "-" . $set->{"end"};
                        my $phase = $set->{"phase"};
                        if ($phase > 1){
                                $str .= "\\" . $phase;
                        }
                        $str .= " ";
                }
                $str .= ";\n";       
        }
        
        $str .= "end;\n";
        
        return $str;


}

1;

