package Umann::Validator;

use 5.010000;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp qw(croak carp confess cluck);
use Data::Dump qw(dump);
use Readonly;
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

Readonly my $CALLER_SUBROUTINE => 3;

sub enum_0th_default {
    my @args = @_;

    if (scalar @args == 1 && is_ar($args[0])) {
        @args = @{ $args[0] };
    }
    if (!@args) {
        confess 'enum_0th_default called with empty list';
    }

    return (enum => [@args], default => $args[0]);
}

sub validate_func {
    my @args = @_;
    if (!@args) {
        confess 'no arg';
    }

    my @rv = _validate_sub(@args);

    return wantarray ? @rv : shift @rv;
}

sub validate_method {
    my @args = @_;

    my ($list_schema, $obj_or_class, @etc) = @args;
    my @rv = (
        $obj_or_class,
        _validate_sub(_check_obj_or_class({ obj => 1, class => 1 }, @args))
    );

    return wantarray ? @rv : shift @rv;
}

sub validate_obj_method {
    my @args = @_;

    my ($list_schema, $obj_or_class, @etc) = @args;
    my @rv = ($obj_or_class,
        _validate_sub(_check_obj_or_class({ obj => 1 }, @args)));

    return wantarray ? @rv : shift @rv;
}

sub validate_class_method {
    my @args = @_;

    my ($list_schema, $obj_or_class, @etc) = @args;
    my @rv = (
        $obj_or_class, _validate_sub(_check_obj_or_class({ class => 1 }, @args))
    );

    return wantarray ? @rv : shift @rv;
}

sub _check_obj_or_class {
    my @args = @_;

    if (@args <= 2) {
        confess
'not enough args: first should be list_schema, last should be obj/class';
    }

    my ($p_hr, $list_schema, $obj_or_class, @etc) = @args;

    (my $package = (caller 2)[$CALLER_SUBROUTINE]) =~ s/^(.*)::.*$/$1/smx
        ;  # 2 because this is called by one of the validate_*method() functions

    my $ref   = ref $obj_or_class;
    my $debug = dump $obj_or_class;

    if ($ref) {
        if (!$p_hr->{obj}) {
            confess "not class name: $debug";
        }
        if (!blessed $obj_or_class) {
            confess "not blessed but ref $ref: $debug";
        }
        if (!$obj_or_class->isa($package)) {
            confess
"not isa($package) - probably should have been called as method: $ref";
        }
    }
    else {
        if (!$p_hr->{class}) {
            confess "not object: $debug";
        }
        if (!looks_like_class_name($obj_or_class)) {
            confess "not class name: $debug";
        }
    }
    return ($list_schema, @etc);
}

sub _validate_sub {
    my @args = @_;

    my $list_schema = shift @args;

    my $ref = ref $list_schema;
    if (!is_in($ref, ref [], ref {})) {
        confess "ref list_schema should be ARRAY or HASH, not `$ref`";
    }

    my $package_sub = (caller 2)[$CALLER_SUBROUTINE]
        ; # 2 because this is called by either validate_func() or validate_method()
    if ((caller 1)[$CALLER_SUBROUTINE] =~ /method/smx) {
        $package_sub =~ s/(.*)::/$1->/smx;
    }

    my $list_validator = Umann::JSON::Validator::OfList->new;
    $list_validator->set_debug($package_sub);

    return $list_validator->validate_list_and_return_data($list_schema, @args)
        ;  # validate will reset debug
}

1;

__END__
