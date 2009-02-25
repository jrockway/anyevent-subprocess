use strict;
use warnings;
use inc::Module::Install;

name 'AnyEvent-Subprocess';
all_from 'lib/AnyEvent/Subprocess.pm';

requires 'Moose';
requires 'MooseX::AttributeHelpers';
requires 'namespace::clean';
requires 'AnyEvent';
requires 'List::Util';

test_requires 'Test::More';
test_requires 'ok';

auto_install;
WriteAll;

