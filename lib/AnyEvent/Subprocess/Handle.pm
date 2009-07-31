package AnyEvent::Subprocess::Handle;
use strict;
use warnings;
use AnyEvent;
use base 'AnyEvent::Handle';

sub new {
    my ($class, @args) = @_;
    my %args = @args;

    my $is_read = 0;
    my $is_write = 0;
    if(my $d = $args{_direction}){
        $is_read  = 1 if $d eq 'r' || $d eq 'rw';
        $is_write = 1 if $d eq 'w' || $d eq 'w';
    }

    my $cv = AnyEvent->condvar;
    my $send = sub {
        my ($handle) = @_;
        # warn "error: $$ @_ ($!) -- ". $handle->name;
        $cv->send(1);
        return 0;
    };

    push @args, on_error => $send, on_eof => $send;

    # if the on_read is not provided, we never get notified of handle
    # close
    push @args, on_read => sub { } if $is_read;

    my $self = $class->SUPER::new(@args);
    $self->{_eof_condvar} = $cv;
    return $self;
}

sub name {
    my $self = shift;
    return $self->{_name} || "<fd ". fileno($self->fh). ">";
}

sub do_not_want {
    my $self = shift;
    close $self->fh if $self->fh; # sometimes people close too soon
    $self->destroy;
}

sub destroy {
    my ($self, @args) = @_;
    my $rbuf = $self->{rbuf};
    $self->SUPER::destroy(@args);
    $self->{rbuf} = $rbuf;
    return;
}

sub eof_condvar { shift->{_eof_condvar} }

1;
