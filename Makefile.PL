use strict;
use warnings;
use inc::Module::Install;

name 'AnyEvent-Subprocess';
all_from 'lib/AnyEvent/Subprocess.pm';

requires 'AnyEvent';
requires 'AnyEventX::Cancel';
requires 'Event::Join', '0.02';
requires 'IO::Pty';
requires 'Moose';
requires 'namespace::autoclean';
requires 'MooseX::Traits', '0.07';

test_requires 'Test::More';
test_requires 'ok';

auto_install;
WriteAll;
