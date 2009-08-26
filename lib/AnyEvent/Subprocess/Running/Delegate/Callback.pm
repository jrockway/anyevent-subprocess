package AnyEvent::Subprocess::Running::Delegate::Callback;
use Moose;

with 'AnyEvent::Subprocess::Running::Delegate';

has 'completion_hook' => (
    init_arg => 'completion_hook',
    reader   => '_completion_hook',
    isa      => 'CodeRef',
    default  => sub { sub {} },
    required => 1,
);

sub completion_hook {
    my ($self, @args) = @_;
    $self->_completion_hook->($self, @args);
}

sub build_done_delegates {}
sub build_events {}

1;
