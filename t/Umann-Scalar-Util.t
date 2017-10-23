#!/usr/bin/env perl

use 5.010;

use strict;
use warnings;

our $VERSION = '0.01';

use Test::More;
use Carp;
use Data::Dump qw(dump);

use Umann::Test qw(:all);

BEGIN { use_ok('Umann::Scalar::Util') }

run_test_cases(
    { default => { class('Umann::Scalar::Util') } },
    { function('looks_like_class_name'), args(),          returns_false(), },
    { function('looks_like_class_name'), args('111'),     returns_false(), },
    { function('looks_like_class_name'), args('whateva'), returns_false(), },
    { function('looks_like_class_name'), args(undef),     returns_false(), },
    { function('looks_like_class_name'), args('Class::Name'), returns(1), },
    {
        function('looks_like_class_name'), args('Class::Name::LikeThis'),
        returns(1),
    },
    {
        function('looks_like_class_name'), args('Class::Name::likeThis'),
        returns_false(),
    },
    { function('looks_like_sub_name'), args(),           returns_false(), },
    { function('looks_like_sub_name'), args('111'),      returns_false(), },
    { function('looks_like_sub_name'), args('whateva'),  returns(1), },
    { function('looks_like_sub_name'), args(undef),      returns_false(), },
    { function('looks_like_sub_name'), args('sub_name'), returns(1), },
    {
        function('looks_like_sub_name'), args('sub_name_like_this'), returns(1),
    },
    {
        function('looks_like_sub_name'), args('sub_name_like_This'),
        returns_false(),
    },
    { function('undef_safe_eq'), args(),  dies_like('exactly 2'), },
    { function('undef_safe_eq'), args(1), dies_like('exactly 2'), },
    { function('undef_safe_eq'), args(1, 2, 'bar'), dies_like('exactly 2'), },
    { function('undef_safe_eq'), args(1,     undef), returns_false(), },
    { function('undef_safe_eq'), args(undef, 1),     returns_false(), },
    { function('undef_safe_eq'), args(undef, undef), returns(1), },
    { function('undef_safe_eq'), args(1,     1),     returns(1), },
    { function('undef_safe_eq'), args(1,     2),     returns_false(), },
    { function('undef_safe_eq'), args('a',   'b'),   returns_false(), },

);

done_testing();

__END__
