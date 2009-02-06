package AnyEvent::Subprocess::Done;
use Moose;

has 'exit_status' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has [qw/stdout stderr/] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;
