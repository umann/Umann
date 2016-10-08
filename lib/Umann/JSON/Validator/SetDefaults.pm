package Umann::JSON::Validator::SetDefaults;

use 5.010000;

use strict;
use warnings;

our $VERSION = '0.01';

use parent qw(JSON::Validator);

use Umann::Scalar::Util qw(is_ar is_hr);
use Umann::Util qw(deep_copy);
use Carp qw(carp croak confess longmess);
use Data::Dump qw(dump);

# overrides JSON::Validator::validate
#  1. accepts {} as empty schema
#  2. calls JSON::Validator::validate that will use overridden _validate_type_object to set defaults
#  3. calls JSON::Validator::validate again with defaults set (if p_hr->{insane} is false)

sub set_debug {
    my $self = shift;
    return $self->{debug} = shift;
}

sub get_debug {
    my $self  = shift;
    my $extra = shift;
    return join q{ }, map { $_ // () } $self->{debug}, $extra;
}

sub validate_and_return_data {
    my ($self, $data, $schema, $p_hr) = @_;
    if(my @errors = $self->validate($data, $schema, $p_hr)) {
        croak join "\n", @errors;
    }
    return $data;
}
    
sub validate {
    my ($self, $data, $schema, $p_hr) = @_;
    if(is_hr($schema) && !%{$schema}) { # empty schema, passes everything
        return; # no error
    }
    if(my @errors = $self->SUPER::validate($data, deep_copy($schema))) {
        return @errors;
    }
    
    $p_hr //= {};

    my $debug = $p_hr->{debug} // __PACKAGE__;    
    
    if(!$p_hr->{insane}) {
        return map { "$debug with defaults: $_" } $self->SUPER::validate($data, deep_copy($schema));
    }
    return;
}

# overrides JSON::Validator::_validate_type_object 
#  1. calls JSON::Validator::_validate_type_object
#  2. sets defaults

sub _validate_type_object {
    my ($self, $data, $path, $schema) = @_;
    $SIG{__DIE__} = \&confess;
    if(my @errors = $self->SUPER::_validate_type_object($data, $path, $schema)) {
        return @errors;
    }
    for my $k (keys %{$schema->{properties} // {}}) {
        if (!exists $data->{$k} and exists $schema->{properties}{$k}{default}) {
            $data->{$k} = $schema->{properties}{$k}{default};
        }
    }
    return;
}

1;

__END__

#sub set_defaults_and_validate {
    my ($self, $data, $schema, $p_hr) = @_;
    
    $p_hr //= {};

    my $debug = $p_hr->{debug} // __PACKAGE__;
    
    if(my @errors = $self->validate($data, deep_copy($schema))) {
        confess join q{ }, $debug, @errors;
    }
    
    if(!$p_hr->{insane}) {
        if(my @errors2 = $self->validate($data, deep_copy($schema))) {
            confess join q{ }, "$debug with defaults", @errors2;
        }
    }
    return $data;
}

sub _set_defaults {
    my ($self, $data, $schema) = @_;

    if($schema->{properties}) {
        return $self->_set_defaults_of_object($data, $schema->{properties});
    }
    if($schema->{items}) {
        return $self->_set_defaults_of_array($data, $schema->{items});
    }
    return $data;
}

sub _set_defaults_of_object {
    my ($self, $data, $properties_hr) = @_;
    
    #JSON::Validator accepts e.g. {multipleOf => 90, properties => { ..}} if type is not explicitly set
    if(!is_hr($data)) {
        confess 'data should be HASH ref, not ' . dump $data;
    }

    my $rv = deep_copy($data); # not to modify original
    for my $property (sort keys %{$properties_hr}) {
        if(!exists $rv->{$property} && exists $properties_hr->{$property}{default}) {
            $rv->{$property} = $properties_hr->{$property}{default};
        }
    }
    return $rv;
}

sub _set_defaults_of_array {
    my ($self, $data, $item_hr) = @_;
    
    #JSON::Validator accepts e.g. {multipleOf => 90, items => { ..}} if type is not explicitly set
    if(!is_ar($data)) {
        confess 'data should be ARRAY ref, not ' . dump $data;
    }
    return [ map { $self->_set_defaults($_, $item_hr) } @{$data} ]
}

