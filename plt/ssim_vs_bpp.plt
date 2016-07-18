# vim: syntax=gnuplot
set terminal pngcairo
set logscale x
set ylabel 'SSIM (dB0)'
set xlabel bppdiff
set title otitle noenhanced
set output ofile
set style line 1 lc rgb '#dd181f' lt 1 lw 2
set style line 2 lc rgb '#0088ff' pt 13 ps 1.5 lt 1 lw 0.5
set style line 3 lc rgb '#00aa33' pt 7 ps 1.5 lt 1 lw 0.5
set key top left
set xrange [0.001:20]
set yrange [0:35]

plot ifile  using 1:2 title 'VP8'       with lines          ls 1, \
     rfile  using 1:2 title 'XC (ref)'  with linespoints    ls 2, \
     file using 1:2 title 'XC'        with linespoints    ls 3
