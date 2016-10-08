#!/usr/bin/env perl

use strict;
use warnings;

use lib '../lib';

use Test::More;
use Carp;
use Data::Dump qw(dump);
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
    { default => { class('Umann::List::Util'), function('hrslice')}},
    {
        args(),
        dies_like('1st param must be HASH ref'),
    },
    {
        args(5),
        dies_like('1st param must be HASH ref'),
    },
    {
        args({}),
        returns({}),
    },
    {
        args({a => 5}),
        returns({}),
    },
    {
        args({a => 5}, 'x'),
        returns({}),
    },
    {
        args({a => 5}, 'x', 'y'),
        returns({}),
    },
    {
        args({a => 5}, ['x', 'y']),
        returns({}),
    },
    {
        args({a => 5, b => 2}),
        returns({}),
    },
    {
        args({a => 5, b => 2}, 'x'),
        returns({}),
    },
    {
        args({a => 5, b => 2}, 'x', 'y'),
        returns({}),
    },
    {
        args({a => 5, b => 2}, ['x', 'y']),
        returns({}),
    },
    {
        args({a => 5, x => 2}),
        returns({}),
    },
    {
        args({a => 5, x => 2}, 'x'),
        returns({x => 2}),
    },
    {
        args({a => 5, x => 2}, 'x', 'y'),
        returns({x => 2}),
    },
    {
        args({a => 5, x => 2}, ['x', 'y']),
        returns({x => 2}),
    },
);

run_test_cases(
    { default => { class('Umann::List::Util'), function('is_in')}},
    {
        args(),
        dies_like('No param'),
    },
    {
        args(5),
        returns_false()
    },
    {
        args(5,2,3),
        returns_false()
    },
    {
        args(5,[2,3]),
        returns_false()
    },
    {
        args(5),
        returns_false()
    },
    {
        args(5, []),
        returns_false()
    },
    {
        args(5,5,3),
        returns(1)
    },
    {
        args(5,[5,3]),
        returns(1)
    },
    {
        args(undef),
        returns_false()
    },
    {
        args(undef,2,3),
        returns_false()
    },
    {
        args(undef,[2,3]),
        returns_false()
    },
    {
        args(undef),
        returns_false()
    },
    {
        args(undef, []),
        returns_false()
    },
    {
        args(undef,undef,3),
        returns(1)
    },
    {
        args(undef,[undef,3]),
        returns(1)
    },
);

run_test_cases(
    { default => { class('Umann::List::Util'), function('to_array')}},
    {
        args(),
        returns_scalar(0),
        returns_array(),
    },
    {
        args([]),
        returns_scalar(0),
        returns_array()
    },
    {
        args(5),
        returns_scalar(1),
        returns_array(5)
    },
    {
        args([5]),
        returns_scalar(1),
        returns_array(5)
    },
    {
        args(5,3),
        returns_scalar(2),
        returns_array(5,3)
    },
    {
        args([5,3]),
        returns_scalar(2),
        returns_array(5,3)
    },
    {
        args(undef),
        returns_scalar(1),
        returns_array(undef)
    },
    {
        args([undef]),
        returns_scalar(1),
        returns_array(undef)
    },
    {
        args(undef,3),
        returns_scalar(2),
        returns_array(undef,3)
    },
    {
        args([undef,3]),
        returns_scalar(2),
        returns_array(undef,3)
    },
);

done_testing();
