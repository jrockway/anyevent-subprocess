use strict;
use warnings;
use Test::More tests => 3;

use AnyEvent::Subprocess;

my $proc = AnyEvent::Subprocess->new(
    code => sub {
        exit 123;
    },
);
ok $proc;

my $done = $proc->run->completion_condvar->recv;
ok $done, 'done';

is $done->exit_value, 123, 'got exit status 123';
