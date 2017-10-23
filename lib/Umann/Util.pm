package Umann::Util;

use 5.010000;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp;
use Data::Dump qw(dump);
use Cwd qw(realpath);
use English qw($OSNAME -no_match_vars);
use List::MoreUtils qw(any);
use Umann::List::Util qw(to_array);
use Umann::Scalar::Util qw(
    is_ar
    is_cr
    is_hr
    is_re
    is_sr
    undef_safe_eq
);

use Readonly;

Readonly my $CALLER_SUBROUTINE => 3;
Readonly my $MORE_THAN_ENOUGH  => 20;
Readonly my $UNDEF             => undef;

use Exporter qw(import);
our @EXPORT_OK = qw(
    deep_copy
    flat_dump
    leaf
    report_ref
    sub_name
    is_in
    is_valid
    act_on
    hr_minus
    hr_grep
    put_first
    canonpath
);

sub leaf {
    my @args = @_;

    my $struct = shift @args;
    if (@args = to_array(@args)) {
        my $key = shift(@args) // return $UNDEF;
        return is_hr($struct)
            ? leaf($struct->{$key}, @args)
            : is_ar($struct) ?
## no critic(RequireCheckingReturnValueOfEval)
            leaf(eval { $struct->[$key] }, @args)
## use critic
            # eval cos $x[-4] would die on @x=(1, 2);
            : undef;
    }
    return $struct;
}

sub deep_copy {
    my @these = @_;
    if (1 != scalar @these) {
        return (map { deep_copy($_) } @these);
    }
    my $this = shift @these;

    return
          is_ar($this) ? [ map { deep_copy($_) } @{$this} ]
        : is_hr($this) ? +{ map { $_ => deep_copy($this->{$_}) } keys %{$this} }
        : is_cr($this) ? sub { &{$this} }
        : is_sr($this) ? do { my $x = ${$this}; \$x }
        : is_re($this) ? qr/$this/smx
        :                $this;
}

sub sub_name {
    my $level = shift // 0;

    for (1 .. $MORE_THAN_ENOUGH) {
        (my $rv = (caller(1 + $level))[$CALLER_SUBROUTINE]) =~ s/.*:://smx;
        if ($rv ne '(eval)') {
            return $rv;
        }
        $level++;
    }
    return;
}

sub is_valid {
    my $value     = shift;
    my $validator = shift;

    return _is_valid($value, $validator);
}

# less strict then is_valid: for HASH ref, key has to exist but need not be true
sub is_in {
    my @args = @_;

    my $value = shift @args;
    my $validator = ref $args[0] ? shift @args : \@args;

    return +(any { undef_safe_eq($value, $_) } @{$validator});  # ? 1 : (); #();
}

sub _is_valid {
    my $value     = shift;
    my $validator = shift;

    my $dispatcher_hr = {
        q{} => sub { undef_safe_eq($value, $validator) },
        Regexp => sub { defined $value && !!($value =~ /$validator/smx) },
## no critic(RequireCheckingReturnValueOfEval)
        HASH => sub {
            eval { $validator->{$value} };
        },  # eval for ->{undef}
## use critic
        ARRAY => sub {
            any { undef_safe_eq($value, $_) } @{$validator};
        },
        CODE => sub { !!&{$validator}($value) },
    };  # end of hr
    return &{
        $dispatcher_hr->{ ref $validator }
            || sub { }
    }($validator) ? 1 : ();
}

sub act_on {
    my $actor = pop;    # NOTE: not shift - mandatory last / 2nd arg
    my $value = shift;  # optional 1st arg

    my $dispatcher_hr = {
        q{}    => sub { $actor },
        Regexp => sub { defined $value ? $value =~ /$actor/smx : () }
        ,               # note it returns grouping result if wantarray
## no critic(RequireCheckingReturnValueOfEval)
        HASH => sub {
            eval { $actor->{$value} };
        },
## use critic
        CODE => sub { &{$actor}($value) },
    };
    return &{
        $dispatcher_hr->{ ref $actor }
            || sub { }
    }($actor);
}

sub hr_minus {
    my ($hr, @minus) = @_;

    return +{ map { $_ => $hr->{$_} } grep { !($_ ~~ \@minus) } keys %{$hr} };
}

sub hr_grep {
    my ($hr, @only) = @_;

    return +{ map { $_ => $hr->{$_} } grep { $_ ~~ \@only } keys %{$hr} };
}

sub put_first {
    my ($firsts_ar, @args) = @_;

    if ('HASH' eq ref $firsts_ar) {
        $firsts_ar = [ keys %{$firsts_ar} ];
    }

    return +(grep { $_ ~~ @args } @{$firsts_ar}),
        grep { !($_ ~~ @{$firsts_ar}) } @args;
}

sub canonpath {
    my $file  = shift;
    my $lcwin = shift;  # optional

    my $slashend = $file =~ s {[\\/]+$}{}smx ? q{/} : q{};
    my $rv = (realpath $file) . $slashend;
    if ($OSNAME =~ /win/smxi) {
        $rv =~ y{\\}{/};
        if ($lcwin) {
            $rv = lc $rv;
            $rv =~ s{^([[:alpha:]])(:/.+)}{\u$1$2}smx
                ;       # drive letter is upper case anyway
        }
    }
    return $rv;
}

sub flat_dump {
    my @args = @_;

    my $rv = dump @args;

    $rv =~ s/^\h*\#[^\n]*//smxg;
    $rv =~ s/\h*\r?\n\h*/ /smxg;
    $rv =~ s/\h+=>\h+/ => /smxg;
    $rv =~ s/,\h+/, /smxg;

    return $rv;
}

sub report_ref {
    my @args = @_;

    return join q{ }, map {
             !ref $_             ? $_
            : ref $_ eq 'SCALAR' ? flat_dump(${$_})
            : flat_dump($_)
    } @args;
}

1;

__END__
