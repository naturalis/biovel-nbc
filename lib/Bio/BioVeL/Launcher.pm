package Bio::BioVeL::Launcher;

use strict;
use warnings;
use Bio::Phylo::Util::Logger ':levels';
use Env::C;

sub new {
	my $class = shift;
	my %args = @_;
	my $self = {};
	bless $self, $class;	
	
	# pass environment variables SUPERSMART_HOME and PATH so 
	#  we can be sure they are available in the launched child processes
	Env::C::setenv("SUPERSMART_HOME", $ENV{SUPERSMART_HOME});
	Env::C::setenv("PATH", $ENV{PATH});
	
	return $self;
}

my $log = Bio::Phylo::Util::Logger->new(
	'-level' => INFO,
	'-class' => [ 
		'Bio::BioVeL::Launcher',
		'Bio::BioVeL::Launcher::WriteAlignments',
	]
);

sub logger { $log };

sub launch {
	die "method launch needs to be implemented by the respective child classes";
}

1;