package AnyEvent::Subprocess::Running;
use Moose;
use MooseX::AttributeHelpers;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Subprocess::Done;
use Event::Join;

# we have to set this "later"
has 'child_pid' => (
    is  => 'rw',
    isa => 'Int',
);

after child_pid => sub {
    my ($self, $pid) = @_;
    $self->child_listener if defined $pid;
};

has 'child_listener' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $child_listener = AnyEvent->child(
            pid => $self->child_pid,
            cb => sub {
                my ($pid, $status) = @_;
                $self->child_event_joiner->send_event( child => $status );
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

has 'child_event_joiner' => (
    is       => 'ro',
    isa      => 'Event::Join',
    required => 1,
    default  => sub {
        my $self = shift;
        return Event::Join->new(
            events        => [qw/stdout_handle stderr_handle child/],
            on_completion => sub {
                my $events = shift;
                my $status = $events->{child};

                $self->completion_condvar->send(
                    AnyEvent::Subprocess::Done->new(
                        exit_status => $status,
                        exit_value  => ($status >> 8),
                        exit_signal => ($status & 127),
                        dumped_core => ($status & 128),
                    ),
                );

                for my $name (qw/stdin_handle stdout_handle stderr_handle comm_handle/){
                    my $h = $self->$name;
                    my $method = "close_$name";
                    $self->$method;
                }
            }
        );
    },
);

has [qw/stdin_handle stdout_handle stderr_handle comm_handle/] => (
    is       => 'ro',
    isa      => 'AnyEvent::Subprocess::Handle',
    required => 1,
);

for my $handle (map { "${_}_handle" } qw/stdin stdout stderr comm/){
    __PACKAGE__->meta->add_method(
        "close_${handle}" => sub {
            my $self = shift;
            my $fh = $self->$handle->fh;
            close $fh if $fh; # closing "again" is not an error
        },
    );
}

sub BUILD {
    my ($self) = @_;

    for my $handle_name (qw/stdout_handle stderr_handle/){
        $self->$handle_name->eof_condvar->cb(
            $self->child_event_joiner->event_sender_for($handle_name),
        );
    }
}

sub kill {
    my $self = shift;
    my $signal = shift || 9;

    kill $signal, $self->child_pid; # BAI
}

1;
