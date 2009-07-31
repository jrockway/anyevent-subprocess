use strict;
use warnings;
use Test::More tests => 10;

use ok 'AnyEvent::Subprocess';

my $forked = 0;
my $proc = AnyEvent::Subprocess->new_with_traits(
    traits => ['WithStandardHandles'],
    code   => sub {
        warn "starting child";

        while(my $line = <STDIN>){
            chomp $line;
            print "got line: {$line}";
        }
        warn "child is done";
    },
    before_fork_hook => sub {
        $forked = 1,
    },
);
ok $proc;

ok !$forked, 'no fork yet';

my $run = $proc->run;
isa_ok $run, 'AnyEvent::Subprocess::Running';

ok $forked, 'before_fork callback called';

my $condvar = $run->completion_condvar;
ok $condvar, 'got condvar';

my $line = "here is a line for the kid";
$run->stdin_handle->push_write($line. "\n");
close $run->stdin_handle->fh;

# $run->stdout_handle->push_read( line => sub {
#     warn "@_";
# });

my $done = $condvar->recv;
isa_ok $done, 'AnyEvent::Subprocess::Done';
is $done->exit_value, 0, 'got exit status 0';
like $run->stderr_handle->{rbuf}, qr/^starting child.*^child is done/ms, 'captured stderr';
is $run->stdout_handle->{rbuf}, "got line: {$line}", 'copied STDIN to STDOUT ok';
