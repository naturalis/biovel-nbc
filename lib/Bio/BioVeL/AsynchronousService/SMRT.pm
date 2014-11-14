package Bio::BioVeL::AsynchronousService::SMRT;
use strict;
use warnings;
use Bio::BioVeL::AsynchronousService ':status';
use Bio::Phylo::Util::Logger 'INFO';
use base 'Bio::BioVeL::AsynchronousService';


=head1 NAME

Bio::BioVeL::AsynchronousService::SMRT 

=head1 DESCRIPTION

This class launches the SUPERSMART web services. Each step of the pipeline
can be ran by specifying the subcommand in the 'command' argument passed to Apache. 
All other subcommands are then specified by the specific subcommand class 
that is invoked (subcommand classes are defined in Bio::SUPERSMART::App::smrt::Command::*).
The output file (or directory) produced by the subcommand is made accessible to the service via the
method C<response_location>.

=head1 METHODS

=over

=item launch

Launches a SUPERSMART subcommand, specified by the service parameter 'command'.
Arguments and options are passed to the subcommand via the parameters of the web service.


=cut

sub launch {
	my $self = shift;

	my $log = $self->logger;
	$log->VERBOSE( '-level' => INFO, '-class' => __PACKAGE__ );
	
	# collect parameters passed to web service
	my $params = $self->{'_params'};
	my $command = delete $params->{'command'};	
	delete $params->{'service'};
		
	# choose command class according to what was specified in parameter 'command'
	my $commandclass = "Bio::SUPERSMART::App::smrt::Command::" . $command;	
	eval "require $commandclass";
	
	# get options of the subcommand and remember the ones
	#  that require an actual file (and not just a filename)
	my @cmd_options = eval "$commandclass" . "::options()";
	my %file_options; 
	foreach my $option ( @cmd_options ) {
		# file options are specified by arg => file
		if ( grep { ( UNIVERSAL::isa($_, "HASH") and ( $_->{arg} eq "file")) } @${option} ){
			my $opt_name = @{$option}[0];
			# keep short name (one letter) and long name
			my ($long, $short) = ($opt_name=~/^(.+?)\|(.)/);
			@file_options{ ($long, $short) } = (1, 1);
		}
	}
	
	# parse the given parameters and construct
	#  an array that corresponds to the ARGV array that would
	#  be passed if we called the subcommand on the command-line
	my @argv;
	foreach my $paramname ( keys $params ) {
		my $paramvalue = $params->{ $paramname };
				
		# if the parameter is an input file, it might have to be decoded,
		#  downloaded and written to the working directory. Check 
		if (exists $file_options{ $paramname }) {
			$log->info("Input file argument $paramname = $paramvalue given, trying to resolve");
			my $readfh  = $self->get_handle( $paramvalue );	
			
			# set filename to name of input parameter
			my $infilename = $self->outdir . "/" .  $paramname . ".txt";
			open my $writefh, '>', $infilename;
			print $writefh $_ while <$readfh>; 
			$paramvalue = $infilename;
		}
		push @argv, length( $paramname) == 1  ? "-" . $paramname : "--" . $paramname;
		push @argv, $paramvalue;
	}
	
	# make command object using the argv array
	$log->info("Instantiating $command class with arguments " . join(" ", @argv));	
	my ($cmd, $opt, $args) = $commandclass->prepare( lc $command, @argv ); 

	# set working directory to directory accessible to the server
	$opt->{'workdir'} = $self->outdir;
	$self->response_location( $self->outdir . "/" . $opt->outfile );

	# here we need to serialize again because otherwise the parent process (and the
	#  serialized object would not know the response location. This is a bit dirty.
	$self->serialize;
	
	# write command output to logfile
	$opt->{'logfile'} = $command . ".log";

	# finally run the subcommand. Input checking is taken care of by the subcommand class	
	$cmd->validate_args( $opt, $args );
	$log->info("executing subcommand $command");
	my $success = $cmd->execute( $opt, $args );	
	$log->debug("command $command finished with return value $success");

	# this is to tell the parent process that we are done
	my $df = $self->done_flag;
	system("touch $df");
}

=item response_location

Redirects the client to the output file (or directory) of the subcommand invoked.

=cut

sub response_location { 
	my $self = shift;
	$self->{'response_location'} = shift if @_;
	return $self->{'response_location'};
}

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

=back

=cut

1;