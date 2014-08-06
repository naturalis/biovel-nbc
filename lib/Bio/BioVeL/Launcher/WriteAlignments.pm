package Bio::BioVeL::Launcher::WriteAlignments;

use base 'Bio::BioVeL::Launcher';

use strict;
use warnings;

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