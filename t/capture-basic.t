use strict;
use warnings;
use Test::More tests => 3;

use AnyEvent::Subprocess;

my $s = AnyEvent::Subprocess->new_with_traits(
    traits => [
        'WithStandardHandles',
        'CaptureHandle' => { handle => 'stdout' },
        'CaptureHandle' => { handle => 'stderr' },
    ],

    code => sub {
        print "Hello, world.  This is stdout.";
        print {*STDERR} "OH HAI, THIS IS STDERR.";
    },
);

my $run = $s->run;
my $done = $run->completion_condvar->recv;

is $done->captured_stdout, 'Hello, world.  This is stdout.', 'got out';
is $done->captured_stderr, 'OH HAI, THIS IS STDERR.', 'got err';
is $done->exit_value, 0, 'exit success';
