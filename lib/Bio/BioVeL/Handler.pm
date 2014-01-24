package Bio::BioVeL::Handler;
use strict;
use warnings;
use JSON;
use MIME::Base64;
use LWP::UserAgent;
use Bio::BioVeL::Job;
use Apache2::Request;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK);
use File::Temp qw[tempfile];

sub handler {
	my $r = shift;
	my $req = Apache2::Request->new($r);
	
	# create or lookup a job
	my %args = map { $_ => $req->param($_) } $req->param;
	my $job = Bio::BioVeL::Job->new(%args); # just need NAME
		
	# job was newly instantiated
	if ( $job->status == LAUNCHING ) {
	
		# decode the arguments
		my $args_json_string = decode_base64($args{'arguments'});
		my $args_hash_ref    = decode_json($json_string);
	
		# download the input files from their URLs
		my $ua = LWP::UserAgent->new;
		my %files;
		for my $param ( $job->fileparams ) {
			my $url = delete $args_hash_ref->{$param};
			my $response = $ua->get($url);
			if ( $response->is_success ) {
				my ( $fh, $filename ) = tempfile( 'DIR' => $job->jobdir );
				print $fh $response->decoded_content;
				$files{$param} = $filename;
			}
		}
		$job->infile(\%files);
		$job->arguments($args_hash_ref);
		
		# launch
		$job->run;
	}

	# return result
	$r->content_type('application/xml');
	print $job->to_xml;

	return Apache2::Const::OK;
}

1;