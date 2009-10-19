package AnyEvent::Subprocess::Job;

use AnyEvent;
use AnyEvent::Subprocess::Types qw(JobDelegate SubprocessCode);

use Try::Tiny;

use namespace::autoclean;

our $VERSION = '0.01';

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

has 'run' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_run',
);

has 'verbose' => (
    is       => 'ro',
    isa      => 'Bool',
    default  => sub { 1 },
    required => 1,
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
    exit 0;
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

# XXX: it would be nice to "catch" exceptions in the child and throw
# them to the parent
sub _run_child {
    my $self = shift;

    # scope_guard {
    #     exit 255;
    # };

    try {
        $self->_child_setup_hook;
        $self->code->({$self->_build_code_args});
        $self->_child_finalize_hook;
    }
    catch {
        # emulate perl's default behavior here
        print {*STDERR} $_ if $self->verbose;
        exit 255;
    };

    return;
}

sub _build_run {
    my $self = shift;

    my $run = $self->_init_run_instance;

    $self->_parent_setup_hook($run);

    # TODO: configurable/delegate-able fork
    my $child_pid = fork;
    confess "fork error: $!" unless defined $child_pid;

    unless($child_pid){
        $self->_run_child();
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

