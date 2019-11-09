package AnyEvent::Subprocess::Done;

# ABSTRACT: represents a completed subprocess run
use Moose;
use namespace::autoclean;

use AnyEvent::Subprocess::Types qw(DoneDelegate);
use POSIX qw(WIFEXITED WEXITSTATUS WIFSIGNALED WIFEXITED WTERMSIG);

with 'AnyEvent::Subprocess::Role::WithDelegates' => {
    type => DoneDelegate,
};

# $? is the exit_status, the argument to exit ("exit 0") is exit_value
# if the process was killed, exit_signal contains the signal that killed it
has 'exit_status' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has [qw[dumped_core exited]] => (
    is         => 'ro',
    isa        => 'Bool',
    lazy_build => 1,
);

has [qw[exit_value exit_signal]] => (
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1,
);

sub _build_exited {
    my $self = shift;
    return WIFEXITED($self->exit_status);
}

sub _build_exit_value {
    my $self = shift;
    return WEXITSTATUS($self->exit_status);
}

sub _build_exit_signal {
    my $self = shift;
    return WIFSIGNALED($self->exit_status) && WTERMSIG($self->exit_status);
}

sub _build_dumped_core {
    my $self = shift;
    return 0 if $self->exit_status < 0;
    return $self->exit_status & 128;
}

sub is_success {
    my $self = shift;
    return $self->exit_status == 0;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

We are C<$done> in a sequence like:

   my $job = AnyEvent::Subprocess->new ( ... );
   my $run = $job->run;
   $run->delegate('stdin')->push_write('Hello, my child!');
   say "Running child as ", $run->child_pid;
   $run->kill(11) if $you_enjoy_that_sort_of_thing;
   my $done = $job->delegate('completion_condvar')->recv;
   say "Child exited with signal ", $done->exit_signal;
   say "Child produced some stdout: ",
       $done->delegate('stdout_capture')->output;

=head1 DESCRIPTION

An instance of this class is returned to your C<on_completion>
callback when the child process exists.

=head1 METHODS

=head2 delegate( $name )

Returns the delegate named C<$name>.

=head2 exit_status

C<$?> from waitpid on the child.  Parsed into the various fields
below:

=head2 exit_value

The value the child supplied to C<exit>.  (0 if "C<exit 0>", etc.)

=head2 exit_signal

The signal number the child was killed by, if any.

=head2 dumped_core

True if the child dumped core.

=head2 is_success

True if the exit_status is 0.  If this is false, your process dumped
core, exited due to a signal, or exited with a value other than 0.

=head1 SEE ALSO

L<AnyEvent::Subprocess>

L<AnyEvent::Subprocess::Role::WithDelegates>

