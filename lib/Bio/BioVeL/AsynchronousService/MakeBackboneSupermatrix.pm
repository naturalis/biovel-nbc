package Bio::BioVeL::AsynchronousService::MakeBackboneSupermatrix;
use strict;
use warnings;
use Bio::BioVeL::Launcher::WriteAlignments;
use Bio::BioVeL::Launcher::MergeAlignments;
use Bio::BioVeL::Launcher::PickExemplars;
use Bio::BioVeL::AsynchronousService ':status';
use Bio::Phylo::Util::Logger 'INFO';
use base 'Bio::BioVeL::AsynchronousService';


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
		
	# contents in this results dir may be made visible to the user
	my $taxafile = $self->outdir . '/taxa.tsv';
	my $alnfile = $self->outdir . '/aligned.txt';
	my $mergedfile = $self->outdir . '/merged.txt';
	my $logfile = $self->outdir . '/MakeBackboneSupermarix.log';
	
	# input taxa file is given as a URL, here we write the contents into $taxafile
	$log->info("going to fetch input taxa from ".$self->taxafile);
	my $readfh  = $self->get_handle( $self->taxafile );	
	open my $writefh, '>', $taxafile;
	print $writefh $_ while <$readfh>; 
	
	# step 1 : get sequence data and perform alignments
	my $launcher = 	Bio::BioVeL::Launcher::WriteAlignments->new;
	my $out = $launcher->launch( $taxafile, $self->outdir, $logfile );
	my $status = $self->write_results( $out, $alnfile );
	$self->status( $status ) if $status eq ERROR;
	
	# step 2: merge alignments
	$launcher = 	Bio::BioVeL::Launcher::MergeAlignments->new;
	$out = $launcher->launch( $alnfile, $self->outdir, $logfile );
	$status = $self->write_results( $out, $mergedfile );
	$self->status( $status ) if $status eq ERROR;
		
	# step 3: write backbone supermatrix
	$launcher = 	Bio::BioVeL::Launcher::PickExemplars->new;
	$out = $launcher->launch( $mergedfile, $taxafile, $logfile );
	$status = $self->write_results( $out, $self->response_location );
	$self->status( $status );
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