package Bio::BioVeL::Service::NeXMLExtractor::CharSetWriter::nexus;
use strict;
use warnings;

use List::MoreUtils qw(uniq);

use Bio::BioVeL::Service::NeXMLExtractor::CharSetWriter;
use base 'Bio::BioVeL::Service::NeXMLExtractor::CharSetWriter';

=over

=item write_charsets

Writes character set definitions to a NEXUS string. The syntax is expected to be like what
is used inside C<mrbayes> blocks and inside C<sets> blocks, i.e.:

	charset <name> = <start coordinate>(-<end coordinate>)?(\<offset>)? ...;

That is, the definition starts with the C<charset> token, a name and an equals sign. Then,
one or more coordinate sets. Each coordinate set has a start coordinate, an optional end
coordinate (otherwise it's interpreted as a single site), and an optional offset statement,
e.g. for codon positions. Alternatively, instead of coordinates, names of other character 
sets may be used. The statement ends with a semicolon. 

=back

=cut

sub write_charsets {
        my ( $self, $charsets ) = @_;
        
        my $str = "#nexus\n";
        $str .= "begin sets;\n";
        my %h = %{$charsets};
        foreach my $name (keys %h) {
                $str .= "charset $name = ";
                my $sets_ref = $h{$name};
                my @sets = @{$sets_ref}; 
                foreach my $set (@sets) {
                        $str .= $set->{"start"} == $set->{"end"} ? $set->{"start"} : $set->{"start"} . "-" . $set->{"end"};
                        my $offset = $set->{"offset"};
                        if ($offset > 1){
                                $str .= "\\" . $offset;
                        }
                        $str .= " ";
                }
                $str .= ";\n";       
        } 
        $str .= "end;\n";
        return $str;
}

1;

