use strict;
use warnings;
use Cache::LRU;
use Test::More;
use Test::NoLeaks;

sub might_leak {
    my $cache = Cache::LRU->new;
    $cache->set(hoge => 111);
    $cache->set(fuga => 222);
    $cache->set(foo  => 333);

    $cache->set(bar => 444);    # Oldest key "hoge" vanishes

    $cache->get('fuga');        # Oldest key "fuga" becomes the newest

    $cache->set(buz => 555);    # Old key "foo" vanishes
}

test_noleaks(
    code          => \&might_leak,
    track_memory  => 1,
    track_fds     => 1,
    passes        => 2,
    warmup_passes => 1,
    tolerate_hits => 0,
);

done_testing;
