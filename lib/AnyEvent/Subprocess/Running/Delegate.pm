package AnyEvent::Subprocess::Running::Delegate;
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
