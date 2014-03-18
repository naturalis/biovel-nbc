package Bio::BioVeL::Service;
use strict;
use warnings;
use Getopt::Long;
use CGI;
use Apache2::Request;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK);
use LWP::UserAgent;
use Bio::Phylo::Util::Logger ':levels';

my $log = Bio::Phylo::Util::Logger->new( 
	'-level' => DEBUG, 
	'-class' => 'Bio::BioVeL::Service::NeXMLMerger',
);
our $AUTOLOAD;

sub new {
	my $class = shift;
	my %args  = @_;
	my $self  = { '_params' => {} };
	my $params = $args{'parameters'};
	if ( $params ) {
		if ( @ARGV ) {
			my %getopt;
			for my $p ( @{ $params } ) {
				$getopt{"${p}=s"} = sub {
					my $value = pop;
					$self->{'_params'}->{$p} = $value;
				};
			}
			GetOptions(%getopt);			
		}
		elsif ( my $req = $args{'request'} ) {
			for my $p ( @{ $params } ) {
				$self->{'_params'}->{$p} = $req->param($p);
			}		
		}
		else {
			my $cgi = CGI->new;
			for my $p ( @{ $params } ) {
				$self->{'_params'}->{$p} = $cgi->param($p);
			}
		}
	}
	return bless $self, $class;
}

sub AUTOLOAD {
	my $self = shift;
	my $method = $AUTOLOAD;
	$method =~ s/.+://;
	if ( $method !~ /^[A-Z]+$/ ) {
		if ( @_ ) {
			$self->{'_params'}->{$method} = shift;
		}
		return $self->{'_params'}->{$method};
	}	
}

=over

=item get_handle

Given a string parameter name, such as 'tree', returns a readable handle that corresponds
with the specified data.

=cut

sub get_handle {
	my ( $self, $location ) = @_;
	
	# location is a URL
	if ( $location =~ m#^(?:http|ftp|https)://# ) {
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

=item handler

Handles request within the context of mod_perl

=cut

sub handler {
	my $request = Apache2::Request->new(shift);
	my $subclass = __PACKAGE__ . '::' . $request->param('service');
	eval "require $subclass";
	my $self = $subclass->new( 'request' => $request );
	print $self->response_header, $self->response_body;
	return Apache2::Const::OK;
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

=item logger

Returns a logger object.

=cut

sub logger { $log }

=back

=cut

1;