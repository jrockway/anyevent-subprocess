package AnyEvent::Subprocess::Running::Delegate::CompletionCondvar;
use Moose;
use AnyEvent;

with 'AnyEvent::Subprocess::Running::Delegate';

has 'condvar' => (
    is       => 'ro',
    isa      => 'AnyEvent::CondVar',
    default  => sub { AnyEvent->condvar },
    handles  => [qw[send recv]],
    required => 1,
);

sub completion_hook {
    my ($self, $args) = @_;
    $self->send($args->{done});
}

sub build_events {}
sub build_done_delegates {}

1;
