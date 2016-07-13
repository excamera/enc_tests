#!/usr/bin/perl -w
# Calculates the average percent increase of bpp needed for XC to achieve the same SSIM as VPX

use strict;

if (scalar @ARGV < 2) {
    print "Usage: $0 <-vp8.out> <-xc.out>\n";
    exit(-1);
}

my $fh_vp8;
my $fh_xc;
open($fh_vp8, "<".$ARGV[0]) or die "Could not open $ARGV[0]: $!";
open($fh_xc, "<".$ARGV[1]) or die "Could not open $ARGV[1]: $!";

# read in the output files into hashes keyed by ssim
my %vp8_hash;
while (<$fh_vp8>) {
    chomp;
    my ($bpp, $ssim) = split(' ');
    $vp8_hash{$ssim} = [ $bpp ];
}
my @vp8_ssim = sort {$a <=> $b} keys %vp8_hash;

my %xc_hash;
while (<$fh_xc>) {
    chomp;
    my ($bpp, $ssim) = split(' ');
    $xc_hash{$ssim} = [ $bpp ];
}
my @xc_ssim = sort {$a <=> $b} keys %xc_hash;
# print "xc ssim\n";
# print "@xc_ssim\n";
# print "xc hash\n";
# use Data::Dumper;
# print Dumper(\%xc_hash);

# print "vp8 ssim\n";
# print "@vp8_ssim\n";
# print "vp8 hash\n";
# use Data::Dumper;
# print Dumper(\%vp8_hash);

my $bpp_diff = 0;
my $count = 0;
# print "dis the size ";
# print scalar @xc_ssim;
# print "\n";

# for each ssim/bpp pair in xc, find the bpp of the same ssim in vp8 and take the difference
foreach (@xc_ssim) {
    # print "ssim: $_\n";
    my $counter = 0;
    while ($counter < scalar @vp8_ssim and $vp8_ssim[$counter] < $_) {
        $counter++;
    }
    # print "counter: $counter\n";
    if ($counter > 0 and $counter < scalar @vp8_ssim) {
        my $vp8_bpp = ($vp8_hash{$vp8_ssim[$counter]}[0]+$vp8_hash{$vp8_ssim[$counter-1]}[0])/2;
        # print "vp8_bpp: $vp8_bpp\n";
        # print "xcc_bpp: $xc_hash{$_}[0]\n";
        my $diff = ($xc_hash{$_}[0]-$vp8_bpp)/$vp8_bpp;
        # print "diff: $diff\n";
        $bpp_diff += $diff;
        $count++;
    }
}
$bpp_diff /= $count;
printf("%.4f\n", $bpp_diff);

# # dump in ascending bpp order
# foreach my $b (sort { int($a) <=> int($b) } keys %res) {
#     my @rv = @{$res{$b}};
#     my $npix = $rv[1];
#     my $ssim = $rv[4];
#     my $bpp = 8 * $b / $npix;

#     # this just dumps out bpp and ssim
#     printf("%4f %4f\n", $bpp, $ssim);
# }
