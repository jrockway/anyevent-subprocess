package AnyEvent::Subprocess::DefaultDelegates;
use strict;
use warnings;

use AnyEvent::Subprocess::Role::WithDelegates::Manager qw(register_delegate);

use AnyEvent::Subprocess::Job::Delegate::Handle;
use AnyEvent::Subprocess::Job::Delegate::CaptureHandle;
use AnyEvent::Subprocess::Job::Delegate::Pty;

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

register_delegate( 'Handle' => 'AnyEvent::Subprocess::Job::Delegate::Handle' );
register_delegate( 'Capture' => 'AnyEvent::Subprocess::Job::Delegate::CaptureHandle' );
register_delegate( 'Pty' => sub {
    my $args = shift || {};
    $args->{name} ||= 'pty';

    return AnyEvent::Subprocess::Job::Delegate::Pty->new(%$args);
});

1;
