package AnyEvent::Subprocess::Types;
use MooseX::Types -declare => [ qw{
    Direction
    JobDelegate
    RunDelegate
    DoneDelegate
    SubprocessCode
}];

use MooseX::Types::Moose qw(Str ArrayRef CodeRef);

subtype Direction, as Str, where {
    $_ eq 'r' || $_ eq 'w' || $_ eq 'rw'
};

role_type JobDelegate, { role => 'AnyEvent::Subprocess::Job::Delegate' };
role_type RunDelegate, { role => 'AnyEvent::Subprocess::Running::Delegate' };
role_type DoneDelegate, { role => 'AnyEvent::Subprocess::Done::Delegate' };

subtype SubprocessCode, as CodeRef;

coerce SubprocessCode, from Str, via {
    my $cmd = $_;
    return sub { exec $cmd };
};

coerce SubprocessCode, from ArrayRef[Str], via {
    my $cmd = $_;
    return sub { exec @$cmd };
};

1;
