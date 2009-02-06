package AnyEvent::Subprocess::Running::WithOutputCallbacks;
use Moose::Role;

has [qw/stdout_callback stderr_callback/] => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub { sub { } },
);

after '_read_stdout' => sub {
    my ($self, $data) = @_;
    $self->stdout_callback->($data);
};

after '_read_stderr' => sub {
    my ($self, $data) = @_;
    $self->stderr_callback->($data);
};

1;
