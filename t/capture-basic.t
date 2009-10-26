use strict;
use warnings;
use Test::More tests => 3;

use AnyEvent::Subprocess;

my $s = AnyEvent::Subprocess->new(
    delegates => [
        'StandardHandles',
        'CompletionCondvar',
        { 'Capture' => {
            name   => 'stdout_capture',
            handle => 'stdout',
        }},
        { 'Capture' => {
            name   => 'stderr_capture',
            handle => 'stderr',
        }},
    ],

    code => sub {
        print "Hello, world.  This is stdout.";
        print {*STDERR} "OH HAI, THIS IS STDERR.";
    },

);

my $run = $s->run;
my $done = $run->delegate('completion_condvar')->recv;

is $done->delegate('stdout_capture')->output,
  'Hello, world.  This is stdout.', 'got out';
is $done->delegate('stderr_capture')->output,
  'OH HAI, THIS IS STDERR.', 'got err';
ok $done->is_success, 'exit success';
