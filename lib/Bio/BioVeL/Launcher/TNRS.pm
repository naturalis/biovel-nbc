package Bio::BioVeL::Launcher::TNRS;

use base 'Bio::BioVeL::Launcher';

use strict;
use warnings;

sub launch {
	my ($self, $infile, $root_taxon, $logfile) = @_;
	my $log = $self->logger;
	
	# SUPERSMART_HOME needs to be known and accessible to the httpd process
	die ("need environment variable SUPERSMART_HOME") if not $ENV{'SUPERSMART_HOME'};
	
	
	
	my $script = $ENV{'SUPERSMART_HOME'} . '/script/supersmart/parallel_write_taxa_table.pl';
	$log->error("no such file: $script") if not -e $script;

	my $command = "mpirun -np 2 perl $script ";
	
	# append 'names' input file, if exists, to system command 
	$command .= " -i " . $infile if -e $infile;
	
	# append root taxon, if given, to system command
	$command .= " -r " . $root_taxon if $root_taxon;
	
	# append STDERR to logfile
	$command .= "  2>>$logfile";
	
	# run the job
	my $out = qx($command);	
	return $out;
}

1;