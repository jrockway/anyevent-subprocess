use strict;
use warnings;
use Test::More tests => 15;

use AnyEvent::Subprocess;
use Scalar::Util qw(looks_like_number);

sub tests {
    my $proc = shift;
    ok $proc;

    my $run = $proc->run;
    my $condvar = $run->delegate('completion_condvar');

    my $got_error = 0;

    $run->delegate('stderr')->handle->on_read( sub { warn @_; warn $_[0]->rbuf; $got_error++ } );

    $run->delegate('stdout')->handle->push_read( line => sub {
        my ($h, $data) = @_;
        ok length $data > 9, 'got some value from `date`';
        ok looks_like_number $data, 'data looks like number';
    });

    my $done = $condvar->recv;

    is $done->exit_value, 0, 'exited with value 0';
    is $got_error, 0, 'no errors/warning/noise on stderr';
}


# test code => ArrayRef
my $proc = AnyEvent::Subprocess->new(
    delegates => [ 'StandardHandles', 'CompletionCondvar' ],
    code      => ['date', '+%s'],
);

tests($proc);

my $proc2 = AnyEvent::Subprocess->new(
    delegates => [ 'StandardHandles', 'CompletionCondvar' ],
    code      => 'date +%s',
);

tests($proc2);

my $proc3 = AnyEvent::Subprocess->new(
    delegates => [ 'StandardHandles', 'CompletionCondvar' ],
    code      => sub {
        exec 'date +%s';
    },
);

tests($proc3);
