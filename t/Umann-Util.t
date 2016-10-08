#!/usr/bin/env perl

use strict;
use warnings;

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

use Test::More tests => 12;
BEGIN { use_ok(qw(Umann::Util)); }

is(Umann::Util::leaf([1], [0]), 1);
is(Umann::Util::leaf([1], undef), undef);
is(Umann::Util::leaf(1,   1),     undef);
is(Umann::Util::leaf(),  undef);
is(Umann::Util::leaf(1), 1);
is(Umann::Util::leaf([3], 1), undef);
is(Umann::Util::leaf([3], 0, 0), undef);
is(Umann::Util::leaf([3], 0), 3);
is(Umann::Util::leaf({ a => 2 }, 'a'), 2);
is(Umann::Util::leaf({ a => 2 }, 'b'), undef);
is(Umann::Util::leaf({ a => [ 2, 3 ] }, 'a', 1), 3);

done_testing();
