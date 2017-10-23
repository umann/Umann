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
use Readonly;

Readonly my $ANY_DEFAULT_SET => 'X-umann-any_default_set';

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
    if (my @errors = $self->validate($data, $schema, $p_hr)) {
        croak join "\n", @errors;
    }
    return $data;
}

sub validate {
    my ($self, $data, $schema, $p_hr) = @_;

    if (is_hr($schema) && !%{$schema}) {  # empty schema, passes everything
        return;                           # no error
    }

    delete $self->{$ANY_DEFAULT_SET};
    if (my @errors = $self->SUPER::validate($data, deep_copy($schema))) {
        return @errors;
    }

    $p_hr //= {};

    my $debug = $p_hr->{debug} // __PACKAGE__;

    if ($self->{$ANY_DEFAULT_SET} && !$p_hr->{insane}) {
        return
            map { "$debug with defaults: $_" }
            $self->SUPER::validate($data, deep_copy($schema));
    }

    return;
}

# overrides JSON::Validator::_validate_type_object
#  1. calls JSON::Validator::_validate_type_object
#  2. sets defaults

## no critic(ProhibitUnusedPrivateSubroutines)
sub _validate_type_object {
## use critic
    my ($self, $data, $path, $schema) = @_;
    local $SIG{__DIE__} = \&confess;
    if (my @errors = $self->SUPER::_validate_type_object($data, $path, $schema))
    {
        return @errors;
    }
    for my $k (keys %{ $schema->{properties} // {} }) {
        if (!exists $data->{$k} && exists $schema->{properties}{$k}{default}) {
            $data->{$k}               = $schema->{properties}{$k}{default};
            $self->{$ANY_DEFAULT_SET} = 1;
        }
    }
    return;
}

1;

__END__
