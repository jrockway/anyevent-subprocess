use strict;
use warnings;
use Test::More tests => 4;

use AnyEvent::Subprocess;

my $proc = AnyEvent::Subprocess->new(
    code => sub {
        exec 'date';
    },
);
ok $proc;

my $run = $proc->run;
my $condvar = $run->completion_condvar;
my $done = $condvar->recv;

is $done->exit_value, 0, 'exited with value 0';
ok length $run->stdout_handle->rbuf > 5, 'got some value from `date`';
ok length $run->stderr_handle->rbuf == 0, 'no errors/warning/noise on stderr';


