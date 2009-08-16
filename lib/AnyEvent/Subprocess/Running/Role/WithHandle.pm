package AnyEvent::Subprocess::Running::Role::WithHandle;
use MooseX::Role::Parameterized;
use AnyEvent::Subprocess::Handle;

use MooseX::Types::Moose qw(Str);
use AnyEvent::Subprocess::Types qw(Direction);

use namespace::autoclean;

parameter 'direction' => (
    is            => 'ro',
    isa           => Direction,
    required      => 1,
    documentation => 'r when parent reads a pipe, w when parent writes to a pipe, rw for a socket',
);

parameter 'name' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

role {
    my $p = shift;
    my $name = $p->name;
    my $direction = $p->direction;

    my $handle_name = "${name}_handle";

    has $handle_name => (
        is       => 'ro',
        isa      => 'AnyEvent::Subprocess::Handle',
        required => 1,
    );

    if( $direction eq 'r' ){
        around '_build_child_events' => sub {
            my ($next, $self) = @_;
            my $other_events = $self->$next;
            return [@$other_events, $handle_name];
        };

        requires 'BUILD';

        after 'BUILD' => sub {
            my ($self) = @_;

            $self->$handle_name->eof_condvar->cb(
                $self->child_event_joiner->event_sender_for($handle_name),
            );
        };
    }
};

1;
