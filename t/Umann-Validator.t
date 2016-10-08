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

use Test::More; # tests => 12;
BEGIN { use_ok(qw(Umann::Validator)); }

run_test_cases(
    { 
        default => { 
            class('Umann::Validator'),
            function('enum_0th_default')
        }
    },
    {
        args(),
        dies_like('called with empty list'),
    },
    {
        args(5),
        returns(enum => [5], default => 5),
    },
    {
        args([5]),
        returns(enum => [5], default => 5),
    },
    {
        args('a', 'b'),
        returns(enum => ['a', 'b'], default => 'a'),
    },
    {
        args(['a', 'b']),
        returns(enum => ['a', 'b'], default => 'a'),
    },
);

func();

done_testing();

sub func {
    run_test_cases(
        { 
            default => { 
                class('Umann::Validator'),
                function('validate_func')
            }
        },
        {
            args({ type => 'object'}, {}),
            returns({}),
        }
    );
}

package My::Class;

sub new {
    return bless {}, shift;
}

sub meth_not_even_1ce {
}
   
1;

__END__