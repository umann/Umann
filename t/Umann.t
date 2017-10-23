#!/usr/bin/env perl

use 5.010;

use strict;
use warnings;

our $VERSION = '0.01';

use lib '../lib';

use Test::More tests => 21;

use Readonly;

Readonly my $NUM1 => 42;
Readonly my $NUM2 => 666;

use Umann::Test qw(:all);

BEGIN { use_ok('Umann') }

my $u;
is(Umann->errstr, undef, 'no errstr as Class Method');
ok($u = Umann->new, 'new from class name');
ok($u->new, 'new from obj');
is($u->errstr, undef, 'no errstr as Object Method');
is(Umann->new({ __test_failed_new__ => 1 }), undef, 'failed new');
is(Umann->errstr, 'errstr for __test_failed_new__', 'errstr for failed new');
is($u->set_errstr('nyul'), undef,  'set_errstr returns undef');
is(Umann->errstr,          'nyul', 'errstr as Class Method');
is($u->errstr,             'nyul', 'errstr as Object Method');
ok($u = Umann->new({ PrintError => 0 }), 'new PrintError=>0');
is($u->set_errstr($NUM2), undef, 'set_errstr as Object Method');
ok($u = Umann->new({ PrintError => 1 }), 'new PrintError=>1');
is($u->set_errstr($NUM2), undef, 'set_errstr as Object Method');
ok($u = Umann->new({ RaiseError => 0 }), 'new RaiseError=>0');
is($u->set_errstr($NUM2), undef, 'set_errstr as Object Method');
ok($u = Umann->new({ RaiseError => 1 }), 'new RaiseError=>1');
my $e = eval { $u->set_errstr($NUM2) };
ok($@, 'set_errstr as Object Method');

## no critic(ProhibitCommaSeparatedStatements)

my $test_obj = Umann->new;
run_test_cases(
    { class('Umann'), method('new'), returns(bless {}, 'Umann'), },
    {
        class('Umann'), method('new'),
        args([]),       dies_like('arg must be HASH ref')
    },
    {
        class('Umann'), method('new'),
        args({}, $NUM1), returns_scalar(bless {}, 'Umann'),
        warns_like('further args ignored')
    },
);

## use critic

done_testing();

__END__
