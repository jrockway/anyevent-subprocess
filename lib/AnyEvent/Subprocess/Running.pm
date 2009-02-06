package AnyEvent::Subprocess::Running;
use Moose;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Subprocess::Done;

with 'AnyEvent::Subprocess::Running::WithOutputCallbacks',
     'AnyEvent::Subprocess::Running::WithOutputAccumulator';

has 'child_pid' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'child_listener' => (
    is       => 'ro',
    # is probably a EV::Child
    required => 1,
);

has 'completion_condvar' => (
    is       => 'ro',
    isa      => 'AnyEvent::CondVar',
    required => 1,
);

has [qw/stdout_handle stderr_handle/] => (
    is       => 'ro',
    isa      => 'AnyEvent::Handle',
    required => 1,
);

sub _setup_handle {
    my ($self, $handle_name, $method_name) = @_;
    $self->$handle_name->on_read(
        sub {
            my ($handle) = @_;
            $self->$method_name($handle->{rbuf});
            $handle->{rbuf} = '';
        },
    );
}

sub BUILD {
    my ($self) = @_;
    $self->_setup_handle( 'stdout_handle', '_read_stdout' );
    $self->_setup_handle( 'stderr_handle', '_read_stderr' );
    $self->child_listener->cb( sub {
        my ($pid, $status) = @_;
        warn $status;
        warn $status & 127;
        warn $status >> 8;
        $self->completion_condvar->send(
            AnyEvent::Subprocess::Done->new(
                exit_status => ($status >> 8),
                stdout      => $self->stdout,
                stderr      => $self->stderr,
            ),
        );
    });
}

sub _read_stdout {
    my ($self, $data) = @_;
}

sub _read_stderr {
    my ($self, $data) = @_;
}

1;
__END__

# internals below
has [qw/_stdout_glob _stderr_glob _stdin_glob/] => (
    is  => 'rw', # don't touch this outside of BUILD
    isa => 'GlobRef',
);

has [qw/_stdout_handle _stderr_handle _stdin_handle/] => (
    is  => 'rw', # don't touch this outside of BUILD
    isa => 'AnyEvent::Handle',
);

has '_socketpair' => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy       => 1,
    auto_deref => 1,
    default    => sub {
        my $self = shift;
        my ($r, $w) = portable_socketpair;
        [$r, $w];
    },
);

1;
