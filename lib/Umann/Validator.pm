package Umann::Validator;

use 5.010000;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp qw(croak carp confess cluck);
use Data::Dump qw(dump);
use Scalar::Util qw(blessed);

use Umann::JSON::Validator::OfList;
use Umann::List::Util qw(is_in);
use Umann::Scalar::Util qw(is_ar);

use Exporter qw(import);

our @EXPORT_OK = qw(
    enum_0th_default
    validate_func
    validate_method
    validate_obj_method
    validate_class_method
);

sub enum_0th_default {
    my @args = @_;

    if(scalar @args == 1 && is_ar($args[0])) {
        @args = @{$args[0]};
    }
    if(!@args) {
        confess 'enum_0th_default called with empty list'
    }

    return (enum => [@args], default => $args[0]);
}

sub validate_func {
    my @args = @_ or confess 'no arg';

    my @rv = _validate_sub(@args);

    return wantarray ? @rv : shift @rv;
}

sub validate_method {
    my @args = @_;

    my($list_schema, $obj_or_class, @etc) = @args;
    my @rv = ($obj_or_class, _validate_sub(_check_obj_or_class({obj => 1, class => 1}, @args)));

    return wantarray ? @rv : shift @rv;
}

sub validate_obj_method {
    my @args = @_;

    my($list_schema, $obj_or_class, @etc) = @args;
    my @rv = ($obj_or_class, _validate_sub(_check_obj_or_class({obj => 1}, @args)));

    return wantarray ? @rv : shift @rv;
}

sub validate_class_method {
    my @args = @_;

    my($list_schema, $obj_or_class, @etc) = @args;
    my @rv = ($obj_or_class,_validate_sub(_check_obj_or_class({class => 1}, @args)));

    return wantarray ? @rv : shift @rv;
}

sub _check_obj_or_class {
    my @args = @_;
    
    if(@args < 3) {
        confess 'not enough args: first should be list_schema, last should be obj/class';
    }
    
    my ($p_hr, $list_schema, $obj_or_class, @etc) = @args; 

    (my $package = (caller 2)[3]) =~ s/^(.*)::.*$/$1/; # 2 because this is called by one of the validate_*method() functions
    
    my $ref   = ref  $obj_or_class;
    my $debug = dump $obj_or_class;
    
    if($ref) {
        if(!$p_hr->{obj}) {
            confess "not class name: $debug";
        }
        if(!blessed $obj_or_class) {
            confess "not blessed but ref $ref: $debug";
        }
        if(!$obj_or_class->isa($package)) {
            confess "not isa($package) - probably should have been called as method: $ref";
        }
    }
    else {
        if(!$p_hr->{class}) {
            confess "not object: $debug";
        }
        if(!looks_like_class_name($obj_or_class)) {
            confess "not class name: $debug";
        }
    }
    return ($list_schema, @etc);
}

sub _validate_sub {
    my @args = @_;
    
    my $list_schema = shift @args;
    
    my $ref = ref $list_schema;
    if(!is_in($ref, ref [], ref {})) {
        confess "ref list_schema should be ARRAY or HASH, not `$ref`";
    }
    
    my $package_sub = (caller 2)[3]; # 2 because this is called by either validate_func() or validate_method()
    if((caller 1)[3] =~ /method/) {
        $package_sub =~ s/(.*)::/$1->/;
    }
    
    my $list_validator = Umann::JSON::Validator::OfList->new;
    $list_validator->set_debug($package_sub);
    
    say dump $list_schema, @args;
    return $list_validator->validate_list_and_return_data($list_schema, @args); # validate will reset debug
}

1;

__END__

# sub validate_sub_args {
#     my @args = @_;
#     my($package, $sub) = (caller 1)[3] =~ /^(.*)::(.*)$/;
#     no strict 'refs';
#     my %validate_sub_args = %{$package . '::VALIDATE_SUB_ARGS'} or return;
#     use strict 'refs';
#     my $package_sub = $package . '::' . $sub;
#     my $can_end_early;
#     my @rv;
#     if(my $schemata = $validate_sub_args{$sub}) {
#         my @schemata = is_ar($schemata) ? @{$schemata} : ($schemata); # one or more
#         for my $i (0 .. $#schemata) {
#             if(my $repeat = $schemata[$i]->{quantifier}) {
#                 if($repeat eq '?') {
#                     $can_end_early = 1;
#                 }
#                 else {
#                     carp("$package_sub currently not supported quantifier:" . dump($repeat));
#                 }
#             }
#             if($#args < $i) {
#                 last if($can_end_early);
#                 confess "$package_sub missing arg $i";
#             }
#             push @rv, Umann::JSON::Validator::SetDefaults->new->set_defaults_and_validate($args[$i], $schemata[$i], {debug => "$package_sub arg #$i"});
#         }
#         return;
#     }
#     die "No list_schema for $package_sub";
# }

#    validate_sub_args

    my $can_end_early;

    my @list_schema = $ref eq ref [] ? @{$list_schema} : ($list_schema); # one or more
    for my $i (0 .. $#list_schema) {
        my $debug = "$package_sub list_schema #$i";
        if(my $repeat = $list_schema[$i]->{quantifier}) {
            if($repeat eq '?') {
                $can_end_early = 1;
            }
            else {
                carp "$debug currently not supported quantifier, ignoring: " . dump($repeat);
            }
        }
        elsif($can_end_early) {
            carp "$debug should contain some quantifier {0,} because previous list_schema(s) did (just sayin')";
        }
        if($#args < $i) {
            if(!$can_end_early) {
                confess "$package_sub missing arg $i " . dump @list_schema;
            }
            #below are optional args.
            
            if(undef_safe_eq($list_schema[$i]->{type}, 'object') || $list_schema[$i]->{properties}) { # it's an object
                $args[$i] = {};  # e.g. Umann::Image->rotate called without args will result in empty hash ref arg that will be filled with defaults below
            }
            else {
                last;
            }
        }
        my $A = $args[$i];
        my $v = $list_schema[$i];
        if(my @rv = Umann::JSON::Validator::SetDefaults->new->validate($A, $v, {debug => "$package_sub arg #$i"})) {
            croak join q{ }, @rv;
        }
    }
    return wantarray ? @args : shift @args;
