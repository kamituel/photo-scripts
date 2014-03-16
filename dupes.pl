#!/usr/bin/perl -w

# Detects duplicate files in given directories.
# First, compares file sizes. If they matches, computes MD5 sum to make sure.
# In the output each line contains list of same files. To delete duplicates,
# delete ALL BUT ONE files mentioned in the line.

# To delete duplicates files, pipe the output of this command like:
#   cat output.txt | awk -F",,," 'BEGIN {OFS="\n"} {$1=""; print}' | grep -vE "^$" | perl -pe 's/ /\\ /g' | xargs -I% rm "%"
# where 'output.txt' is the output of this script. 

use strict;
use File::Find;
use Digest::MD5;

print "Usage: ./dupes.pl DIR1 ...\n" and exit unless $#ARGV >= 0;

my %files;
my $wasted = 0;
foreach (@ARGV) { find(\&check_file, $_); }
#find(\&check_file, $_) while (<@ARGV>);

local $" = ",,,";
foreach my $size (sort {$b <=> $a} keys %files) {
  next unless @{$files{$size}} > 1;
  my %md5;
  foreach my $file (@{$files{$size}}) {
    open(FILE, $file) or next;
    binmode(FILE);
    push @{$md5{Digest::MD5->new->addfile(*FILE)->hexdigest}},$file;
  }
  foreach my $hash (keys %md5) {
    next unless @{$md5{$hash}} > 1;
    print "@{$md5{$hash}}\n";
    $wasted += $size * (@{$md5{$hash}} - 1);
  }
}

1 while $wasted =~ s/^([-+]?\d+)(\d{3})/$1,$2/;
print "$wasted bytes in duplicated files\n";

sub check_file {
  -f && push @{$files{(stat(_))[7]}}, $File::Find::name;
}
