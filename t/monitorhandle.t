use strict;
use warnings;
use Test::More tests => 5;

use AnyEvent::Subprocess;

my $line = AnyEvent->condvar;

my $job = AnyEvent::Subprocess->new(
    code      => sub { while(<>){ print } print "BAI" },
    delegates => ['CompletionCondvar', 'StandardHandles', {
        MonitorHandle => {
            handle   => 'stdout',
            callback => sub { $line->send(shift) },
        },
    }],
);
ok $job;

my $run = $job->run;
ok $run;

my $stdin = $run->delegate('stdin')->handle;

$stdin->push_write("OH HAI\n");

is $line->recv, 'OH HAI', 'got OH HAI';

$line = AnyEvent->condvar;
$line->begin; # original callback
$line->begin; # new one we're adding

my $code = sub { $line->send(shift) };

$job->delegate('stdout_monitor')->add_callback( sub { $code->(shift) } );

$stdin->push_write("new line\n");
is $line->recv, 'new line', 'got second line twice';

$code = sub { }; # NOP
$line = AnyEvent->condvar;

close $stdin->fh;

is $line->recv, 'BAI', 'got final line';

$run->delegate('completion_condvar')->recv;

