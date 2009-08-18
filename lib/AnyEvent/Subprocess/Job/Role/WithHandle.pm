package AnyEvent::Subprocess::Job::Role::WithHandle;
use AnyEvent;
use AnyEvent::Util; # portable socket/pipendle;
use AnyEvent::Subprocess::Handle;
use AnyEvent::Subprocess::Role::WithTrait;

use MooseX::Role::Parameterized;

use MooseX::Types::Moose qw(Str Int GlobRef ArrayRef);
use AnyEvent::Subprocess::Types qw(Direction);

use POSIX qw(dup2);

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

parameter 'replace' => (
    is        => 'ro',
    isa       => GlobRef|Int,
    predicate => 'has_replace',
);

role {
    my $p = shift;

    my $name = $p->name;
    my $direction = $p->direction;

    # I am not sure this is true anymore; let the user decide :)
    #
    # confess 'supplying "replace" does not make sense with "rw" direction'
    #   if $direction eq 'rw' && $p->replace;

    with 'AnyEvent::Subprocess::Role::WithTrait' => {
        type       => 'run',
        trait_name => 'WithHandle',
        trait_args => { name => $name, direction => $direction },
    };

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

    around '_build_run_initargs' => sub {
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

        my $name = $self->$handle_attrname->name;
        $self->$handle_attrname->do_not_want; # DO NOT WANT (in child)

        # reopen fake fds to the "real" ones

        my $ch = $self->$pipe_method->[1];

        if($p->has_replace){
            my $replacement = ref $p->replace ?
              fileno($p->replace) :
              $p->replace;

            dup2( fileno($ch), $replacement )
              or confess "failed to dup $name to $replacement: $!";
        }

        AnyEvent::Util::fh_nonblocking $ch, 0;
    };
};

1;
