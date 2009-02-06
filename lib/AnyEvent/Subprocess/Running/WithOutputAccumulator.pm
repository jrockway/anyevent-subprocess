package AnyEvent::Subprocess::Running::WithOutputAccumulator;
use Moose::Role;
use MooseX::AttributeHelpers;

# TODO: make these timestamped arrays so we can see interleaved
# stdout/stderr

has 'stdout' => (
    metaclass => 'String',
    is        => 'ro',
    isa       => 'Str',
    provides  => {
        append => '_append_stdout',
    },
    default   => sub { '' },
);

has 'stderr' => (
    metaclass => 'String',
    is        => 'ro',
    isa       => 'Str',
    provides  => {
        append => '_append_stderr',
    },
    default   => sub { '' },
);

after '_read_stdout' => sub {
    my ($self, $data) = @_;
    $self->_append_stdout($data);
};

after '_read_stderr' => sub {
    my ($self, $data) = @_;
    $self->_append_stderr($data);
};

1;
