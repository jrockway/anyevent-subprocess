use strict;
use warnings;
use Test::More tests => 5;

use AnyEvent::Subprocess;

my $proc = AnyEvent::Subprocess->new(
    delegates => [
        'CompletionCondvar',
        'StandardHandles',
        { Handle => {
            name      => 'extra_in',
            direction => 'w',
            replace   => 3,
        }},
        { Handle => {
            name      => 'extra_out',
            direction => 'r',
            replace   => 4,
        }},
        { Capture => { handle => 'stdout' }},
        { Capture => { handle => 'stderr' }},
        { Capture => {
            name   => 'extra_capture',
            handle => 'extra_out',
        }},
    ],
    code => sub {
        open my $extra_in, '<&=3' or die "Failed to open fd 3: $!";
        open my $extra_out, '>&=4' or die "Failed to open fd 4: $!";

        my $stdin = <STDIN>;
        print {*STDOUT} "Got: $stdin";

        my $extra_input = <$extra_in>;
        print {$extra_out} "Got: $extra_input";

        print {*STDERR} "No errors\n";
    },
);
ok $proc;

my $run = $proc->run;
my $condvar = $run->delegate('completion_condvar');

$run->delegate('stdin')->handle->push_write("stdin\n");
$run->delegate('extra_in')->handle->push_write("extra_in\n");

my $done = $condvar->recv;

ok $done->is_success, 'exited ok';
is $done->delegate('stdout_capture')->output, "Got: stdin\n", 'got stdin';
is $done->delegate('extra_capture')->output, "Got: extra_in\n", 'got extra_in';
is $done->delegate('stderr_capture')->output, "No errors\n", 'no errors on stderr';
