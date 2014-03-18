package Bio::BioVeL::Service;
use strict;
use warnings;
use Getopt::Long;
use CGI;
use LWP::UserAgent;

sub new { return bless {}, shift }

=over

=item get_param

Given a string parameter name, such as 'treeformat', returns the parameter value, such
as 'newick'. How the service finds out where to get the values is nobody's business, but
it will most likely come from CGI.

=cut

sub get_param {
	my ( $self, $param ) = @_;
	
	# running on the shell
	if ( @ARGV ) {
		my $value;
		GetOptions( "${param}=s" => \$value );
		return $value;
	}
	
	# running on a server
	else {
		my $cgi = CGI->new;
		return $cgi->param($param);
	}
}

=item get_handle

Given a string parameter name, such as 'tree', returns a readable handle that corresponds
with the specified data.

=cut

sub get_handle {
	my ( $self, $param ) = @_;
	
	# find out the location
	my $location;
	if ( @ARGV ) {
		GetOptions( "${param}=s" => \$location );
	}
	else {
		my $cgi = CGI->new;
		$location = $cgi->param($param);
	}
	
	# location is a URL
	if ( $location =~ /^http:/ ) {
		my $ua = LWP::UserAgent->new;
		my $response = $ua->get($location);
		if ( $response->is_success ) {
			my $content = $response->decoded_content;
			open my $fh, '<', \$content;
			return $fh;
		}
	}
	else {
		open my $fh, '<', $location or die $!;
		return $fh;
	}
}

=item response_header

Returns the HTTP response header. This might include the content-type.

=cut

sub response_header {
	die "Implement me!";
}

=item response_body

Returns the response body as a big string.

=cut

sub response_body {
	die "Implement me!";
}

=back

=cut

1;