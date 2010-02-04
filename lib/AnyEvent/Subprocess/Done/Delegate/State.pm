package AnyEvent::Subprocess::Done::Delegate::State;
use Moose;

with 'AnyEvent::Subprocess::Done::Delegate';

has 'state' => ( is => 'ro', isa => 'HashRef', required => 1 );

1;

__END__

=head1 NAME

AnyEvent::Subprocess::Done::Delegate::State

=head1 DESCRIPTION

Allows state to be passed from Job -> Run -> Done.

=head1 STATE

Returns the state received from the Run object.
