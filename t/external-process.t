use strict;
use warnings;
use Test::More tests => 4;

use AnyEvent::Subprocess;

my $proc = AnyEvent::Subprocess->new_with_traits(
    traits => ['WithStandardHandles'],
    code   => sub {
        exec 'date';
    },
);
ok $proc;

my $run = $proc->run;
my $condvar = $run->completion_condvar;

my $got_error = 0;

$run->stderr_handle->on_read( sub { $got_error++ } );

$run->stdout_handle->push_read( line => sub {
    my ($h, $data) = @_;
    ok length $data > 5, 'got some value from `date`';
});

my $done = $condvar->recv;

is $done->exit_value, 0, 'exited with value 0';
is $got_error, 0, 'no errors/warning/noise on stderr';
