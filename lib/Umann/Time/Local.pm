package Umann::Time::Local;

use 5.010000;

use strict;
use warnings;

our $VERSION = '0.01';

my $YYYY_MM_DD_HH_MM_SS_RE = qr/^(\d{4})\D*(\d{2})\D*(\d{2})\D*(\d{2})\D*(\d{2})\D*(\d{2})\b/smx;

use Time::Local qw(timelocal timegm);

use Exporter qw(import);
our @EXPORT_OK = qw(
    my_timelocal
    my_timegm
);

sub my_timelocal {
    return oh_my(\&timelocal, @_);
}

sub my_timegm {
    return oh_my(\&timegm, @_);
}

sub oh_my {
    my $sub                 = shift;
    my $yyyy_mm_dd_hh_mm_ss = shift;
    
    my ($year, $mon1, $mday, $hour, $min, $sec) = $yyyy_mm_dd_hh_mm_ss =~ /$YYYY_MM_DD_HH_MM_SS_RE/ or return;
    my $mon0 = $mon1 - 1;
    return eval {&{$sub}($sec, $min, $hour, $mday, $mon0, $year)};
}

1;

__END__
