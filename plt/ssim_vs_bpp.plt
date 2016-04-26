# vim: syntax=gnuplot
set terminal pngcairo
set logscale x
set ylabel 'SSIM (dB0)'
set xlabel 'bits per pixel'
set title otitle
set output ofile
set style line 1 lc rgb '#dd181f' lt 1 lw 2
set style line 2 lc rgb '#0088ff' pt 13 ps 1.5
set key top left

plot ifile using 1:2 title 'VP8' with lines ls 1, \
     '<cat' using 1:2 title 'XC' with points ls 2
