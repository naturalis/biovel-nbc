package Bio::BioVeL::Service::NeXMLExtractor::TaxaWriter::tsv;
use strict;
use warnings;

use Bio::BioVeL::Service::NeXMLExtractor::TaxaWriter;
use base 'Bio::BioVeL::Service::NeXMLExtractor::TaxaWriter';

=over

=item write_taxa

Writes taxon definitions to a tsv file.  

=back

=cut

sub write_taxa {
        my ( $self, @taxa ) = @_;
        my $result = "AA";
        
        # get Bio::Phylo::Taxa::Taxon objects from Bio::Phylo::Taxa given in argument
        my @all_taxa = map { @{$_->get_entities}x } @taxa;
        my @data = map  { @{$_->get_data} } @all_taxa;
        my @annos = map {@{$_->get_annotation}} @data;
        
        print "Length data : ".scalar(@data)."\n";
        print "Length annos : ".scalar(@annos)."\n";
        #foreach my $d (@data) {
        #        print "Ref d : ".ref($d)."\n";
        #        my $a = $d->get_annotation;
        #        my @ann = @{$a};
        #        print "Length ann : ".scalar(@ann)."\n";
        #        #print "scalar  a : ".scalar(@a)."\n";
        #        print "ref  a : ".ref($a)."\n";
        my $nex = $taxa[0]->to_nexus;
        print $nex."\n";
        my $taxon = $taxa[0];
        print "Ref taxon: ".ref($taxon)."\n";
        my @meta = @{ $taxon->get_meta };
        print "Length meta : ".scalar(@meta)."\n";
        for my $met (@meta){
                print "Ref meta : ".ref($met)."\n";
        }
        use Data::Dumper;
        print Dumper($taxa[0]);
        ##print Dumper(Bio::Phylo::Taxa::)

        #}
        
        
       # foreach my $t (@all_taxa){
       #         print "Ref ent: ".ref($t)."\n";
       #         my @data = @{ $t->get_data };
       #         
       # }
        
        #for my $t( @taxa ){
        #        $result .= $t->to_nexus
        #}
        return $result;
}

1;
