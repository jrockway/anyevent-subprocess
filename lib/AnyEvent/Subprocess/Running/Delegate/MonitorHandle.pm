package AnyEvent::Subprocess::Running::Delegate::MonitorHandle;

# ABSTRACT: Running part of the MonitorHandle delegate
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
    my ($self, $running, $args) = @_;

    my $leftover =
      delete $args->{run}->delegate($self->_job_delegate->handle)->handle->{rbuf};

    $self->_run_callbacks( $leftover ) if $leftover;
}

__PACKAGE__->meta->make_immutable;

1;
