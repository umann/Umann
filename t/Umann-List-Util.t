#!/usr/bin/env perl

use 5.010;

use strict;
use warnings;

our $VERSION = '0.01';

use lib '../lib';

use Test::More;
use Carp;
use Data::Dump qw(dump);
use Readonly;

Readonly my $NUM1 => 42;
Readonly my $NUM2 => 2;
Readonly my $NUM3 => 3;

use Umann::Test qw(
    args
    class
    dies_like
    function
    method
    object
    returns
    returns_anything
    returns_array
    returns_false
    returns_scalar
    run_test_cases
    title
    warns_like
);

BEGIN { use_ok('Umann::List::Util') }

run_test_cases(
    { default => { class('Umann::List::Util'), function('hr_slice') } },
    { args(),      dies_like('1st param must be HASH ref'), },
    { args($NUM1), dies_like('1st param must be HASH ref'), },
    { args({}),    returns({}), },
    { args({ a => $NUM1 }), returns({}), },
    { args({ a => $NUM1 }, 'x'), returns({}), },
    { args({ a => $NUM1 }, 'x', 'y'), returns({}), },
    { args({ a => $NUM1 }, [ 'x', 'y' ]), returns({}), },
    { args({ a => $NUM1, b => $NUM2 }), returns({}), },
    { args({ a => $NUM1, b => $NUM2 }, 'x'), returns({}), },
    { args({ a => $NUM1, b => $NUM2 }, 'x', 'y'), returns({}), },
    { args({ a => $NUM1, b => $NUM2 }, [ 'x', 'y' ]), returns({}), },
    { args({ a => $NUM1, x => $NUM2 }), returns({}), },
    { args({ a => $NUM1, x => $NUM2 }, 'x'), returns({ x => $NUM2 }), },
    { args({ a => $NUM1, x => $NUM2 }, 'x', 'y'), returns({ x => $NUM2 }), },
    {
        args({ a => $NUM1, x => $NUM2 }, [ 'x', 'y' ]), returns({ x => $NUM2 }),
    },
);

run_test_cases(
    { default => { class('Umann::List::Util'), function('is_in') } },
    { args(),      dies_like('No param'), },
    { args($NUM1), returns_false() },
    { args($NUM1, $NUM2, $NUM3), returns_false() },
    { args($NUM1, [ $NUM2, $NUM3 ]), returns_false() },
    { args($NUM1), returns_false() },
    { args($NUM1, []), returns_false() },
    { args($NUM1, $NUM1, $NUM3), returns(1) },
    { args($NUM1, [ $NUM1, $NUM3 ]), returns(1) },
    { args(undef), returns_false() },
    { args(undef, $NUM2, $NUM3), returns_false() },
    { args(undef, [ $NUM2, $NUM3 ]), returns_false() },
    { args(undef), returns_false() },
    { args(undef, []), returns_false() },
    { args(undef, undef, $NUM3), returns(1) },
    { args(undef, [ undef, $NUM3 ]), returns(1) },
);

run_test_cases(
    { default => { class('Umann::List::Util'), function('to_array') } },
    { args(),        returns_scalar(0), returns_array(), },
    { args([]),      returns_scalar(0), returns_array() },
    { args($NUM1),   returns_scalar(1), returns_array($NUM1) },
    { args([$NUM1]), returns_scalar(1), returns_array($NUM1) },
    { args($NUM1, $NUM3), returns_scalar($NUM2), returns_array($NUM1, $NUM3) },
    {
        args([ $NUM1, $NUM3 ]),
        returns_scalar($NUM2),
        returns_array($NUM1, $NUM3)
    },
    { args(undef),   returns_scalar(1), returns_array(undef) },
    { args([undef]), returns_scalar(1), returns_array(undef) },
    { args(undef, $NUM3), returns_scalar($NUM2), returns_array(undef, $NUM3) },
    {
        args([ undef, $NUM3 ]),
        returns_scalar($NUM2),
        returns_array(undef, $NUM3)
    },
);

done_testing();

__END__
