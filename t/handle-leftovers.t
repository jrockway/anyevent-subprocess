use strict;
use warnings;
use Test::More;

use AnyEvent::Subprocess;

my $job = AnyEvent::Subprocess->new(
    code      => sub { sleep 1; exit 0 },
    delegates => [
        'CompletionCondvar',
        { Handle => {
            name           => 'handle',
            direction      => 'w',
            replace        => 42,
            want_leftovers => 1,
        }},
    ],
);
ok $job;

my $run = $job->run;
ok $run;

my $handle = $run->delegate('handle')->handle;
$handle->{wbuf} = 'OH HAI';

my $done = $run->delegate('completion_condvar')->recv;
ok $done->is_success;

my $done_handle = $done->delegate('handle');

ok $done_handle->has_wbuf, 'has wbuf leftover';
ok !$done_handle->has_rbuf, 'does not have rbuf leftover';

like $done_handle->wbuf, qr/OH HAI/, 'wbuf looks sane';
done_testing;
