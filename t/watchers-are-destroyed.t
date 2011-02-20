#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use AnyEvent::Subprocess;

my $exit_count = 0;

my $j = AnyEvent::Subprocess->new(
    code => sub { exit 0 },
    on_completion => sub { ok $_[0]->is_success, 'process exited'; $exit_count++ },
);

my $a = $j->run;
my $b = $j->run;
my $c = $j->run;

EV::loop();

pass 'watchers all expired';

is $exit_count, 3, 'exited 3 times';

done_testing;
