use strict;
use warnings;
use Test::More tests => 6;

use AnyEvent::Subprocess;
use Event::Join;

my $completion_condvar = AnyEvent->condvar;
my $joiner = Event::Join->new(
    events => [qw/exited initial_output echoed_input cooked_input/],
    on_completion => sub {
        my $events = shift;
        return $completion_condvar->send( $events->{exited} );
    },
);

my $proc = AnyEvent::Subprocess->new(
    delegates     => [ 'Pty', 'CommHandle' ],
    on_completion => $joiner->event_sender_for('exited'),
    code          => sub {
        my $args = shift;
        my $comm = $args->{comm};
        local $| = 1;
        print "Hello, parent!\n";

        while(my $line = <STDIN>){
            chomp $line;
            print {$comm} "got line: {$line}\n";

            # XXX: I think this is weird. readline just blocks, even
            # after the tty is closed / shutdown.
            exit 0;
        }
    },
);
ok $proc;

my $run = $proc->run;
$run->delegate('pty')->handle->push_read( line => sub {
    my ($h, $line, $eol) = @_;
    is $line, 'Hello, parent!', 'got initial output';
    $joiner->send_event( 'initial_output' );

    $run->delegate('pty')->handle->push_write( "this is a test\n" );
    $run->delegate('pty')->handle->push_shutdown;
} );

$run->delegate('pty')->handle->push_read( line => sub {
    my ($h, $line, $eol) = @_;
    is $line, 'this is a test', 'echoed input';
    $joiner->send_event( 'echoed_input' );
} );

$run->delegate('comm')->handle->push_read( line => sub {
    my ($h, $line, $eol) = @_;
    is $line, 'got line: {this is a test}', 'process got input and cooked it';
    $joiner->send_event( 'cooked_input' );
    $run->delegate('comm')->handle->close_fh;
} );

my $timeout = AnyEvent->timer( after => 5, cb => sub {
    diag "test subprocess failed to exit; this is strange";
    done_testing;
    exit 0;
});

my $done = $completion_condvar->recv();

undef $timeout;

isa_ok $done, 'AnyEvent::Subprocess::Done';
is $done->exit_value, 0, 'got exit value 0';
