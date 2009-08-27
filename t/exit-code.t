use strict;
use warnings;
use Test::More tests => 3;

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
        $exit->send;
    }
);
ok $proc, 'got proc';
$proc->run;
$exit->recv;
