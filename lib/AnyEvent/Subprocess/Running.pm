package AnyEvent::Subprocess::Running;
use Moose;
use MooseX::AttributeHelpers;
use Event::Join;

use AnyEvent;
use AnyEvent::Subprocess::Done;
use AnyEvent::Subprocess::Types qw(RunDelegate);

with 'AnyEvent::Subprocess::Role::WithDelegates' => {
    type => RunDelegate,
};

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
    return [qw/child/, $self->_invoke_delegates('build_events')];
}

has 'child_event_joiner' => (
    is       => 'ro',
    isa      => 'Event::Join',
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my $joiner = Event::Join->new(
            events        => $self->child_events,
            on_completion => sub {
                my $events = shift;
                my $status = $events->{child};

                $self->_completion_hook(
                    events => $events,
                    status => $status,
                );
            }
        );

        for my $d ($self->_delegates){
            my %events = map { $_ => $joiner->event_sender_for($_) } $d->build_events;
            $d->event_senders(\%events);
        }

        return $joiner;
    },
);

sub _completion_hook {
    my ($self, %args) = @_;
    my $status = $args{status};

    $self->_invoke_delegates('completion_hook', \%args);

    $self->completion_condvar->send(
        AnyEvent::Subprocess::Done->new(
            delegates   => [$self->_invoke_delegates('build_done_delegates')],
            exit_status => $status,
        ),
    );
}

sub kill {
    my $self = shift;
    my $signal = shift || 9;

    kill $signal, $self->child_pid; # BAI
}

sub BUILD {
    my $self = shift;
    $self->child_event_joiner; # vivify
}

1;
