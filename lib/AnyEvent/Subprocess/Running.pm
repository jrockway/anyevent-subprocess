package AnyEvent::Subprocess::Running;

# ABSTRACT: represents a running subprocess
use Moose;
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
    clearer => 'cleanup_child_watcher',
    default => sub {
        my $self = shift;
        confess 'child_listener being built too early'
          unless $self->child_pid;

        my $child_listener = AnyEvent->child(
            pid => $self->child_pid,
            cb => sub {
                my ($pid, $status) = @_;
                $self->child_event_joiner->send_event( child => $status );
                $self->cleanup_child_watcher;
            },
        );
        return $child_listener;
    }
);

has 'on_completion' => (
    is       => 'ro',
    isa      => 'CodeRef',
    default  => sub { sub {} },
    required => 1,
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

    my $done = AnyEvent::Subprocess::Done->new(
        delegates   => [$self->_invoke_delegates('build_done_delegates')],
        exit_status => $status,
    );

    $args{done} = $done;
    $args{run} = $self;
    $self->_invoke_delegates('completion_hook', \%args);
    $self->on_completion->($done);
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

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

We are C<$run> in a sequence like:

   my $job = AnyEvent::Subprocess->new ( ... );
   my $run = $job->run;
   $run->delegate('stdin')->push_write('Hello, my child!');
   say "Running child as ", $run->child_pid;
   $run->kill(11) if $you_enjoy_that_sort_of_thing;
   my $done = $job->delegate('completion_condvar')->recv;
   say "Child exited with signal ", $done->exit_signal;

=head1 DESCRIPTION

An instance of this class is returned when you start a subprocess.  It
contains the child pid, any delegates that operate on the running
subprocess (handles, captures, etc.), and some control methods.

=head1 METHODS

=head2 child_pid

Returns the pid of the child

=head2 kill($signal)

Kills the child with signal number C<$signal>

=head2 delegate($name)

Returns the delegate named C<$name>

=head1 SEE ALSO

L<AnyEvent::Subprocess>

L<AnyEvent::Subprocess::Role::WithDelegates>

