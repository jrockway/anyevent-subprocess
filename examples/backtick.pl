#!/usr/bin/env perl

use strict;
use warnings;

use AnyEvent::Subprocess::Easy qw(qx_nonblock);

# my $result = `ls -l`;
my $result = qx_nonblock(qw/ls -l/)->recv; # your program can handle other
                                           # events while you are waiting

print "Output of ls:\n $result";
