package AnyEvent::Subprocess::Job;
use Moose::Role;

our $VERSION = '0.01';

use namespace::autoclean;

use AnyEvent;
use AnyEvent::Util; # portable socket/pipe
use AnyEventX::Cancel qw(cancel_all_watchers);

has 'code' => (
    is       => 'ro',
    isa      => 'CodeRef', # TODO arrayref or string for `system`
    required => 1,
);

has 'cancel_loop' => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 1,
    required => 1,
);

has 'before_fork_hook' => (
    is       => 'ro',
    isa      => 'CodeRef',
    default  => sub { sub { } },
    required => 1,
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

has 'run_traits' => (
    is         => 'ro',
    isa        => 'ArrayRef[Str]',
    lazy_build => 1,
);

sub _build_run_traits { +[] }

has 'run' => (
    is      => 'ro',
    isa     => 'AnyEvent::Subprocess::Running',
    lazy    => 1,
    builder => '_build_run',
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

sub _build_handle {
    my ($self, $fh, @rest) = @_;
    return $self->handle_class->new( fh => $fh, @rest );
}

sub _init_run_instance {
    my ($self) = @_;
    my $run = $self->run_class->new_with_traits(
        $self->_build_args_to_init_run_instance,
    );
    return $run;
}

# TODO: make these other _build_whatever things attributes, so that the
# user can override later

sub _build_args_to_init_run_instance {
    my $self = shift;
    return (
        traits => $self->run_traits,
    );
}

sub _child_setup_hook {
    my $self = shift;
    cancel_all_watchers( warning => 0 )
      if $self->cancel_loop;

    return;
}

sub _child_finalize_hook {
    exit 0;
}

sub _parent_setup_hook {
    my $self = shift;
    my $run = shift;
    $self->before_fork_hook->($run);
    return;
}

sub _parent_finalize_hook {
    return;
}

sub _build_code_args {
    my $self = shift;
    return;
}

sub _run_child {
    my $self = shift;

    $self->_child_setup_hook;
    $self->code->($self->_build_code_args);
    return $self->_child_finalize_hook;
}

sub _run_parent {
    my $self = shift;
    my $run = shift;

    $self->_parent_finalize_hook;
}

sub _build_run {
    my $self = shift;

    my $run = $self->_init_run_instance;

    $self->_parent_setup_hook($run);

    my $child_pid = fork;

    unless($child_pid){
        $self->_run_child();
    }

    $run->child_pid($child_pid);
    $self->_run_parent($run);

    return $run;
}

1;
