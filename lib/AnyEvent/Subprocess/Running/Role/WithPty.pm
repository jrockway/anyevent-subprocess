package AnyEvent::Subprocess::Running::Role::WithPty;
use Moose::Role;
use AnyEvent::Subprocess::Handle;

has [qw/pty_handle/] => (
    is       => 'ro',
    isa      => 'AnyEvent::Subprocess::Handle',
    required => 1,
);

1;
