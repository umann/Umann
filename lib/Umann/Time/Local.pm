package Umann::Time::Local;

use 5.010000;

use strict;
use warnings;

our $VERSION = '0.01';

my $YYYY_MM_DD_HH_MM_SS_RE =
    qr/^(\d{4})\D*(\d{2})\D*(\d{2})\D*(\d{2})\D*(\d{2})\D*(\d{2})\b/smx;

use Time::Local qw(timelocal timegm);

use Exporter qw(import);
our @EXPORT_OK = qw(
    my_timelocal
    my_timegm
);

sub my_timelocal {
    my @args = @_;
    return oh_my(\&timelocal, @args);
}

sub my_timegm {
    my @args = @_;
    return oh_my(\&timegm, @args);
}

sub oh_my {
    my $sub                 = shift;
    my $yyyy_mm_dd_hh_mm_ss = shift;

    my ($year, $mon1, $mday, $hour, $min, $sec) =
        $yyyy_mm_dd_hh_mm_ss =~ /$YYYY_MM_DD_HH_MM_SS_RE/smx
        or return;
    my $mon0 = $mon1 - 1;
    return eval { &{$sub}($sec, $min, $hour, $mday, $mon0, $year) } // ();
}

1;

__END__
