package AnyEvent::Subprocess::Types;
use MooseX::Types -declare => [ qw{
    Direction
    JobDelegate
    RunDelegate
    DoneDelegate
}];

use MooseX::Types::Moose qw(Str HashRef);

subtype Direction, as Str, where {
    $_ eq 'r' || $_ eq 'w' || $_ eq 'rw'
};

role_type JobDelegate, { role => 'AnyEvent::Subprocess::Job::Delegate' };
role_type RunDelegate, { role => 'AnyEvent::Subprocess::Running::Delegate' };
role_type DoneDelegate, { role => 'AnyEvent::Subprocess::Done::Delegate' };

1;
