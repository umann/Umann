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
Readonly my $NUM8 => 8;
Readonly my $NUM9 => 9;

use Test::More;
use Carp;

my $e;

use_ok('Umann::Test', ':all');

## no critic(ProtectPrivateSubs)

ok(Umann::Test::_chk_nand({ 1 => $NUM2, $NUM3 => $NUM4 }, 1, $NUM9),
    '_chk_nand');

$e = eval { Umann::Test::_chk_nand({ 1 => $NUM2, $NUM3 => $NUM4 }, 1, $NUM3) };
ok($@, '!_chk_nand');

ok(Umann::Test::_chk_xor({ 1 => $NUM2, $NUM3 => $NUM4 }, 1, $NUM9), '_chk_xor');

$e =
    eval { Umann::Test::_chk_xor({ 1 => $NUM2, $NUM3 => $NUM4 }, $NUM8, $NUM9) };
ok($@, '!_chk_xor 1');

$e = eval { Umann::Test::_chk_xor({ 1 => $NUM2, $NUM3 => $NUM4 }, 1, $NUM3) };
ok($@, '!_chk_xor 2');

$e = eval { Umann::Test::_chk_test_cases({ notallowedkey => 'nyul' }) };
ok($@, '!_chk_test_cases');

$e = eval {
    Umann::Test::_chk_test_cases({ default => {}, extrakey => 'nyul' });
};
ok($@, '!_chk_test_cases 2');
ok( Umann::Test::_chk_test_cases(
        {
            default => {
                function => sub { }
            }
        },
        {
            function => sub { }
        }
    ),
    '_chk_test_cases'
);

$e = eval {
    Umann::Test::_chk_test_cases({ default => { notallowedkey => 1 } });
};
ok($@, '!_chk_test_cases not allowed keys');

$e = eval { Umann::Test::_chk_test_cases(1) };
ok($@, '!_chk_test_cases not allowed(1)');

$e = eval { Umann::Test::_chk_test_cases() };
ok(!$@, '!_chk_test_cases()');

subtest subtest =>
    sub { Umann::Test::cmp_like([ 1, $NUM2 ], [ 1, $NUM2 ], 'subtest') };

# use critic

is_deeply([ args() ],     [ args    => [] ],  'args()');
is_deeply([ args(1) ],    [ args    => [1] ], 'args(1)');
is_deeply([ returns() ],  [ returns => [] ],  'returns()');
is_deeply([ returns(1) ], [ returns => [1] ], 'returns(1)');
is_deeply(
    [ returns_anything() ],
    [ returns_anything => 1 ],
    'returns_anything()',
);

$e = eval { returns_anything(1) };
ok($@, '!returns_anything(1)');

is_deeply([ returns_array() ],  [ returns_array => [] ],  'returns_array()');
is_deeply([ returns_array(1) ], [ returns_array => [1] ], 'returns_array(1)');
is_deeply(
    [ returns_array(1, $NUM2) ],
    [ returns_array => [ 1, $NUM2 ] ],
    "returns_array(1,$NUM2)",
);

$e = eval { returns_scalar() };
ok($@, '!returns_scalar()');

is_deeply([ returns_scalar(1) ], [ returns_scalar => 1 ], 'returns_scalar(1)');

$e = eval { returns_scalar(1, $NUM2) };
ok($@, "!returns_scalar(1,$NUM2)");

$e = eval { warns_like() };
ok($@, '!warns_like()');

is_deeply([ warns_like(1) ], [ warns_like => 1 ], 'warns_like(1)');

$e = eval { warns_like(1, $NUM2) };
ok($@, "!warns_like(1,$NUM2)");

$e = eval { dies_like() };
ok($@, '!dies_like()');

is_deeply([ dies_like(1) ], [ dies_like => 1 ], 'dies_like(1)');

$e = eval { dies_like(1, $NUM2) };
ok($@, "dies_like(1,$NUM2)");

ok(!title(), '!title()');
is_deeply([ title(1) ], [ title => 1 ], 'title(1)');

$e = eval { title(undef) };
ok($@, '!title(undef)');

$e = eval { title(1, $NUM2) };
ok($@, "title(1,$NUM2)");

$e = eval { function() };
ok($@, '!function()');

is_deeply(
    [ function('funcname') ],
    [ function => 'funcname' ],
    'function(funcname)',
);
ok([ function(sub { }) ], 'function(sub{})');

$e = eval { function('BadFuncname') };
ok($@, '!function(BadFuncname)');

$e = eval { function('funcname', $NUM2) };
ok($@, "function(funcname,$NUM2)");

$e = eval { method() };
ok($@, '!method()');

is_deeply(
    [ method('methodname') ],
    [ method => 'methodname' ],
    'method(methodname)',
);

$e = eval { method('BadMethodname') };
ok($@, '!method(BadMethodname)');

$e = eval { method('methodname', $NUM2) };
ok($@, "method(methodname,$NUM2)");

$e = eval { class() };
ok($@, '!class()');

is_deeply(
    [ class('Class::Name') ],
    [ class => 'Class::Name' ],
    'class(Class::Name)',
);

$e = eval { class('Bad:Name') };
ok($@, '!class(Bad:Name)');

$e = eval { class('Class::Name', $NUM2) };
ok($@, "class(Class::Name,$NUM2)");

$e = eval { object() };
ok($@, '!object()');

$e = eval { object('not_blessed') };
ok($@, '!object(not_blessed)');

is_deeply(
    [ object(bless {}, 'Whateva') ],
    [ object => bless {}, 'Whateva' ],
    'object(bless {}, Whateva)',
);

## no critic(ProhibitCommaSeparatedStatements)

my $test_obj = My::Test::Package->new;
run_test_cases(
    { default => { function('is_in'), class('Umann::Test'), } },
    { args('a', 'a', 'b'), returns(1) },
    { args('a', [ 'a', 'b' ]), returns(1) },
    { args('a', 'c', 'b'), returns_false() },
    { args('a', [ 'c', 'b' ]), returns_false() },
    { args('a', []), returns_false() },
    { args('a'), returns_false() },
    { args(undef, undef, 'b'), returns(1) },
    { args(undef, [ undef, 'b' ]), returns(1) },
    { args(undef, 'c', 'b'), returns_false() },
    { args(undef, [ 'c', 'b' ]), returns_false() },
    { args(undef, []), returns_false() },
    { args(undef), returns_false() },
);

run_test_cases(
    {
        line(__LINE__),     function('function_nop'),
        returns_anything(), class('main'),
    }, # Comma used to separate statements.  See pages 68,71 of PBP.  (Severity: $NUM4)
    {
        line(__LINE__), class('Umann::Test'),
        function('_chk_nargs'), args($NUM2, 'one', 'two'),
        returns('one', 'two'),
    },
    {
        line(__LINE__), class('main'),
        function('function_returns_one'), args('one', 'two', 'three'),
        returns('one'),
    },
    {
        line(__LINE__), class('main'),
        function('function_returns_two'), args('one', 'two', 'three'),
        returns('one', 'two'),
    },
    {
        line(__LINE__),                    class('My::Test::Package'),
        method('function_warns_and_dies'), warns_like('is a warn'),
        dies_like('is a die'),             class('main'),
        args('one', 'two', 'three'), returns('one', 'two'),
    },
    {
        line(__LINE__),                  class('My::Test::Package'),
        method('method_warns_and_dies'), warns_like('is a warn'),
        dies_like('is a die'),           returns_scalar(1),
    },
    {
        line(__LINE__), class('My::Test::Package'),
        method('method_returns_one'), args('one', 'two', 'three'),
        returns('one'),
    },
    {
        line(__LINE__), class('My::Test::Package'),
        method('method_returns_two'), args('one', 'two', 'three'),
        returns('one', 'two'),
    },
    {
        line(__LINE__),                  object($test_obj),
        method('method_warns_and_dies'), warns_like('is a warn'),
        dies_like('is a die'),           returns_scalar(1),
    },
    {
        line(__LINE__),                  object($test_obj),
        method('method_warns_and_dies'), warns_like(['this is a warn']),
        dies_like('is a die'),           returns_scalar(1),
    },
    {
        line(__LINE__),                  object($test_obj),
        method('method_warns_and_dies'), warns_like(qr/is.a.warn/smx),
        dies_like('is a die'),           returns_scalar(1),
    },
    {
        line(__LINE__),                  object($test_obj),
        method('method_warns_and_dies'), warns_like('is a warn'),
        dies_like('this is a die'),      returns_scalar(1),
    },
    {
        line(__LINE__),                  object($test_obj),
        method('method_warns_and_dies'), warns_like('is a warn'),
        dies_like(qr/this.is.a.die/smx), returns_scalar(1),
    },
    {
        line(__LINE__), object($test_obj),
        method('method_returns_one'), args('one', 'two', 'three'),
        returns('one'),
    },
    {
        line(__LINE__), object($test_obj),
        method('method_returns_two'), args('one', 'two', 'three'),
        returns('one', 'two'),
    },
);

## use critic

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
    return eval { Umann::Test::subname() } || $@;
}

######################################

package My::Test::Package;

use Carp;

sub new {
    return bless {}, shift;
}

sub method_warns_and_dies {
    my $self = shift;
    carp 'this is a warn';
    die "this is a die\n";
}

sub method_returns_one {
    my ($self, $one) = @_;
    return $one;
}

sub method_returns_two {
    my ($self, $one, $two) = @_;
    return ($one, $two);
}

1;

__END__
