package Bio::BioVeL::AsynchronousService::TNRS;
use strict;
use warnings;
use Bio::BioVeL::AsynchronousService ':status';
use Bio::Phylo::Util::Logger 'WARN';
use base 'Bio::BioVeL::AsynchronousService';
use Env::C;
	
    
=head1 NAME

Bio::BioVeL::AsynchronousService::TNRS - wrapper for the SUPERSMART TNRS service

=head1 DESCRIPTION

B<NOTE>: this service is untested, it is a work in progress. It is meant to show
how the scripts of the L<http://www.supersmart-project.org> could be executed as
asynchronous web services.

=head1 METHODS

=over

=item new

The constructor specifies one object property: the location of the input C<names>
list.

=cut

sub new {
	shift->SUPER::new( 'parameters' => [ 'names' ], @_ );	
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
	my $outfile = $self->outdir . '/taxa.tsv';
	my $infile  = $self->outdir . '/names.txt';
	my $logfile = $self->outdir . '/TNRS.log';
	
	# SUPERSMART_HOME needs to be known and accessible to the httpd process
	die ("need environment variable SUPERSMART_HOME") if not $ENV{'SUPERSMART_HOME'};
	
	# with mod_perl, environment variables might not be passed to the child script (depending of OS and apache version); use Env::C to set globally
	Env::C::setenv("SUPERSMART_HOME", $ENV{SUPERSMART_HOME});
	
	my $script = $ENV{'SUPERSMART_HOME'} . '/script/supersmart/parallel_write_taxa_table.pl';
	$log->error("no such file: $script") if not -e $script;
	
	# fetch the input file
	$log->info("going to fetch input names from ".$self->names);
	my $readfh  = $self->get_handle( $self->names );	
	open my $writefh, '>', $infile;
	print $writefh $_ while <$readfh>; 
	
	# run the job
	my $command = "mpirun -np 2 perl $script -i $infile 2>$logfile";
	my $out = qx($command);
	
	# there was an error from the OS
	if ( $? ) {
		$self->status( ERROR );
		$self->lasterr( "unexpected problem, exit code: " . ( $? >> 8 ) );
		$log->error( "unexpected problem, exit code: " . ( $? >> 8 ) ); 
	}
	else {
		# write output file
		open my $fh, '>', $outfile or die;
		print $fh $out;
		close $fh;
		$self->status( DONE );
		$log->info("results written to $outfile, status: ".DONE);
	}
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

Checks wether parameter 'names' if provided, exits with an error if not.

=cut

sub check_input {
	my ($self, $params) = @_;
	my $names_param = ${$params}{'names'};
	my $jobid_param = ${$params}{'jobid'};
	$self->logger->info("checking for parameter 'names' : $names_param");
	die ("either 'names' or 'jobid' parameter is required for TNRS service class") unless $names_param | $jobid_param;
}

=back

=cut

1;