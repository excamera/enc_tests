set terminal png
set logscale x
set ylabel 'SSIM (dB0)'
set xlabel 'bits per pixel'
set title otitle
set output ofile
plot '<cat' using 1:2 title 'SSIM' with lines
