package AnyEvent::Subprocess::Running::Role::WithCommHandle;
use Moose::Role;
use AnyEvent::Subprocess::Handle;

has 'comm_handle' => (
    is       => 'ro',
    isa      => 'AnyEvent::Subprocess::Handle',
    required => 1,
);

1;
