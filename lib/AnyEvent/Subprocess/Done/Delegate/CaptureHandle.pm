package AnyEvent::Subprocess::Done::Delegate::CaptureHandle;
use Moose;

with 'AnyEvent::Subprocess::Done::Delegate';

has 'output' => ( is => 'ro', isa => 'Str', required => 1 );

1;

__END__

=head1 NAME 
