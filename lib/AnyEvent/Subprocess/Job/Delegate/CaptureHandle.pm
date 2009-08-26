package AnyEvent::Subprocess::Job::Delegate::CaptureHandle;
use Moose;
use AnyEvent::Subprocess::Running::Delegate::CaptureHandle;

with 'AnyEvent::Subprocess::Job::Delegate';

has 'handle' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub build_run_delegates {
    my $self = shift;
    return AnyEvent::Subprocess::Running::Delegate::CaptureHandle->new(
        name => $self->name,
    );
}

sub parent_setup_hook {
    my ($self, $run) = @_;

    $run->delegate($self->handle)->handle->on_read( sub {
        my ($handle) = @_;
        my $buf = delete $handle->{rbuf};
        $run->delegate($self->name)->_append_output($buf);
    });
}

sub build_code_args {}
sub child_finalize_hook {}
sub child_setup_hook {}
sub parent_finalize_hook {}

1;
