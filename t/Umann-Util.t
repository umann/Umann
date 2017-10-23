#!/usr/bin/env perl

use 5.010;

use strict;
use warnings;

our $VERSION = '0.01';

use Readonly;

Readonly my $NUM0 => 0;
Readonly my $NUM1 => 1;
Readonly my $NUM2 => 2;
Readonly my $NUM3 => 3;
Readonly my $NUM4 => 4;
Readonly my $NUM5 => 5;

use Umann::Test qw(:all);

use Test::More;  # tests => 13;
BEGIN { use_ok(qw(Umann::Util)); }

run_test_cases(
    {
        default => { module('Umann::Util'), function('leaf'), },
    },
    { args([$NUM1], [$NUM0]), returns($NUM1), },
    { args([$NUM1], undef), returns(undef), },
    { args([$NUM1], [$NUM0]), returns($NUM1), },
    { args([$NUM1], undef), returns(undef), },
    { args($NUM1,   $NUM1), returns(undef), },
    { args(),      returns(undef), },
    { args($NUM1), returns($NUM1), },
    { args([$NUM3], $NUM1), returns(undef), },
    { args([$NUM3], $NUM0,  $NUM0), returns(undef), },
    { args([$NUM3], $NUM0), returns($NUM3), },
    { args({ a => $NUM2 }, 'a'), returns($NUM2), },
    { args({ a => $NUM2 }, 'b'), returns(undef), },
    { args({ a => [ $NUM2, $NUM3 ] }, 'a', $NUM1), returns($NUM3), },
);

run_test_cases(
    {
        default => { module('Umann::Util'), function('is_in') },
    },
    { args($NUM4, [$NUM3]), returns_false(), },
    { function('is_in'), args($NUM4, []), returns_false(), },
    {
        function('is_in'), args($NUM4, [ $NUM4, $NUM5, $NUM3 ]), returns_true(),
    },
    { function('is_in'), args($NUM4,   $NUM3), returns_false(), },
    { function('is_in'), args($NUM4,), returns_false(), },
    { function('is_in'), args($NUM4, $NUM4, $NUM5, $NUM3), returns_true(), },
);

done_testing();

__END__
