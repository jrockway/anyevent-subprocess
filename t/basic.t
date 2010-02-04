use strict;
use warnings;
use Test::More tests => 8;

use ok 'AnyEvent::Subprocess';

my $proc = AnyEvent::Subprocess->new(
    delegates => ['StandardHandles', 'CompletionCondvar'],
    code      => sub {
        my $name = $_[0]->{name};
        warn "starting child $name";

        while(my $line = <STDIN>){
            chomp $line;
            print "got line: {$line}";
        }
        warn "child is done";
    },
);
ok $proc;

my $run = $proc->run({ name => 'foo' });
isa_ok $run, 'AnyEvent::Subprocess::Running';

my $condvar = $run->delegate('completion_condvar')->condvar;
ok $condvar, 'got condvar';

my $line = "here is a line for the kid";
$run->delegate('stdin')->handle->push_write($line. "\n");
$run->delegate('stdin')->handle->on_drain(sub{
    $_[0]->close_fh;
});

my $done = $condvar->recv;
isa_ok $done, 'AnyEvent::Subprocess::Done';

is $done->exit_value, 0, 'got exit status 0';

like $run->delegate('stderr')->handle->{rbuf},
  qr/^starting child foo.*^child is done/ms,
  'captured stderr';

is $run->delegate('stdout')->handle->{rbuf},
  "got line: {$line}",
  'copied STDIN to STDOUT ok';
