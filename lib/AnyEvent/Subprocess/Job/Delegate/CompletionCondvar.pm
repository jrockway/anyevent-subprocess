package AnyEvent::Subprocess::Job::Delegate::CompletionCondvar;

# ABSTRACT: provide a condvar to indicate completion
use AnyEvent::Subprocess::Running::Delegate::CompletionCondvar;
use Moose;

with 'AnyEvent::Subprocess::Job::Delegate';

sub build_run_delegates {
    my $self = shift;
    return AnyEvent::Subprocess::Running::Delegate::CompletionCondvar->new(
          name => $self->name,
      );
}

sub child_setup_hook {}
sub child_finalize_hook {}
sub parent_setup_hook {}
sub parent_finalize_hook {}
sub build_code_args {}
sub receive_child_result {}
sub receive_child_error {}

__PACKAGE__->meta->make_immutable;

1;
