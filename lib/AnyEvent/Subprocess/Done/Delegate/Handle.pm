package AnyEvent::Subprocess::Done::Delegate::Handle;
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
