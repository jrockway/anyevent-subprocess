package AnyEvent::Subprocess::Job;

use AnyEvent;
use AnyEvent::Subprocess::Types qw(JobDelegate SubprocessCode);

use Try::Tiny;

use namespace::autoclean;
use Moose::Role;

with 'AnyEvent::Subprocess::Role::WithDelegates' => {
    type => JobDelegate,
};

has 'code' => (
    is       => 'ro',
    isa      => SubprocessCode,
    required => 1,
    coerce   => 1,
);

has 'on_completion' => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => '_has_on_completion',
);

has 'run_class' => (
    is       => 'ro',
    isa      => 'ClassName',
    required => 1,
    default  => sub {
        require AnyEvent::Subprocess::Running;
        return 'AnyEvent::Subprocess::Running';
    },
);

sub _init_run_instance {
    my ($self) = @_;
    my $run = $self->run_class->new(
        delegates => [$self->_build_run_delegates],
        ($self->_has_on_completion) ? (on_completion => $self->on_completion) : ()
    );
    return $run;
}

sub _build_run_delegates {
    my $self = shift;
    return $self->_invoke_delegates('build_run_delegates');
}

sub _child_setup_hook {
    my $self = shift;

    $self->_invoke_delegates('child_setup_hook');
    return;
}

sub _child_finalize_hook {
    my $self = shift;
    $self->_invoke_delegates('child_finalize_hook');
}

sub _parent_setup_hook {
    my $self = shift;
    my $run = shift;
    $self->_invoke_delegates('parent_setup_hook', $run);
    return;
}

sub _parent_finalize_hook {
    my $self = shift;
    $self->_invoke_delegates('parent_finalize_hook');
    return;
}

sub _build_code_args {
    my $self = shift;
    return $self->_invoke_delegates('build_code_args');
}

sub _run_child {
    my $self = shift;
    my $args = shift || {};

    my $exit_code = 0;
    $self->_child_setup_hook;
    try {
        my $result = $self->code->({%$args, $self->_build_code_args});
        $self->_invoke_delegates('receive_child_result', $result);
    } catch {
        my $error = $_;
        $self->_invoke_delegates('receive_child_error', $error);
        $exit_code = 255; # backcompat
    };
    $self->_child_finalize_hook;
    exit $exit_code;
}

sub run {
    my $orig_self = shift;
    my $args_hash = shift;

    confess "argument to run must be a hashref, not $args_hash"
      if defined $args_hash && !(ref $args_hash && ref $args_hash eq 'HASH');

    my $self = $orig_self->clone;

    my $run = $self->_init_run_instance;

    $self->_parent_setup_hook($run);

    # an event loop must exist before the fork, in case the child
    # exits before we create the watcher
    AnyEvent::detect();

    # TODO: configurable/delegate-able fork
    my $child_pid = fork;
    confess "fork error: $!" unless defined $child_pid;

    unless($child_pid){
        $self->_run_child($args_hash);
    }

    $run->child_pid($child_pid);
    $self->_parent_finalize_hook;

    return $run;
}

1;

__END__

=head1 NAME

AnyEvent::Subprocess::Job - role representing a runnable job

=head1 ATTRIBUTES

=head2 code

Coderef to run in the subprocess; or an arrayref or string to pass to C<exec>.

=head2 on_completion

Coderef to be called when the process exits.  Will be passed a
L<AnyEvent::Subprocess::Done|AnyEvent::Subprocess::Done> object.

=head2 run_class

The classname of the "run" class returned by C<run>; defaults to
C<AnyEvent::Subprocess::Running>.

=head2 run

The instance of the run class above; built lazily.

Calling run twice does not run the process twice, but I think this
might change in the future.

=head1 METHODS

All the methods in this role are internal, and include:

    _init_run_instance
    _build_run_delegates
    _child_setup_hook
    _child_finalize_hook
    _parent_setup_hook
    _parent_finalize_hook
    _build_code_args
    _run_child
    _build_run

If you want to have your own code run at various phases in the
process, implement a delegate.  See
L<AnyEvent::Subprocess::Job::Delegate> for details.

