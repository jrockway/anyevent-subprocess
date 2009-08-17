package AnyEvent::Subprocess::Job::Role::CaptureHandle;
use MooseX::Role::Parameterized;

use AnyEvent::Subprocess::Role::WithTrait;

parameter 'handle' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

parameter 'handle_method' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return $self->handle . '_handle';
    },
);

role {
    my $p = shift;
    my $h = $p->handle;
    my $m = $p->handle_method;

    with 'AnyEvent::Subprocess::Role::WithTrait' => {
        type       => 'run',
        trait_name => 'CaptureHandle',
        trait_args => {
            handle_name => $h,
        },
    };


    after '_parent_setup_hook' => sub {
        my ($self, $run) = @_;
        my $append_method = "_append_to_${h}_output";

        $run->$m->on_read( sub {
            my ($handle) = @_;
            my $buf = delete $handle->{rbuf};
            $run->$append_method($buf);
        });
    }
};

1;
