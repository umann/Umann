package Umann::JSON::Validator::OfList;

use 5.010000;

use strict;
use warnings;

our $VERSION = '0.01';

use parent qw(Umann::JSON::Validator::SetDefaults);

use Carp qw(carp croak confess longmess);
use Data::Dump qw(dump);

use Umann::JSON::Validator::SetDefaults;
use Umann::Scalar::Util qw(is_ar undef_safe_eq);

sub validate_and_return_data {
    my ($self, $arg, $list_schema) = @_;
    return $self->validate_list_and_return_data($list_schema, $arg);
}

sub validate_list_and_return_data {
    my ($self, $list_schema, @args) = @_;
  
    my $can_end_early;
    my @schemata = is_ar($list_schema) ? @{$list_schema} : ($list_schema); # one or more
    for my $i (0 .. $#schemata) {
        my $debug = $self->get_debug("schema #$i");
        if(my $quantifier = $schemata[$i]->{quantifier}) {
            if($quantifier eq '?') {
                $can_end_early = 1;
            }
            else {
                carp "currently not supported quantifier, ignoring: " . dump($quantifier);
            }
        }
        elsif($can_end_early) {
            carp qq{$debug should contain quantifier "?" because schema #} . ($i-1). q{ does (just sayin')};
        }
        if($#args < $i) {
            if(!$can_end_early) {
                confess "$debug missing arg #$i " . dump @schemata;
            }
            
            #below are optional args:
            if(exists $schemata[$i]->{default}) {
                $args[$i] = $schemata[$i]->{default};
            }
            elsif(undef_safe_eq($schemata[$i]->{type}, 'object') || $schemata[$i]->{properties}) { # it's an object
                $args[$i] = {};  # e.g. Umann::Image->rotate called without args will result in empty hash ref arg that will be filled with defaults below
            }
            elsif(undef_safe_eq($schemata[$i]->{type}, 'array') || $schemata[$i]->{items}) { # it's an array
                $args[$i] = [];  
            }
            else {
                last; # no default, leave it as it is
            }
        }
        if(my @rv = Umann::JSON::Validator::SetDefaults->new->validate($args[$i], $schemata[$i], {debug => $debug})) {
            croak join q{ }, @rv;
        }
    }
    $self->set_debug;
    return wantarray ? @args : shift @args;
}

1;

__END__
