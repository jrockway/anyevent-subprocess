package AnyEvent::Subprocess::Job::Role::UserHooks;
use Moose::Role;

has [qw/child_setup_hook child_finalize_hook
        parent_setup_hook parent_finalize_hook
        completion_hook/] => (
    is       => 'ro',
    isa      => 'CodeRef',
    default  => sub { sub {} },
    required => 1,
);

with 'AnyEvent::Subprocess::Role::WithTrait' => {
    type       => 'run',
    trait_name => 'UserHooks',
};

around '_build_run_initargs' => sub {
    my ($orig, $self, @args) = @_;
    return (
        $self->$orig(@args),
        completion_hook => $self->completion_hook,
    );
};

after '_child_setup_hook' => sub {
    my ($self) = @_;
    $self->child_setup_hook->($self);
};

before '_child_finalize_hook' => sub {
    my ($self) = @_;
    $self->child_finalize_hook->($self);
};

after '_parent_setup_hook' => sub {
    my ($self, $run) = @_;
    $self->parent_setup_hook->($self, $run);
};

after '_parent_finalize_hook' => sub {
    my ($self) = @_;
    $self->parent_finalize_hook->($self);
};

1;
