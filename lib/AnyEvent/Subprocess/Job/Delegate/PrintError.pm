package AnyEvent::Subprocess::Job::Delegate::PrintError;

# ABSTRACT: Print errors to a filehandle
use Moose;
use namespace::autoclean;
with 'AnyEvent::Subprocess::Job::Delegate';

has 'handle' => (
    is      => 'ro',
    isa     => 'GlobRef',
    default => sub { \*STDERR },
);

has 'callback' => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub {
        my $self = shift;
        return sub {
            my $msg = join '', @_;
            $msg .= "\n" unless $msg =~ /\n$/;
            print {$self->handle} ($msg);
        }
    },
);

sub receive_child_error {
    my ($self, $job, $error) = @_;
    $self->callback->($error);
}

sub build_run_delegates {}
sub child_setup_hook {}
sub child_finalize_hook {}
sub parent_setup_hook {}
sub parent_finalize_hook {}
sub build_code_args {}
sub receive_child_result {}

__PACKAGE__->meta->make_immutable;

1;
