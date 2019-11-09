package AnyEvent::Subprocess::Running::Delegate::Timeout;

# ABSTRACT: Running part of Timeout delegate
use Moose;
use namespace::autoclean;
use AnyEvent::Subprocess::Done::Delegate::Timeout;

with 'AnyEvent::Subprocess::Running::Delegate';

has 'timer' => (
    is       => 'ro',
    clearer  => 'clear_timer',
);

has 'killed_by_timer' => (
    init_arg => undef,
    accessor => 'killed_by_timer',
    default  => sub { undef },
);

sub completion_hook {
    my $self = shift;
    $self->clear_timer;
}

sub build_done_delegates {
    my $self = shift;
    return AnyEvent::Subprocess::Done::Delegate::Timeout->new(
        name      => $self->name,
        timed_out => $self->killed_by_timer,
    );
}

sub build_events {}
sub build_code_args {}

__PACKAGE__->meta->make_immutable;

1;
