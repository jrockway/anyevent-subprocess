package AnyEvent::Subprocess::Job;

use AnyEvent;
use AnyEvent::Subprocess::Types qw(JobDelegate SubprocessCode);
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

sub _run_child {
    my $self = shift;

    $self->_child_setup_hook;
    $self->code->({$self->_build_code_args});
    return $self->_child_finalize_hook;
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
