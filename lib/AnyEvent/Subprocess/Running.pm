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
    is         => 'ro',
    default => sub {
        my $self = shift;

        my $child_listener = AnyEvent->child(
            pid => $self->child_pid,
            cb => sub {
                my ($pid, $status) = @_;

                # make sure we didn't miss anything
                $self->_read_stdout( $self->stdout_handle->{rbuf} )
                  if defined $self->stdout_handle->{rbuf};
                $self->_read_stderr( $self->stderr_handle->{rbuf} )
                  if defined $self->stderr_handle->{rbuf};

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
    $self->_unblock_child;
}

# we start the child reading from STDIN before we do anything else, so
# that the code block doesn't start executing until we are ready to
# receive its output.  This method puts a line into STDIN, that is
# discarded and then causes the child to actually start.
sub _unblock_child {
    my $self = shift;
    $self->stdin_handle->push_write("\015\012");
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
