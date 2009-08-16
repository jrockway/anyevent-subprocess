package AnyEvent::Subprocess::Types;
use MooseX::Types -declare => ['Direction'];

use MooseX::Types::Moose qw(Str);

subtype Direction, as Str, where {
    $_ eq 'r' || $_ eq 'w' || $_ eq 'rw'
};

1;
