#!/usr/bin/env bash

# exif tag ids:
#   0x0132  DateTime
#   0x9003  DateTimeOriginal
#   0x9004  DateTimeDigitized
exif-date-time() {
  [[ -z "$1" ]] && eecho "Usage: exif-date-time [--format strftime_pattern] image_file [...]" && return 1
  local strftime_pattern='%D %T' SH_QUIET=$SH_QUIET SH_VERBOSE=$SH_VERBOSE
  while [[ "$1" ]]; do case "$1" in
    -f|--format)  strftime_pattern="$2"; shift 2;;
    -q|--quiet)   SH_QUIET=1; shift 1;;
    -v|--verbose) SH_VERBOSE=1; shift 1;;
    *) break;;
  esac; done

  ret=0 file_count=0
  while [[ -n "$1" ]]; do
    image_file="$1"; shift
    ((++file_count))
    vecho "image_file[$file_count]=$image_file"

    date_time="$(veval exif --ifd=EXIF --tag=DateTimeOriginal --machine-readable \"$image_file\")"
    [[ -z "$date_time" ]] && ret=1 && continue
    date_time_seconds="$(date -j -f '%Y:%m:%d %T' "$date_time" +'%s')"
    
    date_time_out="$(format-epoch-seconds "$strftime_pattern" $date_time_seconds)"
    printf '%s\t%s\n' "$date_time_out" "$image_file"
  done

  return $ret
}

format-epoch-seconds() {
  [[ -z "$1" ]] && eecho "Usage: format-epoch-seconds strftime_pattern [epoch_seconds]" && return 1
  strftime_pattern="$1"; shift
  if [[ -n "$1" ]]; then
    epoch_seconds=$1; shift
  else
    epoch_seconds="$(date -j +%s)"
  fi

  date -j -f '%s' "$epoch_seconds" +"$strftime_pattern" 
}

ls-by-name19-size-date() {
  local sort_opts=; [[ "$1" =~ -r|--reverse ]] && sort_opts="-r" && shift
  local head_opts=; [[ "$1" =~ ^[0-9]+$ ]] && head_opts="-n $1" && shift
   ls -oS -D'%F %T' "$@" \
   | cut -w -f 4- \
   | awk '{printf "%-20s %8d %s\n", substr($4 $5 $6,1,19), $1, $0;}' \
   | sort -s -k2 -k5,99 \
   | sort -s -k1  $sort_opts \
   | head $head_opts
}

exiv-tags-csv() {
  local exiv_opts= filename
  while [[ "$1" =~ ^-\w+ ]]; do
    exiv_opts="$exiv_opts $1"; shift
  done
  [[ -z "$1" ]] && eecho "usage: exiv-some-tags [exiv2 opts] file" && return 1
  filename="$1"; shift
  filename="${filename//&/\&}"
  filename="${filename// /\ }"
  eecho "# exiv-some-tags: $filename"
  qeval exiv2 -Pkt print "$filename" \
  | sort \
  | egrep -v '^Exif\.GPSInfo\.GPS(Altitude|Date|Dest|HPos|ImgDir|Speed|Time|Version)' \
  | egrep -v '^Exif\.Image\.(Orientation|YCbCr|ExifTag|Software)' \
  | egrep -v '^Exif\.(Iop|Interop|ISOSpeed|MakerNote|Meter|Scene|ShotInfo)' \
  | egrep -v '^Exif\.Photo\.(Aperture|Bright|Color|ComponentsConfig|DateTimeDigitized|DigitalZoom|ExifVersion|Exposure|Flash|FNum|Focal|ImageUniqueID|Interop|ISO|Lens|MakerNote|Meter|OffsetTime|Scene|Sensing|Shutter|SubjectArea|SubSecTime|White)' \
  | egrep -v '^Xmp\.(xmpMM\.|(.+\.Region.+(type|Struct|Area|Dim|Type|Ext.+Angle|Ext.+Confidence|Rectangle)))' \
  | egrep -v '^Iptc\.Envelope' \
  | sed -E -e 's/Xmp\.MP\..*://g;' \
  | awk -v FNAME="$filename" '{printf "%s|%s|%s\n", FNAME, $1, $2;}'
  # | egrep -v '^Exif.Thumbnail|CustomRendered|ColorSpace|DataDump'
  # | egrep -v '^Exif\.(ISOSpeed|MakerNote|Meter|Scene|ShotInfo)' \
  # | egrep -v '\.Exif|Exposure|Flash|Focal'
  # | egrep -v \.Nikon|Resolution|SensingMethod|Sharpness|SubjectArea|Thumbnail|Value|WhiteBalance|YCbCr|
}

# # keys for title
# Exif.Image.XPTitle
# Iptc.Application2.Headline
# Xmp.dc.title

# # keys for description
# Exif.Image.ImageDescription
# Iptc.Application2.Caption
# Xmp.dc.description

# # keys for keywords
# Exif.Image.XPKeywords ':'
# Iptc.Application2.Keywords
# Xmp.dc.subject ','
# Xmp.MicrosoftPhoto.LastKeywordXMP ','
# Xmp.MicrosoftPhoto.LastKeywordIPTC ','

# # keys for date/time
# Exif.Image.DateTime
# Exif.Photo.DateTimeOriginal
# Iptc.Application2.DateCreated
# Iptc.Application2.TimeCreated
# Xmp.xmp.CreateDate

# # keys for size
# Exif.Photo.PixelXDimension
# Exif.Photo.PixelYDimension

# # keys for person
# Xmp.MP.RegionInfo/MPRI:Regions[1..]/MPReg:PersonDisplayName


# $ exiv2 -pa '200x/2001-12-31 New Years 004.jpg'
#
# Exif.Image.ImageDescription                  Ascii      19  New Years Eve 2001
# Exif.Image.XPTitle                           Byte       38  New Years Eve 2001
# Exif.Photo.DateTimeOriginal                  Ascii      20  2001:12:31 23:04:40
# Exif.Image.XPKeywords                        Byte       48  2001/200112;newyearseve
#
# Iptc.Application2.Headline                   String     13  December 2001
# Iptc.Application2.Caption                    String     18  New Years Eve 2001
# Iptc.Application2.Keywords                   String     11  2001/200112
# Iptc.Application2.Keywords                   String     11  newyearseve
# Iptc.Application2.DateCreated                Date        8  2001-12-31
# Iptc.Application2.TimeCreated                Time       11  23:04:40+00:00
#
# Xmp.dc.subject                               XmpBag      2  2001/200112, newyearseve
# Xmp.dc.title                                 LangAlt     1  lang="x-default" New Years Eve 2001
# Xmp.dc.description                           LangAlt     1  lang="x-default" New Years Eve 2001
# Xmp.MicrosoftPhoto.LastKeywordXMP            XmpBag      2  2001/200112, newyearseve
# Xmp.MicrosoftPhoto.LastKeywordIPTC           XmpBag      2  2001/200112, newyearseve
# Xmp.xmp.CreateDate                           XmpText    19  2001-12-31T23:04:40
# Xmp.MP.RegionInfo                            XmpText     0  type="Struct"
# Xmp.MP.RegionInfo/MPRI:Regions               XmpText     0  type="Bag"
# Xmp.MP.RegionInfo/MPRI:Regions[1]            XmpText     0  type="Struct"
# Xmp.MP.RegionInfo/MPRI:Regions[1]/MPReg:Rectangle XmpText    38  0.401914, 0.119617, 0.161085, 0.241627
# Xmp.MP.RegionInfo/MPRI:Regions[1]/MPReg:PersonDisplayName XmpText     7  jackson
# Xmp.xmpMM.InstanceID                         XmpText    41  uuid:faf5bdd5-ba3d-11da-ad31-d33d75182f1b

# $ exiv2 -pa '201x/2019-12-30 20.46.29.jpg'
# Exif.Image.Orientation                       Short       1  top, left
# Exif.Image.XResolution                       Rational    1  72
# Exif.Image.YResolution                       Rational    1  72
# Exif.Image.DateTime                          Ascii      20  2019:12:30 20:46:29
# Exif.Photo.DateTimeOriginal                  Ascii      20  2019:12:30 20:46:29
# Exif.Photo.OffsetTimeOriginal                Ascii       7  -06:00
# Exif.Photo.SubSecTimeOriginal                Ascii       4  397
# Exif.Photo.PixelXDimension                   Long        1  4032
# Exif.Photo.PixelYDimension                   Long        1  3024

# $ exiv2 -pa '202x/2021-04-14 11.56.13.jpg'
# Exif.Image.Orientation                       Short       1  top, left
# Exif.Image.XResolution                       Rational    1  72
# Exif.Image.YResolution                       Rational    1  72
# Exif.Photo.PixelXDimension                   Long        1  960
# Exif.Photo.PixelYDimension                   Long        1  720


