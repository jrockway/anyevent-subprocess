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

    push @args, on_eof => $send, on_error => $send;

    my $self = $class->SUPER::new(@args);
    $self->{_eof_condvar} = $cv;
    return $self;
}

sub eof_condvar { shift->{_eof_condvar} }

1;
