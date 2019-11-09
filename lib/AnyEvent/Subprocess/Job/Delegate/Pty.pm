package AnyEvent::Subprocess::Job::Delegate::Pty;

# ABSTRACT: give the child a pseudo-terminal
use IO::Pty;
use namespace::autoclean;

use Moose;
use POSIX qw(dup2);

with 'AnyEvent::Subprocess::Job::Delegate';

has 'want_leftovers' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'pty' => (
    traits     => ['NoClone'],
    is         => 'ro',
    isa        => 'IO::Pty',
    lazy_build => 1,
);

has 'slave_pty' => (
    traits     => ['NoClone'],
    is         => 'ro',
    lazy_build => 1,
);

has 'handle' => (
    traits     => ['NoClone'],
    is         => 'ro',
    isa        => 'AnyEvent::Subprocess::Handle',
    lazy_build => 1,
);

has 'handle_class' => (
    is       => 'ro',
    isa      => 'ClassName',
    required => 1,
    default  => sub {
        require AnyEvent::Subprocess::Handle;
        return 'AnyEvent::Subprocess::Handle';
    },
);

sub __build_handle {
    my ($self, $fh, @rest) = @_;
    return $self->handle_class->new( fh => $fh, @rest );
}

has 'run_delegate_class' => (
    is       => 'ro',
    isa      => 'ClassName',
    required => 1,
    default => sub {
        require AnyEvent::Subprocess::Running::Delegate::Handle;
        return 'AnyEvent::Subprocess::Running::Delegate::Handle';
    },
);

has 'redirect_handles' => (
    is         => 'ro',
    isa        => 'ArrayRef[GlobRef]',
    auto_deref => 1,
    required   => 1,
    default    => sub {
        return [\*STDIN, \*STDOUT],
    },
);

sub _build_pty {
    return IO::Pty->new;
}

sub _build_slave_pty {
    my $self = shift;
    return $self->pty->slave;
}

sub _build_handle {
    my $self = shift;

    return $self->__build_handle(
        $self->pty,
        _direction => 'rw',
        _name      => 'parent pty handle: '. $self->name,
    );
}

sub build_run_delegates {
    my $self = shift;
    return $self->run_delegate_class->new(
        name           => $self->name,
        direction      => 'rw',
        handle         => $self->handle,
        want_leftovers => $self->want_leftovers,
    );
}

sub parent_finalize_hook {
    my $self = shift;
    $self->pty->close_slave;
}

sub child_setup_hook {
    my $self = shift;

    $self->pty->make_slave_controlling_terminal;

    $self->handle->do_not_want;

    AnyEvent::Util::fh_nonblocking $self->slave_pty, 0;

    for my $fh ($self->redirect_handles){
        dup2( fileno($self->slave_pty), fileno($fh) )
          or confess "Can't dup2 $fh to slave pty: $!";
    }
}

sub build_code_args {}
sub child_finalize_hook {}
sub parent_setup_hook {}
sub receive_child_result {}
sub receive_child_error {}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 DESCRIPTION

You can have more than one of these, but the last one will become the
controlling tty.

=head1 INITARGS

=head2 redirect_handles

A list of filehandles that will be connected to this Pty in the child.
Defaults to stdout and stderr.

=head1 METHODS

=head2 pty

Returns the L<IO::Pty|IO::Pty> object.  You can use this object to set
the child's window size, etc.

=head2 handle

The handle that you can read/write to communicate with the child.
Note that writing can be confusing; because the Pty emulates a
terminal, and terminals echo input, you will get back things that you
write.  You can disable this behavior by changing the terminal
parameters in the child process.

(If you don't know what "raw mode" and "cooked mode" are, you should
read up on UNIX terminals.  You might really want a pipe, not a pseudo
terminal.)

