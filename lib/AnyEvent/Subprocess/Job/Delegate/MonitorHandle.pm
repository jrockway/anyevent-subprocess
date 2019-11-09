package AnyEvent::Subprocess::Job::Delegate::MonitorHandle;

# ABSTRACT: monitor a handle for input and invoke callbacks with that input
use AnyEvent::Subprocess::Running::Delegate::MonitorHandle;
use AnyEvent::Subprocess::Types qw(CodeList WhenToCallBack);
use MooseX::Types::Moose qw(Str);

use Moose;
use namespace::autoclean;

with 'AnyEvent::Subprocess::Job::Delegate';

has 'handle' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'callbacks' => (
    traits     => ['Array'],
    is         => 'ro',
    isa        => CodeList,
    required   => 1,
    coerce     => 1,
    auto_deref => 1,
    handles    => {
        add_callback => 'push',
    },
);

has 'when' => (
    is       => 'ro',
    isa      => WhenToCallBack,
    required => 1,
    default  => sub { 'Line' },
);

sub parent_setup_hook {
    my ($self, $job, $run) = @_;

    my $handle = $run->delegate($self->handle)->handle;

    if($self->when eq 'Line'){
        my $reader; $reader = sub {
            my ($h, $l, $eol) = @_;
            $self->_run_callbacks($l, $eol);
            $h->push_read(line => $reader);
        };
        $handle->push_read(line => $reader);
    }
    else {
        $handle->on_read( sub {
            my $h = shift;
            $self->_run_callbacks( delete $h->{rbuf} );
            return;
        });
    }

    return;
}

sub _run_callbacks {
    my $self = shift;

    for my $cb ($self->callbacks){
        $cb->(@_);
    }

    return;
}

sub build_run_delegates {
    my $self = shift;
    return AnyEvent::Subprocess::Running::Delegate::MonitorHandle->new(
        name          => $self->name,
        _job_delegate => $self,
    );
}

sub child_setup_hook {}
sub child_finalize_hook {}
sub parent_finalize_hook {}
sub build_code_args {}
sub receive_child_result {}
sub receive_child_error {}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 DESCRIPTION

Monitors a handle for input, and calls a list of coderefs when there is input.  The coderefs get the input.

=head1 INITARGS

=head2 name

The name of the delegate that has the filehandle you want to monitor.

=head2 callbacks

ArrayRef[CodeRef]s to call with input.

=head2 when

'Line' to be called with each line, something else to be called
whenever there is data in the read buffer.

=head1 METHODS

Don't call us, we'll call you.
