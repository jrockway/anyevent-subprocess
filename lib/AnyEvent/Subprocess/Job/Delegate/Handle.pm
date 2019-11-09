package AnyEvent::Subprocess::Job::Delegate::Handle;

# ABSTRACT: share a filehandle or socket with the child
use AnyEvent;
use AnyEvent::Util qw(portable_pipe portable_socketpair);
use AnyEvent::Subprocess::Handle;
use POSIX qw(dup2);

use MooseX::Types::Moose qw(Str Int GlobRef ArrayRef);
use AnyEvent::Subprocess::Types qw(Direction);

use namespace::autoclean;
use Moose;

with 'AnyEvent::Subprocess::Job::Delegate';

has 'direction' => (
    is            => 'ro',
    isa           => Direction,
    required      => 1,
    documentation => 'r when parent reads a pipe, w when parent writes to a pipe, rw for a socket',
);

has 'name' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'replace' => (
    is        => 'ro',
    isa       => GlobRef|Int,
    predicate => 'has_replace',
);

has 'pass_to_child' => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
    required => 1,
);

has 'want_leftovers' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'pipes' => (
    traits     => ['NoClone'],
    is         => 'ro',
    isa        => ArrayRef[GlobRef],
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

has 'handle' => (
    traits     => ['NoClone'],
    is         => 'ro',
    isa        => 'AnyEvent::Subprocess::Handle',
    lazy_build => 1,
);

sub _build_pipes {
    my $self = shift;
    my $direction = $self->direction;

    if ($direction eq 'rw') {
        return [ portable_socketpair() ];
    }
    elsif ( $direction eq 'r' ) {
        return [ portable_pipe() ];
    }
    else {
        return [ reverse (portable_pipe()) ];
    }
}

sub _build_handle {
    my $self = shift;

    my ($name, $direction) = map { $self->$_ } qw/name direction/;

    return $self->__build_handle(
        $self->pipes->[0],
        _direction => $direction,
        _name      => "parent $name handle ($direction)",
    );
};

sub build_run_delegates {
    my $self = shift;
    return $self->run_delegate_class->new(
        name           => $self->name,
        direction      => $self->direction,
        handle         => $self->handle,
        want_leftovers => $self->want_leftovers,
    );
}

sub parent_finalize_hook {
    my $self = shift;

    close $self->pipes->[1];
}

sub child_setup_hook {
    my $self = shift;

    my $name = $self->handle->name;
    $self->handle->do_not_want; # DO NOT WANT (in child)

    # reopen fake fds to the "real" ones

    my $ch = $self->pipes->[1];

    if ($self->has_replace) {
        my $replacement = ref $self->replace ?
          fileno($self->replace) :
            $self->replace;

        dup2( fileno($ch), $replacement )
          or confess "failed to dup $name to $replacement: $!";
    }

    AnyEvent::Util::fh_nonblocking $ch, 0;
}

sub build_code_args {
    my $self = shift;
    if ($self->pass_to_child){
        return $self->name => $self->pipes->[1];
    }
    return;
}

sub parent_setup_hook {}
sub child_finalize_hook {}
sub receive_child_result {}
sub receive_child_error {}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 INITARGS

=head2 direction

'r' for a pipe from the child to the parent, 'w' for a pipe from the
parent to the child, 'rw' for a socket.

=head2 replace

Optional.  If specified, can be a Perl filehandle (C<\*STDERR>) or
integer fd number (C<2>).  This filehandle will be opened to the object
created by this delegate in the child.  (So if you say
C<< direction => 'r', replace => \*STDERR >>, the parent will be able to
read the child's STDERR via this delegate.  If you say
C<< direction => 'w', replace => 3 >>, then the child can open fd #3
 and read from the parent.)

=head2 pass_to_child

If you don't want to replace a filehandle or file descriptor number,
you can just pass the filehandle object to the child instead.  If you
set this to true, the child will get its end of the socket or pipe in
the argument hash passed to the child coderef.  The key will be the
same as the name the delegate.

=head1 METHODS

=head2 handle

This is the
L<AnyEvent::Subprocess::Handle|AnyEvent::Subprocess::Handle> object
that you use to communicate with the child.  You typically want to
C<push_read> and C<push_write>, but all of
L<AnyEvent::Handle|AnyEvent::Handle>'s operations are available.  See
that manpage for further details; there is a lot you can do, and this
module makes it all very easy.
