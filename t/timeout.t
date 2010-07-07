use strict;
use warnings;
use Test::More;

use AnyEvent::Subprocess;

{
    my $proc = AnyEvent::Subprocess->new(
        delegates => [{ Timeout => { timeout => 1 } }, 'CompletionCondvar'],
        code      => sub { sleep 10 },
    );

    my $run = $proc->run;
    my $run_timer = $run->delegate('timeout');
    ok $run_timer->timer, 'has timer';
    ok !$run_timer->killed_by_timer, 'not killed by timer yet';

    my $done = $run->delegate('completion_condvar')->condvar->recv;
    ok $done->delegate('timeout')->timed_out, 'timed out';
    ok !$done->is_success, 'was not a success';
}

{
    my $proc = AnyEvent::Subprocess->new(
        delegates => [{ Timeout => { timeout => 3 } }, 'CompletionCondvar'],
        code      => sub { sleep 1 },
    );

    my $run = $proc->run;
    my $run_timer = $run->delegate('timeout');
    ok $run_timer->timer, 'has timer';
    ok !$run_timer->killed_by_timer, 'not killed by timer yet';

    my $done = $run->delegate('completion_condvar')->condvar->recv;
    ok !$done->delegate('timeout')->timed_out, 'did not time out';
    ok $done->is_success, 'was a success';
}

done_testing;
