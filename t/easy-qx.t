use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;

use AnyEvent::Subprocess::Easy qw(qx_nonblock);

{
    my $cv = qx_nonblock('date');
    my $result = $cv->recv;
    diag $result;
    ok length $result > 5, 'got some result back';
}

{
    # if you have a command with this name on your machine...
    my $cv = qx_nonblock('argle bargle', 'gobbeldy gook');

    throws_ok {
        my $result = $cv->recv;
    } qr/: 255/, 'non-existent command errored';

}
