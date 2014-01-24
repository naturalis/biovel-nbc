package Bio::BioVeL::Job::simulate;
use Bio::BioVeL::Job;
use base 'Bio::BioVeL::Job';

sub name { 'biovel_simulate.pl' }

sub fileparams { qw[file] }

1;