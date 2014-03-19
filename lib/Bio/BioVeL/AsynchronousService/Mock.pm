package Bio::BioVeL::AsynchronousService::Mock;
use strict;
use warnings;
use Bio::BioVeL::AsynchronousService;
use base 'Bio::BioVeL::AsynchronousService';

sub new {
	shift->SUPER::new( 'parameters' => [ 'seconds' ], @_ );
}

sub launch {
	my $self = shift;
	if ( system("sleep", ( $self->seconds || 2 ) ) ) {
		$self->status( Bio::BioVeL::AsynchronousService::ERROR );
		$self->lasterr( $? );
	}
	else {
		$self->status( Bio::BioVeL::AsynchronousService::DONE );
	}
}

sub response_body { "I slept for ".shift->seconds." seconds" }

1;