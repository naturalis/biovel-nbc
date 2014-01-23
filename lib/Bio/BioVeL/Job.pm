package Bio::BioVeL::Job;
use strict;
use warnings;
use threads;
use English;
use constant LAUNCHING => -2;
use constant RUNNING   => -1;
use constant SUCCESS   => 0;
use Exporter;
use Proc::ProcessTable;

our @ISA    = qw(Exporter);
our @EXPORT = qw(LAUNCHING RUNNING SUCCESS);
our $AUTOLOAD;

my @fields = qw(status id session mail stdout stderr output name arguments timestamp);
my %fields = map { $_ => 1 } @fields;
my $dir = $ENV{'BIOVEL_JOB_DIR'} || die "No BIOVEL_JOB_DIR defined";

sub new {
	my $class = shift;
	my %args  = @_;
	if ( $args{'IdJob'} ) {
		return $class->from_file( $dir . '/' . $args{'IdJob'} );
	}
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
	if ( @_ ) {
		$self->{status} = shift;
		$self->to_file( $dir . '/' . $self->id );
	}
	else {
		$self->from_file( $dir . '/' . $self->id );
	}
	return $self->{status};
}

sub run {
	my $self = shift;
	if ( $self->status < RUNNING ) {
		$self->timestamp( time );
		$self->status( RUNNING );
		threads->create( sub {
			my $id = $self->id;
			my @values = map { $self->$_ } qw(name arguments stdout stderr);
			my $command = sprintf '%s %s >%s 2>%s && echo "status=$?" >> %s', @values, "$dir/$id";
			$self->status( system( $command ) );
		} )->detach();
	}
	return $self->status;
}

sub to_string {
	my $self = shift;
	my $result;
	for my $key ( keys %{ $self } ) {
		$result .= $key . '=' . $self->{$key} . "\n";
	}
	return $result;
}

sub to_file {
	my ( $self, $file ) = @_;
	open my $fh, '>', $file or die $!;
	print $fh $self->to_string;
	close $fh;
}

sub from_string {
	my ( $package, $string ) = @_;
	my $self = ref($package) ? $package : bless {}, $package;
	for my $line ( split /\n/, $string ) {
		my ( $k, $v ) = split /=/, $line;
		$self->{$k} = $v;
	}
	return $self;
}

sub from_file {
	my ( $package, $file ) = @_;
	open my $fh, '<', $file or die $!;
	my $string = do { local $/; <$fh> };
	return $package->from_string( $string );
}

sub AUTOLOAD {
	my $self = shift;
	my $prop = $AUTOLOAD;
	$prop =~ s/.+://;
	if ( $fields{$prop} ) {
		$self->{$prop} = shift if @_;
		return $self->{$prop};
	}
}

sub DESTROY {
	my $self = shift;
	ref($self) && $self->to_file( $dir . '/' . $self->id );
}

1;