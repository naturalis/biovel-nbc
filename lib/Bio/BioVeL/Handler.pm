package Bio::BioVeL::Handler;
use strict;
use warnings;
use LWP::UserAgent;
use Bio::BioVeL::Job;
use Apache2::Request;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK);

sub handler {
	my $r = shift;
	my $req = Apache2::Request->new($r);
	
	# create or lookup a job
	my %args = map { $_ => $req->param($_) } $req->param;
	my $job = Bio::BioVeL::Job->new(%args);
	
	# job was newly instantiated
	$job->run if $job->status == LAUNCHING;

	# return result
	$r->content_type('application/xml');
	print $job->to_xml;

	return Apache2::Const::OK;
}
1;