use strict;
use warnings;
use Test::More tests => 3;

use AnyEvent::Subprocess;

my $proc = AnyEvent::Subprocess->new(
    code => sub {
        my $socket = shift;
        while(1) {
            # OH NOES
            $socket->push_write('hihihihihihi');
        }
    },
);
ok $proc;

my $run = $proc->run;
my $condvar = $run->completion_condvar;

$run->kill;

my $done = $condvar->recv;
is $done->exit_signal, 9, 'exited with signal 9';
ok !$done->dumped_core, 'no core dump';
