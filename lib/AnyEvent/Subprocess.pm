package AnyEvent::Subprocess;
use Moose;
use AnyEvent;
use AnyEvent::Util;
use AnyEvent::Handle;

use namespace::clean -except => 'meta';

has [qw/on_stdout on_stderr/] => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub { sub { } },
);

has 'code' => (
    is       => 'ro',
    isa      => 'CodeRef', # TODO arrayref or string for `system`
    required => 1,
);

has '_socketpair' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my ($r, $w) = portable_socketpair;
        die $r;
    },
);

sub socket {

}

sub run {
    my $self = shift;
    my $done = AnyEvent->condvar;

    my $pid = fork;

    if($pid){
        my $child_listener;
        $child_listener = AnyEvent->child (
            pid => $pid,
            cb  => sub {
                my ($pid, $status) = @_;
                $done->send($status);
                undef $child_listener
            },
        );
    }
    else {
        $self->code->();
        exit 0;
    }

    return $done;
}

1;
