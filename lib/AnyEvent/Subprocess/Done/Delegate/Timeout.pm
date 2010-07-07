package AnyEvent::Subprocess::Done::Delegate::Timeout;
use Moose;
use namespace::autoclean;

with 'AnyEvent::Subprocess::Done::Delegate';

has 'timed_out' => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);

1;
