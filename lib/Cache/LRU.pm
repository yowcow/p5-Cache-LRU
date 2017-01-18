package Cache::LRU;
use strict;
use warnings;
use feature 'say';

our $VERBOSE = 0;

sub new {
    my ($class, %args) = @_;
    bless {
        max_size => $args{max_size} || 3,
        nodes => {
            _first => undef,
            _last  => undef,
        },
        keys => {},
        size => 0,
    }, $class;
}

sub max_size {
    shift->{max_size};
}

sub current_size {
    shift->{size};
}

sub _remove_lru {
    my $self = shift;
    if (my $first = $self->{nodes}{_first}) {
        if (!defined $first->{_prev} && !defined $first->{_next}) {    # The only node exists
            $self->{nodes}{_first} = $self->{nodes}{_last} = undef;
        }
        else {                                                         # Multiple nodes exist
            my $next = $first->{_next};
            $next->{_prev} = undef;
            $self->{nodes}{_first} = $next;
        }

        delete $self->{keys}{ $first->{key} };
    }
}

sub set {
    my ($self, $key, $value) = @_;

    if (my $current = $self->{keys}{$key}) {
        $current->{value} = $value;

        if (my $next = $current->{_next}) {    # Not the last node
            if (my $prev = $current->{_prev}) {
                $next->{_prev} = $prev;
                $prev->{_next} = $next;
            }
            else {
                $next->{_prev} = undef;
                $self->{nodes}{_first} = $next;
            }

            my $last = $self->{nodes}{_last};
            $last->{_next}        = $current;
            $current->{_prev}     = $last;
            $current->{_next}     = undef;
            $self->{nodes}{_last} = $current;
        }
    }
    else {    # The last node
        if ($self->{size} >= $self->max_size) {
            $self->_remove_lru;
            $self->{size}--;
        }

        my $node = {
            key   => $key,
            value => $value,
            _prev => undef,
            _next => undef,
        };

        HANDLE_FIRST_NODE: {
            if (!defined $self->{nodes}{_first}) {
                $self->{nodes}{_first} = $node;
            }
        }

        HANDLE_LAST_NODE: {
            if (my $last = $self->{nodes}{_last}) {
                $last->{_next}        = $node;
                $node->{_prev}        = $last;
                $self->{nodes}{_last} = $node;
            }

            $self->{nodes}{_last} = $node;
        }

        $self->{keys}{$key} = $node;
        $self->{size}++;
    }

    $self->render_state if $VERBOSE;
}

sub get {
    my ($self, $key) = @_;
    my $node = $self->{keys}{$key} or return;

    if (my $next = $node->{_next}) {    # Not the last node
        if (my $prev = $node->{_prev}) {    # Not the first node
            $next->{_prev} = $prev;
            $prev->{_next} = $next;
            $node->{_next} = undef;

            my $last = $self->{nodes}{_last};
            $last->{_next} = $node;
            $node->{_prev} = $last;
        }
        else {                              # The first node
            $next->{_prev}         = undef;
            $node->{_next}         = undef;
            $self->{nodes}{_first} = $next;

            my $last = $self->{nodes}{_last};
            $last->{_next} = $node;
            $node->{_prev} = $last;
        }

        $self->{nodes}{_last} = $node;
    }

    $self->render_state if $VERBOSE;

    $node->{value};
}

sub render_state {
    my $self = shift;

    say "*****************************";
    say "=> Cache size: " . $self->current_size;
    say "=> Cache keys: " . join(',', keys %{ $self->{keys} });

    NODES_ASC: {
        my @nodes;
        my $node = $self->{nodes}{_first};

        while ($node) {
            push @nodes, join(':', $node->{key}, $node->{value});
            $node = $node->{_next};
        }

        say "=> Cache nodes (ASC):  " . join(' -> ', @nodes);
    }

    NODES_DESC: {
        my @nodes;
        my $node = $self->{nodes}{_last};

        while ($node) {
            push @nodes, join(':', $node->{key}, $node->{value});
            $node = $node->{_prev};
        }

        say "=> Cache nodes (DESC): " . join(' <- ', @nodes);
    }

    say "*****************************";
}

1;
