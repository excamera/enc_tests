#!/usr/bin/perl -w
# process the output of run_tests.sh
#
# (C) 2016 Riad S. Wahby <rsw@cs.stanford.edu>
#          and the alfalfa project (https://github.com/alfalfa/)

use strict;

if (scalar @ARGV < 1) {
    print "Usage: $0 <outfile>\n";
    exit(-1);
}

my $fh;
open($fh, "<".$ARGV[0]) or die "Could not open $ARGV[0]: $!";

# read in the output file
my %res;
while (<$fh>) {
    chomp;

    my ($qnum, $npix, $nbytes, $psnr, $psnrhvs, $ssim, $fastssim) = split(' ');
    $res{$nbytes} = [ $qnum, $npix, $psnr, $psnrhvs, $ssim, $fastssim ];
}

# dump in ascending bpp order
foreach my $b (sort { int($a) <=> int($b) } keys %res) {
    my @rv = @{$res{$b}};
    my $npix = $rv[1];
    my $ssim = $rv[4];
    my $bpp = 8 * $b / $npix;

    # this just dumps out bpp and ssim
    printf("%4f %4f\n", $bpp, $ssim);
}
