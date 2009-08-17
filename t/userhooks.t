use strict;
use warnings;
use Test::More tests => 5;

use AnyEvent::Subprocess;

my $is_done = 0;

my $s = AnyEvent::Subprocess->new_with_traits(
    traits => ['WithStandardHandles', 'UserHooks',
               'CaptureHandle' => { handle => 'stdout' } ],
    code => sub {
        our $FOO;
        print "OH HAI $FOO";
    },
    child_setup_hook => sub {
        our $FOO = 123;
    },
    child_finalize_hook => sub {
        exit 42;
    },
    parent_setup_hook => sub {
        my ($self, $run) = @_;
        ok $run, 'got run in parent setup hook';
    },
    parent_finalize_hook => sub {
        ok 1, 'parent_finalize_hook called';
    },
    completion_hook => sub {
        ok !$is_done, 'completion_hook ran before completion_condvar was sent';
    },
);

my $run = $s->run;
my $done = $run->completion_condvar->recv;
$is_done = 1;

is $done->exit_value, 42, 'exit 42 in child_finalize_hook was called';
is $done->captured_stdout, 'OH HAI 123', 'got var set in child_setup_hook';

