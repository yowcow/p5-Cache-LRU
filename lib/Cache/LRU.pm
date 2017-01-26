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

sub set {
    my ($self, $key, $value) = @_;
    my $node;

    if ($node = $self->{keys}{$key}) {
        $node->{value} = $value;

        if (my $next = $node->{_next}) {    # Not the last node
            if (my $prev = $node->{_prev}) {
                $next->{_prev} = $prev;
                $prev->{_next} = $next;
            }
            else {
                $next->{_prev} = undef;
                $self->{nodes}{_first} = $next;
            }

            my $last = $self->{nodes}{_last};
            $last->{_next}        = $node;
            $node->{_prev}        = $last;
            $node->{_next}        = undef;
            $self->{nodes}{_last} = $node;
        }
    }
    else {    # The last node
        if ($self->{size} >= $self->max_size) {
            $self->remove($self->{nodes}{_first}{key});
        }

        $node = {
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

sub remove {
    my ($self, $key) = @_;
    my $node = $self->{keys}{$key} or return;
    my ($prev, $next);

    if (($next = $node->{_next}) && ($prev = $node->{_prev})) {    # In the middle
        $next->{_prev} = $prev;
        $prev->{_next} = $next;
    }
    elsif ($next = $node->{_next}) {                               # First
        $self->{nodes}{_first} = $next;
        $next->{_prev} = undef;
    }
    elsif ($prev = $node->{_prev}) {                               # Last
        $self->{nodes}{_last} = $prev;
        $prev->{_next} = undef;
    }
    else {                                                         # The only one
        $self->{nodes}{_first} = undef;
        $self->{nodes}{_last}  = undef;
    }

    delete $self->{keys}{$key};
    $self->{size}--;

    $self->render_state if $VERBOSE;
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
