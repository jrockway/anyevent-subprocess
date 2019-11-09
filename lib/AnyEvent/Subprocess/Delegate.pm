package AnyEvent::Subprocess::Delegate;

# ABSTRACT: role representing a delegate
use Moose::Role;

with 'MooseX::Clone';

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;

__END__

=head1 DESCRIPTION

All delegates consume this role; it provides C<name> and is a type
tag.

=head1 METHODS

=head2 clone

Returns a deep copy of the delegate.

=head1 REQUIRED ATTRIBUTES

=head2 name

The name of the delegate.  You can only have one delegate of each name
per class.

=head1 SEE ALSO

L<AnyEvent::Subprocess>

L<AnyEvent::Subprocess::Role::WithDelegates>
