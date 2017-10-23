package Umann::Test;

use 5.010000;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp qw(carp croak cluck confess);
use Data::Dump qw(dump);
use List::MoreUtils qw(any);
use Scalar::MoreUtils qw(define default);
use Scalar::Util qw(blessed);
use Umann::List::Util qw(is_in);
use Umann::Scalar::Util qw(is_ar is_cr is_hr is_re);
use Umann::Util qw(deep_copy is_valid leaf report_ref);
use Test::More;
use Readonly;

Readonly my $CALLER_SUBROUTINE => 3;

use Umann::Scalar::Util qw(
    is_re
    looks_like_class_name
    looks_like_sub_name
);

use Umann::Util qw(
    sub_name
);

use Exporter qw(import);

Readonly my @ALLOWED_KEYS => qw(
    args
    class
    module
    dies_like
    function
    line
    method
    object
    returns
    returns_anything
    returns_array
    returns_false
    returns_valid
    returns_true
    returns_scalar
    title
    warns_like
);

our @EXPORT_OK = (@ALLOWED_KEYS, 'run_test_cases');
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub class {
    my @args = @_;
    my $arg = _chk_nargs(1, @args);
    if (!looks_like_class_name($arg)) {
        _invalid_arg($arg);
    }
    return class => $arg;  # no sub_name() because module() calls this
}

sub module {
    my @args = @_;
    return class(@args);
}

sub object {
    my @args = @_;
    my $arg = _chk_nargs(1, @args);
    if (!blessed $arg) {
        _invalid_arg($arg);
    }
    return sub_name() => $arg;
}

sub method {
    my @args = @_;
    my $arg = _chk_nargs(1, @args);
    if (!looks_like_sub_name($arg)) {
        _invalid_arg($arg);
    }
    return sub_name() => $arg;
}

sub function {
    my @args = @_;
    my $arg = _chk_nargs(1, @args);
    if (!is_cr($arg) && !looks_like_sub_name($arg)) {
        _invalid_arg($arg);
    }
    return sub_name() => $arg;
}

sub title {
    my @args = @_;
    if (!@args) {
        return;
    }
    my $arg = _chk_nargs(1, @args);
    if (!defined $arg) {
        _invalid_arg($arg);
    }
    return sub_name() => $arg;
}

sub args {
    my @args = @_;
    return sub_name() => \@args;
}

sub returns {
    my @args = @_;
    return sub_name() => \@args;
}

sub returns_anything {
    my @args = @_;
    return sub_name() => _chk_nargs(0, @args);
}

sub returns_array {
    my @args = @_;
    return sub_name() => \@args;
}

sub returns_false {
    my @args = @_;
    _chk_nargs(0, @args);
    return returns_valid => sub { !shift };
}

sub returns_true {
    my @args = @_;
    _chk_nargs(0, @args);
    return returns_valid => sub { shift };
}

sub returns_scalar {
    my @args = @_;
    return sub_name() => _chk_nargs(1, @args);
}

sub returns_valid {
    my @args = @_;
    return sub_name() => _chk_nargs(1, @args);
}

sub line {
    my @args = @_;
    return sub_name() => _chk_nargs(1, @args);
}

sub warns_like {
    my @args = @_;
    return sub_name() => _chk_nargs(1, @args);
}

sub dies_like {
    my @args = @_;
    return sub_name() => _chk_nargs(1, @args);
}

sub run_test_cases {
    my @args = @_;

    my @test_cases = _chk_test_cases(@args);
    for my $test_case_hr (@test_cases) {
        subtest $test_case_hr->{title} => sub { _run_test_case($test_case_hr) }
            or diag $test_case_hr->{caller};
    }

    return;
}

sub _run_test_case {
    my $test_case_hr = shift;

    my @args = @{ $test_case_hr->{args} // [] };

    local $SIG{__WARN__} = sub {

        #say STDERR dump $test_case_hr, @_;
        push @{ $test_case_hr->{warnings_ar} }, @_;
    };

    my $chk_scalar = any { exists $test_case_hr->{$_} }
    qw(returns returns_scalar returns_valid);
    my $chk_array =
        any { exists $test_case_hr->{$_} } qw(returns returns_array);
    my $run_anyway =
        any { exists $test_case_hr->{$_} } qw(dies_like warns_like);

    my $run_scalar =
           $chk_scalar
        || ($run_anyway && !$chk_array)
        || $test_case_hr->{returns_anything};
    my $run_array = $chk_array || ($run_anyway && !$chk_scalar);
    my $run_both = $run_array && $run_scalar;

    my $sub = $test_case_hr->{sub};

    if ($run_scalar) {
        my $rv =
            eval { &{$sub}(deep_copy(@args)) }; # deep_copy because sub might modify args
        if ($@) {
            $test_case_hr->{evalerr} = $@;
        }
        if ($run_both) {
            subtest 'returns_scalar' =>
                sub { _chk_result('returns_scalar', undef, $test_case_hr, $rv) }
                or diag $test_case_hr->{caller};
        }
        else {
            _chk_result('returns_scalar', 'returns_scalar', $test_case_hr, $rv);
        }
    }

    if ($run_array) {
        delete $test_case_hr->{warnings_ar}
            ;  # reset in case $run_scalar fillled it above
        my @rv =
            eval { &{$sub}(deep_copy(@args)) }; # deep_copy because sub might modify args
        if ($@) {
            $test_case_hr->{evalerr} = $@;
        }
        if ($run_both) {
            subtest 'returns_array' =>
                sub { _chk_result('returns_array', undef, $test_case_hr, \@rv) }
                or diag $test_case_hr->{caller};
        }
        else {
            _chk_result('returns_array', 'returns_array', $test_case_hr, \@rv);
        }
    }

    return;
}

sub _chk_test_cases {
    my @test_cases = @_;

    if (my @error = grep { !is_hr($_) } @test_cases) {
        croak report_ref('invalid case(s)', \@error);
    }
    my $default_hr = {};  # default of default

    if (leaf($test_cases[0], 'default')) {
        my $d = shift @test_cases;
        $default_hr = delete $d->{default};
        if (%{$d}) {
            croak report_ref('default must not have other keys like', $d);
        }
        if (is_in('line', keys %{$default_hr})) {
            croak 'key "line" is not allowed in default';
        }
        if (my @error = grep { !is_in($_, @ALLOWED_KEYS) } keys %{$default_hr})
        {
            croak report_ref('key', \@error, 'not allowed in default',
                $default_hr);
        }
    }

    my $after_line;
    my $ncases = scalar @test_cases;
    for my $i (0 .. $#test_cases) {
        my $test_case_hr = $test_cases[$i];

        my $line = $test_case_hr->{line} // ((caller 1)[2] // (caller 0)[2])
            . " $i/$ncases"
            . ($after_line ? " (after line $after_line)" : q{});
        my $file = $test_case_hr->{file} // (caller 1)[1] // (caller 0)[1]
            ;  # caller(0) is used when testing test so caller(1) does not exist
        $test_case_hr->{caller} = " at $file line $line";

        for my $key (sort keys %{$default_hr}) {
            if (!exists $test_case_hr->{$key}) {
                $test_case_hr->{$key} = $default_hr->{$key};
            }
        }
        _chk_test_case($test_case_hr);
    }

    return @test_cases;
}

sub _chk_test_case {
    my ($test_case_hr) = @_;

    if (my @error =
        grep { !is_in($_, 'caller', @ALLOWED_KEYS) } keys %{$test_case_hr}
        )
    {
        croak report_ref('key', \@error, 'not allowed', $test_case_hr);
    }
    _chk_xor($test_case_hr, qw(function method));
    my $method   = $test_case_hr->{method};
    my $function = $test_case_hr->{function};
    if ($method) {
        _chk_xor($test_case_hr, qw(class object));
    }
    else {  # $function
        _chk_nand($test_case_hr, qw(function object));
    }
    _chk_nand($test_case_hr,
        qw(returns returns_anything returns_array returns_valid));
    _chk_nand($test_case_hr,
        qw(returns returns_anything returns_scalar returns_valid));

    if ($test_case_hr->{returns} && 1 != scalar @{ $test_case_hr->{returns} }) {
        $test_case_hr->{returns_array} = delete $test_case_hr->{returns};
    }

    my @args = @{ $test_case_hr->{args} // [] };
    my $dump_args = dump @args;
    $dump_args =~ s/^[(](.*)[)]$/$1/smx;
    $dump_args =~ s/\h*\R+\h*/ /smxg;
    $dump_args =~ s/^(.{40}).{6,}(.{40})/$1 ... $2/smxg;

    $test_case_hr->{sub} =
        $method
        ? (
        $test_case_hr->{class}
        ? sub { $test_case_hr->{class}->$method(@_) }
        : sub { $test_case_hr->{object}->$method(@_) }
        )
        :  # else $function
        (
        is_cr($function)
        ? $function
        : \&{ join q{::}, $test_case_hr->{class} // 'main', $function }
        );

    $test_case_hr->{title} //= (
        $method
        ? ( $test_case_hr->{class}
            ? "$test_case_hr->{class}\-\>$method"
            : '[' . ref($test_case_hr->{object}) . "]->$method"
            )
        :  # else $function
            (
              'CODE' eq ref $function
            ? "[sub $function]"  # some hexa garbage
            : (join q{::}, $test_case_hr->{class} // 'main', $function)
            )
    ) . "($dump_args)";

    return;
}

sub _chk_nand {
    my ($test_case_hr, @options) = @_;

    my @have = grep { $test_case_hr->{$_} } @options;
    if (scalar(@have) >= 2) {
        croak report_ref('only one of', \@options, '(or none) may appear',
            $test_case_hr);
    }

    return 1;  # for test
}

sub _chk_xor {
    my ($test_case_hr, $either, $or) = @_;
    if (!$test_case_hr->{$either} == !$test_case_hr->{$or}) {
        confess report_ref('must be either', \$either, 'or', \$or,
            $test_case_hr);
    }

    return 1;  # for test
}

sub _invalid_arg {
    my $arg = shift;
    croak report_ref(sub_name(1), 'invalid arg', \$arg);
}

sub _chk_nargs {
    my @args  = @_;
    my $nargs = shift @args;

    (my $caller_sub_name = (caller 1)[$CALLER_SUBROUTINE]) =~ s/.*:://smx;
    if (scalar(@args) != $nargs) {
        confess report_ref(sub_name(1),
            "must have exactly $nargs args, not", \@args);
    }
    return $nargs == 0 ? 1 : $nargs == 1 ? shift @args : @args;
}

sub _chk_result {
    my ($context, $title, $test_case_hr, $got, @warnings) = @_;

    if ($test_case_hr->{returns_anything}) {
        $title = 'returns_anything';
        ok(1, $title);
    }
    elsif (!exists $test_case_hr->{evalerr}) {
        if (exists $test_case_hr->{returns_valid}) {
            $title = 'returns_valid';
            ok(is_valid($got, $test_case_hr->{returns_valid}), $title)
                or diag $test_case_hr->{caller};
        }
        else {
            my $expected =
                  $context eq 'returns_scalar'
                ? $test_case_hr->{$context} // $test_case_hr->{returns}[0]
                : $test_case_hr->{$context} // $test_case_hr->{returns};
            is_deeply($got, $expected, $title) or diag $test_case_hr->{caller};
        }
    }

    my $warns_like = $test_case_hr->{warns_like};
    $test_case_hr->{warnings} =
         !defined $test_case_hr->{warnings_ar}
        ? undef
        : join q{ }, @{ $test_case_hr->{warnings_ar} // [] };

    for my $problem (qw(evalerr warnings)) {  # Houston I have. (Yoda)
        if ($test_case_hr->{$problem}) {
            $test_case_hr->{$problem} =~
                s/\x20at\x20\S+\x20line\x20\d+[.]\R+\z//smx
                ;  # it will cut blabla form the last warning only
        }
    }

    my $warn_matcher =
         !defined $warns_like ? undef
        : ref($warns_like)    ? $warns_like
        :                       qr/\Q$warns_like/smx;
    cmp_like(
        $test_case_hr->{warnings},
        $warn_matcher,
        join(q{ }, $title // (), (defined $warns_like ? 'warn' : 'no warn'),),
        $test_case_hr->{caller}
    );

    my $dies_like = $test_case_hr->{dies_like};
    my $die_matcher =
         !defined $dies_like ? $dies_like
        : ref($dies_like)    ? $dies_like
        :                      qr/\Q$dies_like/smx;

    cmp_like(
        $test_case_hr->{evalerr},
        $die_matcher,
        join(q{ }, $title // (), (defined $dies_like ? 'die' : 'no die')),
        $test_case_hr->{caller}
    );

    return;
}

sub cmp_like {
    my ($arg1, $arg2, $title, $diag) = @_;
    my $rv =
          is_in(ref $arg1, qw(HASH ARRAY)) ? is_deeply($arg1, $arg2, $title)
        : is_re($arg2) ? cmp_ok($arg1, q{=~}, $arg2, $title)
        : is_ar($arg2) ? ok(is_in($arg1, $arg2), $title)
        :                is($arg1, $arg2, $title);
    if (!$rv && $diag) {
        diag $diag;
    }
    return $rv;
}

1;

__END__
