use strict;
use warnings;
use inc::Module::Install;

name 'AnyEvent-Subprocess';
all_from 'lib/AnyEvent/Subprocess.pm';

requires 'AnyEvent' => '5.2';
requires 'Event::Join', '0.02';
requires 'IO::Pty';
requires 'Moose', '0.91';
requires 'MooseX::Role::Parameterized';
requires 'MooseX::StrictConstructor';
requires 'POSIX';
requires 'namespace::autoclean';
requires 'Try::Tiny';

test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'ok';

auto_install;
WriteAll;
