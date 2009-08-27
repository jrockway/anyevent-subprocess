use strict;
use warnings;

use AnyEvent::Subprocess;
use Test::More tests => 7;

my $b = Test::Builder->new;

my $job = AnyEvent::Subprocess->new(
    delegates => ['CompletionCondvar'],
    code      => sub {
        pass 'child started running';
        sleep 2;

        $b->current_test( $b->current_test() + 1 );

        pass 'child lived';
        exit 42;
    },
);

ok $job, 'got job';

my $start_time = time;
my $run = $job->run;
sleep 1;

$b->current_test( $b->current_test() + 1 );

ok $run, 'got run';

my $exit = $run->delegate('completion_condvar')->recv;
my $end_time = time;

$b->current_test( $b->current_test() + 1 );

ok $exit, 'got exit';
is $exit->exit_value, 42, 'exited with "exit 42"';
ok ( ( $end_time - $start_time ) > 1, 'kid was alive for more than a second');
