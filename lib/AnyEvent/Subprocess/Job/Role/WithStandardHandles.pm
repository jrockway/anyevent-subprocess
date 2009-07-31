package AnyEvent::Subprocess::Job::Role::WithStandardHandles;
use Moose::Role;

use namespace::autoclean;

use AnyEvent;
use AnyEvent::Util; # portable socket/pipe

has 'pipes' => (
    is         => 'ro',
    isa        => 'ArrayRef[ArrayRef[GlobRef]]',
    lazy_build => 1,
    auto_deref => 1,
);

sub _build_pipes {
    my $self = shift;
    return [ map { [ portable_pipe ] } 0..2 ];
}

has [qw/reader_pipe_handles writer_pipe_handles/] => (
    is         => 'ro',
    isa        => 'ArrayRef[AnyEvent::Subprocess::Handle]',
    lazy_build => 1,
    auto_deref => 1,
);

around '_build_run_traits' => sub {
    my ($next, $self, @args) = @_;
    return [ @{$self->$next(@args)}, 'WithStandardHandles' ];
};

sub _build_reader_pipe_handles {
    my $self = shift;
    my $i = 0;
    return [ map {
        $self->_build_handle(
            $_->[0],
            _direction => 'r',
            _name      => "reader @{[$i++]}",
        )
    } $self->pipes ];
}

sub _build_writer_pipe_handles {
    my $self = shift;
    my $i = 0;
    return [ map {
        $self->_build_handle(
            $_->[1],
            _direction => 'w',
            _name      => "writer @{[$i++]}",
        )
    } $self->pipes ];
}

around '_build_args_to_init_run_instance' => sub {
    my ($orig, $self, @args) = @_;
    return (
        $self->$orig(@args),
        stdin_handle  => $self->writer_pipe_handles->[0],
        stdout_handle => $self->reader_pipe_handles->[1],
        stderr_handle => $self->reader_pipe_handles->[2],
    );
};

before '_parent_finalize_hook' => sub {
    my $self = shift;

    $_->do_not_want for (
        $self->reader_pipe_handles->[0],
        $self->writer_pipe_handles->[1],
        $self->writer_pipe_handles->[2],
    );

};

before '_child_setup_hook' => sub {
    my $self = shift;

    $_->do_not_want for (
        $self->writer_pipe_handles->[0],
        $self->reader_pipe_handles->[1],
        $self->reader_pipe_handles->[2],
    );
};

before '_child_setup_hook' => sub {
    my $self = shift;

    # reopen fake fds to the "real" ones

    my $reopen = sub {
        open $_[0], $_[1]. '&='. fileno($_[2]) or confess "failed to reopen: $!";
    };

    my ($child_stdin, $child_stdout, $child_stderr) =
      ($self->pipes->[0][0],  $self->pipes->[1][1], $self->pipes->[2][1]);

    AnyEvent::Util::fh_nonblocking $child_stdin, 0;

    $reopen->(*STDIN,  '<', $child_stdin);
    $reopen->(*STDOUT, '>', $child_stdout);
    $reopen->(*STDERR, '>', $child_stderr);

    *STDIN  = $child_stdin;
    *STDOUT = $child_stdout;
    *STDERR = $child_stderr;

};

1;
