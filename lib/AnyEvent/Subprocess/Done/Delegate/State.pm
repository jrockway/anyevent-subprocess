package AnyEvent::Subprocess::Done::Delegate::State;

# ABSTRACT: thread state through the job/run/done lifecycle
use Moose;

with 'AnyEvent::Subprocess::Done::Delegate';

has 'state' => ( is => 'ro', isa => 'HashRef', required => 1 );

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 DESCRIPTION

Allows state to be passed from Job -> Run -> Done.

=head1 ATTRIBUTES

=head2 state

Returns the state received from the Run object.
