package AnyEvent::Subprocess::Done::Delegate::State;
use Moose;

with 'AnyEvent::Subprocess::Done::Delegate';

has 'state' => ( is => 'ro', isa => 'HashRef', required => 1 );

1;

__END__

=head1 NAME
