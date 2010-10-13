use strict;
use warnings;
use Test::More;

use AnyEvent;

BEGIN { diag("Using ". AnyEvent::detect()) };

BEGIN { use_ok 'AnyEvent::Subprocess' };

done_testing;
