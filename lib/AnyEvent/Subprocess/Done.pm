package AnyEvent::Subprocess::Done;
use Moose;

has [qw/exit_status exit_signal/] => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'dumped_core' => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);

has [qw/stdout stderr/] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;
