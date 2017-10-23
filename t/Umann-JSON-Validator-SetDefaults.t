#!/usr/bin/env perl

use 5.010;

use strict;
use warnings;

our $VERSION = '0.01';

use Readonly;

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

BEGIN { use_ok('Umann::JSON::Validator::SetDefaults') }

my $ujvs = Umann::JSON::Validator::SetDefaults->new;
ok($ujvs, 'new');

## no critic(ProhibitCommaSeparatedStatements)

run_test_cases(
    { default => { object($ujvs), method('validate_and_return_data') } },
    {
        args(
            { a    => 1 },
            { type => 'object', properties => { b => { default => 44 } } }
        ),
        returns_scalar({ a => 1, b => 44 }),
    },
    {
        args({ a => 1 }, { type => 'array' }),
        dies_like('Expected array - got object'),
    },
    { args({ a => 1 }, { type => 'object' }), returns({ a => 1 }), },
    {
        args(
            { a    => 1 },
            { type => 'object', properties => { b => { enum => [ 1, 2 ] } } }
        ),
        returns({ a => 1 }),
    },
    {
        args(
            { a => 1 },
            {
                type       => 'object',
                properties => { b => { enum => [ 1, 2 ], default => 44 } }
            }
        ),
        dies_like(qr/Not.in.enum.list/smx),
    },
    {
        args(
            { a => 1 },
            {
                type       => 'object',
                properties => { b => { enum => [ 1, 2 ], default => 44 } }
            },
            { insane => 1 }
        ),
        returns({ a => 1, b => 44 }),
    },
);

my @dummy = (
    { args([ 1, 2 ], { type => 'array' }), returns([ 1, 2 ]), },
    {
        args([], { type => 'array', items => { enum => [ 1, 2 ] } }),
        returns([]),
    },
    {
        args([ 1, 2 ], { type => 'array', items => { type => 'number' } }),
        returns([ 1, 2 ]),
    },
    {
        args([ 1, 2 ], { type => 'array', items => { enum => [ 1, 2 ] } }),
        returns([ 1, 2 ]),
    },
    {
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

## use critic

done_testing();

__END__
