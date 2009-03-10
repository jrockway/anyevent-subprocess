package AnyEvent::Subprocess;
use Moose;

our $VERSION = 0.01;

use AnyEvent;
use AnyEvent::Util;
use AnyEvent::Subprocess::Handle;
use AnyEvent::Subprocess::Running;

use namespace::clean -except => 'meta';

has 'code' => (
    is       => 'ro',
    isa      => 'CodeRef', # TODO arrayref or string for `system`
    required => 1,
);

has 'before_fork_hook' => (
    is       => 'ro',
    isa      => 'CodeRef',
    default  => sub { sub { } },
    required => 1,
);

my %loop_killers = (
    'AnyEvent::Impl::POE' => sub {
        POE::Kernel->stop;
    },
    'AnyEvent::Impl::Event' => sub {
        for my $watcher (Event::all_watchers()){
            $watcher->cancel;
        }
    },
    'AnyEvent::Impl::EV' => sub {
        EV::cancel_all_watchers();
    },
);

sub run {
    my $self = shift;
    my $done = AnyEvent->condvar;

    my ($parent_socket, $child_socket) = portable_socketpair;
    my ($parent_stdout, $child_stdout) = portable_pipe;
    my ($parent_stderr, $child_stderr) = portable_pipe;
    my ($child_stdin, $parent_stdin) = portable_pipe;

    my $parent_stdout_handle = AnyEvent::Subprocess::Handle->new(
        fh => $parent_stdout,
    );

    my $parent_stderr_handle = AnyEvent::Subprocess::Handle->new(
        fh => $parent_stderr,
    );

    my $parent_stdin_handle = AnyEvent::Subprocess::Handle->new(
        fh => $parent_stdin,
    );

    my $parent_comm_handle = AnyEvent::Subprocess::Handle->new(
        fh => $parent_socket,
    );

    my $run = AnyEvent::Subprocess::Running->new(
        stdout_handle => $parent_stdout_handle,
        stderr_handle => $parent_stderr_handle,
        stdin_handle  => $parent_stdin_handle,
        comm_handle   => $parent_comm_handle,
    );

    $self->before_fork_hook->($run);

    my $loop_type = AnyEvent::detect;
    my $child_pid = fork;
    unless ($child_pid) {
        close $parent_socket;
        close $parent_stdin;
        close $parent_stdout;
        close $parent_stderr;

        my $loop_killer = $loop_killers{$loop_type};
        $loop_killer->() if $loop_killer;
        if(!$loop_killer){
          print {*STDERR} "WARNING: UNSUPPORTED EVENT LOOP IN USE, ".
              "CHILD MUST NOT CALL INTO EVENT LOOP!\n";
        }

        # setup stdin/stdout/stderr
        my $reopen = sub($$$) {
            open $_[0], $_[1]. '&='. fileno($_[2]) or confess "failed to reopen: $!";
        };

        $reopen->(*STDIN,  '<', $child_stdin);
        $reopen->(*STDOUT, '>', $child_stdout);
        $reopen->(*STDERR, '>', $child_stderr);

        local *STDOUT = $child_stdout;
        local *STDERR = $child_stderr;
        local *STDIN = $child_stdin;

        my $child_comm_handle = AnyEvent::Handle->new(
            fh => $child_socket,
        );

        eval {
            $self->code->($child_comm_handle);
        };
        if($@){
            print {*STDERR} $@;
            exit 255;
        }

        exit 0;
    }

    $run->child_pid($child_pid);

    close $child_socket;
    close $child_stdin;
    close $child_stdout;
    close $child_stderr;

    return $run;
}

1;
