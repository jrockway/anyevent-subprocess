package AnyEvent::Subprocess::Job::Role::WithRunTrait;
use MooseX::Role::Parameterized;

parameter 'trait_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

parameter 'trait_args' => (
    is        => 'ro',
    isa       => 'HashRef',
    predicate => 'has_trait_args',
);

role {
    my $p = shift;

    requires '_build_run_traits';

    around _build_run_traits => sub {
        my ($next, $self, @args) = @_;
        return [
            @{$self->$next(@args)},
            $p->trait_name => ($p->has_trait_args ? $p->trait_args : ()),
        ];
    };
};

1;
