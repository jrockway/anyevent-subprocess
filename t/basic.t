use strict;
use warnings;
use Test::More tests => 8;

use ok 'AnyEvent::Subprocess';

my $proc = AnyEvent::Subprocess->new(
    delegates => ['StandardHandles'],
    code      => sub {
        warn "starting child";

        while(my $line = <STDIN>){
            chomp $line;
            print "got line: {$line}";
        }
        warn "child is done";
    },
);
ok $proc;

my $run = $proc->run;
isa_ok $run, 'AnyEvent::Subprocess::Running';

my $condvar = $run->completion_condvar;
ok $condvar, 'got condvar';

my $line = "here is a line for the kid";
$run->delegate('stdin')->handle->push_write($line. "\n");
close $run->delegate('stdin')->handle->fh;

# $run->stdout_handle->push_read( line => sub {
#     warn "@_";
# });

my $done = $condvar->recv;
isa_ok $done, 'AnyEvent::Subprocess::Done';

is $done->exit_value, 0, 'got exit status 0';

like $run->delegate('stderr')->handle->{rbuf},
  qr/^starting child.*^child is done/ms,
  'captured stderr';

is $run->delegate('stdout')->handle->{rbuf},
  "got line: {$line}",
  'copied STDIN to STDOUT ok';
