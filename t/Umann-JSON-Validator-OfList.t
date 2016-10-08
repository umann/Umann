#!/usr/bin/env perl

use strict;
use warnings;

use feature qw(say state);

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
    returns_scalar
    run_test_cases
    title
    warns_like
);

BEGIN { use_ok('Umann::JSON::Validator::OfList') }
my $ujvol = Umann::JSON::Validator::OfList->new // die;

run_test_cases(
    { default => { object($ujvol), method('validate_list_and_return_data')}}, 
    {
        args({type => 'object', properties => { b => {default => 44}}}, {a => 1}),
        returns_scalar({a => 1, b => 44}),
    },
    {
        args({type => 'array'}, {a => 1}),
        dies_like('Expected array - got object'),
    },  
    {
        args({type => 'object'}, {a => 1}),
        returns({a => 1}),
    },
    {
        args({type => 'object', properties => { b => {enum => [1,2]}}}, {a => 1}),
        returns({a => 1}),
    },
    {
        args({type => 'object', properties => { b => {enum => [1,2], default => 44}}}, {a => 1}),
        dies_like(qr/Not in enum list/),
    },
    #no insane here {
    #no insane here     args({type => 'object', properties => { b => {enum => [1,2], default => 44}}}, {insane => 1}, {a => 1}),
    #no insane here     returns({a => 1, b => 44}),
    #no insane here },
    {
        args({type => 'array'}, [1,2]),
        returns([1,2]),
    },
    {
        args({type => 'array', items => { enum => [1,2]}}, []),
        returns([]),
    },
    {
        args({type => 'array', items => { type => 'number'}}, [1,2]),
        returns([1,2]),
    },    
    {
        args({type => 'array', items => { enum => [1,2]}}, [1,2]),
        returns([1,2]),
    },
    {
        args({type => 'array', items => {type => 'object', properties => { b => {default => 44}}}}, [{a => 1}, {a => 2, b => 33}]),
        returns([{a => 1, b => 44}, {a => 2, b => 33}]),
    },
);

run_test_cases(
    { default => { object($ujvol), method('validate_and_return_data')}}, 
    {
        args({a => 1}, {type => 'object', properties => { b => {default => 44}}}),
        returns_scalar({a => 1, b => 44}),
    },
    {
        args({a => 1}, {type => 'array'}),
        dies_like('Expected array - got object'),
    },  
    {
        args({a => 1}, {type => 'object'}),
        returns({a => 1}),
    },
    {
        args({a => 1}, {type => 'object', properties => { b => {enum => [1,2]}}}),
        returns({a => 1}),
    },
    {
        args({a => 1}, {type => 'object', properties => { b => {enum => [1,2], default => 44}}}),
        dies_like(qr/Not in enum list/),
    },
    #no insane here {
    #no insane here     args({a => 1}, {type => 'object', properties => { b => {enum => [1,2], default => 44}}}, {insane => 1}),
    #no insane here     returns({a => 1, b => 44}),
    #no insane here },
    {
        args([1,2], {type => 'array'}),
        returns([1,2]),
    },
    {
        args([], {type => 'array', items => { enum => [1,2]}}),
        returns([]),
    },
    {
        args([1,2], {type => 'array', items => { type => 'number'}}),
        returns([1,2]),
    },    
    {
        args([1,2], {type => 'array', items => { enum => [1,2]}}),
        returns([1,2]),
    },
    {
        args([{a => 1}, {a => 2, b => 33}], {type => 'array', items => {type => 'object', properties => { b => {default => 44}}}}),
        returns([{a => 1, b => 44}, {a => 2, b => 33}]),
    },
);

run_test_cases(
    { default => { object($ujvol), method('validate_list_and_return_data')}}, 
    {
        args([{type => 'object', properties => { b => {default => 44}}}], {a => 1}),
        returns_scalar({a => 1, b => 44}),
    },
    {
        args([{type => 'array'}], {a => 1}),
        dies_like('Expected array - got object'),
    },  
    {
        args([{type => 'object'}], {a => 1}),
        returns({a => 1}),
    },
    {
        args([{type => 'object', properties => { b => {enum => [1,2]}}}], {a => 1}),
        returns({a => 1}),
    },
    {
        args([{type => 'object', properties => { b => {enum => [1,2], default => 44}}}], {a => 1}),
        dies_like(qr/Not in enum list/),
    },
    #no insane here {
    #no insane here     args([{type => 'object', properties => { b => {enum => [1,2], default => 44}}}, {insane => 1}], {a => 1}),
    #no insane here     returns({a => 1, b => 44}),
    #no insane here },
    {
        args([{type => 'array'}], [1,2]),
        returns([1,2]),
    },
    {
        args([{type => 'array', items => { enum => [1,2]}}], []),
        returns([]),
    },
    {
        args([{type => 'array', items => { type => 'number'}}], [1,2]),
        returns([1,2]),
    },    
    {
        args([{type => 'array', items => { enum => [1,2]}}], [1,2]),
        returns([1,2]),
    },
    {
        args([{type => 'array', items => {type => 'object', properties => { b => {default => 44}}}}], [{a => 1}, {a => 2, b => 33}]),
        returns([{a => 1, b => 44}, {a => 2, b => 33}]),
    },
);

run_test_cases(
    { default => { object($ujvol), method('validate_list_and_return_data')}}, 
    {
        args([{type => 'object', properties => { b => {default => 44}}}, {type => 'object', properties => { b => {default => 44}}}], {a => 1}, {a => 1}),
        returns({a => 1, b => 44}, {a => 1, b => 44}),
    },
    {
        args([{type => 'array'}, {type => 'array'}], {a => 1}, {a => 1}),
        dies_like('Expected array - got object'),
    },  
    {
        args([{type => 'object'}, {type => 'object'}], {a => 1}, {a => 1}),
        returns({a => 1}, {a => 1}),
    },
    {
        args([{type => 'object', properties => { b => {enum => [1,2]}}}, {type => 'object', properties => { b => {enum => [1,2]}}}], {a => 1}, {a => 1}),
        returns({a => 1}, {a => 1}),
    },
    {
        args([{type => 'object', properties => { b => {enum => [1,2], default => 44}}}, {type => 'object', properties => { b => {enum => [1,2], default => 44}}}], {a => 1}, {a => 1}),
        dies_like(qr/Not in enum list/),
    },
    #no insane here {
    #no insane here     args([{type => 'object', properties => { b => {enum => [1,2], default => 44}}}, {insane => 1}, {type => 'object', properties => { b => {enum => [1,2], default => 44}}}, {insane => 1}], {a => 1}, {a => 1}),
    #no insane here     returns({a => 1, b => 44}, {a => 1, b => 44}),
    #no insane here },
    {
        args([{type => 'array'}, {type => 'array'}], [1,2], [1,2]),
        returns([1,2], [1,2]),
    },
    {
        args([{type => 'array', items => { enum => [1,2]}}, {type => 'array', items => { enum => [1,2]}}], [], []),
        returns([], []),
    },
    {
        args([{type => 'array', items => { type => 'number'}}, {type => 'array', items => { type => 'number'}}], [1,2], [1,2]),
        returns([1,2], [1,2]),
    },    
    {
        args([{type => 'array', items => { enum => [1,2]}}, {type => 'array', items => { enum => [1,2]}}], [1,2], [1,2]),
        returns([1,2], [1,2]),
    },
    {
        args([{type => 'array', items => {type => 'object', properties => { b => {default => 44}}}}, {type => 'array', items => {type => 'object', properties => { b => {default => 44}}}}], [{a => 1}, {a => 2, b => 33}], [{a => 1}, {a => 2, b => 33}]),
        returns([{a => 1, b => 44}, {a => 2, b => 33}], [{a => 1, b => 44}, {a => 2, b => 33}]),
    },
    {
        args([{type => 'array', items => {type => 'object', properties => { b => {default => 44}}}, quantifier => '?'}, {type => 'array', items => {type => 'object', properties => { b => {default => 44}}}, quantifier => '?'}]),
        returns([], []),
    },
    {
        args([{type => 'array', items => {}, quantifier => '?'}]),
        returns([]),
    },
    {
        args([{items => {}, quantifier => '?'}]),
        returns([]),
    },
    {
        args([{type => 'array', quantifier => '?'}]),
        returns([]),
    },
    {
        args([{type => 'object', properties => {}, quantifier => '?'}]),
        returns({}),
    },
    {
        args([{properties => {}, quantifier => '?'}]),
        returns({}),
    },
    {
        args([{type => 'object', quantifier => '?'}]),
        returns({}),
    },
);

done_testing();




