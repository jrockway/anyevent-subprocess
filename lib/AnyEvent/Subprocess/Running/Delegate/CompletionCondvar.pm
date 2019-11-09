package AnyEvent::Subprocess::Running::Delegate::CompletionCondvar;

# ABSTRACT: Running part of the CompletionCondvar delegate
use Moose;
use AnyEvent;

with 'AnyEvent::Subprocess::Running::Delegate';

has 'condvar' => (
    is       => 'ro',
    isa      => 'AnyEvent::CondVar',
    default  => sub { AnyEvent->condvar },
    handles  => [qw[send recv]],
    required => 1,
);

sub completion_hook {
    my ($self, $running, $args) = @_;
    $self->send($args->{done});
}

sub build_events {}
sub build_done_delegates {}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 ATTRIBUTES

=head2 condvar

An L<AnyEvent::Condvar> that is invoked with the C<Done> instance when
the process exits.

=head3 send

=head3 recv

These methods are delegated from the condvar to this class, to save a
bit of typing.
