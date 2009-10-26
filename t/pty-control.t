use strict;
use warnings;
use Test::More tests => 3;
use AnyEvent::Subprocess;

my $proc = AnyEvent::Subprocess->new(
    delegates     => [ 'Pty', 'CompletionCondvar' ],
    code          => sub {
        open my $tty, '>', '/dev/tty' or die $!;
        print {$tty} "ok\n";
    },
);
ok $proc;

my $run  = $proc->run;

$run->delegate('pty')->handle->push_read( line => sub {
    my ($h, $line) = @_;
    is $line, 'ok', 'got "OK" written to /dev/tty';
});

my $done = $run->delegate('completion_condvar')->recv;

ok $done->is_success, 'exited ok';

