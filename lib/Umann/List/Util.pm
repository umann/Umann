package Umann::List::Util;

use 5.010000;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp;
use Data::Dump qw(dump);

use Umann::Scalar::Util qw(
    is_ar 
    is_hr 
    undef_safe_eq
);

use Exporter qw(import);
our @EXPORT_OK = qw(
    hrslice
    is_in
    to_array
);

sub hrslice {
    my $hr   = shift;
    if(!is_hr($hr)) {
        croak '1st param must be HASH ref';
    }
    my @keys = @_;
    
    return {map {$_ => $hr->{$_}} grep {exists $hr->{$_}} to_array(@keys)};
}

sub is_in {
    my @args = @_;
    if(!@args) {
        croak 'No param';
    }
    my $candidate = shift @args;
    
    for my $elem (to_array(@args)) {
        if(undef_safe_eq($elem, $candidate)) {
            return 1;
        }
    }
    return;
}

sub to_array {
    my @args = @_;
    return
        1 == scalar(@args) && is_ar($args[0])
        ?
        @{$args[0]}
        :
        @args
    ;
}

1;

__END__
