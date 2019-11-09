package AnyEvent::Subprocess::Easy;

# ABSTRACT: wrappers around AnyEvent::Subprocess to save typing in simple cases
use strict;
use warnings;

use AnyEvent;
use AnyEvent::Subprocess;

use Try::Tiny;

use Sub::Exporter -setup => {
    exports => ['qx_nonblock'],
};

sub _build_input_capture_job {
    my ($callback, $code, @delegates) = @_;

    my $proc = AnyEvent::Subprocess->new(
        delegates => [
            'PrintError',
            { Handle => {
                name      => 'stdout',
                direction => 'r',
                replace   => \*STDOUT,
            }},
            { Capture => { handle => 'stdout' } },
            @delegates,
        ],
        code          => $code,
        on_completion => $callback,
    );

    return $proc;
}

sub qx_nonblock {
    my (@args) = @_;

    my $cmd = [@args];
    $cmd = $args[0] if @args == 1;

    my $result_ready = AnyEvent->condvar;
    my $callback = sub {
        my $done = shift;

        if($done->exit_status != 0){
            # make "recv" die with error message
            $result_ready->croak(
                "Process exited unsuccessfully with exit code: ". $done->exit_value
            ),
        }
        else {
            # send captured output
            $result_ready->send(
                $done->delegate('stdout_capture')->output,
            );
        }
    };

    my $proc = _build_input_capture_job(
        $callback, $cmd,
    );

    $proc->run;

    return $result_ready;
}

1;

__END__

=head1 SYNOPSIS

    use AnyEvent::Subprocess::Easy qw(qx_nonblock);

    my $date = qx_nonblock('date')->recv;

=head1 DESCRIPTION

I was writing some examples and noticed some patterns that came up
again and again, so I converted them to functions.  These are opaque
and non-customizeable, but might be helpful if you want to do
something common without a lot of typing.  If they don't work quite
the way you want, it is not too hard to use AnyEvent::Subprocess
directly.

=head1 EXPORTS

We use L<Sub::Exporter|Sub::Exporter> here, so you can customize the
exports as appropriate.

=head2 qx_nonblock( $cmdline | @cmdline )

C<qx_nonblock> works like qx, except that it returns a condvar that
you C<recv> on to get the captured stdout.  The C<recv> will throw an
exception if the process you run doesn't exit cleanly.

You can pass in one string for the shell to interpret (like C<exec>),
or you can pass in a list of arguments (passed directly to C<exec>).
You can also pass in a coderef if you like; it will be called with an
undefined number of arguments in the child process (and should C<exit 0>
if it is successful).

=head1 BUGS

Not enough "easy" stuff here yet.  Please contribute your common
patterns!

=head1 SEE ALSO

L<AnyEvent::Subprocess|AnyEvent::Subprocess>
