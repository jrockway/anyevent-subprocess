package AnyEvent::Subprocess::Job::Delegate;

# ABSTRACT: role that delegates on the Job class must implement
use Moose::Role;

with 'AnyEvent::Subprocess::Delegate';

requires 'build_run_delegates';
requires 'child_setup_hook';
requires 'child_finalize_hook';
requires 'parent_setup_hook';
requires 'parent_finalize_hook';
requires 'build_code_args';
requires 'receive_child_result';
requires 'receive_child_error';

1;

__END__
