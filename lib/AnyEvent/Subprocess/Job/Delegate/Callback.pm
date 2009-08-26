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

sub build_run_delegates {
    my $self = shift;
    return AnyEvent::Subprocess::Running::Delegate::Callback->new(
          name            => $self->name,
          completion_hook => $self->_completion_hook,
      );
}

sub child_setup_hook {
    my ($self) = @_;
    $self->_child_setup_hook->($self);
}

sub child_finalize_hook {
    my ($self) = @_;
    $self->_child_finalize_hook->($self);
}

sub parent_setup_hook {
    my ($self, $run) = @_;
    $self->_parent_setup_hook->($self, $run);
}

sub parent_finalize_hook {
    my ($self) = @_;
    $self->_parent_finalize_hook->($self);
}

sub build_code_args {}

1;
