#!/usr/bin/perl
use strict;
use warnings;

my $file = $ARGV[0];
my $prefix = $ARGV[1];

open(my $fh, '<', $file) || die "Can't open file $file: $!";

while(my $line = <$fh>) {
  
  my $isMatch = $line =~ /(.*url\()['"]?(.+?)['"]?(\).*)/;
  print $isMatch ? "$1 <<datauri \"$prefix/$2\">> $3\n" : $line;

}

close $fh;