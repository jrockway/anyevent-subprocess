use strict;
use warnings;
use Test::More tests => 6;

use AnyEvent::Subprocess;

my $proc = AnyEvent::Subprocess->new_with_traits(
    traits => ['Pty', 'WithCommHandle'],
    code   => sub {
        my $comm = shift;
        local $| = 1;
        print "Hello, parent!\n";
        while(my $line = <STDIN>){
            chomp $line;
            print {$comm} "got line: {$line}\n";
        }
        exit 0;
    },
);
ok $proc;

my $run = $proc->run;

my $completion_condvar = AnyEvent->condvar;
my $joiner = Event::Join->new(
    events => [qw/exited initial_output echoed_input cooked_input/],
    on_completion => sub {
        my $events = shift;
        return $completion_condvar->send( $events->{exited}->recv );
    },
);

$run->completion_condvar->cb( $joiner->event_sender_for( 'exited' ) );

$run->pty_handle->push_read( line => sub {
    my ($h, $line, $eol) = @_;
    is $line, 'Hello, parent!', 'got initial output';
    $joiner->send_event( 'initial_output' );
} );

$run->pty_handle->push_read( line => sub {
    my ($h, $line, $eol) = @_;
    is $line, 'this is a test', 'echoed input';
    $joiner->send_event( 'echoed_input' );
    close $run->pty_handle->fh;
} );

$run->comm_handle->push_read( line => sub {
    my ($h, $line, $eol) = @_;
    is $line, 'got line: {this is a test}', 'process got input and cooked it';
    $joiner->send_event( 'cooked_input' );
    close $run->comm_handle->fh;
} );

$run->pty_handle->push_write( "this is a test\n" );

my $done = $completion_condvar->recv();
isa_ok $done, 'AnyEvent::Subprocess::Done';
is $done->exit_value, 0, 'got exit value 0';
