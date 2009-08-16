package AnyEvent::Subprocess::Job::Role::Pty;
use Moose::Role;

excludes 'AnyEvent::Subprocess::Job::Role::WithStandardHandles';

use IO::Pty;

use namespace::autoclean;

has 'pty' => (
    is         => 'ro',
    isa        => 'IO::Pty',
    lazy_build => 1,
);

has 'slave_pty' => (
    is         => 'ro',
    lazy_build => 1,
);

has 'pty_handle' => (
    is         => 'ro',
    isa        => 'AnyEvent::Subprocess::Handle',
    lazy_build => 1,
);

sub _build_pty {
    return IO::Pty->new;
}

sub _build_slave_pty {
    my $self = shift;
    return $self->pty->slave;
}

sub _build_pty_handle {
    my $self = shift;

    return $self->_build_handle(
        $self->pty,
        _direction => 'rw',
        _name      => 'pty',
    );
}

around '_build_run_traits' => sub {
    my ($next, $self, @args) = @_;
    return [
        @{$self->$next(@args)},
        'WithHandle' => { name => 'pty', direction => 'rw' },
    ];
};

around '_build_run_initargs' => sub {
    my ($orig, $self, @args) = @_;
    return (
        $self->$orig(@args),
        pty_handle => $self->pty_handle,
    );
};

before '_parent_finalize_hook' => sub {
    my $self = shift;
    $self->pty->close_slave;
    #$self->pty->make_slave_controlling_terminal;
};

before '_child_setup_hook' => sub {
    my $self = shift;

    $self->pty_handle->do_not_want;

    # reopen fake fds to the "real" ones

    my $reopen = sub {
        open $_[0], $_[1]. '&='. $_[2]->fileno or confess "failed to reopen: $!";
    };

    AnyEvent::Util::fh_nonblocking $self->slave_pty, 0;

    $reopen->(*STDIN,  '<', $self->slave_pty);
    $reopen->(*STDOUT, '>', $self->slave_pty);
    $reopen->(*STDERR, '>', $self->slave_pty);

    *STDIN  = $self->slave_pty;
    *STDOUT = $self->slave_pty;
    *STDERR = $self->slave_pty;
};

1;
