package AnyEvent::Subprocess::Job::Delegate::Callback;

# ABSTRACT: call callbacks for each job/run/done step
use AnyEvent::Subprocess::Running::Delegate::Callback;
use Moose;
use MooseX::StrictConstructor;

with 'AnyEvent::Subprocess::Job::Delegate';

for my $a (qw/child_setup_hook child_finalize_hook
              parent_setup_hook parent_finalize_hook
              completion_hook build_code_args receive_child_result
              receive_child_error/) {

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

sub build_code_args {
    my ($self, $job) = @_;
    return $self->_build_code_args->($self, $job);
}

sub receive_child_result {
    my ($self, $job, $result) = @_;
    return $self->_receive_child_result->($self, $job, $result);
}

sub receive_child_error {
    my ($self, $job, $error) = @_;
    return $self->_receive_child_error->($self, $job, $error);
}

1;

__PACKAGE__->meta->make_immutable;
