#!/usr/bin/perl

use strict;
use Cwd;
# This is a cut-down version of the version used for the Light and Matter books.

use XML::Parser;

# Run this script in the book's directory; it automatically runs eruby on all the chapters.
# Normally the eruby is executed with BOOK_OUTPUT_FORMAT='print', but
# with 'w' on the command line, it will produce web (html) output as well, running
# eruby a second time with BOOK_OUTPUT_FORMAT='web' and calling translate_to_html.rb.
# It also creates the table of contents (index.html), which is then filled in by
# translate_to_html.rb.
# Any command-line options in environment variable WOPT are passed on to translate_to_html.rb.
# Example:
#   WOPT='--no_write' make web

my $eruby = "fruby"; # use my reimplementation of eruby, for better error handling and better compatibility with TeX (see comments at top of fruby)

my $web = 0;
if (@ARGV) {
  my $a = $ARGV[0];
  $web = 1 if $a=~/w/;
}

my $wopt = '';
if (exists $ENV{WOPT}) {$wopt = $ENV{WOPT}}
my $no_write = 0;
if ($wopt=~/\-\-no_write/) {$no_write=1}
my $wiki = 0;
if ($wopt=~/\-\-wiki/) {$wiki=1}
my $xhtml = 0;
if ($wopt=~/\-\-modern/) {$xhtml=1}

print "run_eruby.pl, no_write=$no_write, wiki=$wiki, xhtml=$xhtml\n";

mkdir "temp" unless -d "temp";
foreach (<ch*/*.rbtex>) {
  my $file = $_;
  $file =~ m/ch(\d+)/;
  my $ch = $1;
  my $o = $file;
  $o =~ s/\.rbtex//;
  my $outfile_base = $o . "temp";
  my $cmd = "BOOK_OUTPUT_FORMAT='print' $eruby $file >$outfile_base.tex"; # is always executed by sh, not bash or whatever
  do_system($cmd,$file,'eruby (print)');
}

sub do_system {
  my $cmd = shift;
  my $file = shift;
  system($cmd)==0 or die "died on $file, $?, cmd=$cmd";
}
