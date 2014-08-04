package Bio::BioVeL::AsynchronousService::MakeBackboneSupermatrix;
use strict;
use warnings;
use Bio::BioVeL::AsynchronousService ':status';
use Bio::Phylo::Util::Logger 'INFO';
use base 'Bio::BioVeL::AsynchronousService';
use Env::C;

=head1 NAME

Bio::BioVeL::AsynchronousService::MakeBackboneSupermatrix - wrapper for the SUPERSMART script 
collecting sequence data for a given list of taxa and performing the alignment

=head1 DESCRIPTION

=head1 METHODS

=over

=item new

The constructor specifies one object property: the location of the input C<taxafile>
list.

=cut

sub new {
	shift->SUPER::new( 
					'parameters' => [ 
						'taxafile' 		# tsv (output from TNRS web service)  
								
						],
				@_ );
}


=item launch

Launches the script 'parallel_write_alignments'. This will require the SUPERSMART_HOME environment 
variable to be defined, which when running under mod_perl needs to be done by
adding something like the following to httpd.conf:

 PerlSetEnv SUPERSMART_HOME /Library/WebServer/Perl/supersmart

=cut

sub launch {
	my $self = shift;
	my $log = $self->logger;
	$log->VERBOSE( '-level' => INFO, '-class' => __PACKAGE__ );
	
	# step 1 : get sequence data and perform alignments
	
	# contents in this results dir may be made visible to the user
	my $alnfile = $self->outdir . '/aligned.txt';
	my $taxafile  = $self->outdir . '/taxa.tsv';
	my $logfile = $self->outdir . '/MakeBackboneSupermarix.log';
	
	# SUPERSMART_HOME needs to be known and accessible to the httpd process
	die ("need environment variable SUPERSMART_HOME") if not $ENV{'SUPERSMART_HOME'};

	# with mod_perl, environment variables might not be passed to the child script (depending of OS and apache version); use Env::C to set globally
	Env::C::setenv("SUPERSMART_HOME", $ENV{SUPERSMART_HOME});
	Env::C::setenv("PATH", $ENV{PATH});

	
	my $script = $ENV{'SUPERSMART_HOME'} . '/script/supersmart/parallel_write_alignments.pl';
	$log->error("no such file: $script") if not -e $script;
	
	# fetch the species table file
	$log->info("going to fetch input taxa from ".$self->taxafile);
	my $readfh  = $self->get_handle( $self->taxafile );	
	open my $writefh, '>', $taxafile;
	print $writefh $_ while <$readfh>; 
	my $workdir = $self->outdir;
	
	# run the alignment job, make sure the PATH and SUPERSMART environment variables are passed to the script
	my $command = "mpirun -x PATH=$ENV{PATH} -x SUPERSMART_HOME=$ENV{SUPERSMART_HOME} -np 4 perl $script -i $taxafile -w $workdir -v 2>$logfile";
	$log->info("Running command $command");
	my $out = qx($command);
	
	# there was an error from the OS
	if ( $? ) {
		$self->status( ERROR );
		$self->lasterr( "unexpected problem, exit code: " . ( $? >> 8 ) );
		$log->error( "unexpected problem, exit code: " . ( $? >> 8 ) ); 
	}
	else {
		# write output alignment file
		open my $fh, '>', $alnfile or die;
		print $fh $out;
		close $fh;
		#$self->status( DONE );
		$log->info("results written to $alnfile");
	}
	
	# step 2: merge alignments
	my $merged_file = $self->outdir . '/merged.txt';
	
	# run the merging job, make sure the PATH and SUPERSMART environment variables are passed to the script
	$script = $ENV{'SUPERSMART_HOME'} . '/script/supersmart/parallel_merge_alignments.pl';
		
	$command = "mpirun -x PATH=$ENV{PATH} -x SUPERSMART_HOME=$ENV{SUPERSMART_HOME} -np 2 perl $script -l $alnfile -w $workdir -v 2>>$logfile";
	
	$log->info("Running command $command");
	$out = qx($command);
	
	# there was an error from the OS
	if ( $? ) {
		$self->status( ERROR );
		$self->lasterr( "unexpected problem, exit code: " . ( $? >> 8 ) );
		$log->error( "unexpected problem, exit code: " . ( $? >> 8 ) ); 
	}
	else {
		# write output alignment file
		open my $fh, '>', $merged_file or die;
		print $fh $out;
		close $fh;
		$log->info("results written to $merged_file");
	}
	
	# step 3: write backbone supermatrix
	my $matrix_file = $self->outdir . '/supermatrix.phy';
	
	$script = $ENV{'SUPERSMART_HOME'} . '/script/supersmart/pick_exemplars.pl';
	
	$command = "perl $script -l $merged_file -t $taxafile 2>>$logfile";
	$out = qx($command);

	# there was an error from the OS
	if ( $? ) {
		$self->status( ERROR );
		$self->lasterr( "unexpected problem, exit code: " . ( $? >> 8 ) );
		$log->error( "unexpected problem, exit code: " . ( $? >> 8 ) ); 
	}
	else {
		# write output alignment file
		open my $fh, '>', $matrix_file or die;
		print $fh $out;
		close $fh;
		$log->info("results written to $matrix_file status: ".DONE);
		$self->status( DONE );		
	}
	
}

=item response_location

B<NOTE>: this is an untested feature. The idea is that child classes can re-direct
the client to an alternate location with, e.g. the most important output file or a
directory listing of files.

=cut

sub response_location { shift->outdir . '/supermatrix.phy' }

=item response_body

Returns the analysis result as a string. In this service, this is a list with the alignemnt files
produced in the working directory

=cut

sub response_body {
	my $self = shift;
	open my $fh, '<', $self->response_location;
	my @result = do { local $/; <$fh> };
	return join "\n", @result;
}

=item content_type

Returns the MIME type.

=cut

sub content_type { 'text/plain' }

=item check_input

Checks whether parameter 'taxafile' or 'jobid' is provided, exits with an error if not.

=cut

sub check_input {
	my ($self, $params) = @_;
	my $taxafile_param = ${$params}{'taxafile'};
	my $jobid_param = ${$params}{'jobid'};
	$self->logger->info("checking for essential service input parameters");
	die ("either 'taxafile' or 'jobid' parameter is required for MakeBackboneSupermatrix service class") unless $taxafile_param or $jobid_param;
}

=back

=cut

1;