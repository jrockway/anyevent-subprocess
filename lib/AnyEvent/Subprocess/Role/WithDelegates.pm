package AnyEvent::Subprocess::Role::WithDelegates;

# ABSTRACT: paramaterized role consumed by classes that have delegates
use MooseX::Role::Parameterized;

use MooseX::Types::Moose qw(HashRef ArrayRef Str);

use AnyEvent::Subprocess::Role::WithDelegates::Manager qw(build_delegate);

parameter type => (
    is       => 'ro',
    required => 1,
);

role {
    with 'MooseX::Clone';

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
        traits     => ['NoClone'],
        init_arg   => undef,
        reader     => '_delegates',
        isa        => ArrayRef[$p->type],
        auto_deref => 1,
        lazy       => 1,
        builder    => '_build_delegate_ordering',
    );

    has 'delegates_table' => (
        traits     => ['Hash', 'NoClone'],
        init_arg   => undef,
        isa        => HashRef[$p->type],
        auto_deref => 1,
        lazy       => 1,
        builder    => '_build_delegates_table',
        handles    => {
            delegate           => 'get',
            '_delegate_exists' => 'exists',
        },
    );

    around clone => sub {
        my ($orig, $self, @args) = @_;

        my @cloned_delegates = map {
            blessed $_ && $_->can('clone') ? $_->clone : $_
        } $self->_delegate_list;

        return $self->$orig(
            delegate_list => \@cloned_delegates,
            @args,
        );
    };

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

    after 'clone' => sub {
        my $self = shift;
        $self->_delegates; # vivify noclones after cloning
    };

    method 'BUILD' => sub {
        my $self = shift;
        $self->_delegates;
    };

    method '_invoke_delegates' => sub {
        my ($self, $method, @args) = @_;

        return map {
            my $d = $_;
            $d->$method($self, @args);
        } $self->_delegates;
    };
};

1;

__END__

=head1 DESCRIPTION

This role gives its consuming class the ability to have typed
delegates.  The type of the delegate is provide at application time
via the C<type> parameter.

Once applied, you get:

=head1 INITARGS

=head2 delegates

A list (arrayref) of delegates.  A delegate can be an instance of a
C<AnyEvent::Subprocess::Delegate> class, a string (which will be
resolved via
L<AnyEvent::Subprocess::Role::WithDelegates::Manager|AnyEvent::Subprocess::Role::WithDelegates::Manager>,
or a two-element hashref or arrayref of the delegate name and a
hashref of delegate args. C<< [ Name => { args } ] >> or C<< { Name =>
{ args } } >>.  C<Name> is treated like a string above, and the args
are handled by the delegate's constructor or by the method supplied at
delegate registration time.  See
L<AnyEvent::Subprocess::Role::WithDelegates::Manager> for details.

=head1 METHODS

=head2 delegate($name)

Return the delegate named C<$name>.  Dies if there is no delegate by
that name.

(This method is called by users of C<AnyEvent::Subprocess>.)

=head2 _invoke_delegates($method, @args)

Invokes C<< $delegate->$method($self, @args) >> on each delegate (in the
order they were passed to the constructor).  Returns a list of the
return values of each delegate.

(This method is usually called internally by C<AnyEvent::Subprocess>,
not by end-users.)

=head1 SEE ALSO

L<AnyEvent::Subprocess>

Delegate users:

L<AnyEvent::Subprocess::Job>

L<AnyEvent::Subprocess::Running>

L<AnyEvent::Subprocess::Done>
