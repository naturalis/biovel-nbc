package Bio::BioVeL::Service::NeXMLExtractor;
use strict;
use warnings;

use Bio::BioVeL::Service;
use Bio::BioVeL::Service::NeXMLExtractor::CharSetWriter;

use Bio::AlignIO;
use Bio::Phylo::IO qw (parse unparse);
use Bio::Phylo::Util::CONSTANT ':objecttypes';
use base 'Bio::BioVeL::Service';



=head1 NAME

Bio::BioVeL::Service::NeXMLExtractor - extracts and converts data from a NeXML document

=head1 SYNOPSIS

 use Bio::BioVeL::Service::NeXMLExtractor;

 # arguments can either be passed in from the command line argument array or as 
 # HTTP request parameters, e.g. from $QUERY_STRING
 @ARGV = (
     '-nexml'      => $nexml,
     '-object'     => 'Trees',
     '-treeformat' => 'newick',
     '-dataformat' => 'nexus',
     '-charsetformat' => 'nexus',
 );

 my $extractor = Bio::BioVeL::Service::NeXMLExtractor->new;
 my $data = $extractor->response_body;

=head1 DESCRIPTION

This package extracts phylogenetic data from a NeXML document. Although
it can be used inside scripts that receive command line arguments, it is intended to be
used as a RESTful web service that clients can be written against, e.g. in 
L<http://taverna.org.uk> for inclusion in L<http://biovel.eu> workflows.

=head1 METHODS

=over

=item new

The constructor typically receives no arguments.

=cut

sub new {
    my $self = shift->SUPER::new(
    
		# these parameters are turned into object properties
		# whose values are magically filled in. after object
		# construction the object can access these properties,
		# e.g. as $self->nexml    
		'parameters' => [
			'nexml',        # input 
			'object',       # Taxa|Trees|Matrices|Charsets
			'treeformat',   # NEXUS|Newick|PhyloXML|NeXML
			'dataformat',   # NEXUS|PHYLIP|FASTA|Stockholm 
			'metaformat',   # tsv|JSON|csv
                        'charsetformat' # NEXUS|JSON
                ],
		@_,
	);	
    return $self;
}

=item response_header

Returns the Content-type HTTP header. Note: at present this isn't really used, instead
C<content_type> (see below) is used by the superclass to compose the header through
mod_perl

=cut

sub response_header { "Content-type: ".shift->content_type."\n\n" }

=item content_type

Returns the MIME type.

=cut

sub content_type { 'text/plain' }

=item response_body

Generates the requested response. It does this by reading a NeXML document and collecting
objects of the type specified by the object() property (i.e. 'Matrices', 'Trees' or 
'Taxa'). It then serializes these to the requested format.

=cut

sub response_body {
    my $self = shift;
    my $result;
    my $log      = $self->logger;
    my $location = $self->nexml;
    my $object   = $self->object;
    
    if ( not $location or not $object ) {
		$log->info("no nexml file or no object to extract given; nothing to do");
		return;
    } 
    
    # read the input
    my $project = parse(
		'-handle'     => $self->get_handle( $location ),
		'-format'     => 'nexml',
		'-as_project' => 1,
	);
    
    # get alignments
    if ( $object eq "Matrices" ) {
		my $format = ucfirst( lc($self->dataformat || 'FASTA') );
		my @matrices = @{ $project->get_items( _MATRIX_ ) };
		$log->info("extracting ".scalar(@matrices)." alignment(s) as $format");
		
		# serialize output as stockholm, using bioperl's Bio::AlignIO
		if ( $format =~ /stockholm/i ) {
			my $virtual_file;
			open my $fh, '>', \$virtual_file; # see perldoc -f open
			my $writer = Bio::AlignIO->new(
				'-format' => 'stockholm',
				'-fh'     => $fh,
			);
			$_->visit(sub { shift->set_position(1) }) for @matrices;
			$writer->write_aln($_) for @matrices;
			$result .= $virtual_file;
		}
		
		# use Bio::Phylo's unparse()
		else {		
			for my $matrix ( @matrices ){
				$result .= unparse (
					'-format' => ucfirst $format,
					'-phylo'  => $matrix,
				);
			}
		}
    }
    
    # get trees
    if ( $object eq "Trees" ){
		my $format = $self->treeformat || "Newick";
		my @trees = @{ $project->get_items( _TREE_ ) };
		$log->info("extracting ".scalar(@trees)." tree(s) as $format");
		for my $tree ( @trees ){
			$result .= unparse (
				'-format' => ucfirst $format,
				'-phylo'  => $tree,
			);
		}
    }
    
    # get taxa
    if ( $object eq "Taxa" ){
		my @taxa = @{ $project->get_items( _TAXA_ ) };
		$log->info("extracting ".scalar(@taxa)." taxa blocks as NEXUS");
		
		# nexus format seems to be the only supported one right now
		for my $t( @taxa ){
			$result .= $t->to_nexus
		}
    }

    # get character sets
    if ( $object eq "Charsets" ){
            $log->info("extracting character sets");
            my @charsets = $self->_extract_charsets($project);
            my $f = $self->charsetformat || "JSON";
            my $writer = Bio::BioVeL::Service::NeXMLExtractor::CharSetWriter->new(lc($f));
            $result .= $writer->write_charsets(@charsets);
    }
    $project->reset_xml_ids;
    return $result;    
}

# extracts the charset data from a given project object.
# returns an array of hash references with charset information of the form:
# 	{
#		'start' => <start coordinate>, 
#		'end'   => <end coordinate>,  
#		'phase' => <steps to the next site in set>, 
#		'ref'   => <name of character set>, 
#	}

sub _extract_charsets {
        my ( $self, $project ) = @_;
	my $log = $self->logger;
        
        my @charsets;

        # extracting sets from matrix object
        my ($matrix) = @{ $project->get_items(_MATRIX_) };
        my $characters = $matrix->get_characters;
        my @sets = @{ $characters->get_sets };            
        my $first_id;
        my @setnames = map {$_->get_name} @sets;

        # iterate over all characters and put them into respective sets
        my %set_chrs;
        @set_chrs{@setnames} = [];
        while (my $char = $characters->next) {
                # strip non-digits (e.g. 'cr')
                my $id = ${$char->get_attributes}{"id"} =~ s/[^0-9]//gr;
                $first_id = $id if ! $first_id;
                for my $set (@sets) {
                        if ($characters->is_in_set($char, $set)) {
                                # subtract id for first character, so characters start from one
                                push @{$set_chrs{$set->get_name}}, $id - $first_id + 1;
                        }
                }
        }
        
        # now, iterate over each caracter set and look if we can summarize some characters 
        #  (e.g. 1-100 instead of all characters inbetween, or 3-9\3 for characters in steps of 3).
        foreach my $setname (@setnames) {
                my @ids = @{$set_chrs{$setname}};
                my $last_diff;
                my $start = $ids[0];
                my $end;
                for my $i (1..($#ids+1)){
                        my $diff;
                        if ($i <($#ids+1)){
                                $diff = $ids[$i] - $ids[$i-1];
                        }
                        if (!$diff || ( $last_diff && ($last_diff != $diff)) ) {
                                $end = $ids[$i-1];
                                my $coord_set = { 'start'=> $start,
                                                  'end'  => $end,
                                                  'phase'=> $start == $end ? 1 : $last_diff,
                                                  'ref'  => $setname
                                };
                                push @charsets, $coord_set;
                                $start = $ids[$i];
                        }
                        $last_diff = $diff;
                }
        }
        return @charsets;
}

=back

=cut

1;
