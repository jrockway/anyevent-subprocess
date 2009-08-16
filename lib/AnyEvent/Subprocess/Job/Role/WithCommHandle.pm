package AnyEvent::Subprocess::Job::Role::WithCommHandle;
use Moose::Role;

with
  'AnyEvent::Subprocess::Job::Role::WithHandle' => {
      name           => 'comm',
      direction      => 'rw',
  };

around '_build_code_args' => sub {
    my $next = shift;
    my $self = shift;

    return ($self->_comm_pipes->[1], $self->$next(@_));
};

1;
