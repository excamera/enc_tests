#!/usr/bin/perl -w
# Calculates the average percent increase of bpp needed for XC to achieve the same SSIM as VPX

use strict;

if (scalar @ARGV < 2) {
    print "Usage: $0 <-vp8.out> <-xc.out>\n";
    exit(-1);
}

# read in the output files into hashes keyed by ssim
my $fh_vp8;
open($fh_vp8, "<".$ARGV[0]) or die "Could not open $ARGV[0]: $!";
my %vp8_hash;
while (<$fh_vp8>) {
    chomp;
    my ($bpp, $ssim) = split(' ');
    $vp8_hash{$ssim} = [ $bpp ];
}
my @vp8_ssim = sort {$a <=> $b} keys %vp8_hash;
close $fh_vp8;

my $fh_xc;
open($fh_xc, "<".$ARGV[1]) or die "Could not open $ARGV[1]: $!";
my %xc_hash;
while (<$fh_xc>) {
    chomp;
    my ($bpp, $ssim) = split(' ');
    $xc_hash{$ssim} = [ $bpp ];
}
my @xc_ssim = sort {$a <=> $b} keys %xc_hash;
close $fh_xc;

my $bpp_diff = 0;
my $count = 0;

# for each ssim/bpp pair in xc, find the bpp of the same ssim in vp8 and take the difference
foreach (@xc_ssim) {
    # after the while loop, counter points at the vpx ssim directly above the given xc ssim
    my $counter = 0;
    while ($counter < scalar @vp8_ssim and $vp8_ssim[$counter] < $_) {
        $counter++;
    }
    # if the xc ssim is not within the range of vp8's ssim, discard it
    if ($counter > 0 and $counter < scalar @vp8_ssim) {
        # using the adjacent vp8 ssim/bpp points to create a line, find the bpp corresponding to the given xc ssim
        my $vp8_bpp = $vp8_hash{$vp8_ssim[$counter-1]}[0]
            +(($vp8_hash{$vp8_ssim[$counter]}[0]-$vp8_hash{$vp8_ssim[$counter-1]}[0])
                *($_-$vp8_ssim[$counter-1])/($vp8_ssim[$counter]-$vp8_ssim[$counter-1]));
        my $diff = ($xc_hash{$_}[0]-$vp8_bpp)/$vp8_bpp;
        $bpp_diff += $diff;
        $count++;
    }
}
if ($count > 0) {
    $bpp_diff /= $count;
}
printf("%.4f\n", $bpp_diff);
