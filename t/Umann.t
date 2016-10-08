#!/usr/bin/env perl

use strict;
use warnings;

use lib '../lib';

use Test::More tests => 20;
use Umann::Test qw(:all);
    # args
    # class
    # dies_like
    # function
    # method
    # object
    # returns
    # returns_anything
    # returns_array
    # returns_scalar
    # run_test_cases
    # title
    # warns_like
# );

BEGIN { use_ok('Umann') }

my $u;
is(Umann->errstr, undef, 'no errstr as Class Method');
ok($u = Umann->new, 'new');
is($u->errstr, undef, 'no errstr as Object Method');
is(Umann->new({ __test_failed_new__ => 1 }), undef, 'failed new');
is(Umann->errstr, 'errstr for __test_failed_new__', 'errstr for failed new');
is($u->set_errstr('nyul'), undef,  'set_errstr returns undef');
is(Umann->errstr,          'nyul', 'errstr as Class Method');
is($u->errstr,             'nyul', 'errstr as Object Method');
ok($u = Umann->new({ PrintError => 0 }), 'new PrintError=>0');
is($u->set_errstr(666), undef, 'set_errstr as Object Method');
ok($u = Umann->new({ PrintError => 1 }), 'new PrintError=>1');
is($u->set_errstr(666), undef, 'set_errstr as Object Method');
ok($u = Umann->new({ RaiseError => 0 }), 'new RaiseError=>0');
is($u->set_errstr(666), undef, 'set_errstr as Object Method');
ok($u = Umann->new({ RaiseError => 1 }), 'new RaiseError=>1');
is(eval { $u->set_errstr(666) }, undef, 'set_errstr as Object Method');


my $test_obj = Umann->new;
run_test_cases(
    {
        class('Umann'), method('new'),
        returns(bless {}, 'Umann'),
    },
    {
        class('Umann'), method('new'),
        args([]), 
        dies_like('arg must be HASH ref')
    },
    {
        class('Umann'), method('new'),
        args({}, 42), 
        returns_scalar(bless {}, 'Umann'),
        warns_like('further args ignored')
    },
);

done_testing();
