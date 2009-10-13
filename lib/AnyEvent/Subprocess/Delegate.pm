package AnyEvent::Subprocess::Delegate;
use Moose::Role;

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;

__END__

=head1 NAME

AnyEvent::Subprocess::Delegate - role representing a delegate

=head1 DESCRIPTION

All delegates consume this role; it provides C<name> and is a type
tag.

=head1 REQUIRED ATTRIBUTES

=head2 name

The name of the delegate.  You can only have one delegate of each name
per class.

=head1 SEE ALSO

L<AnyEvent::Subprocess>

L<AnyEvent::Subprocess::Role::WithDelegates>
