package AnyEvent::Subprocess;
use Moose;
with 'AnyEvent::Subprocess::Job';

our $VERSION = '0.00_01';

use AnyEvent::Subprocess::DefaultDelegates;

use namespace::autoclean;

1;

__END__

=head1 NAME

AnyEvent::Subprocess - flexible, OO, asynchronous process spawning and management

=head1 SYNOPSIS

    use AnyEvent::Subprocess;

    # prepare the job
    my $job = AnyEvent::Subprocess->new(
        delegates     => ['StandardHandles'],
        on_completion => sub { die 'bad exit status' unless $_[0]->is_success },
        code          => sub {
            my %args = %{$_[0]};
            while(<>){
                print "Got line: $_";
            }
            exit 0;
        },
    );

    # start the child
    my $run = $job->run;

    # add watcher to print the next line we see on the child's stdout
    $run->delegate('stdout')->push_read( line => sub {
        my ($h, $line) = @_;
        say "The child said: $line";
    });

    # write to the child's stdin
    $run->delegate('stdin')->push_write("Hello, world!\n");

    # prints "The child said: Got line: Hello, world!"

    # kill the child
    $run->kill(9); # BAI.

    # ensure the event loop runs until the on_completion handler dies
    EV::loop(); # you can use any AnyEvent-compatible event loop, including POE

=head1 OVERVIEW

C<AnyEvent::Subprocess> is a set of modules for running external
processes, and interacting with them in the context of an event-driven
program.  It is similar to L<POE::Wheel::Run|POE::Wheel::Run>, but
much more customizable (and Moose-based).  It is also similar to
modules that really want to be event-based, but aren't for some
reason; this includes L<IPC::Run|IPC::Run> and
L<IPC::Open3|IPC::Open3>, L<Expect|Expect>, and even the built-in
C<qx//> operator.  You can replace all those modules with this one,
and have the ability to write much more flexible applications and
libraries.

AnyEvent::Subprocess is based on three classes;
C<AnyEvent::Subprocess::Job>, which represents a job that can be run
at a later time, C<AnyEvent::Subprocess::Running>, which represents a
running child process, and C<AnyEvent::Subprocess::Done>, which
represents a completed job.  The C<Job> object contains the command to
run, information about its environment (which handles to capture,
which plugins to run, what to do when the job is done, etc.).  Then
C<Run> object is returned by C<< $job->run >>, and lets you interact
with the running subprocess.  This includes things like writing to its
pipes/sockets, reading from its pipes, sending it signals, and so on.
When the running job exits, the C<on_completion> handler provided by
the Job object is called with a C<Done> object.  This contains the
exit status, output that the process produced (if requested), and so
on.

What makes this more interesting is the ability to add delegates to
any of these classes.  These delegates are called into at various
points and allow you to add more features.  By default, you just get a
callback when the process exits.  You can also kill the running
process.  That's it.  From there, you can add delegates to add more
features.  You can add a pipe to share between the parent and the
child.  Instead of sharing a pipe, you can have an fd opened to an
arbitrary file descriptor number in the child.  You have an infinite
number of these, so you can capture the child's stdout and stderr,
write to its stdin, and also share a socket for out-of-band
communication.  You can also open a pipe to the child's fd #5 and
write to it.  (This is nice if you are invoking something like C<gpg>
that wants the password written on an arbitrary fd other than 1.)

(This is all done with the included C<Handle> delegate.  See
L<AnyEvent::Subprocess::Job::Delegate::Handle>.)

You can then build upon this; instead of writing your own code to
reading the handles when they become readable and accumulate input,
you can write a delegate that saves all the data coming from a given
handle and gives it to your program after the child exits (via the
C<Done> instance).

(This is also included via the C<CaptureHandle> delegate.  See
L<AnyEvent::Subprocess::Job::Delegate::CaptureHandle.)

All of this integrates into your existing event-based app; waiting for
IO from the child (or waiting for the child to exit) is asynchronous,
and lets your app do other work while waiting for the child.  (It can
integrate nicely into Coro, for example, unlike the default C<qx//>.)

=head1 TUTORIAL

There are so many possible ways to use this module that a tutorial
would take me months to write.  You should definitely read the test
suite to see what possibilities exist.

The basic "flow" is like in the SYNOPSIS section; create a job, call
run, wait for your callback to be called with the results.

The fun comes when you add delegates.

Delegates are technically instances of classes.  Typing:

   my $stdin = AnyEvent::Subprocess::Job::Delegate::Handle->new(
       name      => 'stdin',
       direction => 'w',
       replace   => \*STDIN,
   );

Every time you want to be able to write to STDIN is going to become
tiring after a while.  When you load C<AnyEvent::Subprocess>, you also
load
L<AnyEvent::Subprocess::DefaultDelegate|AnyEvent::Subprocess::DefaultDelegates>.
This registers short names for each delegate and will cause
C<AnyEvent::Subprocess::Job> to build the actual instances
automatically.  This means you can say C<'StandardHandles'> to get a
delegate for each of STDIN, STDOUT, and STDERR.  If you want to know
how all the sugary names work, just open C<DefaultDelegates.pm> and
take a look.  (The documentation for that module also covers that, as
well as how to define your own delegate builders.)

XXX: more docs

=head1 BUGS

The parent's event loop still exists in the child process, which means
you can't safely use it in the child.  I have tried to work around
this in a few event loops; my C<AnyEventX::Cancel> module on github is
an early attempt.  When that becomes stable, I will remove this
restriction.

In the mean time, YOU MUST NOT USE ANY EVENT-LOOP FUNCTIONS IN THE
CHILD.

This is not a problem if you are running external processes, but is a
problem if you are running a code block and you want to do event-ful
things in there.  (Note that EV is designed to allow the child to
handle events that the parent created watchers for.  You can do that
just fine.  It's if you want a fresh event loop with no existing
watchers that doesn't work well yet.)

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>

Yuval Kogman helped with the design.  If he wasn't around, this module
would be about 1000x slower (!)

=head1 COPYRIGHT

Copyright (c) 2009 Jonathan Rockway.

This module is Free software, you can redistribute it under the same
terms as Perl itself.
