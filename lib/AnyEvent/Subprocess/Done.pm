package AnyEvent::Subprocess::Done;
use Moose;

# $? is the exit_status, the argument to exit ("exit 0") is exit_value
# if the process was killed, exit_signal contains the signal that killed it
has 'exit_status' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'dumped_core' => (
    is         => 'ro',
    isa        => 'Bool',
    lazy_build => 1,
);

has [qw[exit_value exit_signal]] => (
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1,
);

sub _build_exit_value {
    my $self = shift;
    return $self->exit_status >> 8;
}

sub _build_exit_signal {
    my $self = shift;
    return $self->exit_status & 127;
}

sub _build_dumped_core {
    my $self = shift;
    return $self->exit_status & 128;
}

1;
