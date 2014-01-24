package Bio::BioVeL::Job;
use strict;
use warnings;
use English;
use constant LAUNCHING => -2;
use constant RUNNING   => -1;
use constant SUCCESS   => 0;
use Exporter;

# export readable constants to use elsewhere
our @ISA    = qw(Exporter);
our @EXPORT = qw(LAUNCHING RUNNING SUCCESS);

# many getters/setters are done with sub AUTOLOAD
our $AUTOLOAD;
my @fields = qw(status id infile session mail stdout stderr output name arguments timestamp);
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
		my $jobdir = $dir . '/' . $PROCESS_ID . '.dir';
		mkdir $jobdir;
		my $self = {
			'id'        => $PROCESS_ID,
			'session'   => ( $args{sessionId} || die "No session given" ),
			'mail'      => ( $args{mail}      || die "No mail given" ),
			'name'      => ( $args{NAME}      || die "No NAME given" ),
			'arguments' => $args{arguments}   || '',
			'stdout'    => $jobdir . '/stdout',
			'stderr'    => $jobdir . '/stderr',
		};
		bless $self, $class;
		$self->status( LAUNCHING );		
		return $self;
	}
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
		my @values = map { $self->$_ } qw(name arguments stdout stderr);
		my $command = sprintf '%s %s >%s 2>%s &', @values;
		
		# execute and record exit value
		$self->status( system( $command ) );
	}
	return $self->status;
}

# write self to simple XML
sub to_xml {
	my $self = shift;
	my $result = "<job>\n";
	for my $key ( keys %{ $self } ) {
		$result .= "    <$key>" . $self->{$key} . "</$key>\n";
	}
	$result .= "</job>";
	return $result;	
}

# write self to key=value string
sub to_string {
	my $self = shift;
	my $result;
	for my $key ( keys %{ $self } ) {
		$result .= $key . '=' . $self->{$key} . "\n";
	}
	return $result;
}

# write key=value string to file
sub to_file {
	my ( $self, $file ) = @_;
	open my $fh, '>', $file or die $!;
	print $fh $self->to_string;
	close $fh;
}

# instantiate/update invocant from key=value string
sub from_string {
	my ( $package, $string ) = @_;
	my $self = ref($package) ? $package : bless {}, $package;
	for my $line ( split /\n/, $string ) {
		my ( $k, $v ) = split /=/, $line;
		$self->{$k} = $v;
	}
	return $self;
}

# instantiate/update invocant from key=value file
sub from_file {
	my ( $package, $file ) = @_;
	open my $fh, '<', $file or die $!;
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