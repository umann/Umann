#!/usr/bin/env perl

use 5.010;

use strict;
use warnings;

our $VERSION = '0.01';

use Test::More;
use Carp;
use Data::Dump qw(dump);
use Readonly;

Readonly my $NUM1 => 42;
Readonly my $NUM2 => 666;

use Umann::Test qw(
    args
    class
    dies_like
    function
    line
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
my $ujvol = Umann::JSON::Validator::OfList->new;

ok($ujvol, 'new');

run_test_cases(
    { default => { object($ujvol), method('validate_list_and_return_data') } },
    {
        line(__LINE__),
        args(
            { type => 'object', properties => { b => { default => 44 } } },
            { a    => 1 }
        ),
        returns_scalar({ a => 1, b => 44 }),
    },
    {
        line(__LINE__),
        args({ type => 'array' }, { a => 1 }),
        dies_like('Expected array - got object'),
    },
    {
        line(__LINE__),
        args({ type => 'object' }, { a => 1 }),
        returns({ a => 1 }),
    },
    {
        line(__LINE__),
        args(
            { type => 'object', properties => { b => { enum => [ 1, 2 ] } } },
            { a    => 1 }
        ),
        returns({ a => 1 }),
    },
    {
        line(__LINE__),
        args(
            {
                type       => 'object',
                properties => { b => { enum => [ 1, 2 ], default => 44 } }
            },
            { a => 1 }
        ),
        dies_like(qr/Not.in.enum.list/smx),
    },

#no insane here {
#no insane here     line(__LINE__),
#        args({type => 'object', properties => { b => {enum => [1,2], default => 44}}}, {insane => 1}, {a => 1}),
#no insane here     returns({a => 1, b => 44}),
#no insane here },
    {
        line(__LINE__),
        args({ type => 'array', items => { enum => [ 1, 2 ] } }, []),
        returns([]),
    },
    {
        line(__LINE__),
        args({ type => 'array', items => { type => 'number' } }, [ 1, 2 ]),
        returns([ 1, 2 ]),
    },
    {
        line(__LINE__),
        args({ type => 'array', items => { enum => [ 1, 2 ] } }, [ 1, 2 ]),
        returns([ 1, 2 ]),
    },
    {
        line(__LINE__),
        args(
            {
                type  => 'array',
                items => {
                    type       => 'object',
                    properties => { b => { default => 44 } }
                }
            },
            [ { a => 1 }, { a => 2, b => 33 } ]
        ),
        returns([ { a => 1, b => 44 }, { a => 2, b => 33 } ]),
    },
    { line(__LINE__), args({ type => 'array' }, [ 1, 2 ]), returns([ 1, 2 ]), },
);

run_test_cases(
    { default => { object($ujvol), method('validate_and_return_data') } },
    {
        line(__LINE__),
        args(
            { a    => 1 },
            { type => 'object', properties => { b => { default => 44 } } }
        ),
        returns_scalar({ a => 1, b => 44 }),
    },
    {
        line(__LINE__),
        args({ a => 1 }, { type => 'array' }),
        dies_like('Expected array - got object'),
    },
    {
        line(__LINE__),
        args({ a => 1 }, { type => 'object' }),
        returns({ a => 1 }),
    },
    {
        line(__LINE__),
        args(
            { a    => 1 },
            { type => 'object', properties => { b => { enum => [ 1, 2 ] } } }
        ),
        returns({ a => 1 }),
    },
    {
        line(__LINE__),
        args(
            { a => 1 },
            {
                type       => 'object',
                properties => { b => { enum => [ 1, 2 ], default => 44 } }
            }
        ),
        dies_like(qr/Not.in.enum.list/smx),
    },

#no insane here {
#no insane here     line(__LINE__),
#        args({a => 1}, {type => 'object', properties => { b => {enum => [1,2], default => 44}}}, {insane => 1}),
#no insane here     returns({a => 1, b => 44}),
#no insane here },
    { line(__LINE__), args([ 1, 2 ], { type => 'array' }), returns([ 1, 2 ]), },
    {
        line(__LINE__),
        args([], { type => 'array', items => { enum => [ 1, 2 ] } }),
        returns([]),
    },
    {
        line(__LINE__),
        args([ 1, 2 ], { type => 'array', items => { type => 'number' } }),
        returns([ 1, 2 ]),
    },
    {
        line(__LINE__),
        args([ 1, 2 ], { type => 'array', items => { enum => [ 1, 2 ] } }),
        returns([ 1, 2 ]),
    },
    {
        line(__LINE__),
        args(
            [ { a => 1 }, { a => 2, b => 33 } ],
            {
                type  => 'array',
                items => {
                    type       => 'object',
                    properties => { b => { default => 44 } }
                }
            }
        ),
        returns([ { a => 1, b => 44 }, { a => 2, b => 33 } ]),
    },
);

run_test_cases(
    { default => { object($ujvol), method('validate_list_and_return_data') } },
    {
        line(__LINE__),
        args(
            [ { type => 'object', properties => { b => { default => 44 } } } ],
            { a => 1 }
        ),
        returns_scalar({ a => 1, b => 44 }),
    },
    {
        line(__LINE__),
        args([ { type => 'array' } ], { a => 1 }),
        dies_like('Expected array - got object'),
    },
    {
        line(__LINE__),
        args([ { type => 'object' } ], { a => 1 }),
        returns({ a => 1 }),
    },
    {
        line(__LINE__),
        args(
            [
                {
                    type       => 'object',
                    properties => { b => { enum => [ 1, 2 ] } }
                }
            ],
            { a => 1 }
        ),
        returns({ a => 1 }),
    },
    {
        line(__LINE__),
        args(
            [
                {
                    type       => 'object',
                    properties => { b => { enum => [ 1, 2 ], default => 44 } }
                }
            ],
            { a => 1 }
        ),
        dies_like(qr/Not.in.enum.list/smx),
    },

#no insane here {
#no insane here     line(__LINE__),
#        args([{type => 'object', properties => { b => {enum => [1,2], default => 44}}}, {insane => 1}], {a => 1}),
#no insane here     returns({a => 1, b => 44}),
#no insane here },
    {
        line(__LINE__),
        args([ { type => 'array' } ], [ 1, 2 ]),
        returns([ 1, 2 ]),
    },
    {
        line(__LINE__),
        args([ { type => 'array', items => { enum => [ 1, 2 ] } } ], []),
        returns([]),
    },
    {
        line(__LINE__),
        args([ { type => 'array', items => { type => 'number' } } ], [ 1, 2 ]),
        returns([ 1, 2 ]),
    },
    {
        line(__LINE__),
        args([ { type => 'array', items => { enum => [ 1, 2 ] } } ], [ 1, 2 ]),
        returns([ 1, 2 ]),
    },
    {
        line(__LINE__),
        args(
            [
                {
                    type  => 'array',
                    items => {
                        type       => 'object',
                        properties => { b => { default => 44 } }
                    }
                }
            ],
            [ { a => 1 }, { a => 2, b => 33 } ]
        ),
        returns([ { a => 1, b => 44 }, { a => 2, b => 33 } ]),
    },
);

run_test_cases(
    { default => { object($ujvol), method('validate_list_and_return_data') } },
    {
        line(__LINE__),
        args(
            [
                { type => 'object', properties => { b => { default => 44 } } },
                { type => 'object', properties => { b => { default => 44 } } }
            ],
            { a => 1 },
            { a => 1 }
        ),
        returns({ a => 1, b => 44 }, { a => 1, b => 44 }),
    },
    {
        line(__LINE__),
        args(
            [ { type => 'array' }, { type => 'array' } ],
            { a => 1 },
            { a => 1 }
        ),
        dies_like('Expected array - got object'),
    },
    {
        line(__LINE__),
        args(
            [ { type => 'object' }, { type => 'object' } ],
            { a => 1 },
            { a => 1 }
        ),
        returns({ a => 1 }, { a => 1 }),
    },
    {
        line(__LINE__),
        args(
            [
                {
                    type       => 'object',
                    properties => { b => { enum => [ 1, 2 ] } }
                },
                {
                    type       => 'object',
                    properties => { b => { enum => [ 1, 2 ] } }
                }
            ],
            { a => 1 },
            { a => 1 }
        ),
        returns({ a => 1 }, { a => 1 }),
    },
    {
        line(__LINE__),
        args(
            [
                {
                    type       => 'object',
                    properties => { b => { enum => [ 1, 2 ], default => 44 } }
                },
                {
                    type       => 'object',
                    properties => { b => { enum => [ 1, 2 ], default => 44 } }
                }
            ],
            { a => 1 },
            { a => 1 }
        ),
        dies_like(qr/Not.in.enum.list/smx),
    },

#no insane here {
#no insane here     line(__LINE__),
#        args([{type => 'object', properties => { b => {enum => [1,2], default => 44}}}, {insane => 1}, {type => 'object', properties => { b => {enum => [1,2], default => 44}}}, {insane => 1}], {a => 1}, {a => 1}),
#no insane here     returns({a => 1, b => 44}, {a => 1, b => 44}),
#no insane here },
    {
        #
        line(__LINE__),
        args([ { type => 'array' }, { type => 'array' } ], [ 1, 2 ], [ 1, 2 ]),
        returns([ 1, 2 ], [ 1, 2 ]),
    },
    {
        line(__LINE__),
        args(
            [
                { type => 'array', items => { enum => [ 1, 2 ] } },
                { type => 'array', items => { enum => [ 1, 2 ] } }
            ],
            [],
            []
        ),
        returns([], []),
    },
    {
        line(__LINE__),
        args(
            [
                { type => 'array', items => { type => 'number' } },
                { type => 'array', items => { type => 'number' } }
            ],
            [ 1, 2 ],
            [ 1, 2 ]
        ),
        returns([ 1, 2 ], [ 1, 2 ]),
    },
    {
        line(__LINE__),
        args(
            [
                { type => 'array', items => { enum => [ 1, 2 ] } },
                { type => 'array', items => { enum => [ 1, 2 ] } }
            ],
            [ 1, 2 ],
            [ 1, 2 ]
        ),
        returns([ 1, 2 ], [ 1, 2 ]),
    },
    {
        line(__LINE__),
        args(
            [
                {
                    type  => 'array',
                    items => {
                        type       => 'object',
                        properties => { b => { default => 44 } }
                    }
                },
                {
                    type  => 'array',
                    items => {
                        type       => 'object',
                        properties => { b => { default => 44 } }
                    }
                }
            ],
            [ { a => 1 }, { a => 2, b => 33 } ],
            [ { a => 1 }, { a => 2, b => 33 } ]
        ),
        returns(
            [ { a => 1, b => 44 }, { a => 2, b => 33 } ],
            [ { a => 1, b => 44 }, { a => 2, b => 33 } ]
        ),
    },
    {
        line(__LINE__),
        args(
            [
                {
                    type  => 'array',
                    items => {
                        type       => 'object',
                        properties => { b => { default => 44 } }
                    },
                    quantifier => q{?}
                },
                {
                    type  => 'array',
                    items => {
                        type       => 'object',
                        properties => { b => { default => 44 } }
                    },
                    quantifier => q{?}
                }
            ],
            [],
            [],
        ),
        returns([], []),
    },
    {
        line(__LINE__),
        args(
            [
                {
                    type    => 'array',
                    default => [ {} ],
                    items   => {
                        type       => 'object',
                        properties => { b => { default => 44 } }
                    },
                    quantifier => q{?}
                },
                {
                    type  => 'array',
                    items => {
                        type       => 'object',
                        properties => { b => { default => 14 } }
                    },
                    quantifier => q{?}
                }
            ],
        ),
        returns([ { b => 44 } ]),
    },
    {
        line(__LINE__),
        args(
            [
                {
                    type       => 'array',
                    items      => {},
                    quantifier => q{?},
                    default    => []
                }
            ]
        ),
        returns([]),
    },
    {
        line(__LINE__),
        args([ { items => {}, quantifier => q{?}, default => [] } ]),
        returns([]),
    },
    {
        line(__LINE__), args([ { type => 'array', quantifier => q{?} } ]),
        returns(),
    },
    {
        line(__LINE__),
        args([ { type => 'array', quantifier => q{?}, default => [] } ]),
        returns([]),
    },
    {
        line(__LINE__),
        args([ { type => 'object', properties => {}, quantifier => q{?} } ]),
        returns(),
    },
    {
        line(__LINE__), args([ { properties => {}, quantifier => q{?} } ]),
        returns(),
    },
    {
        line(__LINE__), args([ { type => 'object', quantifier => q{?} } ]),
        returns(),
    },
);

0 && run_test_cases(
    { default => { object($ujvol), method('validate_list_and_return_data') } },
    {
        line(__LINE__),
        args(
            { type => 'object', properties => {}, quantifier => '{2}' },
            { a    => 1 },
            { a    => 1 }
        ),
        returns({ a => 1 }, { a => 1 }),
    },
    {
        line(__LINE__),
        args(
            {
                type       => 'object',
                properties => { b => { default => 44 } },
                quantifier => '{2}'
            },
            { a => 1 },
            { a => 1 }
        ),
        returns({ a => 1, b => 44 }, { a => 1, b => 44 }),
    },
    {
        line(__LINE__),
        args(
            [
                {
                    type       => 'object',
                    properties => { b => { default => 44 } },
                    quantifier => '{1,2}'
                }
            ],
            { a => 1 },
            { a => 1 }
        ),
        returns({ a => 1, b => 44 }, { a => 1, b => 44 }),
    },
    {
        line(__LINE__),
        args(
            [
                { type => 'object', quantifier => '{1,1}' },
                { type => 'number' }
            ],
            {},
            $NUM1
        ),
        returns({}, $NUM1),
    },
    {
        line(__LINE__),
        args(
            [
                { type => 'object', quantifier => '{1,2}' },
                { type => 'number' }
            ],
            {},
            {},
            $NUM1
        ),
        returns({}, {}, $NUM1),
    },
    {
        line(__LINE__),
        args(
            [
                { type       => 'object', quantifier => q{*} },
                { type       => 'number' },
                { quantifier => '{1}' }
            ],
            {},
            {},
            {},
            $NUM1, 'a'
        ),
        returns({}, {}, {}, $NUM1, 'a'),
    },
    {
        line(__LINE__),
        args(
            [
                { type       => 'number' },
                { quantifier => '{1}' },
                { type       => 'object', quantifier => q{*} },
                { type       => 'number' },
                { quantifier => '{1}' }
            ],
            $NUM2, 'b',
            {},
            {},
            {},
            $NUM1, 'a'
        ),
        returns($NUM2, 'b', {}, {}, {}, $NUM1, 'a'),
    },
);

done_testing();

__END__
