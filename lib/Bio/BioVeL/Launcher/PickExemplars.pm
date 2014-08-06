package Bio::BioVeL::Launcher::PickExemplars;

use base 'Bio::BioVeL::Launcher';

use strict;
use warnings;

sub launch {
	my ( $self, $mergedfile, $taxafile, $logfile ) = @_;
	
	my $script = $ENV{'SUPERSMART_HOME'} . '/script/supersmart/pick_exemplars.pl';
	
	my $command = "perl $script -l $mergedfile -t $taxafile 2>>$logfile";
	$self->logger->info("Running command $command");

	my $out = qx($command);
	
	return ( $out );	
}

1;