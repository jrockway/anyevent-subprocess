package AnyEvent::Subprocess::Done::Role::CaptureHandle;
use MooseX::Role::Parameterized;
use MooseX::AttributeHelpers;

parameter 'handle_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

role {
    my $p = shift;
    my $n = $p->handle_name;

    has "captured_$n" => (
        is        => 'ro',
        isa       => 'Str',
        required  => 1,
    );
};

1;
