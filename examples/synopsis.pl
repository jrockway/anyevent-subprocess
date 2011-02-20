#!/usr/bin/env perl

use strict;
use warnings;

use AnyEvent::Subprocess;
use EV;

# prepare the job
my $killer;
my $cv = AnyEvent->condvar;
my $job = AnyEvent::Subprocess->new(
    delegates     => ['StandardHandles'],
    on_completion => sub {
        warn 'bad exit status' unless $_[0]->is_success;
        undef $killer;
        $cv->send();
    },
    code => sub {
        my %args = %{$_[0]};
        sleep rand 5;
        while (<>) {
            print "Got line: $_";
        }
        exit 0;
    },
);

# start the child
my $run = $job->run;

# add watcher to print the next line we see on the child's stdout
$run->delegate('stdout')->handle->push_read( line => sub {
    my ($h, $line) = @_;
    say "The child said: $line";
});

# write to the child's stdin
$run->delegate('stdin')->handle->push_write("Hello, world!\n");

# close stdin after it has been written to the child
$run->delegate('stdin')->handle->on_drain(sub { $_[0]->close_fh });

# kill the child if it takes too long to produce a result
$killer = AnyEvent->timer( after => 2, interval => 0, cb => sub {
    warn "TOO SLOW.  BAI.";
    $run->kill(2);              # SIGINT.
});

$cv->cb( sub { $cv->recv; exit 0 } );
# ensure the event loop runs until the on_completion handler dies
EV::loop(); # you can use any AnyEvent-compatible event loop, including POE

# eventually prints "the child said: got line: hello, world!", or
# perhaps dies if your system is really really overloaded.
