use strict;
use warnings;
use Test::More tests => 4;

use AnyEvent::Subprocess;

my $proc = AnyEvent::Subprocess->new(
    delegates => [ 'StandardHandles', 'CompletionCondvar' ],
    code      => sub {
        while(<>) {
            $| = 1;
            chomp;
            print "Got line: $_\n";
        }
        print "Exiting cleanly\n";
        exit 0;
    },
);
ok $proc;

my $run = $proc->run;
my $condvar = $run->delegate('completion_condvar');

my $got_line = AnyEvent->condvar;
my $got_exit = AnyEvent->condvar;

$run->delegate('stdout')->handle->push_read(
    line => sub { my ($h, $d) = @_; $got_line->send($d) },
);
$run->delegate('stdout')->handle->push_read(
    line => sub { my ($h, $d) = @_; $got_exit->send($d) },
);

$run->delegate('stdin')->handle->push_write("This is line 1\n");

my $line = $got_line->recv;
is $line, "Got line: This is line 1", 'echoed line OK';

$run->delegate('stdin')->handle->do_not_want;

my $exit = $got_exit->recv;
is $exit, "Exiting cleanly", 'got message about exiting cleanly';

my $done = $condvar->recv;
is $done->exit_value, 0, 'exited with status 0';
