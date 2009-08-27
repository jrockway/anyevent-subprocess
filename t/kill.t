use strict;
use warnings;
use Test::More tests => 4;

use AnyEvent::Subprocess;

my $proc = AnyEvent::Subprocess->new(
    delegates => ['CommHandle', 'CompletionCondvar'],
    code      => sub {
        my $args = shift;
        my $socket = $args->{comm};

        while(1) {
            # OH NOES
            print {$socket} "hihihihihihi\n";
        }
    },
);
ok $proc;

my $run = $proc->run;
my $condvar = $run->delegate('completion_condvar');

$run->delegate('comm')->handle->push_read( line => sub {
    my (undef, $line) = @_;
    is $line, 'hihihihihihi', 'got line before killing';
    $run->kill;
});

my $done = $condvar->recv;
is $done->exit_signal, 9, 'exited with signal 9';
ok !$done->dumped_core, 'no core dump';
