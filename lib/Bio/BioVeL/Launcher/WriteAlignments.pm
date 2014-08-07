package Bio::BioVeL::Launcher::WriteAlignments;

use base 'Bio::BioVeL::Launcher';

use strict;
use warnings;

=head1 NAME

Bio::BioVeL::Launcher::WriteAlignments - wrapper for the SUPERSMART script 
collecting sequence data for a given list of taxa and performing the alignment

=head1 DESCRIPTION

This wrapper class calls the SUPERSMART script write_alignments to collect and align sequence
data for a given list of input taxa. The script can be called via the L<launch> method.

=head1 METHODS

=over

=item launch

The launch method collects the taxafile $infile and the working directory.
Using these parameters, a system call to the SUPERSMART script write_alignments
is executed and the STDOUT from the system call is returned as a string. 

=cut


sub launch {
	my ($self, $infile, $dir, $logfile) = @_;
	
	# SUPERSMART_HOME needs to be known and accessible to the httpd process
	die ("need environment variable SUPERSMART_HOME") if not $ENV{'SUPERSMART_HOME'};
	
	my $script = $ENV{'SUPERSMART_HOME'} . '/script/supersmart/parallel_write_alignments.pl';
	$self->logger->error("no such file: $script") if not -e $script;
	
	# run the job, make sure the PATH and SUPERSMART environment variables are passed to the script
	my $command = "mpirun -x PATH=$ENV{PATH} -x SUPERSMART_HOME=$ENV{SUPERSMART_HOME} -np 2 perl $script -i $infile -w $dir 2>$logfile";
	$self->logger->info("Running command $command");
	
	my $out = qx($command);
	return $out;
}

1;