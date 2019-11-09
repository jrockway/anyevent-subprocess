package AnyEvent::Subprocess::Running::Delegate;

# ABSTRACT: delegate on the running process class
use Moose::Role;

with 'AnyEvent::Subprocess::Delegate';

has 'event_senders' => (
    is        => 'rw',
    isa       => 'HashRef',
    predicate => 'has_event_senders',
);

# you can call this before event_senders are vivified
sub event_sender_for {
    my ($self, $event) = @_;
    return sub {
        my $val = shift;
        $self->send_event($event, $val);
    }
}

sub send_event {
    my ($self, $event, $value) = @_;
    confess "No event senders set yet!"
      unless $self->has_event_senders;
    my $sender = $self->event_senders->{$event};
    confess "No event sender '$event' found"
      unless $sender && ref $sender;

    $sender->($value);
    return;
}

requires 'build_events';
requires 'build_done_delegates';
requires 'completion_hook';

1;

__END__

=head1 REQUIRED METHODS

Delegates must implement these methods:

=head2 build_events

Return a list of events that need to be sent before the run will be
considered complete

=head2 build_done_delegates

Return a list of delegates to be passed to the "done" instance.

=head2 completion_hook

Called after all events are received but before calling the final
C<on_complete> method.

=head1 METHODS

=head2 event_sender_for($name)

Returns the event sender coderef for the event named C<$name>.
C<$name> should have been returned by C<build_events>, otherwise this
will break.

=head2 send_event($name, $value)

Method that works like calling the coderef returned by
C<event_sender_for($name)>.

