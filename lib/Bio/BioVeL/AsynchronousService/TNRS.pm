package Bio::BioVeL::AsynchronousService::TNRS;
use strict;
use warnings;
use Bio::BioVeL::AsynchronousService ':status';
use Bio::Phylo::Util::Logger 'WARN';
use Bio::BioVeL::Launcher::TNRS;
use base 'Bio::BioVeL::AsynchronousService';

	
	    
=head1 NAME

Bio::BioVeL::AsynchronousService::TNRS - SUPERSMART TNRS service

=head1 DESCRIPTION

Takes a list of taxon names as input and maps them to their respective 
identifiers in their NCBI taxonomy for various taxonomic ranks. 
Alternatively, a higher level root taxon name can be provided; the service 
then returns all descendant taxa with rank Species. If a taxon name cannot 
be resolved, the 'Taxonomic Name Resolution Service' 
(L<http://tnrs.iplantcollaborative.org/TNRSapp.html>) is queried. The service 
returns a table (tab separated values) with taxon names and NCBI taxon 
identifiers for the ranks species, genus, family, order, class, phylum, kingdom.

=head1 METHODS

=over

=item new

The constructor specifies one object property: the location of the input C<names>
list.

=cut

sub new {
	shift->SUPER::new( 'parameters' => [ 
										'names',      # location of file with taxon names 
										'root_taxon', # or root taxon as a string
										'jobid'       # jobid to fetch the result  
										], @_ );	
}


=item launch

Launches the TNRS script. This will require the SUPERSMART_HOME environment 
variable to be defined, which when running under mod_perl needs to be done by
adding something like the following to httpd.conf:

 PerlSetEnv SUPERSMART_HOME /Library/WebServer/Perl/supersmart

=cut

sub launch {
	my $self = shift;
	my $log = $self->logger;
	$log->VERBOSE( '-level' => WARN, '-class' => __PACKAGE__ );
	
	# contents in this results dir may be made visible to the user
	my $infile = $self->outdir . '/names.txt';
	my $outfile = $self->outdir . '/taxa.tsv';
	my $logfile = $self->outdir . '/TNRS.log';
	
	
	# fetch the input file if given as argument
	if ( $self->names ) {
		$log->info("going to fetch input names from ".$self->names);
		my $readfh  = $self->get_handle( $self->names );	
		open my $writefh, '>', $infile;
		print $writefh $_ while <$readfh>; 
	}

	my $launcher = Bio::BioVeL::Launcher::TNRS->new;
	my $out = $launcher->launch( $infile, $self->root_taxon, $logfile );
	my $status = $self->write_results( $out, $self->response_location );
	$self->status( $status );
}

=item response_location

B<NOTE>: this is an untested feature. The idea is that child classes can re-direct
the client to an alternate location with, e.g. the most important output file or a
directory listing of files.

=cut

sub response_location { shift->outdir . '/taxa.tsv' }

=item response_body

Returns the analysis result as a string. In this service, this is the tab-separated
file of names-to-taxon-ID mappings.

=cut

sub response_body {
	my $self = shift;
	open my $fh, '<', $self->outdir . '/taxa.tsv';
	my @result = do { local $/; <$fh> };
	return join "\n", @result;
}

=item content_type

Returns the MIME type.

=cut

sub content_type { 'text/plain' }

=item check_input

Checks if either parameter L<names>, L<jobid> or L<root_taxon> is 
provided, exits with an error otherwise.

=cut

sub check_input {
	my ($self, $params) = @_;
	my $names_param = ${$params}{'names'};
	my $jobid_param = ${$params}{'jobid'};
	my $root_taxon_param = ${$params}{'root_taxon'};
	$self->logger->info("checking for essential service input parameters");
	die ("either 'names' or 'jobid' parameter is required for TNRS service class") unless $names_param or $jobid_param or $root_taxon_param;
}

=back

=cut

1;