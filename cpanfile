requires 'Test::Exception';
requires 'Test::More';
requires 'Test::Pretty';

on 'test' => sub {
    requires 'Test::NoLeaks';
};
