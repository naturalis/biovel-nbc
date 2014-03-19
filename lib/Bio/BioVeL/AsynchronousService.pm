package Bio::BioVeL::AsynchronousService;
use strict;
use warnings;
use File::Path 'make_path';
use Scalar::Util 'refaddr';
use Bio::BioVeL::Service;
use Digest::MD5 'md5_hex';
use Apache2::Const '-compile' => 'OK';
use Proc::ProcessTable;
use base 'Bio::BioVeL::Service';

# status constants
use constant RUNNING => 'running';
use constant DONE    => 'done';
use constant ERROR   => 'error';

=head1 DESCRIPTION

Asynchronous services need to subclass this class and implement at least the following
methods: C<launch>, C<update>, and C<response_body>. The trick lies in making launch()
fork off a process and return immediately with enough information, stored as object
properties, so that update() can check how things are going and update the status(). 
Once the status set to C<DONE>, C<response_body> is executed to generate the output.

Successful implementations are likely going to have simple, serializable object properties
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
		$self = $class->from_file( $class->workdir . '/' . $id . '.yml' );
		
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
		
		# generate UID: service module name, object memory address, epoch time
		my $uid = join '::', ref($self), refaddr($self), timestamp($self);
		$uid =~ s/::/./g;
		$self->jobid($uid);
		
		# launch the service
		eval { $self->launch_wrapper };
		if ( $@ ) {
			my $msg = "$@";
			$log->error("problem launching $self: $msg");
			$self->lasterr( $msg );
			$self->status( ERROR );
		}
		else {
			$log->info("launched $self successfully");
			$self->status( RUNNING );
		}		
	}
	return $self;
}

=item launch

The concrete child class needs to implement the launch() method, which presumably
will fork off a process, e.g. using system("command &"), such that it will be able
to keep track of its status, e.g. by knowing the PID of the child processes.

=cut

sub launch { 
	die "The launch() method needs to be implemented by the concrete child class\n" 
}

=item launch_wrapper

Wraps the service launch() inside a fork() to keep track of the PID.

=cut

sub launch_wrapper {
	my $self = shift;
	my $log  = $self->logger;
	my $pid  = fork();
	if ( $pid == 0 ) {
		
		# we're in the child process
		$log->info("launching the child process");
		$self->launch;
		exit(0);
	}
	else {
	
		# we're in the parent
		$log->info("launched service job with PID $pid");
		$self->pid($pid);
	}
}

=item update 

The concrete child class needs to implement the update() method, which will check on
the process that was launched by launch(), and will update the status, e.g. from RUNNING
to DONE or ERROR.

=cut

sub update { 
	my $self   = shift;
	my $log    = $self->logger;
	my $status = $self->status;
	if ( my $pid = $self->pid ) {
		my $timestamp = $self->timestamp;
		my $pt = Proc::ProcessTable->new;
		PROC: for my $proc ( @{ $pt->table } ) {
			if ( $proc->pid == $pid ) {
				if ( abs( $timestamp - $proc->start ) < 2 ) {
					$log->info("still running: ".$proc->cmndline);
					$status = RUNNING;
					last PROC;
				}
			}
		}
	}
	$self->status($status);
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

The process ID of the service job.

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
	return $self->{'lasterr'} // '';
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
	my $request = Apache2::Request->new(shift);
	my $subclass = __PACKAGE__ . '::' . $request->param('service');
	eval "require $subclass";
	my $self = $subclass->new( 
		'request' => $request, 
		'jobid'   => ( $request->param('jobid') || 0 ),
	);
	if ( $self->status eq DONE ) {
		print $self->response_body;
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

This returns a directory inside $ENV{BIOVEL_HOME}, which consequently needs to be defined,
for example by specifying it with PerlSetEnv inside httpd.conf. See:
L<http://modperlbook.org/html/4-2-10-PerlSetEnv-and-PerlPassEnv.html>

=cut

sub workdir {
	my $class = shift;
	my $name = ref($class) || $class;
	$name =~ s/.+//;
	my $dir = $ENV{'BIOVEL_HOME'} . '/' . $name;
	make_path($dir) if not -d $dir;
	return $dir;
}

=item DESTROY

The object destructor automatically serializes the dying object inside workdir.

=cut

sub DESTROY {
	my $self  = shift;
	my $wdir  = $self->workdir;
	my $jobid = $self->jobid;
	my $file  = "${wdir}/${jobid}.yml";
	my $log = $self->logger;
	$log->info("writing $self as $jobid to file $file");
	$self->to_file( $file );
}

=back

=cut

1;