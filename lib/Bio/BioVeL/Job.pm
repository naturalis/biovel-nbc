package Bio::BioVeL::Job;
use strict;
use warnings;
use YAML;
use English;
use constant LAUNCHING => -2;
use constant RUNNING   => -1;
use constant SUCCESS   => 0;
use Exporter;
use base 'Exporter';

# export readable constants to use elsewhere
our @EXPORT = qw(LAUNCHING RUNNING SUCCESS ERROR);

# many getters/setters are done with sub AUTOLOAD
our $AUTOLOAD;
my @fields = qw(status id session mail stdout stderr output name arguments timestamp jobdir cpus);
my %fields = map { $_ => 1 } @fields;

# this is the directory with the status files
my $dir = $ENV{'BIOVEL_JOB_DIR'} || die "No BIOVEL_JOB_DIR defined";

sub new {
	my $class = shift;
	my %args  = @_;
	
	# create job from existing ID
	if ( $args{'IdJob'} ) {
		return $class->from_file( $dir . '/' . $args{'IdJob'} );
	}
	
	# create new job
	else {
		$class .= '::' . lc($args{NAME});
		eval "require $class";
		my $jobdir = $dir . '/' . $PROCESS_ID . '.dir';
		mkdir $jobdir;
		my $self = {
			'id'        => $PROCESS_ID,
			'session'   => ( $args{sessionId} || die "No session given" ),
			'mail'      => ( $args{mail}      || die "No mail given" ),
			'name'      => ( $args{NAME}      || die "No NAME given" ),
			'arguments' => $args{arguments},
			'stdout'    => $jobdir . '/stdout',
			'stderr'    => $jobdir . '/stderr',
			'jobdir'    => $jobdir,
		};
		bless $self, $class;
		$self->status( LAUNCHING );		
		return $self;
	}
}

# override this if the job produces a separate output file, not
# just stdout
sub output { shift->stdout }

# override this to use an executable that's different than the
# name as provided in the query string
sub exe { shift->name }

# override this for MPI jobs, i.e. for examl, and perhaps for 
# likelihood calculator
sub cpus { 1 }

# override this to use a command-line interface that is different
# from the 'arguments' parameter as provided in the query string
sub cli {
	my $self = shift;

	# this will eventually become a Getopt::Long-
	# compatible argument string
	my %cli;
	
	if ( my $jobargs = $self->arguments ) {
	
		# copy the arguments hash
		my $argshr = $jobargs->args;
		if ( ref($argshr) && ref($argshr) eq 'HASH' ) {
			for my $param ( keys %{ $argshr } ) {
				$cli{$param} = $argshr->{$param};
			}
		}
	
		# copy the infile hash
		my $infilehr = $jobargs->files;
		if ( ref($infilehr) && ref($infilehr) eq 'HASH' ) {
			for my $param ( keys %{ $infilehr } ) {
				$cli{$param} = $infilehr->{$param};			
			}
		}
	}
	
	# transform to Getopt::Long argument string
	my @args;
	for my $key ( keys %cli ) {
		if ( ref $cli{$key} ) {
			my %inner = %{ $cli{$key} };
			push @args, map { '--' . $key . ' ' . $_ . '=' . $inner{$_} } keys %inner;
		}
		else {
			push @args, '--' . $key . '=' . $cli{$key};
		}
	}
	
	return join ' ', @args;
}

sub status {
	my $self = shift;
	
	# argument given: write to file
	if ( @_ ) {
		$self->{status} = shift;
		$self->to_file( $dir . '/' . $self->id );
	}
	
	# no argument given: read from file
	else {
		$self->from_file( $dir . '/' . $self->id );
	}
	return $self->{status};
}

sub run {
	my $self = shift;
	if ( $self->status < RUNNING ) {
	
		# record the time and changed status in status file
		$self->timestamp( time );
		$self->status( RUNNING );

		# generate the command		
		my @values = map { $self->$_ } qw(exe cli stdout stderr);
		my $command = sprintf '%s %s >%s 2>%s &', @values;
		
		# execute and record exit value
		$self->status( system( $command ) );
	}
	return $self->status;
}

# write self to YAML string
sub to_string { Dump(shift) }

# write self to YAML file
sub to_file {
	my ( $self, $file ) = @_;
	open my $fh, '>', $file or die $!;
	print $fh $self->to_string;
}

# instantiate/update invocant from key=value string
sub from_string {
	my ( $package, $string ) = @_;
	my $self = ref($package) ? $package : bless {}, $package;
	my $yaml = Load( $string );
	for my $k ( keys %{ $yaml } ) {
		$self->{$k} = $yaml->{$k};
	}
	return $self;
}

# instantiate/update invocant from key=value file
sub from_file {
	my ( $package, $file ) = @_;
	open my $fh, '<', $file or die "Problem opening $file: $!";
	my $string = do { local $/; <$fh> };
	return $package->from_string( $string );
}

# handle getters and setters
sub AUTOLOAD {
	my $self = shift;
	my $prop = $AUTOLOAD;
	$prop =~ s/.+://;
	if ( $fields{$prop} ) {
		$self->{$prop} = shift if @_;
		return $self->{$prop};
	}
}

# preserve self as file when going out of scope
sub DESTROY {
	my $self = shift;
	ref($self) && $self->to_file( $dir . '/' . $self->id );
}

1;