package Bio::BioVeL::Service::Supersmart;
use strict;
use warnings;

use File::Path qw(make_path);
use Apache2::Const -compile => qw(REDIRECT HTTP_ACCEPTED HTTP_INTERNAL_SERVER_ERROR HTTP_OK);

use base qw'Bio::BioVeL::Service';

# status constants
use constant RUNNING => 'running';
use constant DONE    => 'done';
use constant ERROR   => 'error';

sub new {
	my $class = shift;
	my %args  = @_;
				
	my $r = $args{'request'};
	
	my $command = $r->param('command');

	my $obj = $class->unserialize( $r->param('jobid'),  $command );
	
	my $self;
	if ( ! $obj ) {
		$self = $class->SUPER::new( %args );;
		$self->jobid( $r->param('jobid') );
		$self->command ($command);
		# launch the subcommand
		$self->launch_wrapper;			
	} else {
		$self = $obj;
	}
		
	return $self;
}

sub launch_wrapper {
	my $self = shift;
	my $log  = $self->logger;
	my $pid  = fork();
	if ( $pid == 0 ) {
				
		# we're in the child process. make its logger
		# (which is a copy of the original process),
		# write to a job-specific file
		
		#$self->serialize;
				
		my $logfile = $self->outdir . '/job.log';
		open my $logfh, '>', $logfile or die $!;
		$log->set_listeners(sub{$logfh->print(shift)});
		$log->info("launching the child process");
		
		# try to trap disasters
		#$SIG{'__DIE__'} = sub {
		#	my @loc = caller(1);
		#	$log->fatal("fatality caused at line $loc[2] in $loc[1]");
		#};
		
		# the idea is that this could take days or
		# however long it needs
		$self->status( RUNNING );
		$self->launch;
		exit(0);
	}
	else {
		# we're in the parent
		$log->info("launched service job with PID $pid");
		$self->pid($pid);
		$self->status( RUNNING );
		#$self->serialize;
	}
}

sub launch2{
	my $self = shift;
	my $log  = $self->logger;
	$log->info("Launching application");
	$self->serialize;
	
	sleep(30);
	
	$self->status( DONE );
	$self->serialize;
	
}

sub launch {
	my $self = shift;

	my $log = $self->logger;
#	$log->VERBOSE( '-level' => INFO, '-class' => __PACKAGE__ );
	
	# collect parameters passed to web service
	my $params = $self->{'_params'};
	my $command = delete $params->{'command'};	
	$self->command($command);
	
	# delete params that are not meant for the subcommand
	delete $params->{'service'};
	delete $params->{'jobid'};
		
	# choose command class according to what was specified in parameter 'command'
	my $commandclass = "Bio::SUPERSMART::App::smrt::Command::" . $command;	
	eval "require $commandclass";
	
	# get options of the subcommand and remember the ones
	#  that require an actual file (and not just a filename)
	my @cmd_options = eval "$commandclass" . "::options()";
	my %file_options; 
	foreach my $option ( @cmd_options ) {
		# file options are specified by arg => file
		my $has_file_arg = eval {grep { ( UNIVERSAL::isa($_, "HASH") and ( $_->{arg} eq "file")) } @${option}};
		if ( $has_file_arg ){
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
	
	# increase verbosity
	push @argv, "-v";
	# make command object using the argv array
	$log->info("Instantiating $command class with arguments " . join(" ", @argv));	
	my ($cmd, $opt, $args) = $commandclass->prepare( lc $command, @argv ); 

	# set working directory to directory accessible to the server
	$opt->{'workdir'} = $self->outdir;
	
	my $outfile = $opt->{'outfile'};
	if ( $outfile ) {
		$self->response_location( $self->outdir . "/" . $outfile );
	}
	else {
		$self->response_location( $self->outdir );
	}
	# here we need to serialize again because otherwise the parent process (and the
	#  serialized object would not know the response location. This is a bit dirty.
	$self->serialize;
	
	# write command output to logfile
	$opt->{'logfile'} = $command . ".log";

	# Input checking is taken care of by the subcommand class	
	$cmd->validate_args( $opt, $args );

	# In case the result already exists from a previous run, we're done.
	# Otherwise execute the cubcommand
	my $success;
	if ( $outfile and (-e $self->response_location) and (-s $self->response_location ) ) {
		$log->info("output result file already present! skipping execution of  subcommand $command");
		$success = 1;
	} else {
		$log->info("executing subcommand $command");
		$success = $cmd->execute( $opt, $args );			
	}

	$log->debug("command $command finished with return value $success");
	
	if ( $success ) {
		$self->status( DONE );
	}
	else {
		$self->set_status( ERROR );
	}
	$self->serialize;
}


sub unserialize {
	my $self = shift;
	my $jobid = shift if @_;
	my $command = shift if @_;
	my $obj;
	my $workdir;
	my $file = $self->workdir . '/' . $jobid . '_' . $command .  '.yml';
	if ( -e $file ) {
		$obj = $self->from_file( $file );
	}

	return $obj;
}

sub serialize {
	my $self = shift;
	
	my $log = $self->logger;
	my $file = $self->workdir . '/' . $self->jobid . '_' . $self->command .  '.yml';
	$self->to_file( $file );
}

sub jobid {
	my $self = shift;
	$self->{'jobid'} = shift if @_;
	return $self->{'jobid'};
}

sub command {
	my $self = shift;
	$self->{'command'} = shift if @_;
	return $self->{'command'};
}


sub status {
	my $self = shift;
	$self->{'status'} = shift if @_;
	return $self->{'status'};
}

sub outdir {
	my $self = shift;
	my $dir  = $self->workdir . '/' . $self->jobid;
	make_path($dir) if not -d $dir;
	return $dir;
}

sub handler {
	my $r = shift;
	my $request = Apache2::Request->new($r);
		
	my $self = __PACKAGE__->new('request' => $request);
			
	if ( $self->status eq DONE ) {
		$self->logger->info("Status: Done. Response location : " . $self->response_location . "\n");
		if ( my $loc = $self->response_location and ( -e $self->response_location ) ) {
			my $docroot = $r->document_root;
			my $path    = $r->location;
			my $server  = $r->get_server_name;
			$loc =~ s/^\Q$docroot\E//;
			my $url = 'http://' . $server . $loc;
			$r->headers_out->set('Location' => $url);
			$r->status(Apache2::Const::REDIRECT);
		}
		else {
			$r->status(Apache2::Const::HTTP_OK);
		}
	} 
	elsif ( $self->status eq RUNNING ) {
		$r->status(Apache2::Const::HTTP_ACCEPTED);
		print " ";
		$r->headers_out->set('jobid' => $self->jobid);
	}
	else {
		$r->status(Apache2::Const::HTTP_INTERNAL_SERVER_ERROR);
	} 
	return $r->status;
}

1;