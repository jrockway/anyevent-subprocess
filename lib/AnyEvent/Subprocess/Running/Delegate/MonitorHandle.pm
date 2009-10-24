package AnyEvent::Subprocess::Running::Delegate::MonitorHandle;
use Moose;
use namespace::clean;

with 'AnyEvent::Subprocess::Running::Delegate';

has '_job_delegate' => (
    is       => 'ro',
    isa      => 'AnyEvent::Subprocess::Job::Delegate::MonitorHandle',
    handles  => ['_run_callbacks'],
    required => 1,
);

sub build_events {}
sub build_done_delegates {}

sub completion_hook {
    my ($self, $args) = @_;

    my $leftover =
      delete $args->{run}->delegate($self->_job_delegate->handle)->handle->{rbuf};

    $self->_run_callbacks( $leftover ) if $leftover;
}

1;
