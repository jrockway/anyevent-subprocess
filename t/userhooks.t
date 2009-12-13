use strict;
use warnings;
use Test::More tests => 8;

use AnyEvent::Subprocess;

my $is_done = 0;

my $s = AnyEvent::Subprocess->new(
    code => sub {
        our $FOO;
        print "OH HAI $FOO";
    },
    delegates => [
        'CompletionCondvar',
        'StandardHandles',
        { Callback => {
            state => { whatever => 42 },
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
        }},
    ],
);

is $s->delegate('callback')->state->{whatever}, 42,
  'got job "state"';

my $run = $s->run;

is $run->delegate('callback')->state->{whatever}, 42,
  'got run "state"';

my $done = $run->delegate('completion_condvar')->recv;
$is_done = 1;

is $done->delegate('callback')->state->{whatever}, 42,
  'got done "state"';

my $out = $run->delegate('stdout')->handle->{rbuf};

is $done->exit_value, 42, 'exit 42 in child_finalize_hook was called';
is $out, 'OH HAI 123', 'got var set in child_setup_hook';

