package AnyEvent::Subprocess::Job::Delegate::Timeout;

# ABSTRACT: Kill a subprocess if it takes too long
use Moose;
use namespace::autoclean;

use AnyEvent;
use AnyEvent::Subprocess::Running::Delegate::Timeout;
use MooseX::Types::Signal qw(Signal);

with 'AnyEvent::Subprocess::Job::Delegate';

has 'time_limit' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'kill_with' => (
    is       => 'ro',
    isa      => Signal,
    coerce   => 1,
    required => 1,
    default  => 'SIGKILL',
);

has 'child' => (
    init_arg => undef,
    accessor => 'child',
);

sub build_run_delegates {
    my $self = shift;
    my $run; $run = AnyEvent::Subprocess::Running::Delegate::Timeout->new(
        name  => $self->name,
        timer => AnyEvent->timer( after => $self->time_limit, interval => 0, cb => sub {
            $run->killed_by_timer(1);
            $self->child->kill( $self->kill_with );
            $run->clear_timer;
        }),
    );

    return $run;
}

sub parent_setup_hook {
    my ($self, $job, $run) = @_;
    $self->child($run);
}

sub build_code_args {}
sub child_setup_hook {}
sub child_finalize_hook {}
sub parent_finalize_hook {}
sub receive_child_error {}
sub receive_child_result {}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

    my $timed = AnyEvent::Subprocess::Job::Delegate::Timeout->new(
        name       => 'timeout',
        time_limit => 10,     # 10 seconds
        kill_with  => 'FIRE', # may not be available on your OS
    );

    my $job = AnyEvent::Subprocess->new( delegates => [$timed], code => ... );
    my $run = $job->run;

Later...

    my $done = ...;
    say 'your job took too long, so i killed it with fire'
        if $done->delegate('tiemout')->timed_out;

=head1 ATTRIBUTES

=head2 time_limit

Number of seconds to allow the subprocess to run for.  Required.

=head2 kill_with

UNIX signal to kill the subprocess with when its time expires.
Defaults to SIGKILL.
