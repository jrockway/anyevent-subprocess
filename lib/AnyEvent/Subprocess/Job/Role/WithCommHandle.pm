package AnyEvent::Subprocess::Job::Role::WithCommHandle;
use Moose::Role;
use AnyEvent::Util;
use namespace::autoclean;

has '_comm_socket' => (
    is         => 'ro',
    isa        => 'ArrayRef[GlobRef]', # (parent, child)
    lazy_build => 1,
);

sub _build__comm_socket {
    my $self = shift;
    return [ portable_socketpair ];
}

has '_comm_handle' => (
    is         => 'ro',
    isa        => 'ArrayRef[AnyEvent::Subprocess::Handle]',
    lazy_build => 1,
    auto_deref => 1,
);

sub _build__comm_handle {
    my $self = shift;
    my @name = qw/parent child/;
    return [ map {
        $self->_build_handle(
            $_,
            _direction => 'rw',
            _name      => 'comm '. shift @name,
        )
    } @{$self->_comm_socket} ];
}

around '_build_run_traits' => sub {
    my ($next, $self, @args) = @_;
    return [ @{$self->$next(@args)}, 'WithCommHandle' ];
};

before '_child_setup_hook' => sub {
    my $self = shift;
    $self->_comm_handle->[0]->do_not_want;

    # XXX: the child handle needs to be constructed in the child;
    # otherwise fail.  we keep the filehandle, though.
    $self->_comm_handle->[1]->destroy;
};

before '_parent_finalize_hook' => sub {
    my $self = shift;
    $self->_comm_handle->[1]->do_not_want;
};

around '_build_code_args' => sub {
    my $next = shift;
    my $self = shift;
    return ($self->_comm_socket->[1], $self->$next(@_));
};

around '_build_args_to_init_run_instance' => sub {
    my $next = shift;
    my $self = shift;
    return (
        $self->$next(@_),
        comm_handle => $self->_comm_handle->[0],
    );
};


1;
