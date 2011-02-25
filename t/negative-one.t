use strict;
use warnings;
use Test::More;
use AnyEvent::Subprocess::Done;

my $done = AnyEvent::Subprocess::Done->new(
    exit_status => -1,
);

TODO: {
    local $TODO = 'different behavior on different unix flavors';
    is $done->exit_value, 255, '255 exit value';
}

is $done->exit_signal, 0, 'no signal';
ok !$done->exited, 'exited normally';
ok !$done->dumped_core, 'no dump';
ok !$done->is_success, 'not a success';

done_testing;
