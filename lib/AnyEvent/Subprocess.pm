package AnyEvent::Subprocess;
use Moose;

use AnyEvent;
use AnyEvent::Util;
use AnyEvent::Handle;

use AnyEvent::Subprocess::Running;

use namespace::clean -except => 'meta';

has [qw/on_stdout on_stderr/] => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub { sub { } },
);

has 'code' => (
    is       => 'ro',
    isa      => 'CodeRef', # TODO arrayref or string for `system`
    required => 1,
);

sub run {
    my $self = shift;
    my $done = AnyEvent->condvar;

    #my ($parent_socket, $child_socket) = $self->_socketpair;
    my ($parent_stdout, $child_stdout) = portable_pipe;
    my ($parent_stderr, $child_stderr) = portable_pipe;

    my $parent_stdout_listener = AnyEvent::Handle->new(
        fh => $parent_stdout,
    );

    my $parent_stderr_listener = AnyEvent::Handle->new(
        fh => $parent_stderr,
    );

    my $parent_stdin_listener = AnyEvent::Handle->new(
        fh => $parent_stdin,
    );

    AnyEvent::detect;
    my $child_pid = fork;

    unless( $child_pid ){
        local *STDOUT = $child_stdout;
        local *STDERR = $child_stderr;
        $self->code->();
        exit 0;
    }

    return AnyEvent::Subprocess::Running->new(
        child_pid     => $child_pid,
        stdout_handle => $parent_stdout_listener,
        stderr_handle => $parent_stderr_listener,
        stdin_handle  => $parent_stdin_listener,
    );

}

1;
