;; Written by Lisa A Poyneer
;;; taken direclty from code in telemetyr_analysis_07/analyze_data

;;; uses a Fourier domain algorithm to fit r0

function estimate_r0, power_atm, d

  dims = size(power_atm)
  n = dims[1]

  generate_freq_grids, pk, pl, n, scale=1./(n*d)
  pmag = sqrt(pk^2 + pl^2)
  locs2 = where((pk GE 0) and (pl EQ 0.))


  plot, pmag, /ylog,  power_atm, psym=4, xtitle='spatial frequency (1/m)', $
        ytitle='Power (nm^2 per spatial frequency)', yrange=[1e1, 1e5]

  log_power_atm = alog10(power_atm)


end
