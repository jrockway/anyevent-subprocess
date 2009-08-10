package AnyEvent::Subprocess;
use Moose;
with 'AnyEvent::Subprocess::Job', 'MooseX::Traits';

our $VERSION = 0.01;

use namespace::autoclean;

has '+_trait_namespace' => (
    default => 'AnyEvent::Subprocess::Job::Role',
);

1;
