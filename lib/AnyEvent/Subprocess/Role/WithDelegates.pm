package AnyEvent::Subprocess::Role::WithDelegates;
use MooseX::Role::Parameterized;
use MooseX::AttributeHelpers;

use MooseX::Types::Moose qw(HashRef ArrayRef Str);

use AnyEvent::Subprocess::Role::WithDelegates::Manager qw(build_delegate);

parameter type => (
    is       => 'ro',
    required => 1,
);

role {
    my $p = shift;

    has 'delegate_list' => (
        init_arg   => 'delegates',
        reader     => '_delegate_list',
        isa        => ArrayRef[$p->type | Str | ArrayRef | HashRef],
        default    => sub { +[] },
        auto_deref => 1,
        required   => 1,
    );

    has 'delegate_ordering' => (
        init_arg   => undef,
        reader     => '_delegates',
        isa        => ArrayRef[$p->type],
        auto_deref => 1,
        lazy       => 1,
        builder    => '_build_delegate_ordering',
    );

    has 'delegates_table' => (
        metaclass  => 'Collection::Hash',
        init_arg   => undef,
        isa        => HashRef[$p->type],
        auto_deref => 1,
        lazy       => 1,
        builder    => '_build_delegates_table',
        provides   => {
            get    => 'delegate',
            exists => '_delegate_exists',
        },
    );

    before 'delegate' => sub {
        my ($self, $delegate) = @_;
        confess "No delegate named '$delegate'" if !$self->_delegate_exists($delegate);
    };

    method '_build_delegate_ordering' => sub {
        my ($self) = @_;
        my @delegates_list = $self->_delegate_list;
        my @result;
        for my $d (@delegates_list){
            if( blessed $d ) {
                push @result, $d;
            }
            else {
                push @result, build_delegate($d);
            }
        }
        return \@result;
    };

    method '_build_delegates_table' => sub {
        my ($self) = @_;
        return {
            map { $_->name => $_ } $self->_delegates,
        };
    };

    method 'BUILD' => sub {
        my $self = shift;
        $self->_delegates;
    };

    method '_invoke_delegates' => sub {
        my ($self, $method, @args) = @_;

        return map {
            my $d = $_;
            $d->$method(@args);
        } $self->_delegates;
    };
};

1;
