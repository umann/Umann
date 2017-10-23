package Umann::List::Util;

use 5.010000;

use strict;
use warnings;

our $VERSION = '0.01';

no lib q{.}
    ; # because in dir Umann/, List::Util would mean the same as Umann::List::Util

use Carp;
use Data::Dump qw(dump);
use Digest::MD5 qw(md5_hex);
use List::Util qw(any);
use URI::Query;

use Umann::Scalar::Util qw(
    is_ar
    is_hr
    undef_safe_eq
);

use Exporter qw(import);
our @EXPORT_OK = qw(
    do_on_struct
    hr_slice
    is_in
    md5_defined_val_hr
    to_array
);

sub hr_slice {
    my ($hr, @keys) = @_;

    if ('HASH' ne ref $hr) {
        croak '1st param must be HASH ref';
    }
    return {
        map { $_ => $hr->{$_} }
        grep { exists $hr->{$_} } to_array(@keys)
    };
}

sub is_in {
    my @args = @_;
    if (!@args) {
        croak 'No param';
    }
    my $candidate = shift @args;
    return any { undef_safe_eq($_, $candidate) } to_array(@args);
}

sub to_array {
    my @args = @_;
    return 1 == scalar(@args) && is_ar($args[0])
        ? @{ $args[0] }
        : @args;
}

sub do_on_struct {
    my ($sub, @structs) = @_;

    if (1 != scalar @structs) {
        return map { do_on_struct($sub, $_) } @structs;
    }
    my $struct = shift @structs;
    if (!ref $struct) {
        return &{$sub}($struct);
    }
    if (is_ar($struct)) {
        return [ map { do_on_struct($sub, $_) } @{$struct} ];
    }
    if (is_hr($struct)) {
        return +{
            map { $_ => do_on_struct($sub, $struct->{$_}) }
                keys %{$struct}
        };
    }
    return $struct;
}

# md5_defined_val_hr() returns md5 hex of simple hash ref, without keys that have undef value
sub md5_defined_val_hr {
    my $hr = shift;
    my $qq = URI::Query->new($hr);
    $qq->strip_null;
    $qq->separator(q{;});
    return md5_hex("$qq");  # stringified
}

1;

__END__
