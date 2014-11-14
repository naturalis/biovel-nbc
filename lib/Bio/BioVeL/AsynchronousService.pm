package Bio::BioVeL::AsynchronousService;
use strict;
use warnings;
use Exporter;
use Data::Dumper;
use File::Path 'make_path';
use Scalar::Util 'refaddr';
use Bio::BioVeL::Service;
use Digest::MD5 'md5_hex';
use Apache2::Const '-compile' => qw'OK REDIRECT';
use Proc::ProcessTable;
use Bio::Phylo::Util::Exceptions 'throw';
use base qw'Bio::BioVeL::Service Exporter'; # NOTE: multiple inheritance

# status constants
use constant RUNNING => 'running';
use constant DONE    => 'done';
use constant ERROR   => 'error';

our @EXPORT_OK = qw(RUNNING DONE ERROR);
our %EXPORT_TAGS = (
	'status' => [ qw(RUNNING DONE ERROR) ]
);

=head1 NAME

Bio::BioVeL::AsynchronousService - base class for asynchronous web services

=head1 SYNOPSIS

 use Bio::BioVeL::AsynchronousService::Mock; # example class
 
 # this static method returns a writable directory into which
 # service objects are persisted between request/response cycles
 my $wd = Bio::BioVeL::AsynchronousService::Mock->workdir;

 # when instantiating objects, values for the 'parameters' that are defined
 # in their constructors can be provided as named arguments
 my $mock = Bio::BioVeL::AsynchronousService::Mock->new( 'seconds' => 1 );

 # every async service has a record of when it started
 my $epoch_time = $mock->timestamp;

 # can be RUNNING, ERROR or DONE
 if ( $mock->status eq Bio::BioVeL::AsynchronousService::DONE ) {
 	print $mock->response_body;
 }

=head1 DESCRIPTION

Asynchronous services need to inherit from this package and implement at least the following
methods: C<launch> and C<response_body>. This package makes sure that the child's C<launch>
runs inside a forked process so that the parent returns immediately with enough information, 
stored as object properties, such that C<update> can check how things are going and update the 
C<status>. Once the status set to C<DONE>, C<response_body> is executed to generate the 
output.

Successful implementations are likely going to have simple, persistable object properties
that allow a newly de-serialized object (i.e. during the next polling cycle) to probe
the process table or the job directory to check the status.

=head1 METHODS

=over

=item new

The constructor may or may not be passed the named argument 'jobid', which is used to
deserialize the job object and check on its status. If no job ID is provided, a new
object is created and launched.

=cut

sub new {
	my $class = shift;
	my $log   = $class->logger;
	my %args  = @_;
	my $self;
	if ( my $id = $args{'jobid'} ) {
	
		# unfreeze from file
		$log->info("instantiating existing $class job: $id");
		my $objfile = $class->workdir . '/' . $id . '.yml';
		if ( -e  $objfile ){
			$log->info("file $objfile exists");
		} else {
			$log->error("could not find $objfile");
		}
		$self = $class->from_file( $objfile );
		$log->info("object created from file, process id set to " . $self->pid);
		
		# check the service status
		eval { $self->update };
		if ( $@ ) {
			my $msg = "$@";		
			$log->error("problem updating $self: $msg");
			$self->lasterr( $msg );
			$self->status( ERROR );
		}
	}
	else {
		
		# create new instance
		$log->info("launching new $class job");
		$self = $class->SUPER::new( 'timestamp' => time(), %args );
		
		# generate UID: {pointer address}.{epoch time}
		$self->jobid( refaddr($self) . '.' . timestamp($self) );
		
		# launch the service
		eval { $self->launch_wrapper };
		if ( $@ ) {
			$log->info("Launch wrapper errors : " . $@);
			if ( $@ !~ /ModPerl::Util::exit/ ) {
				my $msg = "$@";
				$log->error("problem launching $self: $msg");
				$self->lasterr( $msg );
				$self->status( ERROR );
			}
			else {
				$log->info("ModPerl::Util::exit was trapped, assume we are done");
				$self->status( DONE );
			}
		}
		else {
			$log->info("launched $self successfully");
			$self->status( RUNNING );
		}		
	}
	return $self;
}

=item launch

The concrete child class needs to implement the C<launch> method, which it should do simply
as something like a C<system> or `backticks` call such that the child class stays around
to chaperonne the process.

=cut

sub launch { 
	die "The launch() method needs to be implemented by the concrete child class\n" 
}

=item launch_wrapper

Wraps the service C<launch> inside a C<fork> to keep track of the PID.

=cut

sub launch_wrapper {
	my $self = shift;
	my $log  = $self->logger;
	#$log->info("PID HERE : $$");
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
		$SIG{'__DIE__'} = sub {
			my @loc = caller(1);
			$log->fatal("fatality caused at line $loc[2] in $loc[1]");
			$log->fatal("process died with the following argument stack: ".Dumper(\@_));
			throw 'API' => $@;
		};
		
		# the idea is that this could take days or
		# however long it needs
		$self->launch;
		exit(0);
	}
	else {
	
		# we're in the parent
		$log->info("launched service job with PID $pid");
		$self->pid($pid);
		$self->serialize;
	}
}

=item update 

Updates the status of the forked child process, currently by checking the C<done_flag>

=cut

sub update { 
	my $self   = shift;
	my $log    = $self->logger;

	#my $pid = $self->pid;
	#use POSIX ":sys_wait_h";	
	#my $res = waitpid($pid, WNOHANG);

	my $status = RUNNING;
	
	if ( -e $self->done_flag ) {
		$status = DONE;
	}
		
	$log->info("Setting status to $status");
	$self->status($status);
}

=item done_flag

Gives the location of a file that is created by the child class when the calculation of
the service in the spawned child process is done. This is a small workaround which avoids
dealing with process id's which behave very differently if the service is called from
within unit tests within perl or in the browser, respectively.

=cut

sub done_flag {
	my $self = shift;
	return ( $self->outdir . '/done' ); 
}


=item jobid

The unique ID of the service job.

=cut

sub jobid {
	my $self = shift;
	$self->{'jobid'} = shift if @_;
	return $self->{'jobid'};
}

=item pid

The process ID of the forked child process.

=cut

sub pid {
	my $self = shift;
	$self->{'pid'} = shift if @_;
	return $self->{'pid'};
}

=item timestamp

The launch timestamp of the job.

=cut

sub timestamp { 
	my $self = shift;
	$self->{'timestamp'} = shift if @_;
	return $self->{'timestamp'};
}

=item lasterr

The last error string that occurred.

=cut

sub lasterr {
	my $self = shift;
	$self->{'lasterr'} = shift if @_;
	return $self->{'lasterr'};
}

=item status

The job status, either RUNNING, DONE or ERROR.

=cut

sub status {
	my $self = shift;
	$self->{'status'} = shift if @_;
	return $self->{'status'};
}

=item handler

The mod_perl handler. Tries to rebuild the job object, checks its status, returns
either a status report or the response body.

=cut

sub handler {
	my $r = shift;
	my $request = Apache2::Request->new($r);

	my $subclass = __PACKAGE__ . '::' . $request->param('service');
	eval "require $subclass";
	my $self = $subclass->new( 
		'request' => $request, 
		'jobid'   => ( $request->param('jobid') || 0 ),
	);

	
	if ( $self->status eq DONE ) {
		$self->logger->info("asynchronous server status: DONE. response location: ".$self->response_location);
		if ( my $loc = $self->response_location and ( -e $self->response_location ) ) {
			my $docroot = $r->document_root;
			my $path    = $r->location;
			my $server  = $r->get_server_name;
			$loc =~ s/^\Q$docroot\E//;
			my $url = 'http://' . $server . $loc;
			$r->headers_out->set('Location' => $url);
			$r->status(Apache2::Const::REDIRECT);			
			$self->logger->info("setting url for asynchronous server response to : ".$url);
		}
		else {
			$self->logger->warn("child process has status DONE, but file in response location is not found!");
			print $self->response_body;
		}
	}
	else {
		my $template = <<'TEMPLATE';
<response>
	<jobid>%s</jobid>
	<status>%s</status>
	<error>%s</error>
	<timestamp>%i</timestamp>
</response>
TEMPLATE
		no warnings 'uninitialized';
		printf $template, $self->jobid, $self->status, $self->lasterr, $self->timestamp;
	}
	return Apache2::Const::OK;
}

=item workdir

This static method returns a directory to which the web server has access. This dir is used 
for serializing the job object, so its location can be generated/pulled out of the air by 
static methods (as the object might not exist yet). For job-specific output (e.g. analysis
result files), use outdir(). 

=cut

sub workdir {
	my $class = shift;
	my $name = ref($class) || $class;
	$name =~ s|::|/|g;
	die ("writable document root needs to be specified either in \$DOCUMENT_ROOT in apache's configuration file or alternatively in \$BIOVEL_HOME") 
		if not $ENV{'DOCUMENT_ROOT'} and not $ENV{'BIOVEL_HOME'}; 
	my $root = $ENV{'DOCUMENT_ROOT'} ? $ENV{'DOCUMENT_ROOT'} : $ENV{'BIOVEL_HOME'};
	my $dir = $root . '/' . $name;
	make_path($dir) if not -d $dir;
	$class->logger("WORKDIR : $dir");
	return $dir;
}

=item outdir

This object method returns a directory location where the child class can write its output

=cut

sub outdir {
	my $self = shift;
	my $dir  = $self->workdir . '/' . $self->jobid;
	make_path($dir) if not -d $dir;
	return $dir;
}

=item logfile

Getter/setter for log file of the invoked child process of the asynchronous service

=cut

sub logfile {
	my $self = shift;
	if ( @_ ){
		$self->{'logfile'} = shift;
	}
	return $self->{'logfile'};
}

=back

=cut

1;
