package Umann::JSON::Validator::OfList;

use 5.010000;

use strict;
use warnings;

our $VERSION = '0.01';

use parent qw(Umann::JSON::Validator::SetDefaults);

use Carp qw(carp croak confess longmess);
use Data::Dump qw(dump);
use List::Util qw(sum0);
use Readonly;

use Umann::JSON::Validator::SetDefaults;
use Umann::Scalar::Util qw(is_ar undef_safe_eq);

Readonly my $INFINITE      => 1e9;
Readonly my $NONNEG_INT_RE => '(?:0|[1-9][0-9]*)';

sub validate_and_return_data {
    my ($self, $arg, $list_schema) = @_;
    return $self->validate_list_and_return_data($list_schema, $arg);
}

sub validate_list_and_return_data {
    my ($self, $list_schema, @args) = @_;
    my @schemata = $self->get_schemata($list_schema, @args);

SCHEMA: for my $i (0 .. $#schemata) {
        if ($#args < $i) {
            my $type = $schemata[$i]->{type} // q{};
            $args[$i] =
                exists $schemata[$i]->{default}
                ? val_or_retval($schemata[$i]->{default})
                : $type eq 'object' || $schemata[$i]->{properties} ? {}
                : $type eq 'array'  || $schemata[$i]->{items}      ? []
                :   do { carp "no default for args\[$i], using undef"; undef };
        }
        if (my @rv = Umann::JSON::Validator::SetDefaults->new->validate(
                $args[$i], $schemata[$i],
                { debug => $self->get_debug("args\[$i]") }
            )
            )
        {
            croak join q{ }, @rv;
        }
    }
    return wantarray ? @args : shift @args;
}

sub val_or_retval {
    my $x = shift;

    return ref $x eq 'CODE' ? &{$x} : $x;
}

sub get_schemata {
    my ($self, $list_schema, @args) = @_;

    my @quantifiers = $self->get_quantifiers($list_schema, @args);

    my $quantifier_types = join q{}, map { $_->{type} } @quantifiers;
    if ($quantifier_types !~ qr{\A(?:
        1*[*?]1*  # one * or ? in the beginning, middle or end
        |
        1*[?]*    # arbitrary number of ?'s at the end
        |
        [?]+1*    # arbitrary number of ?'s at the beginning
    )\z}smx
        )
    {
        croak 'invalid order of quantifiers ' . dump map { $_->{type} }
            @quantifiers;
    }

    my (@rv_start, @rv_mid, @rv_end);

    # take starting fixed-number quantifiers:
    while (@quantifiers && $quantifiers[0]{type} eq '1') {
        my $quantifier = shift @quantifiers;
        for (1 .. $quantifier->{from}) {
            shift @args;
            push @rv_start, $quantifier->{schema};
            my @rv = (@rv_start, @rv_mid, @rv_end);
        }
    }

    # take ending fixed-number quantifiers:
    while (@quantifiers && $quantifiers[-1]{type} eq '1') {
        my $quantifier = pop @quantifiers;
        for (1 .. $quantifier->{from}) {
            pop @args;
            unshift @rv_end, $quantifier->{schema};
            my @rv = (@rv_start, @rv_mid, @rv_end);
        }
    }

    # take ?'s:
    while (@quantifiers
        && $quantifiers[0]{type} eq q{?}
        && (@args || exists $quantifiers[0]{schema}{default}))
    {
        my $quantifier = shift @quantifiers;
        shift @args;
        push @rv_mid, $quantifier->{schema};
        my @rv = (@rv_start, @rv_mid, @rv_end);
    }

    # the rest - if any - is {\d+,$INFINITE}:
    if (@args) {
        my $quantifier = shift @quantifiers;
        while (@args) {
            pop @args;
            unshift @rv_mid, $quantifier->{schema};
            my @rv = (@rv_start, @rv_mid, @rv_end);
        }
    }

    my @rv = (@rv_start, @rv_mid, @rv_end);
    return @rv;
}

sub get_quantifiers {
    my ($self, $list_schema, @args) = @_;

    my @schemata0 =
        is_ar($list_schema) ? @{$list_schema} : ($list_schema);  # one or more

    my @rv;
    my $nargs     = scalar @args;
    my $min_nargs = 0;
    my $max_nargs = 0;
    for my $ix (0 .. $#schemata0) {
        my $quantifier = $schemata0[$ix]{quantifier} // '{1}';
        if ($quantifier eq q{?}) {
            $max_nargs++;
            push @rv, { type => $quantifier, schema => $schemata0[$ix] };
            next;
        }
        if ($quantifier eq q{*}) {
            $quantifier = '{0,}';
        }
        if ($quantifier eq q{+}) {
            $quantifier = '{1,}';
        }
        if ($quantifier =~
            /^[{]($NONNEG_INT_RE)(?:(,)?($NONNEG_INT_RE)?)[}]$/smx)
        {
            my ($from, $comma, $to) = ($1, $2, $3);
            $to //= $comma ? $INFINITE : $from;
            if ($from > $to) {
                croak
"first quantifier number must not be greater than second: $quantifier";
            }
            $min_nargs += $from;
            $max_nargs += $to;
            push @rv,
                {
                type => $from eq $to ? 1 : q{*},
                from => $from,
                schema => $schemata0[$ix]
                };
            next;
        }
        croak "invalid quantifier: $quantifier";
    }
    if ($min_nargs == $max_nargs && $min_nargs != $nargs) {
        croak "exactly $min_nargs args required, $nargs found " . dump \@args,
            \@rv;
    }
    if ($nargs < $min_nargs) {
        croak "at least $min_nargs args required, only $nargs found";
    }
    if ($nargs > $max_nargs) {
        croak "at most $min_nargs args required, $nargs found";
    }

    return @rv;
}

1;

__END__
