package Umann::Image;

use 5.010000;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp qw(croak carp confess cluck);
use Data::Dump qw(dump);
use File::Slurp;
use Scalar::MoreUtils qw(define);
use Readonly;
use Image::ExifTool qw(ImageInfo);
use Image::Magick;
use File::Temp ();

use Umann::List::Util qw(is_in);
use Umann::Util qw(deep_copy);
use Umann::Scalar::Util qw(is_cr is_sr);
use Umann::Validator qw(enum_0th_default validate_obj_method);

Readonly my $JSON_SCHEMA_SCALAR => ['number', 'string', 'null'];
Readonly my $JSON_SCHEMA_PERL_BOOL => $JSON_SCHEMA_SCALAR;
Readonly my %JSON_SCHEMA_PERL_BOOL => (type => $JSON_SCHEMA_SCALAR);
Readonly my %JSON_SCHEMA_FILE_NAME => (type => 'string', pattern => '^([a-zA-Z]:|/|\\|//|\\\\)?(([a-zA-Z0-9.-_])+[/\\])*([a-zA-Z0-9.-_])+[.][jJ][pP][eE]?[gG]$');
Readonly my %JSON_SCHEMA_CONTENT => (type => 'string');

Readonly my $THUMB_SMALLER => 120;
Readonly my $THUMB_CREATE_LIMIT_SMALLER => 4 * $THUMB_SMALLER;


my $YYYY_MM_DD_HH_MM_SS_RE = qr/^(\d{4})\D*(\d{2})\D*(\d{2})\D*(\d{2})\D*(\d{2})\D*(\d{2})/smx; # cannot Readonly regexp

Readonly my @EXIFTOOL_OPTIONS = (
    Group0 => ['EXIF', 'File', 'MakerNotes', 'MWG' , 'Composite', 'XMP', 'IPTC', 'XMP-mwg-coll', 'XMP-mwg-kw', 'XMP-mwg-rs'],
    Unknown => 1,
    Struct => 1,
    (map { $_ => 'Latin2'} qw(CharsetEXIF CharsetIPTC)),
    (map { $_ => 'UTF8'} qw(Charset CharsetID3 CharsetPhotoshop CharsetQuickTime))
);

Readonly my %CW_DEGREES_TO_EXIF_ORIENTATION => (
    0 => 'Horizontal (normal)',
    180 => 'Rotate 180'         ,
    90 => 'Rotate 90 CW'       ,
    270 => 'Rotate 270 CW'      ,
);
Readonly my %EXIF_ORIENTATION_TO_CW_DEGREES => reverse %CW_DEGREES_TO_EXIF_ORIENTATION;
Readonly my %CW_DEGREES_TO_MAKERNOTES_AUTOROTATE => (
    0 => 'None'         ,
    180 => 'Rotate 180'   ,
    90 => 'Rotate 90 CW' ,
    270 => 'Rotate 270 CW',
);
Readonly my %ROTATE_NAME_TO_CW_DEGREES => reverse(%CW_DEGREES_TO_EXIF_ORIENTATION, %CW_DEGREES_TO_MAKERNOTES_AUTOROTATE);

use parent qw(Umann);

sub get_filename {
    my @args = @_;

    my $self = validate_obj_method([], @args);

    return $self->{filename};
}

sub set_filename {
    my @args = @_;

    my ($self, $filename) = validate_obj_method(
        {
            %JSON_SCHEMA_FILE_NAME,
        },
        @args
    );

    return $self->{filename} = $filename;
}

sub set_content {
    my @args = @_;

    my ($self, $content) = validate_obj_method(
        {
            %JSON_SCHEMA_CONTENT
        },
        @args
    );

    return $self->{content} = $content;
}

sub get_content {
    my $self = shift;

    return $self->{content} //= $self->read_content(@_);
}

sub read_content {
    my @args = @_;

    my ($self, $filename) = validate_obj_method(
        {
            quantifier => '?',
            %JSON_SCHEMA_FILE_NAME,
        },
        @args
    );

    $filename //= $self->get_filename;

    return read_file($filename, { binmode => ':raw' });
}

sub get_content_ref {
    my @args = @_;

    my $self = validate_obj_method([], @args);

    my $content = $self->get_content;

    return \$content;
}

sub write_content {
    my @args = @_;

    my ($self, $p_hr) = validate_obj_method(
        {
            type => 'object',
            additionalProperties => 0,
            quantifier => '?',
            properties => {
                content  => { %JSON_SCHEMA_CONTENT   },
                filename => { %JSON_SCHEMA_FILE_NAME },
            },
        },
        @args
    ) ;

    return write_file($p_hr->{filename} // $self->get_filename, { binmode => ':raw' }, $p_hr->{content} // $self->get_content);
}

sub get_thumb {
    my $self    = shift;

    return Image::ExifTool::ImageInfo($self->get_content_ref, 'thumbnailimage')->{ThumbnailImage};
}

sub rotate {
    my @args = @_;

    my ($self, $p_hr) = validate_obj_method(
        {
            type => 'object',
            quantifier => '?',
            additionalProperties => 0,
            properties => {
                cw_degrees => {
                    type       => 'number',
                    multipleOf => 90,
                    default    => 0,
                },
                auto => {
                    %JSON_SCHEMA_PERL_BOOL,
                    default => 1,
                },
                orientation => {
                    enum_0th_default('auto', 'Horizontal (normal)', 'Rotate 180', 'Rotate 90 CW', 'Rotate 270 CW', undef),
                },
            },
            additionalProperties => 0
        },
        @args
    );  
    
    $p_hr = deep_copy($p_hr) // {};
    
    my $exif_hr          = $self->get_exif_hr({simple => 1});
    my $exif_orientation = $exif_hr->{Orientation} // $exif_hr->{AutoRotate};
    
    if($p_hr->{auto} && !$exif_orientation) {
        $self->set_warning('No metadata found for auto rotate');
        $p_hr->{auto} = 0;
    }

    my $cw_degrees_orientation = 
        !defined $exif_orientation 
        ? 0 
        : $ROTATE_NAME_TO_CW_DEGREES{$exif_orientation} // do {
            return 
                  $self->set_error('Unknown orientation in metadata' 
                . dump $exif_orientation, hrslice($exif_hr, 'Orientation', 'AutoRotate'));
          }
    ;  # end of do

    my $cw_degrees_direct = $p_hr->{cw_degrees}; # // 0 not needed because there is default; 
    my $cw_degrees = ($cw_degrees_direct + $cw_degrees_orientation) % 360;

    my $set_exif_hr = {};

    if(!defined $p_hr->{orientation}) { # exists but undef
        if($exif_orientation) {
            $set_exif_hr->{Orientation} = undef;
            $set_exif_hr->{AutoRotate } = undef;
        }
    }
    elsif($p_hr->{orientation} eq 'auto') {
        my $cw_degrees_direct_revert = (-$cw_degrees_direct) % 360;
        $set_exif_hr->{Orientation} = $CW_DEGREES_TO_EXIF_ORIENTATION{$cw_degrees_direct_revert};
        $set_exif_hr->{AutoRotate } = $CW_DEGREES_TO_MAKERNOTES_AUTOROTATE{$cw_degrees_direct_revert};
    }
    elsif(my $deg = $EXIF_ORIENTATION_TO_CW_DEGREES{$p_hr->{orientation}}) {
        $set_exif_hr->{Orientation} = $CW_DEGREES_TO_EXIF_ORIENTATION{$deg};
        $set_exif_hr->{AutoRotate } = $CW_DEGREES_TO_MAKERNOTES_AUTOROTATE{$deg};
    }

    if(!$exif_hr->{AutoRotate}) {
        delete $set_exif_hr->{AutoRotate };
    }

    if($cw_degrees || %{$set_exif_hr}) {
        $set_exif_hr->{ThumbnailImage} = 
            $self->_rotate_and_return_thumb($cw_degrees)
        ;
    }
    $self->set_exiftool_values($set_exif_hr);
        
    return $self;
}

sub __get_new_thumb_dims_hash {
    my $magick_image = shift;
    my ($width, $height) = $magick_image->Get('width', 'height');
    
    my %rv;
    
    if($width > $THUMB_CREATE_LIMIT_SMALLER && $height > $THUMB_CREATE_LIMIT_SMALLER) {
        if($width > $height) {
            $rv{height} = $THUMB_SMALLER;
            $rv{width}  = int($width / $height * $rv{height});
        }
        else {
            $rv{width}  = $THUMB_SMALLER;
            $rv{height} = int($height / $width * $rv{width});
        }
    }
    
    return %rv;
}

# do not mix up with set_exiftool_values that does not expect $exiftool as arg
sub _set_exiftool_values {
    my $self     = shift;
    my $exiftool = shift;
    my $exif_hr  = shift;

    for my $key (sort keys %{$exif_hr}) {
        my $val = $exif_hr->{$key}; # do not use perl's each
        if(!defined $val) {
            $exiftool->DeleteTag($key)
        }
        else {
            $exiftool->SetNewValue($key => $val, $key eq 'ThumbnailImage' ? (Type => 'ValueConv') : ());
        }
    }
    return $self;
}

# returns rotated thumb (if created)
sub _rotate_and_return_thumb {
    my $self       = shift;
    my $cw_degrees = shift;
    
    return $self->do_frame(magick => __rotate_with_magick_and_return_thumb => $cw_degrees);
}

# returns rotated thumb (if created)
sub __rotate_with_magick_and_return_thumb {
    my $self = shift;
    my $magick_image = shift;
    my $cw_degrees   = shift;
    
    if($cw_degrees) {
        $magick_image->Write('before.jpg');
        $magick_image->Rotate(degrees => $cw_degrees);
        $magick_image->Write('after.jpg');
    }
    if(my %thumb_dims = __get_new_thumb_dims_hash($magick_image)) {
        my $magick_thumb = $magick_image->Clone;
        $magick_thumb->Thumbnail(%thumb_dims);
        return +($magick_thumb->ImageToBlob)[0];
    }
    return;
} 

# do not mix up with _set_exiftool_values that expects $exiftool as arg
sub set_exiftool_values {
    my $self = shift;   
    my @args = @_;

    my %hash = 1 == scalar @args ? %{$args[0] // {}} : @args;
    
    if(%hash) {
        $self->do_frame(exiftool => _set_exiftool_values => \%hash);
    }
    return $self;
}

sub _do_tmp {
    my $self = shift;
    my $sub = shift;
    my $tmp = File::Temp->new(SUFFIX => '.jpg')->filename; # .jpg is just to make debugging easier, not used otherwise. TODO: Use the exact ext (if it's not a jpeg file)
    $self->write_content({filename => $tmp});
    $sub->($self, $tmp);
    unlink $tmp || carp "unlink $tmp: $!";
}

sub do_frame {
    my $self            = shift;
    my $frame           = shift; # 'exiftool' or 'magick'
    my $method_or_func  = shift; # of current class
    my @args_for_method = @_;    # rest is optional
    
    my @rv;
    
    my $_new_method = "_new_$frame";
    my $frame_obj = $self->$_new_method; # _new_magick or _new_exiftool
    
    my @all_args  = ($frame_obj, @args_for_method);
    
    if(is_cr($method_or_func)) {
        my $sub = $method_or_func;
        @rv = wantarray ? $sub->(@all_args) : (scalar $sub->(@all_args));
    }
    else { 
        if(ref $method_or_func) {
            croak dump $method_or_func;
        }
        my $method = $method_or_func; # method name of Umann::Image (or inherited) object. Method will get exiftool or magick object as 1st arg then the optional ones.
        @rv = wantarray ? $self->$method(@all_args) : (scalar $self->$method(@all_args));
    }

    my $_end_method = "_end_$frame";
    $self->$_end_method($frame_obj);
    
    return wantarray ? @rv : $rv[0];
}

sub _new_exiftool {
    my $self         = shift;

    my $exiftool = Image::ExifTool->new;
    $exiftool->Options($self->get_exiftool_options);
    $self->{exiftool} = $exiftool;
    return $exiftool;
}

sub _end_exiftool {
    my $self = shift;
    my $exiftool = shift // $self->{exiftool};

    $self->_do_tmp( sub {
        my($self, $tmp) = @_;
        $exiftool->WriteInfo($tmp);
        delete $self->{exif_hr};
        delete $self->{content};
        $self->get_content($tmp);
    });

    return $self;
}

sub _new_magick {
    my $self         = shift;

    my $magick_image = Image::Magick->new;
    if(define($self->{info_src}) eq 'file') {
        $self->_set_errstr_if_true($magick_image->Read($self->get_filename));
    }
    else {
        # IDKW BlobToImage does not work for embedded thumbnails. Must write to file and read from there.
        if($magick_image->BlobToImage($self->get_content)) { # true means error
            $self->_do_tmp( sub {
                my($self, $tmp) = @_;
                $self->_set_errstr_if_true($magick_image->Read($tmp));
            });
        }
    }
    return $self->{magick_image} = $magick_image;
}

sub _end_magick {
    my $self         = shift;
    my $magick_image = shift // $self->{magick_image};

    $self->set_content(($magick_image->ImageToBlob)[0]);

    $magick_image->DESTROY;

    delete $self->{magick_image};
    delete $self->{exif_hr};

    return $self;
}

sub _set_errstr_if_true {
    my $self = shift;
    my $x    = shift // return;

    carp dump $x;
}

sub get_exif_hr {
    my @args = @_;
    my ($self, $p_hr) = validate_obj_method(
        {
            type => 'object',
            additionalProperties => 0,
            properties => {
                umann => {
                    %JSON_SCHEMA_PERL_BOOL,
                },
                flat => {
                    %JSON_SCHEMA_PERL_BOOL,
                },
                simple => {
                    %JSON_SCHEMA_PERL_BOOL,
                },                
                binary => {
                    %JSON_SCHEMA_PERL_BOOL,
                    default => 1
                },
            },
        },
        @args
    );

    my @options = $self->get_exiftool_options;

    # dump is used to serialize settings:
    return $self->{exif_hr_hr}{dump $p_hr, @options} //= do {
        my $hr;
        my $exiftool = new Image::ExifTool;
        $exiftool->Options(@options);
        my $info = $exiftool->ImageInfo(
              define($self->{info_src}) eq 'file'
            ? $self->get_filename
            : $self->get_content_ref
        );
        for my $tag ($exiftool->GetFoundTags('Group0')) {
            my $group = $exiftool->GetGroup($tag);
            my $val = $info->{$tag};
            $tag =~s/ \(\d+\)\z//smx; #UK2014dec23
            if (is_sr($val)) {
                if(!$p_hr->{binary}) {
                    return; # do not return huge thumbnail if binary is false
                }
                $val = ${$val};
            }
            $hr->{"$group.$tag"} = $val;
        }
        if($p_hr->{umann}) {
            $hr = {%{$hr}, %{$self->_get_umann_of_exif_hr($hr)}};
        }
        if(!$p_hr->{flat} && !$p_hr->{simple}) {
            $hr = __unflatten_exif_hr($hr);
        }
        if($p_hr->{simple}) {
            $hr = __simplify_exif_hr($hr);
        }
        $hr;
    }; #end of do
}

sub __unflatten_exif_hr {
    my $exif_hr = shift // {};

    my $rv_hr = \%{$exif_hr}; # 1-level-deep copy
    for my $key (sort keys %{$exif_hr}) {
        if($key =~ /\A(.+)[.](.+)\z/smx) {
            $rv_hr->{$1}{$2} = $exif_hr->{$key};
        }
    }
    return $rv_hr;
}

sub __simplify_exif_hr {
    my $exif_hr = shift // {};

    my $rv_hr = \%{$exif_hr}; # 1-level-deep copy
    for my $key (sort keys %{$exif_hr}) {
        if($key =~ /\A.+[.](.+)\z/smx) {
            $rv_hr->{$1} = $exif_hr->{$key};
        }
    }
    return $rv_hr;
}

sub _get_umann_of_exif_hr {
    my $self = shift;
    my $exif_hr = shift;
    my $umann_hr = {};

=pod

    my %shot = (
        local => $exif_hr->{'EXIF.DateTimeOriginal'},
        gm => $exif_hr->{'Composite.GPSDateTime'},
    )

   #my $tz_assumed = 0;
   #if (my $ts_local = my_timelocal($shot{local}) {
   #    my $ts_local_as_gm = my_timegm($shot{local};
   #    if (my $ts_gm = my_timegm($shot{gm}) {
   #        $diffsec = $ts_local_as_gm - $ts_gm;
   #    }
   #    else {
   #        $diffsec = $ts_local_as_gm - $ts_local; # TODO: sure???
   #        $tz_assumed = 1;
   #    }
   #}
    if(define($exif_hr->{'EXIF.DateTimeOriginal'}) =~ /$YYYY_MM_DD_HH_MM_SS_RE/smx)
    {
        my $shot = "$1-$2-$3 $4:$5:$6";
        my($year_localtime, $mon1_localtime, $mday_localtime, $hour_localtime, $min_localtime, $sec_localtime) = ($1, $2, $3, $4, $5, $6);
        my $mon0_localtime = $mon1_localtime - 1;
        my $timestamp;
        my $diffsec;
        if(define($exif_hr->{'Composite.GPSDateTime'}) =~ /$YYYY_MM_DD_HH_MM_SS_RE/smx)
        {
            # we have a real GMT shoot time
            my ($year_gmtime, $mon1_gmtime, $mday_gmtime, $hour_gmtime, $min_gmtime, $sec_gmtime) = ($1, $2, $3, $4, $5, $6);
            my $mon0_gmtime = $mon1_gmtime - 1;
            my $timestamp_gmtime = timegm($sec_gmtime, $min_gmtime, $hour_gmtime, $mday_gmtime, $mon0_gmtime, $year_gmtime);
            my $timestamp_localtime_fake = timegm($sec_localtime, $min_localtime, $hour_localtime, $mday_localtime, $mon0_localtime, $year_localtime); #fake, mert gmtime-mal szamolunk localtime-ot, csak a diffsec kiszamitasahoz kell
            $timestamp = $timestamp_gmtime;
            $diffsec = $timestamp_localtime_fake - $timestamp_gmtime;
        }
        else
        {
            #no real GMT shoot time, we assume time is localtime
            my $timestamp_localtime = timelocal($sec_localtime, $min_localtime, $hour_localtime, $mday_localtime, $mon0_localtime, $year_localtime);
            my $timestamp_gmtime_fake = timegm($sec_localtime, $min_localtime, $hour_localtime, $mday_localtime, $mon0_localtime, $year_localtime); #fake because it's used for calculating diffsec only
            $timestamp = $timestamp_localtime;
            $diffsec = $timestamp_gmtime_fake - $timestamp_localtime;
            $umann_hr->{'Umann.IsTimeZoneAssumed'} = 1;
        }
        my $tz = diffsec2tz($diffsec);
        my $isdst = (localtime($timestamp))[8]; # not sure that time is in our localtime but w e do not have anything else
        $umann_hr->{'Umann.AssumedTimeZone'} = $tz;
        $umann_hr->{'Umann.AssumedIsDst'} = $isdst;
        $umann_hr->{'Umann.AssumedDateTimeWithTimeZone'} = "$shot $tz";
        $umann_hr->{'Umann.AssumedTimeStamp'} = $timestamp;
        if(!$umann_hr->{'Umann.IsTimeZoneAssumed'}) {
            for my $key (sort keys %{$umann_hr}) {
                if($key =~ /^(Umann[.])Assumed(.+)$/) {
                    $umann_hr->{$1.$2} = $umann_hr->{$key};
                }
            }
        }
        #my($md5_soul, $md5) = soul($jpg, ['md5_soul', 'md5']);
        #$umann_hr->{'Umann.Md5'} = $md5;
        #$umann_hr->{'Umann.Md5Soul'} = $md5_soul;
        $umann_hr->{'Umann.PrintOrientation'} = $exif_hr->{'File.ImageHeight'} > $exif_hr->{'File.ImageWidth'} ? 'Portrait' : 'Landscape';
    }

=cut

    return $umann_hr;
}

sub set_exiftool_options {
    my $self    = shift;
    my @options = @_;

    $self->{exiftool_options_ar} = [@options]; # not \@options so it won't change by surprise (at least the array elements)

    return @options;
}

sub get_exiftool_options {
    my $self = shift;

    $self->{exiftool_options_ar} //= \@EXIFTOOL_OPTIONS;

    return @{$self->{exiftool_options_ar}};
}

1;

__END__

=head1 NAME

Umann::Image - using PerlMaginck and ExifTool together

=head1 VERSION

This document describes version 0.0.1

=head1 SYNOPSIS

  use Umann::Image;

  my $ui = Umann::Image->new;

  $ui->read('image.jpg');

  $ui->rotate({auto => 1, ccw_degrees => 90, orientation => 'auto'})

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 Class methods

=item new

See L<Umann>

=head2 Object methods

=item rotate($params_hr)

Takes one HASH ref argument. Keys:

=over

=item auto

=over

=item Posibble values: value is considered as boolean

=item Default value: 1

=back

If TURE, rotates image accoring to Exif metadata Orientation. Warns if explicitly set to TRUE but no Orientation found.

=item cw_degrees

=over

=item Possible values: any multiple of 90.

=item Default value: 0

Rotates further (in addition to auto) clockwise.

=item orientation

=over

=item Possible values:

=over

=item     'auto'

=item     'Horizontal (normal)'

=item     'Rotate 180'

=item     'Rotate 90 CW'

=item     'Rotate 270 CW'

=item     undef (to delete both EXIF.Orientation and MakerNotes.Autorotate)

=back

=item Default value:

=over If Orientation found in EXIF metadata: auto

=over If Orientation not found in EXIF metadata: None

=back

Sets Orientation EXIF Metadata, and Canon's Autorotate makernote (if exists)

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

#sub write_binary_file {
#    my $self = shift;
#    my ($p_hr, @etc) = @_;
#    $p_hr //= {};
#    $p_hr = validate_sub_args($p_hr, $etc)
#
#    return write_file($p_hr->{filename} // $self->get_filename, { binmode => ':raw' }, $p_hr->{content} // $self->get_content);
#}

#sub _rotate_with_magick {
#    my $self       = shift;
#    my $cw_degrees = shift || return;
#    $self->do_magick(Rotate => degrees => $cw_degrees);
#    return $self;
#}

#sub _rotate_with_exiftool {
#    my $self      = shift;
#    my $exiftool  = shift;
#    my $p_hr      = shift;
#
#    # rotate embedded thumbnail:
#    if($p_hr->{degrees}) {
#        if(my $thm_content = $self->get_thumb) {
#            my $thm_obj = $self->new({content => $thm_content});
#            $thm_obj->_rotate_with_magick($p_hr->{degrees});
#            $exiftool->SetNewValue(ThumbnailImage => $thm_obj->get_content, Type => 'ValueConv');
#        }
#    }
#    if($p_hr->{exif}) {
#        $self->do_exiftool(
#            sub {
#                my $exiftool = shift;
#                my $exif_hr  = shift;
#                $self->_set_exiftool_values($exiftool, $exif_hr);
#            },
#            $p_hr->{exif};
#        );
#    }
#    return $self;
#}

                #create_missing_thumb => {
                #    %JSON_SCHEMA_PERL_BOOL,
                #    default => 0,
                #},
    #my $cw_degrees_direct = 0; # default: don't rotate
    #if(exists $p_hr->{cw_degrees}) {
    #    $cw_degrees_direct = $p_hr->{cw_degrees};
    #    if(define($cw_degrees_direct) !~ /\A[+-]?\d+\z/smx) {
    #        return $self->set_error('not numeric degrees ' . dump $cw_degrees_direct);
    #    }
    #    $cw_degrees_direct %= 360;
    #    if(!is_in($cw_degrees_direct, [0, 90, 180, 270])) {
    #        return $self->set_error('not quadrant degrees ' . dump $cw_degrees_direct);
    #    }
    #    croak "not quadrant degrees $cw_degrees_direct";
    #}

        #if(!exists $p_hr->{auto} || $p_hr->{auto}) {
    #    $p_hr->{auto} = 1;
    #}
    #validate handles this if(!exists $p_hr->{orientation}) {
    #    $p_hr->{orientation} = 'auto';
    #}

    # validate handles this else {
    #    return $self->set_error('Unknown orientation ' . dump $p_hr->{orientation});
    #}
   # $self->_rotate_with_magick($cw_degrees);
    
    #$self->do_exiftool(
    #    $exiftool->SetNewValue(ThumbnailImage => $thm_obj->get_content, Type => 'ValueConv');
    #    _rotate_with_exiftool => {
    #        degrees => $cw_degrees,
    #        exif    => $set_exif_hr,
    #        %{hrslice($p_hr, 'create_missing_thumb')},
    #    }
    #);
    #my $tmp = File::Temp->new(SUFFIX => '.jpg')->filename; # .jpg is just to make debugging easier, not used otherwise. TODO: Use the exact ext (if it's not a jpeg file)
    #$self->write_content({filename => $tmp});
    #$exiftool->WriteInfo($tmp);
    #delete $self->{exif_hr};
    #delete $self->{content};
    #$self->get_content($tmp);
    #unlink $tmp || carp "unlink $tmp: $!";
sub do_magick0 {
    my $self            = shift;
    my $method_or_func  = shift; # method is of Image::Magick object
    my @args_for_method = @_;    # optional

    if(ref $method_or_func) { # it must be a code ref then
        my $sub = $method_or_func;
        return $sub->(@args_for_method); # HUJESEG !!!!
    }
    else { # method name
        my $method = $method_or_func;
        my $magick_image = $self->_new_magick;
        my @rv = wantarray ? $magick_image->$method(@args_for_method) : (scalar $magick_image->$method(@args_for_method));
        $self->_end_magick($magick_image);
        return wantarray ? @rv : $rv[0];
    }
}
sub do_exiftool {
    my $self            = shift;
    my $method_or_func  = shift; # method is of $self
    my @args_for_method = @_;    # optional

    my @rv;
    my $exiftool = $self->_new_exiftool;
    my @all_args  = ($exiftool, @args_for_method);

    if(is_cr($method_or_func)) {
        my $sub = $method_or_func;
        @rv = wantarray ? $sub->(@all_args) : (scalar $sub->(@all_args));
    }
    else { 
        if(ref $method_or_func) {
            croak dump $method_or_func;
        }
        my $method = $method_or_func; # method name of Umann::Image (or inherited) object. Method will get exiftool object as 1st arg then the optional ones.
        @rv = wantarray ? $self->$method(@all_args) : (scalar $self->$method(@all_args));
    }

    $self->_end_exiftool($exiftool);

    return wantarray ? @rv : $rv[0];
}

sub do_magick {
    my $self            = shift;
    my $method_or_func  = shift; # method is of Image::Magick object
    my @args_for_method = @_;    # rest is optional
    
    my @rv;
    
    my $magick_image = $self->_new_magick;
    
    my @all_args  = ($magick_image, @args_for_method);
    
    if(is_cr($method_or_func)) {
        my $sub = $method_or_func;
        @rv = wantarray ? $sub->(@all_args) : (scalar $sub->(@all_args));
    }
    else { 
        if(ref $method_or_func) {
            croak dump $method_or_func;
        }
        my $method = $method_or_func; # method name of Umann::Image (or inherited) object. Method will get exiftool object as 1st arg then the optional ones.
        @rv = wantarray ? $self->$method(@all_args) : (scalar $self->$method(@all_args));
    }

    $self->_end_magick($magick_image);
    
    return wantarray ? @rv : $rv[0];
}

