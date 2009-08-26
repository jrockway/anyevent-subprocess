package AnyEvent::Subprocess::Running::Delegate::CaptureHandle;
use Moose;
use AnyEvent::Subprocess::Done::Delegate::CaptureHandle;

use MooseX::AttributeHelpers;

with 'AnyEvent::Subprocess::Running::Delegate';

has 'output' => (
    metaclass => 'String',
    init_arg  => undef,
    is        => 'ro',
    isa       => 'Str',
    default   => '',
    provides  => {
        append => '_append_output',
    },
);

sub build_done_delegates {
    my $self = shift;

    return AnyEvent::Subprocess::Done::Delegate::CaptureHandle->new(
        name   => $self->name,
        output => $self->output,
    );
}

sub build_events {}
sub completion_hook {}

1;
