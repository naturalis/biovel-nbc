package Bio::BioVeL::Launcher::MergeAlignments;

use base 'Bio::BioVeL::Launcher';

use strict;
use warnings;

=head1 NAME

Bio::BioVeL::Launcher::MergeAlignments - wrapper for the SUPERSMART script 
collecting 
=head1 DESCRIPTION

This wrapper class calls the SUPERSMART script merge_alignments to merge given sequence alignments. This is done
by assessing their orthology by all vs. all BLAST searches and profile aligning the orthologous clusters.
The script can be called via the L<launch> method.

=head1 METHODS

=over

=item launch

The launch method collects the input file $infile with a list of alignemnts (as produced by 
L<Bio::BioVeL::Launcher::WriteAlignments>), the working directory and a logfile.
Using these parameters, a system call to the SUPERSMART script merge_alignments
is executed and the STDOUT from the system call is returned as a string. 

=cut

sub launch {
	my ( $self, $infile, $dir, $logfile ) = @_;
	
	# run the merging job, make sure the PATH and SUPERSMART environment variables are passed to the script
	my $script = $ENV{'SUPERSMART_HOME'} . '/script/supersmart/parallel_merge_alignments.pl';
		
	my $command = "mpirun -x PATH=$ENV{PATH} -x SUPERSMART_HOME=$ENV{SUPERSMART_HOME} -np 2 perl $script -l $infile -w $dir -v 2>>$logfile";
	
	$self->logger->info("Running command $command");
	my $out = qx($command);
	
	return ( $out );	
}

1;