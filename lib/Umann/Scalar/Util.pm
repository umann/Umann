package Umann::Scalar::Util;

use 5.010000;

use strict;
use warnings;

our $VERSION = '0.01';

no lib q{.}
    ; # because in dir Umann/, Scalar::Util would mean the same as Umann::Scalar::Util

use Carp;
use Data::Dump qw(dump);

use Exporter qw(import);
our @EXPORT_OK = qw(
    bool
    is_ar
    is_cr
    is_hr
    is_re
    is_sr
    looks_like_class_name
    looks_like_sub_name
    undef_safe_eq
);

sub bool {
    my $arg = shift;
    return $arg ? 1 : ();
}

sub is_ar {
    my $x = shift;
    return bool(ref $x eq ref []);
}

sub is_cr {
    my $x = shift;
    return bool(ref $x eq ref sub { });
}

sub is_hr {
    my $x = shift;
    return bool(ref $x eq ref {});
}

sub is_sr {
    my $x = shift;
    return bool(ref $x eq ref \q{});
}

sub is_re {
    my $x = shift;
    return bool(ref $x eq ref qr//smx);
}

sub looks_like_class_name {
    my $x = shift // q{};

    state $token_re = qr/[[:upper:]][[:alpha:][:digit:]]*/smx;

    return bool($x =~ /\A(?:main|$token_re(?:::$token_re)*)\z/smx);
}

sub looks_like_sub_name {
    my $x = shift // q{};

    state $token1_re = qr/[[:lower:]][[:lower:][:digit:]]*/smx;
    state $token2_re = qr/[[:lower:][:digit:]]+/smx;

    return bool($x =~ /\A_{0,2}$token1_re(?:_$token2_re)*\z/smx);
}

sub undef_safe_eq {
    my @args = @_;
    if (scalar @args != 2) {
        croak 'undef_safe_eq requires exactly 2 args, not ' . dump @args;
    }
    my ($l, $r) = @args;
    return bool(
        defined $l && defined $r
        ? $l eq $r
        : !defined $l && !defined $r
    );
}

1;

__END__
