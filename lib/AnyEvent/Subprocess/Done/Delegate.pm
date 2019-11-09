package AnyEvent::Subprocess::Done::Delegate;

# ABSTRACT: role that delegates on the Done class must implement
use Moose::Role;

with 'AnyEvent::Subprocess::Delegate';

1;

__END__
