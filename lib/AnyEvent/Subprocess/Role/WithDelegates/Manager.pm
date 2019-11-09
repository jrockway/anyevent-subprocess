package AnyEvent::Subprocess::Role::WithDelegates::Manager;

# ABSTRACT: manage delegate shortcuts
use strict;
use warnings;

use Carp qw(cluck confess);

use Sub::Exporter -setup => {
    exports => ['register_delegate', 'build_delegate'],
};

my %builder_map;

sub register_delegate {
    my ($name, $builder) = @_;
    cluck "Overwriting existing delegate '$name' with '$builder'"
      if exists $builder_map{$name};

    $builder_map{$name} = $builder;
    return;
}

sub lookup_delegate {
    my ($name) = @_;
    confess "No delegate named '$name' registered"
      unless exists $builder_map{$name};

    return $builder_map{$name};
}

sub build_delegate {
    my ($spec) = @_;

    my $builder;
    my @args;

    if(ref $spec){
        my ($k, $v);
        # perl sucks
        eval { ($k, $v) = %$spec } ||
        eval { ($k, $v) = @$spec } ||
        confess 'Invalid data!';

        $builder = lookup_delegate($k);
        @args = $v;
    }
    else {
        $builder = lookup_delegate($spec);
    }

    if( ref $builder && ref $builder eq 'CODE' ) {
        return $builder->(@args);
    }
    return $builder->new(@args);
}

1;

__END__

=head1 DESCRIPTION

Creating an instance of a delegate to pass to
C<AnyEvent::Subprocess>'s constructor is tedious.  This module maps
sugary names to builders of delegate objects, so that the user can say
C<'Foo'> instead of C<< AnyEvent::Subprocess::Job::Delegate::Foo->new >>.

If you are writing a delegate for C<AnyEvent::Subprocess>, simply call
C<register_delegate> in your module.  When the users C<use>s your
module, the sugary name will become available.  And yeah, it's global,
so be careful.

=head1 EXPORTS

None by default, but you can request C<register_delegate> and
C<build_delegate>.

=head1 FUNCTIONS

=head2 register_delegate( $name, &$builder )

Register C<$builder> to build delegates named C<$name>.  C<$builder>
is a coderef that is eventually called with the key/value pairs
supplied by the user.  (The docs say this has to be a hashref, but it
can actually be any scalar value.  Checking is up to you.)  The
builder must return an instance of a class that does
L<AnyEvent::Subprocess::Delegate|AnyEvent::Subprocess::Delegate>,
although this condition is not checked by this module.  (You will get
a type error when you are building the class that uses the delegate.)

In the common case where the args should be passed directly to some
class' constructor, you can just supply the class name as the
C<$builder>.  C<new> will be called with any args the user supplies.

You get a noisy warning if you reuse a C<$name>.  This is almost
always an error, though; only the most recent name/builder pair is
remembered.

=head2 build_delegate( $spec )

Given a C<$spec>, return an instance of the correct delegate.  Dies if
we don't know how to build a delegate according to C<$spec>.

C<$spec> can be a string naming the delegate to be built, or it can be
a hashref or arrayref of name/args pair.  Name is the same name passed
to C<register_delegate>, and the args should be a hashref.

=head1 SEE ALSO

L<AnyEvent::Subprocess>

L<AnyEvent::Subprocess::Delegate>

L<AnyEvent::Subprocess::Role::WithDelegates>
