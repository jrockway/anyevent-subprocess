package AnyEvent::Subprocess::Done::Delegate::Timeout;

# ABSTRACT: done delegate for a job that can time out
use Moose;
use namespace::autoclean;

with 'AnyEvent::Subprocess::Done::Delegate';

has 'timed_out' => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 ATTRIBUTES

=head2 timed_out

True if the job was killed because it ran out of time.
