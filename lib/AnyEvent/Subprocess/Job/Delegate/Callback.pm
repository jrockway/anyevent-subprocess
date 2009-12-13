package AnyEvent::Subprocess::Job::Delegate::Callback;
use AnyEvent::Subprocess::Running::Delegate::Callback;
use Moose;
use MooseX::StrictConstructor;

with 'AnyEvent::Subprocess::Job::Delegate';

for my $a (qw/child_setup_hook child_finalize_hook
              parent_setup_hook parent_finalize_hook
              completion_hook/) {

    has $a => (
        init_arg => $a,
        reader   => "_$a",
        isa      => 'CodeRef',
        default  => sub { sub {} },
        required => 1,
    );
}

has 'state' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
    default  => sub { +{} },
);

sub build_run_delegates {
    my $self = shift;
    return AnyEvent::Subprocess::Running::Delegate::Callback->new(
          name            => $self->name,
          completion_hook => $self->_completion_hook,
          state           => $self->state,
      );
}

sub child_setup_hook {
    my ($self, $job) = @_;
    $self->_child_setup_hook->($self, $job);
}

sub child_finalize_hook {
    my ($self, $job) = @_;
    $self->_child_finalize_hook->($self, $job);
}

sub parent_setup_hook {
    my ($self, $job, $run) = @_;
    $self->_parent_setup_hook->($self, $job, $run);
}

sub parent_finalize_hook {
    my ($self, $job) = @_;
    $self->_parent_finalize_hook->($self, $job);
}

# XXX: add this
sub build_code_args {}

1;
