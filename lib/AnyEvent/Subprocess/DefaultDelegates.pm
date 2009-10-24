package AnyEvent::Subprocess::DefaultDelegates;
use strict;
use warnings;
use Carp qw(confess);

use AnyEvent::Subprocess::Role::WithDelegates::Manager qw(register_delegate);

use AnyEvent::Subprocess::Job::Delegate::Callback;
use AnyEvent::Subprocess::Job::Delegate::CaptureHandle;
use AnyEvent::Subprocess::Job::Delegate::CompletionCondvar;
use AnyEvent::Subprocess::Job::Delegate::Handle;
use AnyEvent::Subprocess::Job::Delegate::MonitorHandle;
use AnyEvent::Subprocess::Job::Delegate::Pty;

register_delegate( 'Handle' => 'AnyEvent::Subprocess::Job::Delegate::Handle' );

register_delegate( 'StandardHandles' => sub {
    my $args = shift || {};
    my $prefix = $args->{prefix} || '';
    my $class  = $args->{class}  || 'AnyEvent::Subprocess::Job::Delegate::Handle';

    return (
        $class->new(
            name      => "${prefix}stdin",
            direction => 'w',
            replace   => \*STDIN,
        ),
        $class->new(
            name      => "${prefix}stdout",
            direction => 'r',
            replace   => \*STDOUT,
        ),
        $class->new(
            name      => "${prefix}stderr",
            direction => 'r',
            replace   => \*STDERR,
        ),
    );
});

register_delegate( 'CommHandle' => sub {
    my $args = shift || {};
    my $name = $args->{name} || 'comm';

    return AnyEvent::Subprocess::Job::Delegate::Handle->new(
        name          => $name,
        direction     => 'rw',
        pass_to_child => 1,
    );
});

register_delegate( 'Pty' => sub {
    my $args = shift || {};
    $args->{name} ||= 'pty';

    if(delete $args->{stderr}){
        $args->{redirect_handles} = [
            \*STDIN,
            \*STDOUT,
            \*STDERR,
        ];
    }

    return AnyEvent::Subprocess::Job::Delegate::Pty->new(%$args);
});

register_delegate( 'CompletionCondvar' => sub {
    my $args = shift || {};
    $args->{name} ||= 'completion_condvar';

    return AnyEvent::Subprocess::Job::Delegate::CompletionCondvar->new(%$args);
});

register_delegate( 'Callback' => sub {
    my $args = shift || {};
    $args->{name} ||= 'callback';

    return AnyEvent::Subprocess::Job::Delegate::Callback->new(%$args);
});

register_delegate( 'Capture' => sub {
    my $args = shift || {};
    confess 'need handle' unless $args->{handle};
    $args->{name} ||= $args->{handle} . '_capture';

    return AnyEvent::Subprocess::Job::Delegate::CaptureHandle->new(%$args);
});

register_delegate( 'MonitorHandle' => sub {
    my $args = shift || {};
    confess 'need handle' unless $args->{handle};
    confess 'need callbacks' unless $args->{callbacks} || $args->{callback};

    my $handle = $args->{handle};
    $args->{name} ||= $handle . '_monitor';

    $args->{callbacks} ||= $args->{callback};
    delete $args->{callback};

    return AnyEvent::Subprocess::Job::Delegate::MonitorHandle->new(%$args);
});

1;

__END__

=head1 NAME

AnyEvent::Subprocess::Delegates - sets up default delegate name/builder mappings

=head1 DELEGATES PROVIDED

=head2 Handle

Provides connections to an arbitrary filehandle / fd / pipe / socket /
etc.

See L<AnyEvent::Subprocess::Job::Delegate::Handle>

=head2 StandardHandles

Provides connections to the child's STDIN/STDOUT/STDERR handles.
Delegates are named stdin/stdout/stderr.  Optional arg prefix adds a
prefix string to the delegates' names.

=head2 CommHandle

Provides a (bidirectional) socket to be shared between the child and
parent.  Optional arg name provides delegate name (so you can have
more than one, if desired).

Optional arg name controls name; defaults to 'comm.

=head2 Pty

Provides the child with stdin and stdout attached to a pseudo-tty, and
provides the parent with a delegate to control this.  Optional arg
stderr controls whether or not the child's stderr will also go to the
pty; defaults to no.

Optional arg name controls name; defaults to 'pty'.

=head2 CompletionCondvar

Supplies a delegate that is a L<AnyEvent::Condvar> that is sent the
child exit information ("Done class") when the child process exits.

=head2 Callback

Sets up an
L<AnyEvent::Subprocess::Job::Delegate::Callback|AnyEvent::Subprocess::Job::Delegate::Callback>
delegate.  Optional argument name controls callback instance name;
defaults to 'callback'.

=head2 Capture

Captures a handle.  Mandatory arg handle is the name of the handle
delegate to capture.  The handle must be readable by the parent.
(i.e., a socket or a pipe from the child to the parent.)

Delegate is named '[handle name]_capture'.

(Note that you should not use the captured handle for reading anymore;
this delegate will steal all input.  Captured output is returned in
via a delegate in the "done class".)

=head2 MonitorHandle

Calls a list of coderefs whenever a line is read from a handle.

=head1 SEE ALSO

See the test suite to see all of these shortcuts in use.
