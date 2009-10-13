use strict;
use warnings;
use inc::Module::Install;

name 'AnyEvent-Subprocess';
all_from 'lib/AnyEvent/Subprocess.pm';

requires 'AnyEvent';
requires 'Event::Join', '0.02';
requires 'IO::Pty';
requires 'Moose';
requires 'MooseX::AttributeHelpers';
requires 'MooseX::Role::Parameterized';
requires 'POSIX';
requires 'namespace::autoclean';

test_requires 'Test::More';
test_requires 'ok';

auto_install;
WriteAll;
