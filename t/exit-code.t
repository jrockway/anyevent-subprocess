use strict;
use warnings;
use Test::More tests => 6;

use AnyEvent::Subprocess;

my $exit = AnyEvent->condvar;

my $proc = AnyEvent::Subprocess->new(
    code => sub {
        exit 123;
    },
    on_completion => sub {
        my $done = shift;
        ok $done, 'done';
        is $done->exit_value, 123, 'got exit status 123';
        ok $done->exited, 'did not exit with signal';
        ok !$done->dumped_core, 'no core dump';
        ok !$done->is_success, 'not a brilliant success.';
        $exit->send;
    }
);
ok $proc, 'got proc';
$proc->run;
$exit->recv;
