package AnyEvent::Subprocess::Running::Delegate::Callback;

# ABSTRACT: the C<Running> part of the Callback delegate
use Moose;

use AnyEvent::Subprocess::Done::Delegate::State; # name change

with 'AnyEvent::Subprocess::Running::Delegate';

has 'completion_hook' => (
    init_arg => 'completion_hook',
    reader   => '_completion_hook',
    isa      => 'CodeRef',
    default  => sub { sub {} },
    required => 1,
);


has 'state' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
    default  => sub { +{} },
);

sub completion_hook {
    my ($self, $running, @args) = @_;
    $self->_completion_hook->($self, @args);
}

sub build_done_delegates {
    my ($self) = @_;
    return AnyEvent::Subprocess::Done::Delegate::State->new(
        name  => $self->name,
        state => $self->state,
    );
}
sub build_events {}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 DESCRIPTION

Calls the completion hook that was setup in the Job delegate, passes
saved state to the Done delegate.
