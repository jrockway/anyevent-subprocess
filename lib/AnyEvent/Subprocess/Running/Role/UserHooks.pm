package AnyEvent::Subprocess::Running::Role::UserHooks;
use Moose::Role;

has [qw/completion_hook/] => (
    is       => 'ro',
    isa      => 'CodeRef',
    default  => sub { sub {} },
    required => 1,
);

before '_completion_hook' => sub {
    my ($self, %args) = @_;
    $self->completion_hook->($self, %args);
};

1;
