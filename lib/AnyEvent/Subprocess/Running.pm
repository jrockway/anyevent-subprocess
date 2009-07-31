package AnyEvent::Subprocess::Running;
use Moose;
use MooseX::AttributeHelpers;
use AnyEvent;
use AnyEvent::Subprocess::Done;
use Event::Join;

with 'MooseX::Traits';

has '+_trait_namespace' => (
    default => 'AnyEvent::Subprocess::Running::Role',
);

# we have to set this "later"
has 'child_pid' => (
    is  => 'rw',
    isa => 'Int',
    trigger => sub {
        my ($self, $pid) = @_;
        $self->child_listener if defined $pid;
    },
);

has 'child_listener' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        confess 'child_listener being built too early'
          unless $self->child_pid;

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

has 'child_events' => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    builder => '_build_child_events',
);

sub _build_child_events {
    my $self = shift;
    return [qw/child/];
}

sub _finalize {
    my $self = shift;
    return;
}

has 'child_event_joiner' => (
    is       => 'ro',
    isa      => 'Event::Join',
    required => 1,
    default  => sub {
        my $self = shift;
        return Event::Join->new(
            events        => $self->child_events,
            on_completion => sub {
                my $events = shift;
                my $status = $events->{child};

                $self->completion_condvar->send(
                    AnyEvent::Subprocess::Done->new(
                        exit_status => $status,
                    ),
                );

                $self->_finalize;
            }
        );
    },
);

sub kill {
    my $self = shift;
    my $signal = shift || 9;

    kill $signal, $self->child_pid; # BAI
}

1;
