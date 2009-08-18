use strict;
use warnings;
use Test::More tests => 5;

use AnyEvent::Subprocess;

my $proc = AnyEvent::Subprocess->new_with_traits(
    traits => [
        'WithStandardHandles',
        'WithHandle'    => { name => 'extra_in',  direction => 'w', replace => 3 },
        'WithHandle'    => { name => 'extra_out', direction => 'r', replace => 4 },
        'CaptureHandle' => { handle => 'stdout' },
        'CaptureHandle' => { handle => 'stderr' },
        'CaptureHandle' => { handle => 'extra_out' },
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
my $condvar = $run->completion_condvar;

$run->stdin_handle->push_write("stdin\n");
$run->extra_in_handle->push_write("extra_in\n");

my $done = $condvar->recv;

is $done->exit_value, 0, 'exited ok';
is $done->captured_stdout, "Got: stdin\n", 'got stdin';
is $done->captured_extra_out, "Got: extra_in\n", 'got extra_in';
is $done->captured_stderr, "No errors\n", 'no errors on stderr';
