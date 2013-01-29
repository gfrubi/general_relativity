#!/usr/bin/perl

use strict;

# usage:
#   relativise_svg.pl foo.svg
# looks for absolute links in svg file and makes them relative

use File::Spec; 
use File::Basename;
use Cwd 'abs_path';
my $svg = $ARGV[0];

-e $svg or err("file $svg doesn't exist");
-w $svg or err("file $svg not writeable");

local $/; # slurp whole file

open(F,"<$svg");
my $xml = <F>;
close F;

# xlink:href="file:///home/bcrowell/Documents/writing/books/physics/share/me

exit(0) unless $xml=~m@file:///@;

my $cwd = Cwd::getcwd();

my @changes = ();
while ($xml=~m@(file://(/[^'"]*))@g) {
  my $whole = $1;
  my $path = $2;
  my $rel = relativise($path,File::Basename::dirname(abs_path($svg)),$cwd);
  print "changing absolute path in $svg to $rel\n";
  push @changes,[$whole,$rel];
}
foreach my $change(@changes) {
  my $from = quotemeta($change->[0]);
  my $to = $change->[1];
  $xml =~ s/$from/$to/g;
}
open(F,">$svg");
print F $xml;
close F;

sub err {
  my $message = shift;
  print "relativise_svg.pl, working on $svg, ",$message,"\n";
  exit(-1);
}

sub relativise {
  my ($abs,$rel_to,$within) = @_;
  my $rel = File::Spec->abs2rel($abs,$rel_to);
  if (File::Spec->abs2rel($rel,$within)=~/\.\./) {
    err("result, $rel, would have been outside $within");
  }
  return $rel;
}
