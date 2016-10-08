#!/usr/bin/env perl

use strict;
use warnings;

use feature qw(say state);

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

use Test::More;
use Carp;

# recur();

# sub recur {
    # my $x = shift // 0;
    # if($x <30) {
        # return recur($x+1);
    # }
    # is(Umann::Test::subname(), undef, 'subname undef');
# }
# __END__

ok(Umann::Test::_chk_nand({ 1 => 2, 3 => 4 }, 1, 9));
ok(!eval { Umann::Test::_chk_nand({ 1 => 2, 3 => 4 }, 1, 3) });
ok(Umann::Test::_chk_xor({ 1 => 2, 3 => 4 }, 1, 9));
ok(!eval { Umann::Test::_chk_xor({ 1 => 2, 3 => 4 }, 8, 9) });
ok(!eval { Umann::Test::_chk_xor({ 1 => 2, 3 => 4 }, 1, 3) });
ok(!eval { Umann::Test::_chk_test_cases({ notallowedkey => 'nyul' }) });
ok( !eval {
        Umann::Test::_chk_test_cases({ default => {}, extrakey => 'nyul' });
    }
);
ok( Umann::Test::_chk_test_cases(
        {
            default => {
                function => sub { }
            }
        },
        {
            function => sub { }
        }
    )
);

#Umann::Test::_chk_test_cases({default => { notallowedkey => 1}});
ok( !eval {
        Umann::Test::_chk_test_cases({ default => { notallowedkey => 1 } });
    }
);
ok(!eval { Umann::Test::_chk_test_cases(1) });
ok(!eval { Umann::Test::_chk_test_cases() });
subtest subtest => sub { Umann::Test::cmp_like([ 1, 2 ], [ 1, 2 ], 'subtest') };

is_deeply([ args() ],     [ args => [] ],  'args()',);
is_deeply([ args(1) ],    [ args => [1] ], 'args(1)',);
is_deeply([ returns() ],  [ returns => [] ],  'returns()',);
is_deeply([ returns(1) ], [ returns => [1] ], 'returns(1)',);
is_deeply(
    [ returns_anything() ],
    [ returns_anything => 1 ],
    'returns_anything()',
);
is_deeply([ eval { returns_anything(1) } ], [], 'returns_anything(1)',);
is_deeply([ returns_array() ],  [ returns_array => [] ],  'returns_array()',);
is_deeply([ returns_array(1) ], [ returns_array => [1] ], 'returns_array(1)',);
is_deeply(
    [ returns_array(1, 2) ],
    [ returns_array => [ 1, 2 ] ],
    'returns_array(1,2)',
);
is_deeply([ eval { returns_scalar() } ], [], 'returns_scalar()',);
is_deeply([ returns_scalar(1) ], [ returns_scalar => 1 ], 'returns_scalar(1)',);
is_deeply([ eval { returns_scalar(1, 2) } ], [], 'returns_scalar(1,2)',);
is_deeply([ eval { warns_like() } ], [], 'warns_like()',);
is_deeply([ warns_like(1) ], [ warns_like => 1 ], 'warns_like(1)',);
is_deeply([ eval { warns_like(1, 2) } ], [], 'warns_like(1,2)',);
is_deeply([ eval { dies_like() } ], [], 'dies_like()',);
is_deeply([ dies_like(1) ], [ dies_like => 1 ], 'dies_like(1)',);
is_deeply([ eval { dies_like(1, 2) } ], [], 'dies_like(1,2)',);
is_deeply([ title() ], [], 'title()',);
is_deeply([ title(1) ], [ title => 1 ], 'title(1)',);
is_deeply([ eval { title(undef) } ], [], 'title(undef)',);
is_deeply([ eval { title(1, 2) } ], [], 'title(1,2)',);
is_deeply([ eval { function() } ], [], 'function()',);
is_deeply(
    [ function('funcname') ],
    [ function => 'funcname' ],
    'function(funcname)',
);
ok([ function(sub { }) ], 'function(sub{})',);
is_deeply([ eval { function('BadFuncname') } ], [], 'function(BadFuncname)',);
is_deeply([ eval { function('funcname', 2) } ], [], 'function(funcname,2)',);
is_deeply([ eval { method() } ], [], 'method()',);
is_deeply(
    [ method('methodname') ],
    [ method => 'methodname' ],
    'method(methodname)',
);
is_deeply([ eval { method('BadMethodname') } ], [], 'method(BadMethodname)',);
is_deeply([ eval { method('methodname', 2) } ], [], 'method(methodname,2)',);
is_deeply([ eval { class() } ], [], 'class()',);
is_deeply(
    [ class('Class::Name') ],
    [ class => 'Class::Name' ],
    'class(Class::Name)',
);
is_deeply([ eval { class('Bad:Name') } ], [], 'class(Bad:Name)',);
is_deeply([ eval { class('Class::Name', 2) } ], [], 'class(Class::Name,2)',);
is_deeply([ eval { object() } ], [], 'object()',);
is_deeply(
    eval {
        [ eval { object('not_blessed') } ];
    },
    [],
    'object(not_blessed)',
);
is_deeply(
    [ object(bless {}, 'Whateva') ],
    [ object => bless {}, 'Whateva' ],
    'object(bless {}, Whateva)',
);

#is_deeply([eval{object(bless({}, 'Whateva'),2)}] , []                     , 'object(bless({}, Whateva),2)',);
# ok(Umann::Test::is_in(1, 1, 2), 'is_in(1, 1, 2)');
# ok(Umann::Test::is_in(1, [ 1, 2 ]), 'is_in(1, [1, 2])');
# ok(!Umann::Test::is_in(1, [ 3, 2 ]), 'is_in(1, [3, 2])');
# ok(!Umann::Test::is_in(1, 3, 2), 'is_in(1, 3, 2)');
# ok(!Umann::Test::is_in(1, []), 'is_in(1, [])');
# ok(!Umann::Test::is_in(1), 'is_in(1)');
# ok(!Umann::Test::is_in(),  'is_in()');
# ok(Umann::Test::is_in(undef, undef, 2), 'is_in(undef, undef, 2)');
# ok(Umann::Test::is_in(undef, [ undef, 2 ]), 'is_in(undef, [undef, 2])');
# ok(!Umann::Test::is_in(undef, [ 3, 2 ]), 'is_in(undef, [3, 2])');
# ok(!Umann::Test::is_in(undef, 3, 2), 'is_in(undef, 3, 2)');
# ok(!Umann::Test::is_in(undef, []), 'is_in(undef, [])');
# ok(!Umann::Test::is_in(undef), 'is_in(undef)');
# is(eval_subname(), 'eval_subname',
    # 'eval subname');

my $test_obj = My::Test::Package->new;
run_test_cases(
    { default => { function('is_in'), class('Umann::Test'), }}, # Comma used to separate statements.  See pages 68,71 of PBP.  (Severity: 4)
    { args('a', 'a', 'b'), returns(1)},
    { args('a', ['a', 'b']), returns(1)},
    { args('a', 'c', 'b'), returns_false()},
    { args('a', ['c', 'b']), returns_false()},
    { args('a', []), returns_false()},
    { args('a'), returns_false()},
    { args(undef, undef, 'b'), returns(1)},
    { args(undef, [undef, 'b']), returns(1)},
    { args(undef, 'c', 'b'), returns_false()},
    { args(undef, ['c', 'b']), returns_false()},
    { args(undef, []), returns_false()},
    { args(undef), returns_false()},
);
#run_test_cases(
#    { default => { function('function_nop'), class('main'), }}, # Comma used to separate statements.  See pages 68,71 of PBP.  (Severity: 4)
#    {},
#);
run_test_cases(
    { function('function_nop'), returns_anything(), class('main'), }, # Comma used to separate statements.  See pages 68,71 of PBP.  (Severity: 4)
    {
        class('Umann::Test'), function('_chk_nargs'),
        args(2, 'one', 'two'), returns('one', 'two'),
    },
    {
        class('main'), function('function_returns_one'),
        args('one', 'two', 'three'), returns('one'),
    },
    {
        class('main'), function('function_returns_two'),
        args('one', 'two', 'three'), returns('one', 'two'),
    },
    {
        class('My::Test::Package'), method('function_warns_and_dies'),
        warns_like('is a warn'),    dies_like('is a die'),
        class('main'), args('one', 'two', 'three'),
        returns('one', 'two'),
    },
    {
        class('My::Test::Package'), method('method_warns_and_dies'),
        warns_like('is a warn'),    dies_like('is a die'),
        returns_scalar(1),
    },
    {
        class('My::Test::Package'), method('method_returns_one'),
        args('one', 'two', 'three'), returns('one'),
    },
    {
        class('My::Test::Package'), method('method_returns_two'),
        args('one', 'two', 'three'), returns('one', 'two'),
    },
    {
        object($test_obj),       method('method_warns_and_dies'),
        warns_like('is a warn'), dies_like('is a die'),
        returns_scalar(1),
    },
    {
        object($test_obj),              method('method_warns_and_dies'),
        warns_like(['this is a warn']), dies_like('is a die'),
        returns_scalar(1),
    },
    {
        object($test_obj),         method('method_warns_and_dies'),
        warns_like(qr/is a warn/), dies_like('is a die'),
        returns_scalar(1),
    },
    {
        object($test_obj),       method('method_warns_and_dies'),
        warns_like('is a warn'), dies_like(["this is a die"]),
        returns_scalar(1),
    },
    {
        object($test_obj),       method('method_warns_and_dies'),
        warns_like('is a warn'), dies_like(qr/this is a die/),
        returns_scalar(1),
    },
    {
        object($test_obj), method('method_returns_one'),
        args('one', 'two', 'three'), returns('one'),
    },
    {
        object($test_obj), method('method_returns_two'),
        args('one', 'two', 'three'), returns('one', 'two'),
    },
);

done_testing();

sub function_nop {
}

sub function_warns_and_dies {
    carp 'this is a warn';
    croak 'this is a die';
}

sub function_returns_one {
    my ($one) = @_;
    return $one;
}

sub function_returns_two {
    my ($one, $two) = @_;
    return ($one, $two);
}

sub eval_subname {
    return eval {Umann::Test::subname()} || $@;
}

######################################

package My::Test::Package;

use Carp;

sub new {
    return bless {}, shift;
}

sub method_warns_and_dies {
    my $self = shift;
    carp('this is a warn');
    die('this is a die');
}

sub method_returns_one {
    my ($self, $one) = @_;
    return $one;
}

sub method_returns_two {
    my ($self, $one, $two) = @_;
    return ($one, $two);
}
