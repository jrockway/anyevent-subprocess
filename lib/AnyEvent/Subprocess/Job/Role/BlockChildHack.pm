package AnyEvent::Subprocess::Job::Role::BlockChildHack;
use Moose::Role;

use AnyEvent::Util qw(portable_pipe);
use namespace::autoclean;

has 'pipe' => (
    is      => 'ro',
    isa     => 'ArrayRef[GlobRef]',
    default => sub { [ portable_pipe ] },
);

after '_parent_finalize_hook' => sub  {
    my $self = shift;
    close $self->pipe->[0];
    syswrite $self->pipe->[1], 'X';
    close $self->pipe->[1];
};

after '_child_setup_hook' => sub {
    my $self = shift;
    warn "waiting...";
    close $self->pipe->[1];
    sysread $self->pipe->[0], my $buf, 1; # block until parent is running
    warn "GOT ITEM!!!!!!";
    close $self->pipe->[0];
};

1;
