use strict;
use warnings;
use Test::More;

use AnyEvent::Subprocess;

my $cv = AnyEvent->condvar;
my @dones;

my $proc = AnyEvent::Subprocess->new(
    delegates     => [ 'StandardHandles' ],
    code          => sub { local $/; print <STDIN> },
    on_completion => sub { push @dones, @_; $cv->end },
);

my @runs = map { $cv->begin; $proc->run } 1..5;
ok @runs == 5, 'got the runs'; # ...

{ my %hash;
  @hash{@runs} = @runs;
  ok scalar keys %hash == 5, 'got 5 unique runs';
}

my @got_output;
for my $i (0..4) {
    my $run = $runs[$i];
    $run->delegate('stdout')->handle->push_read( line => sub {
        $got_output[$i] = $_[1];
    });

    $run->delegate('stdin')->handle->push_write( "$i\n" );
    $run->delegate('stdin')->handle->on_drain( sub {
        $_[0]->close_fh;
    });
}

$cv->recv;

ok @dones == 5;
is_deeply \@got_output, [0..4], 'got output';

done_testing;
