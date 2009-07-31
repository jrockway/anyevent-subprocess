package AnyEvent::Subprocess::Running::Role::WithStandardHandles;
use Moose::Role;
use AnyEvent::Subprocess::Handle;

has [qw/stdin_handle stdout_handle stderr_handle/] => (
    is       => 'ro',
    isa      => 'AnyEvent::Subprocess::Handle',
    required => 1,
);

around '_build_child_events' => sub {
    my ($next, $self) = @_;
    my $other_events = $self->$next;
    return [@$other_events, qw/stdout_handle stderr_handle/];
};

sub BUILD {
    my ($self) = @_;

    for my $handle_name (qw/stdout_handle stderr_handle/){
        $self->$handle_name->eof_condvar->cb(
            $self->child_event_joiner->event_sender_for($handle_name),
        );
    }
}

1;
