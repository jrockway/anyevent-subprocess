package AnyEvent::Subprocess::Running;
use Moose;
use MooseX::AttributeHelpers;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Subprocess::Done;
use List::Util qw(reduce);

with 'AnyEvent::Subprocess::Running::WithOutputCallbacks',
     'AnyEvent::Subprocess::Running::WithOutputAccumulator';

# we have to set this "later"
has 'child_pid' => (
    is  => 'rw',
    isa => 'Int',
);

after child_pid => sub {
    my ($self, $pid) = @_;
    $self->child_listener if defined $pid;
};

# this is updated by callbacks for EOF and child exit
has 'completion_flags' => (
    metaclass => 'Collection::Hash',
    is        => 'ro',
    isa       => 'HashRef',
    default   => sub {+{}},
    required  => 1,
    provides  => {
        set => 'set_completion_flag',
    },
);

# every time a callback sets a completion flag, check if everthing is
# done.  if so, send to the completion condvar
after set_completion_flag => sub {
    my $self = shift;
    my @fields = qw/stdout_handle stderr_handle/;
    my $done = reduce { $a && $b }
      (1,
      (map { $self->completion_flags->{$_} } @fields),
      exists $self->completion_flags->{child});

    if($done){
        my $status = $self->completion_flags->{child};
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
};

has 'completion_condvar' => (
    is      => 'ro',
    isa     => 'AnyEvent::CondVar',
    default => sub {
        AnyEvent->condvar,
    },
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
                $self->set_completion_flag( child => $status );
            },
        );
        return $child_listener;
    }
);

has [qw/stdout_handle stderr_handle stdin_handle comm_handle/] => (
    is       => 'ro',
    isa      => 'AnyEvent::Subprocess::Handle',
    required => 1,
);

sub _setup_handle {
    my ($self, $handle_name, $method_name) = @_;

    if($method_name){
        my $reader;
        $reader = sub {
            my ($handle, $data, $eol) = @_;
            $self->$method_name($data.$eol);
            $handle->push_read(line => $reader);
            return;
        };
        $self->$handle_name->push_read(line => $reader);
    }

    $self->$handle_name->eof_condvar->cb(sub {
      $self->set_completion_flag($handle_name, 1);
    });
}

sub BUILD {
    my ($self) = @_;
    $self->_setup_handle( 'stdout_handle', '_read_stdout' );
    $self->_setup_handle( 'stderr_handle', '_read_stderr' );
   #  $self->_setup_handle( 'comm_handle' );
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
