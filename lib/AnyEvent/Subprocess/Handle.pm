package AnyEvent::Subprocess::Handle;
use strict;
use warnings;
use AnyEvent;
use base 'AnyEvent::Handle';

sub new {
    my ($class, @args) = @_;
    my $cv = AnyEvent->condvar;
    my $send = sub {
        my ($handle) = @_;
        $cv->send(1);
    };

    # if the on_read is not provided, we never get notified of handle
    # close
    push @args, on_eof => $send, on_error => $send, on_read => sub {};

    my $self = $class->SUPER::new(@args);
    $self->{_eof_condvar} = $cv;
    return $self;
}

sub eof_condvar { shift->{_eof_condvar} }

1;
