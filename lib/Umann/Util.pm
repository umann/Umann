package Umann::Util;

use 5.010000;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp;
use Data::Dump qw(dump);
use Umann::List::Util qw(to_array);
use Umann::Scalar::Util qw(
    is_ar 
    is_cr 
    is_hr 
    is_re 
    is_sr
);

use Exporter qw(import);
our @EXPORT_OK = qw(
    deep_copy
    leaf
);

sub leaf {
    my @args = @_;

    my $struct = shift @args;
    if (@args = to_array(@args)) {
        my $key = shift(@args) // return undef;
        return 
            is_hr($struct)
            ?
            leaf($struct->{$key}, @args)
            :
            is_ar($struct)
            ?
            leaf(eval { $struct->[$key] }, @args)
                                  # eval cos $x[-4] would die on @x=(1, 2);
            :
            undef
        ;
    }
    return $struct;
}

sub deep_copy {
    my @these = @_;
    if(1 != scalar @these) {
        return (map { deep_copy($_) } @these);
    }
    my $this = shift @these;
    
    return 
        is_ar($this) ? [map deep_copy($_), @{$this}]                         :
        is_hr($this) ? +{map { $_ => deep_copy($this->{$_}) } keys %{$this}} :
        is_cr($this) ? sub{&{$this}}                                         :
        is_sr($this) ? do { my $x = ${$this}; \$x }                            :
        is_re($this) ? qr/$this/                                             :
                       $this
    ;
}

1;

__END__
#cartesian([1,2], [3,4]) => ([1,3], [1,4], [2,3], [2,4])
#cartesian([3,4], [5,6]) => ([3,5], [4,5], [3,6], [4,6])
#cartesian([1,2], [3,4], [5,6]) => ([1,3,5], [1,4,5], [1,3,6], [1,4,6], [2,3,5], [2,4,5], [2,3,6], [2,4,6])
#cartesian([0,1,2], [3,4]) => ([0,3], [0,4], [1,3], [1,4], [2,3], [2,4])
#sub cartesian {
#    my @ars = @_;
#    return if (!@ars);
#    my $ar = shift @ars;
#    return map { [$_] } @{$ar} if (!@ars);
#    my @left = cartesian(@ars);
#    my @rv;
#    for my $item (@{$ar}) {
#        for my $left_ar (@left) {
#            push @rv, [ $item, @{$left_ar} ];
#        }
#    }
#    return @rv;
#}
#
#sub cartesian_sprintf {
#    my ($format, @args) = @_;
#    carp 'cartesian_sprintf arg number mismatch'
#        if (@args != $format =~ s/%[^%]/$&/g);
#    return map { sprintf $format, @{$_} } cartesian(@args);
#}

# kinda works like ~~ with the following exceptions:
# with 0 args returns fales
# with 1 arg returns arg
# with >2 args returns arg1 ~~ [arg2, arg3, ...]
# with 2 arg
#  if both args are defined scalars then returns "arg2 string contains arg1"  (that's the main point)
#  if arg1 is scalar and arg2 is scalar ref then returns $arg1 ~~ $$arg2

#sub kinda {
#    my @args = @_;
#
#    my $nargs = scalar @args // return;  # false for no arg
#    if ($nargs == 1) {
#        return $args[0];                 # itself for one arg
#    }
#    if ($nargs > 2) {
#        my $arg1 = shift @args;
#        return kinda($arg1, \@args);     #convert 2 .. args to one arrayref
#    }
#    my ($arg1, $arg2) = @args;
#    if (!ref $arg1 && defined $arg1 && !ref $arg2 && defined $arg2) {
#        return
#            index($arg1, $arg2) > -1
#            ; # if both are strings (can be numbers), returns "arg2 contains arg1"
#    }
#    if (!ref $arg1 && ref($arg2) eq 'SCALAR') {
#        return $arg1 ~~ $$arg2
#            ; # if arg1 is strings (or number) and arg2 is , returns "arg2 contains arg1"
#    }
#}

1;

__END__
