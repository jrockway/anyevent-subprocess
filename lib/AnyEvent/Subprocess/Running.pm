package AnyEvent::Subprocess::Running;
use Moose;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Subprocess::Done;

with 'AnyEvent::Subprocess::Running::WithOutputCallbacks',
     'AnyEvent::Subprocess::Running::WithOutputAccumulator';

# we have to set this "later"
has 'child_pid' => (
    is  => 'rw',
    isa => 'Int',
);

has 'child_listener' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $child_listener = AnyEvent->child(
            pid => $self->child_pid,
            cb => sub {
                my ($pid, $status) = @_;
                $self->_send_completion_message($status);
            },
        );

        return $child_listener;
    }
);

has 'completion_condvar' => (
    is      => 'ro',
    isa     => 'AnyEvent::CondVar',
    default => sub {
        AnyEvent->condvar,
    },
);

has [qw/stdout_handle stderr_handle stdin_handle comm_handle/] => (
    is       => 'ro',
    isa      => 'AnyEvent::Handle',
    required => 1,
);

sub _setup_handle {
    my ($self, $handle_name, $method_name) = @_;

    my $reader;
    $reader = sub {
        my ($handle, $data, $eol) = @_;
        $self->$method_name($data.$eol);
        $handle->push_read(line => $reader);
    };
    $self->$handle_name->push_read(line => $reader);
}

sub _send_completion_message {
    my ($self, $status) = @_;

    # for some reason, we need to call into the event loop one more
    # time to get our last events.  i tried waiting for the handles to
    # send EOF events, but they never get sent.
    my $var = AnyEvent->condvar;
    if(AnyEvent::detect() eq 'AnyEvent::Impl::EV'){
        # for some reason, the EV event loop gets stuck and needs help
        # getting restarted.  i really need to figure this out and fix
        # it.
        EV::loop(EV::LOOP_NONBLOCK());
    }
    $var->send;
    $var->recv;

    $self->completion_condvar->send(
        AnyEvent::Subprocess::Done->new(
            exit_status => $status,
            exit_value  => ($status >> 8),
            exit_signal => ($status & 127),
            dumped_core => ($status & 128),
            stdout      => $self->stdout,
            stderr      => $self->stderr,
        ),
    );
}

sub BUILD {
    my ($self) = @_;
    $self->_setup_handle( 'stdout_handle', '_read_stdout' );
    $self->_setup_handle( 'stderr_handle', '_read_stderr' );
}

# hook these with roles (or a subclass)
sub _read_stdout { my ($self, $data) = @_ }
sub _read_stderr { my ($self, $data) = @_ }

# utility methods

sub kill {
    my $self = shift;
    my $signal = shift || 9;

    kill $signal, $self->child_pid; # BAI
}

1;
