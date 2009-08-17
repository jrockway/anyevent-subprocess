package AnyEvent::Subprocess::Role::WithTrait;
use MooseX::Role::Parameterized;

parameter 'type' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

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
    my $type = $p->type;

    my $build_method = "_build_${type}_traits";

    requires $build_method;

    around $build_method => sub {
        my ($next, $self, @args) = @_;
        return [
            @{$self->$next(@args)},

            # this looks weird, but does work in both cases
            $p->trait_name => ($p->has_trait_args ? $p->trait_args : ()),
        ];
    };
};



1;
