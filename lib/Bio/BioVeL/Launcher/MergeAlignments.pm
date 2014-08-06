package Bio::BioVeL::Launcher::MergeAlignments;

use base 'Bio::BioVeL::Launcher';

use strict;
use warnings;

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