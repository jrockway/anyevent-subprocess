package AnyEvent::Subprocess::Handle;

# ABSTRACT: AnyEvent::Handle subclass with some additional methods for AnyEvent::Subprocess
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
        $is_write = 1 if $d eq 'w' || $d eq 'rw';
    }

    my $send = sub {
        my $handle = shift;
        # warn "handle error: $$ @_ ($!) -- ". $handle->name
        #   if $ENV{PERL_ANYEVENT_VERBOSE} && @_;

        $handle->_do_finalize;
        return 0;
    };

    push @args, on_error => $send, on_eof => $send;

    # if the on_read is not provided, we never get notified of handle
    # close (presumably because no watchers are ever created)
    push @args, on_read => sub { } if $is_read;

    my $self = $class->SUPER::new(@args);

    return $self;
}

sub on_finalize {
    my ($self, $cb) = @_;
    $self->{__on_finalize} = $cb if $cb;

    if($cb && $self->{destroyed} && !$self->{finalized}){
        $cb->($self);
    }

    return $self->{__on_finalize} || sub { };
}

sub _do_finalize {
    my ($self) = @_;
    return if $self->{finalized}++;
    $self->_drain_rbuf;
    $self->on_finalize->();
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

# not push_close, since I am not sure what the semantics of that would
# be.  use "on_drain( close_fh )" to close after your last write (or
# push_shutdown).
sub close_fh {
    my $self = shift;
    close $self->fh;
}

sub destroy {
    my ($self, @args) = @_;
    my $rbuf = $self->{rbuf};
    $self->_do_finalize;
    $self->SUPER::destroy(@args);
    $self->{rbuf} = $rbuf;
    $self->{destroyed} = 1;
    return;
}

1;

__END__

=head1 DESCRIPTION

Assume this acts like a normal L<AnyEvent::Handle|AnyEvent::Handle>.
It just has some extra code to make the handle delegate's life easier.

=head1 EXTRA METHODS

=head2 name

Returns the name of the filehandle, or "<fd #>" if no name was passed
to the constructor.

=head2 close_fh

Closes the underlying filehandle, sending EOF to the child process.
