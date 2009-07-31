use strict;
use warnings;
use inc::Module::Install;

name 'AnyEvent-Subprocess';
all_from 'lib/AnyEvent/Subprocess.pm';

requires 'AnyEvent';
requires 'AnyEventX::Cancel';
requires 'Event::Join';
requires 'Moose';
requires 'namespace::clean';

test_requires 'Test::More';
test_requires 'ok';

auto_install;
WriteAll;

