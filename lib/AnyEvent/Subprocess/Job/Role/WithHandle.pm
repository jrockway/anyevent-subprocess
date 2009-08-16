package AnyEvent::Subprocess::Job::Role::WithHandle;
use AnyEvent;
use AnyEvent::Util; # portable socket/pipendle;
use AnyEvent::Subprocess::Handle;

use MooseX::Role::Parameterized;

use MooseX::Types::Moose qw(Str GlobRef ArrayRef);
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

parameter 'replace_handle' => (
    is        => 'ro',
    isa       => GlobRef,
    predicate => 'has_replace_handle',
);

# sub BUILD {
#     my $self = shift;
#     confess 'supplying "replace_handle" does not make sense with "rw" direction'
#       if $self->direction eq 'rw' && $self->replace_handle;
# }

role {
    my $p = shift;
    my $name = $p->name;
    my $direction = $p->direction;

    my $pipe_method = "_${name}_pipes";
    has $pipe_method => (
        is         => 'ro',
        reader     => $pipe_method,
        isa        => ArrayRef[GlobRef],
        lazy_build => 1,
    );

    my $handle_name = "${name}_handle";
    my $handle_attrname = "_$handle_name";
    has $handle_attrname => (
        is         => 'ro',
        isa        => 'AnyEvent::Subprocess::Handle',
        lazy_build => 1,
    );

    method "_build__${name}_pipes" => sub {
        my $self = shift;

        if($direction eq 'rw'){
            return [ AnyEvent::Util::portable_socketpair() ];
        }
        elsif( $direction eq 'r' ){
            return [ AnyEvent::Util::portable_pipe() ];
        }
        else {
            return [ reverse (AnyEvent::Util::portable_pipe()) ];
        }
    };

    requires '_build_handle'; # provided by ::Job, usually

    method "_build__${name}_handle" => sub {
        my $self = shift;

        return $self->_build_handle(
            $self->$pipe_method->[0],
            _direction => $direction,
            _name      => "parent $name handle ($direction)",
        );
    };

    around '_build_run_traits' => sub {
        my ($next, $self, @args) = @_;
        return [
            @{$self->$next(@args)},
            'WithHandle', { name => $name, direction => $direction },
        ];
    };

    around '_build_args_to_init_run_instance' => sub {
        my ($orig, $self, @args) = @_;
        return (
            $self->$orig(@args),
            $handle_name => $self->$handle_attrname,
        );
    };

    before '_parent_finalize_hook' => sub {
        my $self = shift;

        close $self->$pipe_method->[1];
    };

    before '_child_setup_hook' => sub {
        my $self = shift;

        $self->$handle_attrname->do_not_want; # DO NOT WANT (in child)

        # reopen fake fds to the "real" ones

        my $ch = $self->$pipe_method->[1];

        if($p->has_replace_handle){
            my $dir = ($direction eq 'r') ? '>' : '<'; # reverse because we are in child
            open $p->replace_handle, "$dir&=". fileno($ch)
              or confess "failed to reopen $name for $dir: $!";

            *{$p->replace_handle} = $ch;
        }

        AnyEvent::Util::fh_nonblocking $ch, 0;
    };
};

1;
