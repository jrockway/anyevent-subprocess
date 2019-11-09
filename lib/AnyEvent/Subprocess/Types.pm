package AnyEvent::Subprocess::Types;

# ABSTRACT: C<MooseX::Types> used internally
use MooseX::Types -declare => [ qw{
    Direction
    JobDelegate
    RunDelegate
    DoneDelegate
    SubprocessCode
    CodeList
    WhenToCallBack
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
    return sub { no warnings; exec $cmd or die "Failed to exec '$cmd': $!" };
};

coerce SubprocessCode, from ArrayRef[Str], via {
    my $cmd = $_;
    my $str = join ' ', @$cmd;
    return sub { no warnings; exec @$cmd or die "Failed to exec '$str': $!" };
};

subtype CodeList, as ArrayRef[CodeRef];
coerce CodeList, from CodeRef, via { [$_] };

enum WhenToCallBack, [qw/Readable Line/];

1;

__END__

=head1 TYPES

    Direction
    JobDelegate
    RunDelegate
    DoneDelegate
    SubprocessCode
    CodeList
    WhenToCallBack
