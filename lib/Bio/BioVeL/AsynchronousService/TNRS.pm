package Bio::BioVeL::AsynchronousService::TNRS;
use strict;
use warnings;
use Bio::BioVeL::AsynchronousService;
use base 'Bio::BioVeL::AsynchronousService';

sub new {
	shift->SUPER::new( 'parameters' => [ 'names' ], @_ );
}

sub launch {
	my $self = shift;
	
	# this results dir may be made visible to the user
	my $outfile = $self->outdir . '/taxa.tsv';
	my $infile  = $self->outdir . '/names.txt';
	my $logfile = $self->outdir . '/TNRS.log';
	
	# SUPERSMART_HOME needs to be known and accessible to the httpd process
	my $script = $ENV{'SUPERSMART_HOME'} . '/script/supersmart/mpi_write_taxa_table.pl';
	
	# fetch the input file
	my $readfh  = $self->open_handle( $self->names );	
	open my $writefh, '>', $infile;
	print $writefh $_ while <$readfh>; 
	
	# run the job
	if ( system( $script, '-i' => $infile, ">$outfile", "2>$logfile" ) ) {
		$self->status( Bio::BioVeL::AsynchronousService::ERROR );
		$self->lasterr( $? );
	}
	else {
		$self->status( Bio::BioVeL::AsynchronousService::DONE );
	}
}

sub response_location { shift->outdir . '/taxa.tsv' }

sub response_body {
	my $self = shift;
	open my $fh, '<', $self->outdir . '/taxa.tsv';
	my @result = do { local $/; <$fh> };
	return join "\n", @result;
}

1;