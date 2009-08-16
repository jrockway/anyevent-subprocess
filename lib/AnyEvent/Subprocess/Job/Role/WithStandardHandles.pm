package AnyEvent::Subprocess::Job::Role::WithStandardHandles;
use Moose::Role;

with
  'AnyEvent::Subprocess::Job::Role::WithHandle' => {
      name           => 'stdin',
      direction      => 'w',
      replace_handle => \*STDIN,
  },

  'AnyEvent::Subprocess::Job::Role::WithHandle' => {
      name           => 'stdout',
      direction      => 'r',
      replace_handle => \*STDOUT,
  },

  'AnyEvent::Subprocess::Job::Role::WithHandle' => {
      name           => 'stderr',
      direction      => 'r',
      replace_handle => \*STDERR,
  };

1;
