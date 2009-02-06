use strict;
use warnings;
use Test::More tests => 4;

use ok 'AnyEvent::Subprocess';

my $proc = AnyEvent::Subprocess->new(
    code => sub {
        warn "starting child";
        sleep 1;
        warn "child is done";
    },
);

ok $proc;

my $condvar = $proc->run;

ok $condvar, 'got condvar';

is $condvar->recv, 0, 'got exit status 0';

