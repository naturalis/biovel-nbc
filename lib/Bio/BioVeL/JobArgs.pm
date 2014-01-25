package Bio::BioVeL::JobArgs;
use strict;
use warnings;
use JSON;
use MIME::Base64;
use LWP::UserAgent;
use File::Temp qw[tempfile];

sub new {
	my ( $class, $argstring, $job ) = @_;
	
	# decode the arguments
	my $args_json_string = decode_base64($argstring);
	my $args_hash_ref    = decode_json($args_json_string);

	# download the input files from their URLs
	my %files;
	my $ua = LWP::UserAgent->new;
	for my $param ( $job->fileparams ) {
		my $url = delete $args_hash_ref->{$param};
		my $response = $ua->get($url);
		if ( $response->is_success ) {
			my ( $fh, $filename ) = tempfile( 'DIR' => $job->jobdir );
			print $fh $response->decoded_content;
			$files{$param} = $filename;
		}
	}
	return bless { 
		'files'   => \%files, 
		'args'    => $args_hash_ref,
		'encoded' => $argstring,
	}, $class;
}

sub encoded { shift->{'encoded'} }

sub files { shift->{'files'} }

sub args { shift->{'args'} }

1;