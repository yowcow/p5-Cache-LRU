package Cache::LRU;

use warnings;
use utf8;
use strict;
use Data::Dumper;

sub new {
    my $hash_ref = {};
    my $class    = shift;

    $hash_ref->{max_size} = 3;

    return bless $hash_ref, $class;
}

sub max_size {
    my $self = shift;

    return $self->{max_size};
}

1;
