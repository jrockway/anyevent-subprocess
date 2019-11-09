package AnyEvent::Subprocess::Done::Delegate::Handle;

# ABSTRACT: store leftover wbuf/rbuf from running Handle
use Moose;
use namespace::autoclean;

with 'AnyEvent::Subprocess::Done::Delegate';

has 'rbuf' => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_rbuf',
);

has 'wbuf' => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_wbuf',
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 ATTRIBUTES

=head2 rbuf

=head2 wbuf

Attributes to store leftover data in the handle's rbuf or wbuf.

=head1 METHODS

=head2 rbuf

=head2 wbuf

Return the residual data.

=head2 has_rbuf

=head2 has_wbuf

Check for existence of residual data.
