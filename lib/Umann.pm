package Umann;

use 5.010;

use strict;
use warnings;

our $VERSION = 0.001;

use Carp;
use Data::Dump qw(dump);
use Scalar::Util qw(blessed);

use Umann::Scalar::Util qw(is_hr);
use Umann::Util qw(deep_copy);

my $global_errstr;

sub new {
    my @args = @_;

    my $this = shift @args;
    my $arg  = shift @args;

    my $class = ref $this || $this;
    my $self = deep_copy($arg) || {};

    if (!is_hr($self)) {
        croak 'arg must be HASH ref: ' . dump $self;
    }
    if (@args) {
        carp 'further args ignored: ' . dump @args;
    }
    if ($self->{__test_failed_new__}) {
        return set_errstr('errstr for __test_failed_new__');
    }
    return bless $self, $class;
}

sub set_errstr {
    my $self = shift;
    $global_errstr = shift;

    # called as function:
    if (!blessed $self) {
        $global_errstr = $self;  # unshift
        return;
    }

    # called as method:
    if ($self->{RaiseError}) {
        croak $global_errstr;
    }
    if ($self->{PrintError} || !exists $self->{PrintError}) {
        carp $global_errstr ;
    }

    $self->{errstr} = $global_errstr;
    return;
}

sub errstr {
    my $that = shift;
    return blessed $that ? $that->{errstr} : $global_errstr;
}

1;

__END__

=head1 NAME

Umann - parent class of Umann::... classes

=head1 VERSION

This document describes Umann version 0.0.1

=head1 SYNOPSIS

  package Umann::Whatever

  use parent qw(Umann);

  ...

  use Umann::Whatever;

  my $uw = Umann::Whatever->new({foo => 'bar'}) || die Umann::Whatever->errstr;
  $uw->fornicate || die $uw->errstr;

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 Class methods

=over

=item new

Creates a new Umann object. It takes an optional hashref argument with initial values of object

 my $u = Umann->new({foo => 'bar'});

Note that currently the hash ref is not deep copied so modifying object values will modify original lvalue:

 my $hashref = {foo => 'bar'};
 my $u = Umann->new($hashref);
 $u->{foo} = 'baz';
 print $hashref->{foo}; # baz, not bar

=item errstr

Takes no argument. Returns last error string of the class (or undef if none)

 my $u = Umann->new || die Umann::errstr;

=back

=head2 Object methods

=over

=item errstr

Takes no argument. Returns last error string of the object (or undef if none)

 my $uw = Umann::Whatever->new;
 $uw->fornicate || die $uw->errstr;

=item set_errstr

Takes a string as argument.
Prints string to STDERR if PrintError was set.
Carps if RaiseError was set.
Returns undef if RaiseError was not set.

 my $uw = Umann::Whatever->new;
 $uw->fornicate || warn $uw->errstr;

 my $uw = Umann::Whatever->new({RaiseError => 1};
 try {
    $uw->fornicate
 }
 catch {
    ...
 }

=back

=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate
(even the ones that will "never happen"), with a full explanation of each
problem, one or more likely causes, and any suggested remedies.
(See also "Documenting Errors" in Chapter 13.)

If hash ref arg of new() contains a true __test_failed_new__ key then new() returns false and errstr is set to 'errstr for __test_failed_new__' (or carps if RaiseError is set in args)

=head1 CONFIGURATION AND ENVIRONMENT

None

=head1 DEPENDENCIES

=item Scalar::Util

=head1 INCOMPATIBILITIES

No known.

=head1 BUGS AND LIMITATIONS

No known.

=head1 AUTHOR

E<lt>perl(GuessWhat)umann(GuessAgain)hu<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016 by Kornel Umann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
