package AnyEvent::Subprocess::Job::Role::WithStandardHandles;
use Moose::Role;

with
  'AnyEvent::Subprocess::Job::Role::WithHandle' => {
      name      => 'stdin',
      direction => 'w',
      replace   => \*STDIN,
  },

  'AnyEvent::Subprocess::Job::Role::WithHandle' => {
      name      => 'stdout',
      direction => 'r',
      replace   => \*STDOUT,
  },

  'AnyEvent::Subprocess::Job::Role::WithHandle' => {
      name      => 'stderr',
      direction => 'r',
      replace   => \*STDERR,
  };

1;
