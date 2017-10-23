package Umann::Image;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp qw(croak carp confess cluck);
use Data::Dump qw(dump);
use File::Slurp;
use Scalar::MoreUtils qw(define);
use Readonly;
use Image::ExifTool qw(ImageInfo);
no lib q{.};  # ExifTool adds '.' to @INC;
use Image::Magick;
use File::Temp ();
use File::Basename qw(dirname basename);
use List::MoreUtils qw(uniq);
use Time::Local qw(timegm);
use Time::HiRes qw(time);  # !!!
use Encode qw(decode_utf8);

use Umann::List::Util qw(is_in do_on_struct);
use Umann::Util qw(deep_copy);
use Umann::Scalar::Util qw(is_cr is_sr);
use Umann::Validator qw(enum_0th_default validate_obj_method);

Readonly my $JSON_SCHEMA_SCALAR => [ 'number', 'string', 'null' ];
Readonly my $JSON_SCHEMA_PERL_BOOL => $JSON_SCHEMA_SCALAR;
Readonly my %JSON_SCHEMA_PERL_BOOL => (type => $JSON_SCHEMA_SCALAR);
Readonly my $BASENAME_RE           => '(?:[[:alpha:][:digit:]._-])+';
Readonly my $EXT_RE                => '[.][jJ][pP][eE]?[gG]';
Readonly my %JSON_SCHEMA_JPEG_NAME => (
    type => 'string',
    pattern =>
qr{\A(?:([[:alpha:]]:)?(?:[/\\]{1,2}))?(?:$BASENAME_RE[/\\])*$BASENAME_RE$EXT_RE\z}smx
);
Readonly my %JSON_SCHEMA_FILE_NAME => (
    type    => 'string',
    pattern => '\s',
);
Readonly my %JSON_SCHEMA_CONTENT => (type => 'string');

Readonly my $QUADRANT                   => 90;
Readonly my $JPEG_QUALITY               => 95;
Readonly my $YEAR_OFFSET                => 1900;
Readonly my $FULL_ANGLE_DEG             => 360;
Readonly my $MINS_PER_HOUR              => 60;
Readonly my $SECS_PER_MIN               => 60;
Readonly my $THUMB_SMALLER              => 120;
Readonly my $THUMB_CREATE_LIMIT_SMALLER => 4 * $THUMB_SMALLER;

Readonly my @TIME_TAGS = qw(
    EXIF:DateTimeOriginal
    EXIF:GPSDateStamp
    EXIF:GPSTimeStamp
    EXIF:SubSecTimeOriginal
    EXIF:OffsetTimeOriginal
    IPTC:DateCreated
    IPTC:TimeCreated
    XMP-iptcExt:CircaDateCreated
    XMP-photoshop:DateCreated
    XMP-xmp:CreateDate
);

my $YYYY_MM_DD_HH_MM_SS_RE =
    qr/^(\d{4})\D*(\d{2})\D*(\d{2})\D*(\d{2})\D*(\d{2})\D*(\d{2})/smx
    ;  # cannot Readonly regexp

Readonly my @EXIFTOOL_OPTIONS = (
    Group0 => [
        qw(
            Composite
            EXIF
            File
            IPTC
            MWG
            MakerNotes
            XMP
            XMP-iptcExt
            XMP-mwg-coll
            XMP-mwg-kw
            XMP-mwg-rs
            XMP-xmp
            )
    ],
    Unknown => 1,
    Struct  => 1,
    (map { $_ => 'Latin2' } qw(CharsetEXIF)),
    (   map { $_ => 'UTF8' }
            qw(CharsetIPTC Charset CharsetID3 CharsetPhotoshop CharsetQuickTime)
    ),
);

Readonly my %CW_DEGREES_TO_EXIF_ORIENTATION => (
    '0'   => 'Horizontal (normal)',
    '90'  => 'Rotate 90 CW',
    '180' => 'Rotate 180',
    '270' => 'Rotate 270 CW',
);
Readonly my %EXIF_ORIENTATION_TO_CW_DEGREES =>
    reverse %CW_DEGREES_TO_EXIF_ORIENTATION;
Readonly my %CW_DEGREES_TO_MAKERNOTES_AUTOROTATE => (
    '0'   => 'None',
    '90'  => 'Rotate 90 CW',
    '180' => 'Rotate 180',
    '270' => 'Rotate 270 CW',
);
Readonly my %ROTATE_NAME_TO_CW_DEGREES =>
    reverse %CW_DEGREES_TO_EXIF_ORIENTATION,
    %CW_DEGREES_TO_MAKERNOTES_AUTOROTATE;

use parent qw(Umann);

sub get_filename {
    my $self = shift;

    return $self->{filename};
}

sub set_filename {
    my @args = @_;

    my ($self, $filename) =
        validate_obj_method({%JSON_SCHEMA_FILE_NAME}, @args);

    return $self->{filename} = $filename;
}

sub set_content {
    my @args = @_;

    my ($self, $content) = validate_obj_method({%JSON_SCHEMA_CONTENT}, @args);

    return $self->{content} = $content;
}

sub get_content {
    my @args = @_;
    my $self = shift @args;

    return $self->{content} //= $self->read_content(@args);
}

sub read_content {
    my @args = @_;

    my ($self, $filename) = validate_obj_method(
        {
            quantifier => q{?},
            default    => sub { $self->get_filename },
            %JSON_SCHEMA_FILE_NAME,
        },
        @args
    );

    my $rv = read_file($filename, { binmode => ':raw' });
    return $rv;  # return read_file() would return an array
}

sub get_content_ref {
    my @args = @_;

    my $self = validate_obj_method([], @args);

    my $content = $self->get_content;

    return \$content;
}

sub write_content {

    my ($self, $p_hr) = @_;
    my @args = @_;

    return write_file(
        $p_hr->{filename} // $self->get_filename,
        { binmode => ':raw' },
        $p_hr->{content} // $self->get_content
    );
}

sub get_thumb {
    my $self = shift;

    return Image::ExifTool::ImageInfo($self->get_content_ref, 'thumbnailimage')
        ->{ThumbnailImage};
}

sub rotate {
    my @args = @_;

    my ($self, $p_hr) = validate_obj_method(
        {
            type                 => 'object',
            quantifier           => q{?},
            additionalProperties => 0,
            properties           => {
                cw_degrees => {
                    type       => 'number',
                    multipleOf => $QUADRANT,
                    default    => 0,
                },
                auto => {
                    %JSON_SCHEMA_PERL_BOOL, default => 1,
                },
                orientation => {
                    enum_0th_default('auto', 'ROTATE_VIEW')

#, #, 'Horizontal (normal)', 'Rotate 180', 'Rotate 90 CW', 'Rotate 270 CW', undef),
                },
            },
        },
        @args
    );

    $p_hr = deep_copy($p_hr) // {};
    my $cw_degrees_direct =
        $p_hr->{cw_degrees};  # // 0 not needed because there is default;
    my $set_exif_hr = {};

    my $exif_hr = $self->get_exif_hr({ simple => 1 });
    my $exif_orientation = $exif_hr->{Orientation} // $exif_hr->{AutoRotate}
        // $CW_DEGREES_TO_EXIF_ORIENTATION{0};
    my $cw_degrees_orientation = $ROTATE_NAME_TO_CW_DEGREES{$exif_orientation}
        // return $self->set_error(
        'Unknown orientation in metadata' . dump $exif_orientation,
        hr_slice($exif_hr, 'Orientation', 'AutoRotate')
        );

    if ($p_hr->{orientation} eq 'ROTATE_VIEW') {
        my $cw_degrees_direct_revert =
            ($cw_degrees_orientation + $cw_degrees_direct) % $FULL_ANGLE_DEG;
        $set_exif_hr->{Orientation} =
            $CW_DEGREES_TO_EXIF_ORIENTATION{$cw_degrees_direct_revert};
        $set_exif_hr->{AutoRotate} =
            $CW_DEGREES_TO_MAKERNOTES_AUTOROTATE{$cw_degrees_direct_revert};
        $self->set_exiftool_values($set_exif_hr);
        return $self;
    }

    if ($p_hr->{auto} && !$exif_orientation) {
        $self->set_warning('No metadata found for auto rotate');
        $p_hr->{auto} = 0;
    }

    my $cw_degrees =
        ($cw_degrees_direct + $cw_degrees_orientation) % $FULL_ANGLE_DEG;

    my $cw_degrees_direct_revert = 0;  #(-$cw_degrees_direct) % $FULL_ANGLE_DEG;
    $set_exif_hr->{Orientation} =
        $CW_DEGREES_TO_EXIF_ORIENTATION{$cw_degrees_direct_revert};
    $set_exif_hr->{AutoRotate} =
        $CW_DEGREES_TO_MAKERNOTES_AUTOROTATE{$cw_degrees_direct_revert};

    if (!$exif_hr->{AutoRotate}) {
        delete $set_exif_hr->{AutoRotate};
    }

    if ($cw_degrees || %{$set_exif_hr}) {
        $set_exif_hr->{ThumbnailImage} =
            $self->_rotate_and_return_thumb($cw_degrees);
    }

    $self->set_exiftool_values($set_exif_hr);

    return $self;
}

sub __get_new_thumb_dims_hash {
    my $magick_image = shift;
    my ($width, $height) = $magick_image->Get('width', 'height');

    my %rv;

    if (   $width > $THUMB_CREATE_LIMIT_SMALLER
        && $height > $THUMB_CREATE_LIMIT_SMALLER)
    {
        if ($width > $height) {
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
        my $val = $exif_hr->{$key};  # do not use perl's each
        $key =~ s/^Composite[.]//smx;

        my %options;
        if ($key =~ /^(.*)[.:](.*)$/smx) {
            $options{Group} = $1;
            $key = $2;
        }
        if ($key eq 'Keywords') {
            if (!ref $val) {
                $val = [$val];
            }
            $val = [ uniq(grep { defined } @{$val}) ];
            $options{Replace} = 1;
        }
        if ($key eq 'ThumbnailImage') {
            $options{Type} = 'ValueConv';
        }

        if (0 && !defined $val) {
            $exiftool->DeleteTag($key);
        }
        else {

            if ($key eq 'ThumbnailImage') {
                $key .= q{#}  # ValueConv
            }
            $exiftool->SetNewValue($key => $val, %options)
                ;  #, $key eq 'ThumbnailImage' ? (Type => 'ValueConv') : ());
        }
    }
    return $self;
}

# returns rotated thumb (if created)
sub _rotate_and_return_thumb {
    my $self       = shift;
    my $cw_degrees = shift;

    return $self->do_frame(
        magick => \&{_rotate_with_magick_and_return_thumb},
        $cw_degrees
    );
}

# returns rotated thumb (if created)
sub _rotate_with_magick_and_return_thumb {
    my $self         = shift;
    my $magick_image = shift;
    my $cw_degrees   = shift;

    if ($cw_degrees) {
        $magick_image->Rotate(degrees => $cw_degrees);
        $magick_image->Set('quality', $JPEG_QUALITY);
    }
    if (my %thumb_dims = __get_new_thumb_dims_hash($magick_image)) {
        my $magick_thumb = $magick_image->Clone;
        $magick_thumb->Thumbnail(%thumb_dims);
        return +($magick_thumb->ImageToBlob)[0];
    }
    return;
}

# do not mix up with _set_exiftool_values that expects $exiftool as arg
sub set_exiftool_values {
    my @args = @_;
    my $self = shift @args;

    my %hash = 1 == scalar @args ? %{ $args[0] // {} } : @args;

    if (%hash) {
        $self->do_frame(exiftool => \&{_set_exiftool_values}, \%hash);
    }
    return $self;
}

sub _do_tmp {
    my $self = shift;
    my $sub  = shift;
    my $tmp  = File::Temp->new(SUFFIX => '.jpg')
        ->filename
        ; # .jpg is just to make debugging easier, not used otherwise. TODO: Use the exact ext (if it's not a jpeg file)
    $self->write_content({ filename => $tmp });
    $sub->($self, $tmp);
    unlink $tmp || carp "unlink $tmp: $!";
    return $self;
}

sub do_frame {
    my ($self, $frame, $sub, @args_for_method) = @_;

    state $hr => {
        new => {
            magick   => \&{_new_magick},
            exiftool => \&{_new_exiftool},
        },
        end => {
            magick   => \&{_end_magick},
            exiftool => \&{_end_exiftool},
        },
        }

        my $frame_obj = &{ hr->{new} }($self);

    my @all_args = ($self, $frame_obj, @args_for_method);

    my @rv =
        wantarray
        ? &{$sub}(@all_args)
        : (scalar &{$sub}(@all_args));

    &{ hr->{end} }($self, $frame_obj);

    return wantarray ? @rv : $rv[0];
}

sub _new_exiftool {
    my $self = shift;

    my $exiftool = Image::ExifTool->new;
    $exiftool->Options($self->get_exiftool_options);
    $self->{exiftool} = $exiftool;
    return $exiftool;
}

sub _end_exiftool {
    my $self = shift;
    my $exiftool = shift // $self->{exiftool};

    $self->_do_tmp(
        sub {
            my ($self, $tmp) = @_;
            $exiftool->WriteInfo($tmp) || croak $exiftool->GetValue('Error');
            delete $self->{exif_hr};
            delete $self->{content};
            $self->set_content($self->read_content($tmp));
        }
    );

    return $self;
}

sub _new_magick {
    my $self = shift;

    my $magick_image = Image::Magick->new;
    if (define($self->{info_src}) eq 'file') {
        $self->_set_errstr_if_true($magick_image->Read($self->get_filename));
    }
    else {
# IDKW BlobToImage does not work for embedded thumbnails. Must write to file and read from there.
        if ($magick_image->BlobToImage($self->get_content)) { # true means error
            $self->_do_tmp(
                sub {
                    my ($self, $tmp) = @_;
                    $self->_set_errstr_if_true($magick_image->Read($tmp));
                }
            );
        }
    }
    return $self->{magick_image} = $magick_image;
}

sub _end_magick {
    my $self = shift;
    my $magick_image = shift // $self->{magick_image};

    $self->set_content(($magick_image->ImageToBlob)[0]);

    $magick_image->DESTROY;

    delete $self->{magick_image};
    delete $self->{exif_hr};

    return $self;
}

sub _set_errstr_if_true {
    my $self = shift;
    my $x = shift // return;

    carp dump $x;
    return;
}

sub get_exif_hr {
    my @args = @_;
    my ($self, $p_hr) = validate_obj_method(
        {
            type                 => 'object',
            additionalProperties => 0,
            properties           => {
                umann => {%JSON_SCHEMA_PERL_BOOL},
                flat  => {
                    type => $JSON_SCHEMA_SCALAR,
                },
                simple => {%JSON_SCHEMA_PERL_BOOL},
                binary => {
                    %JSON_SCHEMA_PERL_BOOL, default => 1
                },
            },
        },
        @args
    );
    my $flat_separator = define($p_hr->{flat}) eq q{:} ? $p_hr->{flat} : q{.};
    my @options = $self->get_exiftool_options;

    # dump is used to serialize settings:
    return $self->{exif_hr_hr}{ dump $p_hr, @options } //= do {
        my $hr;
        my $exiftool = Image::ExifTool->new;
        $exiftool->Options(@options);
        my $info = $exiftool->ImageInfo(
            define($self->{info_src}) eq 'file'
            ? $self->get_filename
            : $self->get_content_ref
        );
        for my $tag ($exiftool->GetFoundTags('Group0')) {
            my $group = $exiftool->GetGroup($tag);
            my $val   = $info->{$tag};
            $tag =~ s/\s*[(][[:digit:]]+[)]\z//smx;  #UK2014dec23
            if (is_sr($val)) {
                if (!$p_hr->{binary}) {
                    next;  # do not return huge thumbnail if binary is false
                }
                $val = ${$val};
            }
            else {
                $val = do_on_struct(\&try_decode_utf8, $val);
            }
            $hr->{"$group$flat_separator$tag"} = $val;
        }
        if (my $fn = $self->get_filename) {
            $hr->{"File${flat_separator}Directory"} //= dirname($fn);
            $hr->{"File${flat_separator}FileName"}  //= basename($fn);

            #warn $hr->{"File${flat_separator}FileName"};
        }
        if ($p_hr->{umann}) {
            $hr = { %{$hr}, %{ $self->_get_umann_of_exif_hr($hr) } };
        }
        if (!$p_hr->{flat} && !$p_hr->{simple}) {
            $hr = __unflatten_exif_hr($hr);
        }
        if ($p_hr->{simple}) {
            $hr = __simplify_exif_hr($hr);
        }
        $hr;
    };  #end of do
}

sub try_decode_utf8 {
    my $exif_val = shift // return;

    if (my $decoded = eval { decode_utf8($exif_val, 1) }) {
        $exif_val = $decoded;
    }
    $exif_val =~ s/\b([Aa]rriver|[Pp]artir)[?]/$1\xf2/smxg
        ;  # sorry for this - Italian accented o &ograve; is not in latin2
    return $exif_val;
}

sub __unflatten_exif_hr {
    my $exif_hr = shift // {};

    my $rv_hr = {};  # why?: \%{$exif_hr}; # 1-level-deep copy
    for my $key (sort keys %{$exif_hr}) {
        if ($key =~ /\A(.+)[.](.+)\z/smx) {
            $rv_hr->{$1}{$2} = $exif_hr->{$key};
        }
    }
    return $rv_hr;
}

sub __simplify_exif_hr {
    my $exif_hr = shift // {};

    my $rv_hr = \%{$exif_hr};  # 1-level-deep copy
    for my $key (sort keys %{$exif_hr}) {
        if ($key =~ /\A.+[.](.+)\z/smx) {
            $rv_hr->{$1} = $exif_hr->{$key};
        }
    }
    return $rv_hr;
}

sub _get_umann_of_exif_hr {
    my $self     = shift;
    my $exif_hr  = shift;
    my $umann_hr = {};

    return $umann_hr;
}

sub set_exiftool_options {
    my ($self, @options) = @_;

    $self->{exiftool_options_ar} = [@options]
        ; # not \@options so it won't change by surprise (at least the array elements)

    return @options;
}

sub get_exiftool_options {
    my $self = shift;

    $self->{exiftool_options_ar} //= \@EXIFTOOL_OPTIONS;

    return @{ $self->{exiftool_options_ar} };
}

sub get_partial_datetime_settings {
    my $x = shift;

    my $m_hr;

## no critic(ProhibitComplexRegexes)
    @{$m_hr}{qw(year mon mday hour min sec fract tz)} = define($x) =~ m{^
        ((?:19|20)(?:\d{2}|\d{1}X|XX))   # year 19.. or 20..
        (?:
            \D?                      # optional separator
            (\d{2})                  # month, later chkd precisely by timegm
            (?:
                \D?                  # optional separator
                (\d{2})              # day of month, later chkd precisely by timegm
                (?:
                    \D?              # optional separator
                    ([01]\d|2[0-3])  # hour; if exists, must be followed by minute
                    \D?              # optional separator
                    ([0-5]\d)        # minute
                    (?:
                        \D?          # optional separator
                        (?:
                            ([0-5]\d)# second
                            (?:
                                ([.]\d{1,6}) # fraction of second up to microsecond only (sry)
                            )?
                        )?
                        (?:
                            ([+-][01]\d:(?:[03]0|[14]5)|Z) # time zone Z or multiple of 15 minutes
                        )?
                    )?
                )?
            )?
        )?
    $}smx or do {
        croak 'invalid input: ' . dump $x;
    };  # end of do
## use critic

    if ($m_hr->{year} =~ /X/smx && defined $m_hr->{mon}) {
        croak 'invalid use of X in input: ' . dump $x;
    }
    $m_hr->{fract} //= q{};
    $m_hr->{tz}    //= q{};

    $m_hr->{tz} =~ s/Z/+00:00/smx;

    my $rv = _partial_match($m_hr);

    if (my $d = delete $rv->{w3c_datetime}) {
        $rv->{'XMP-xmp:CreateDate'} = $rv->{'XMP-photoshop:DateCreated'} = $rv;
    }

    # paranoia
    if (my @unkonwn_keys = grep { !($_ ~~ \@TIME_TAGS) } keys %{$rv}) {
        croak 'Internal error - unknown keys: ' . dump @unkonwn_keys;
    }
    return +{ map { $_ => $rv->{$_} } @TIME_TAGS };
}

sub _partial_match {
    my $m_hr = shift;

    my $rv;

    if (defined $m_hr->{mday}) {
        if (!eval {
                timegm(
                    0, 0, 0, $m_hr->{mday},
                    $m_hr->{mon} - 1,
                    $m_hr->{year} - $YEAR_OFFSET
                );
            }
            )
        {
            croak "invalid date: $m_hr->{year}-$m_hr->{mon}-$m_hr->{mday}";
        }
        $rv->{'IPTC:DateCreated'} = "$m_hr->{year}:$m_hr->{mon}:$m_hr->{mday}";
    }

    if (defined $m_hr->{sec}) {
        $rv->{w3c_datetime} =
              "$m_hr->{year}-$m_hr->{mon}-$m_hr->{mday}"
            . "T$m_hr->{hour}:$m_hr->{min}:$m_hr->{sec}"
            . "$m_hr->{fract}$m_hr->{tz}";
        $rv->{'EXIF:DateTimeOriginal'} =
              "$m_hr->{year}:$m_hr->{mon}:$m_hr->{mday}"
            . " $m_hr->{hour}:$m_hr->{min}:$m_hr->{sec}";
        $rv->{'IPTC:TimeCreated'} = "$m_hr->{hour}:$m_hr->{min}:$m_hr->{sec}";
        if ($m_hr->{fract} =~ /^[.](\d+)$/smx) {
            $rv->{'EXIF:SubSecTimeOriginal'} = $1;
        }
        if ($m_hr->{tz}) {
            my $offset_mins =
                $m_hr->{tz} =~ /^([+-])(\d\d):?(\d\d)$/smx
                ? sgnval(${1}) * ($2 * $MINS_PER_HOUR + $3)
                : croak 'wtf';
            my $time = timegm(
                $m_hr->{sec}, $m_hr->{min}, $m_hr->{hour}, $m_hr->{mday},
                $m_hr->{mon} - 1,
                $m_hr->{year} - $YEAR_OFFSET
            );
            my ($sec, $min, $hour, $mday, $mon0, $year19) =
                gmtime($time - $offset_mins * $SECS_PER_MIN);
            $rv->{'EXIF:OffsetTimeOriginal'} = $m_hr->{tz};
            $rv->{'EXIF:GPSDateStamp'}       = sprintf '%04d-%02d-%02d',
                $year19 + $YEAR_OFFSET, $mon0 + 1, $mday;
            $rv->{'EXIF:GPSTimeStamp'} = sprintf '%02d:%02d:%02d', $hour, $min,
                $sec;
        }
        return $rv;
    }

    if (defined $m_hr->{mon}) {
        $rv->{w3c_datetime} =
            defined $m_hr->{min}
            ? "$m_hr->{year}-$m_hr->{mon}-$m_hr->{mday}T$m_hr->{hour}:$m_hr->{min}$m_hr->{tz}"
            : defined $m_hr->{mday} ? "$m_hr->{year}-$m_hr->{mon}-$m_hr->{mday}"
            :                         "$m_hr->{year}-$m_hr->{mon}";
        if (!$m_hr->{mday}) {
            $rv->{'XMP-iptcExt:CircaDateCreated'} =
                "$m_hr->{year}-$m_hr->{mon}";
        }
        return $rv;
    }

    if ($m_hr->{year} =~ /(\d{2})XX/smx) {
        my $cent = $1;
        $rv->{'XMP-iptcExt:CircaDateCreated'} = "${cent}00-${cent}99";
        return $rv;
    }

    if ($m_hr->{year} =~ /(\d{3})X/smx) {
        my $deca = $1;
        $rv->{'XMP-iptcExt:CircaDateCreated'} = "${deca}0-${deca}9";
        return $rv;
    }

    $rv->{w3c_datetime} = $m_hr->{year};
    $rv->{'XMP-iptcExt:CircaDateCreated'} = $m_hr->{year};
    return $rv;
}

sub sgnval {
    my $x = shift;

    state $hr = { q{-} => -1, q{+} => 1 };

    return $hr->{x};
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

See L<Umann|parent class Umann>

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
