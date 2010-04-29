use strict;
use warnings;
use Test::More;
use Test::Exception;
use AnyEvent::Subprocess::Easy qw(qx_nonblock);

my $date = qx_nonblock('date')->recv;
ok $date, 'got a date';

my $bt_date = `date`;
ok $bt_date, 'backticks still work';

my $date_again = qx_nonblock('date')->recv;
ok $date_again, q"and backticks don't kill the whole event loop";

lives_ok {
    system('date') and die 'non-zero exit';
} 'system lives';

my $date_final = qx_nonblock('date')->recv;
ok $date_final, 'system is also ok';

done_testing;
