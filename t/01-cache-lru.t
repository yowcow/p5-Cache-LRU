use strict;
use warnings;
use Cache::LRU;
use Test::Exception;
use Test::More;
use Test::Pretty;

subtest 'new()' => sub {

    subtest 'should create an instance' => sub {
        my $cache = Cache::LRU->new;

        isa_ok $cache, 'Cache::LRU';
        is $cache->max_size, 3;
    };

    subtest 'should initialize to given max_size' => sub {
        my $cache = Cache::LRU->new(max_size => 1);

        is $cache->max_size, 1;
        is $cache->current_size, 0;
    };
};

subtest 'set() and get()' => sub {
    my $cache = Cache::LRU->new;

    subtest 'stores given value' => sub {

        lives_ok { $cache->set(hoge => 111) };

        subtest 'gets stored value' => sub {
            is $cache->get('hoge'), 111;
            is $cache->current_size, 1;
        };
    };

    subtest 'overwrites with given value' => sub {

        lives_ok {
            $cache->set(hoge => 222);
        };

        subtest 'gets stored value' => sub {
            is $cache->get('hoge'), 222;
            is $cache->current_size, 1;
        };
    };
};

subtest 'Keys are stored up to 3' => sub {
    my $cache = Cache::LRU->new;

    $cache->set(hoge => 111);
    $cache->set(fuga => 222);
    $cache->set(foo  => 333);
    $cache->set(bar  => 444);

    subtest 'current_size is 3' => sub {
        is $cache->current_size, 3;
    };

    subtest 'keys "fuga", "foo", and "bar" exist' => sub {
        is $cache->get('fuga'), 222;
        is $cache->get('foo'),  333;
        is $cache->get('bar'),  444;
    };

    subtest 'key "hoge" is expired' => sub {
        is $cache->get('hoge'), undef;
    };
};

subtest 'Least recently used key expires' => sub {
    my $cache = Cache::LRU->new;

    $cache->set(hoge => 111);
    $cache->set(fuga => 222);
    $cache->set(foo  => 333);

    $cache->get('foo');     # Make "foo" recently used
    $cache->get('fuga');    # Make "fuga" recently used
    $cache->get('hoge');    # Make "hoge" recently used

    subtest 'When new key "bar" is set' => sub {

        lives_ok { $cache->set(bar => 444) };

        subtest 'current_size is 3' => sub {
            is $cache->current_size, 3;
        };

        subtest 'key "hoge" still exists' => sub {
            is $cache->get('hoge'), 111;
        };

        subtest 'key "foo" is expired' => sub {
            is $cache->get('foo'), undef;
        };
    };

    subtest 'When fuga is updated, and new key "buz" is set' => sub {

        lives_ok {
            $cache->set(fuga => 2222);
        };

        lives_ok {
            $cache->set(buz => 555);
        };

        subtest 'current_size is 3' => sub {
            is $cache->current_size, 3;
        };

        subtest 'key "bar" expires' => sub {
            is $cache->get('bar'), undef;
        };

        subtest 'key "fuga" is updated' => sub {
            is $cache->get('fuga'), 2222;
        };
    };
};

done_testing;
