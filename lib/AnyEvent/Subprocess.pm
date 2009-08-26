package AnyEvent::Subprocess;
use Moose;
with 'AnyEvent::Subprocess::Job';

our $VERSION = 0.01;

use AnyEvent::Subprocess::DefaultDelegates;

use namespace::autoclean;

1;
