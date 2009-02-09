package AnyEvent::Subprocess::Done;
use Moose;

# $? is the exit status, the argument to exit ("exit 0") is the value
# if the process was killed, exit_signal contains the signal that killed it
has [qw/exit_status exit_value exit_signal/] => (
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
