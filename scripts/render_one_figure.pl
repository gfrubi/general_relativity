#!/usr/bin/perl

use strict;

# usage:
#   render_one_figure.pl foo.svg
# Renders it unless rendering already exists and is newer than svg. Attempts to render it to pdf first. If that
# fails preflight, redoes it as a bitmap.

my $not_for_real = 0;

my $svg = $ARGV[0];

my $exists = 0;
foreach my $e('pdf','jpg','png') {
  my $rendered = $svg;
  $rendered =~ s/\.svg$/.$e/;
  $exists = $exists || -e $rendered;
  if (-e $rendered && -M $svg > -M $rendered) {exit(0)} # -M finds age in days
}

if ($exists) {
  print "rendering figure $svg , which has a rendering older than the svg\n";
}
else {
  print "rendering figure $svg\n";
}

my $pdf=$svg;
$pdf=~s/\.svg$/.pdf/;
unless (-e $pdf && -M $svg > -M $pdf) { # 
  my $c="inkscape --export-text-to-path --export-pdf=$pdf $svg  --export-area-drawing 1>/dev/null"; 
  print "  $c\n"; 
  unless ($not_for_real) {
    system($c)==0 or die "error in render_one_figure.pl, rendering figure using command $c";
  }
  # Check that inkscape output pdf 1.4, since pdftk has buggy support for 1.5.
  # See https://bugs.launchpad.net/inkscape/+bug/1110549
  # Don't just depend on preflight_one_fig.pl to do this, because that would result in it being rendered to bitmap.
  my $pdf_version = detect_pdf_version($pdf);
  $pdf_version eq '1.4' or die "error in render_one_figure.pl, inkscape output pdf version='$pdf_version'; see https://bugs.launchpad.net/inkscape/+bug/1110549";
}

-x "scripts/preflight_one_fig.pl" or die "couldn't find scripts/preflight_one_fig.pl -- are you running me from home dir?";

if (system("scripts/preflight_one_fig.pl $svg")==0) {exit(0)}

print "  preflight failed on pdf rendering of $svg , probably due to transparency; rendering to bitmap instead\n";
unlink($pdf) or die "error deleting $pdf, $!";
my $png = $svg;
$png=~s/\.svg$/.png/;
my $c="inkscape --export-png=$png --export-dpi=300 $svg  --export-area-drawing  1>/dev/null"; 
print "  $c\n"; 
unless ($not_for_real) {
  system($c)==0 or die "error in render_one_figure.pl, rendering figure using command $c";
  system("mogrify -background white -flatten -alpha off $png")==0 or die "error removing transparency from $png";
}

print "\n";

# code duplicated in preflight_one_fig.pl
sub detect_pdf_version {
  my $pdf = shift;
  open (my $F,"<$pdf") or return undef;
  my $version_line = <$F>; # should be %PDF-1.4
  close $F;
  $version_line =~ /^\%PDF\-(\d+\.\d+)/i or return undef;
  my $version = $1;
  return $version;
}
