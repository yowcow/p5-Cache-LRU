package Cache::LRU;

use warnings;
use utf8;
use strict;
use Data::Dumper;

sub new {
    my $hash_ref = {};
    my $class    = shift;
    my %constract = @_;

    if (exists $constract{max_size}) {
        $hash_ref->{max_size} = $constract{max_size};
    }
    else {
        $hash_ref->{max_size} = 3;
    }
        return bless $hash_ref, $class;
}

sub max_size {
    my $self = shift;

    return $self->{max_size};
}

sub current_size {
    my $self = shift;

    return 0;
}

1;
