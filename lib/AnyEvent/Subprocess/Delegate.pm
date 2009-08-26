package AnyEvent::Subprocess::Delegate;
use Moose::Role;

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;
