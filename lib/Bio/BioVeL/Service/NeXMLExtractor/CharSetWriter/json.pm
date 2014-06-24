package Bio::BioVeL::Service::NeXMLExtractor::CharSetWriter::json;
use JSON;
use strict;
use warnings;

use List::MoreUtils qw(uniq);

use Bio::BioVeL::Service::NeXMLExtractor::CharSetWriter;
use base 'Bio::BioVeL::Service::NeXMLExtractor::CharSetWriter';

=over

=item write_charsets

Writes character set definitions to a JSON string. The syntax is as follows

{setname:[{'start'=start, 'end'=end, 'phase'=phase}, ...] ...}

where 'start' and 'end' are the respective start and end positions of the set and
'phase' is the offset between the characters in one set.

=back

=cut

sub write_charsets {
        my ( $self, $charsets ) = @_;
        return encode_json($charsets);
        

}

1;

