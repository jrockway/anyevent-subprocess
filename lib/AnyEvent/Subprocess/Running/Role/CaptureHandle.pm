package AnyEvent::Subprocess::Running::Role::CaptureHandle;
use MooseX::Role::Parameterized;

use AnyEvent::Subprocess::Role::WithTrait;

parameter 'handle_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

role {
    my $p = shift;
    my $h = $p->handle_name;

    with 'AnyEvent::Subprocess::Role::WithTrait' => {
        type       => 'done',
        trait_name => 'CaptureHandle',
        trait_args => { handle_name => $p->handle_name },
    };

    my $output_reader = "_${h}_output";
    has $output_reader => (
        metaclass => 'String',
        init_arg  => undef,
        is        => 'ro',
        isa       => 'Str',
        default   => '',
        provides  => {
            append => "_append_to_${h}_output",
        },
    );

    around '_build_done_initargs' => sub {
        my ($next, $self, @args) = @_;
        return (
            $self->$next(@args),
            "captured_$h" => $self->$output_reader,
        );
    };
};

1;
