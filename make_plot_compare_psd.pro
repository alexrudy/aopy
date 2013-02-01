;;; Written by lisa A. Poyneer

;;; makes a nice plot of the data PSd, the fits to it, and the found
;;; peaks called out.

;; can save to PDF.


pro make_plot_compare_psd, hz, modal_psds, fit_data, obs, k, l, $
                           fully=fullyflag, fullx=fullxflag, pdf=pdfflag

  per_len = n_elements(hz)

  insidelocs = where(abs(hz) LE 50.)

  if keyword_set(fullyflag) then $
     yrange=[10.^floor(alog10(min(modal_psds[k,l,where(modal_psds[k,l,*] NE 0.)]))), $
             10.^ceil(alog10(max(modal_psds[k,l,*])))] else $
                yrange=[10.^floor(alog10(min(modal_psds[k,l,insidelocs]))), $
                        10.^ceil(alog10(max(modal_psds[k,l,insidelocs])))]
  

  if keyword_set(fullxflag) then $
     xrange=[-1,1]*max(abs(hz)) else $
        xrange = [-1,1]*50.
  peaks_hz = fit_data.est_omegas_peaks/(2*!pi)*obs.rate

  mypeaks = peaks_hz[k,l,*]
  plocs = where(mypeaks NE 0., nump)
  mypeaks = mypeaks[plocs]
  mypeaks = mypeaks[sort(mypeaks)]
  if nump GT 0 then begin
     
     data_peakvals = mypeaks*0.
     for t=0, nump-1 do begin
        minv = min(abs(hz - mypeaks[t]), minl)
        data_peakvals[t] = modal_psds[k,l,minl]
     endfor

     tys = mypeaks*0. + yrange[1]/2.
     txs = tys*0.
     
     spacing = 10.
     neglocs= reverse(where(mypeaks LT 0, numneg))
     if numneg GT 0 then begin
        txs[neglocs] = mypeaks[neglocs] - spacing/2.
        if numneg GT 0 then begin
           for tt=1, numneg-1 do begin
              if txs[neglocs[tt]] GT (txs[neglocs[tt-1]] - spacing) then $
                 txs[neglocs[tt:numneg-1]] -= spacing
           endfor
        endif
     endif

     poslocs= where(mypeaks GT 0, numpos)
     if numpos GT 0 then begin
        txs[poslocs] = mypeaks[poslocs] + spacing/2
        if numpos GT 0 then begin
           for tt=1, numpos-1 do begin
              if txs[poslocs[tt]] LT (txs[poslocs[tt-1]] + spacing) then $
                 txs[poslocs[tt:numpos-1]] += spacing
           endfor
        endif
     endif
  endif

  if keyword_set(pdfflag) then begin
     ;;; try using Gnuplot

     fname = 'tmp/data.dat'

     ;; save the data to a file
     openw, u, fname, /get_lun
     printf, u, '##### data'

     data = make_array(5, per_len)
     data[0,*] = shift(hz, per_len/2)
     data[1,*] = shift(reform(modal_psds[k,l,*]), per_len/2)
     data[2,*] = shift(reform(fit_data.fit_atm_psds[k,l,*]), per_len/2)
     data[3,*] = shift(reform(fit_data.fit_atm_psds[k,l,*]-fit_data.fit_atm_peaks_psds[k,l,*]), per_len/2)
     data[4,*] = shift(reform(fit_data.fit_atm_peaks_psds[k,l,*]), per_len/2)
     for t=0, per_len-1 do $
        printf, u, data[*,t]
     free_lun, u


     fname1 = 'tmp/commands.plot'
     openw, u, fname1, /get_lun

     fname2 = 'figures/psd_compare'+obs.telescope + '_' + obs.filename + $
              '_k'+strcompress(/rem,(string(round(k)))) + '_l' + $
              strcompress(/rem,(string(round(l))))+ '.pdf'

     printf, u, 'set term pdf enhanced font "Times,12" size 6,4'
     printf, u, 'set output ' + '"' + fname2 + '"'
     printf, u, 'set title ' + '"' + obs.telescope + ': ' + obs.filename + $
             ' --- Fourier Mode k='+strcompress(/rem,(string(round(k)))) + ', ' + $
             strcompress(/rem,(string(round(l)))) + $
             '" font "Times,18" noenhanced'
     printf, u, 'set tics back'
     printf, u, 'set grid back lt 4 lc rgb "grey"' ; lt 3 lc rgb "grey"'
     printf, u, 'set key on inside right center vertical Right nobox '
;     printf, u, 'set '
     printf, u, 'set logscale y'
     printf, u, 'set ytics 1e-4, 10'
     printf, u, 'set format y "10^{%3T}"' 
     printf, u, 'set yrange [' + strcompress(string(yrange[0])) + ':' + strcompress(string(yrange[1])) + ']'
     printf, u, 'set xrange [' + strcompress(string(xrange[0])) + ':' + strcompress(string(xrange[1])) + ']'
     printf, u, 'set mxtics 5'
     printf, u, 'set xlabel ' + '"Frequency (Hz)" offset 0,.5'
     printf, u, 'set ylabel ' + '"nm^2 per spatial frequency per Hz" offset 0,0'
     

     colors = ['dark-red', 'red', 'dark-pink', 'magenta', 'coral', 'orange']

     if nump GT 0 then begin
        for t=0, nump-1 do begin

           printf, u, 'set arrow ' + $
                   'from ' + strcompress(/rem, string(txs[t])+','+string(tys[t]))+$
                   'to '+strcompress(/rem, string(mypeaks[t])+','+string(data_peakvals[t]))+$
                   'head filled lt rgb '+'"'+colors[t]+'"'
           if txs[t] GT mypeaks[t] then begin
              printf, u, 'set label "'+strcompress(/rem, string(mypeaks[t], format='(F10.1)'))+$
                      ' Hz" at '+strcompress(string(txs[t]))+','+$
                      strcompress(string(tys[t]))+' left front textcolor rgb "'+colors[t]+'"'
           endif else begin
              printf, u, 'set label "'+strcompress(/rem, string(mypeaks[t], format='(F10.1)'))+$
                      ' Hz" at '+strcompress(string(txs[t]))+','+$
                      strcompress(string(tys[t]))+' right front textcolor rgb "'+colors[t]+'"' 
           endelse
        endfor
     endif
     ;;; plot the peaks_hz


     printf, u, "plot '"+fname+"' using 1:2 with lines  lt rgb "+'"black"'+" title " + '"Data"' + ',' + $
             '"'+fname+'"'+ ' using  1:3 with lines  lt rgb '+'"red"'+" title " + '"Fit"' + ',' + $
             '"'+fname+'"'+ ' using  1:4 with lines  lt rgb '+'"orange"'+" title " + '"DC Fit"' + ',' + $
             '"'+fname+'"'+ ' using  1:5 with lines  lt rgb '+'"magenta"'+" title " + '"Peaks Fit"'


     free_lun, u


     cmd = 'gnuplot ' + fname1
     spawn, cmd

     ;;; clean up
     cmd = '\rm ' + fname
;     spawn, cmd

     ;;; clean up
     cmd = '\rm ' + fname1
;     spawn, cmd

  endif else begin


     plot, shift(hz, per_len/2), shift(modal_psds[k,l,*], per_len/2), $
           /ylog, xrange=xrange, xtitle='Frequency (hz)', $
           ytitle='nm^2 per spatial frequency per hz', $
           title=strcompress(obs.telescope+':' + obs.filename+' Fmodes: K:' + $
                             string(round(k)) + ', L: ' + string(round(l))), $
           yrange=yrange
     oplot, [0,0], yrange, line=1

     oplot, shift(hz, per_len/2), shift(fit_data.fit_atm_psds[k,l,*], per_len/2), color=250
     oplot, shift(hz, per_len/2), shift(fit_data.fit_atm_psds[k,l,*]-$
                                        fit_data.fit_atm_peaks_psds[k,l,*], per_len/2), color=200, line=2
     oplot, shift(hz, per_len/2), shift(fit_data.fit_atm_peaks_psds[k,l,*], per_len/2), color=150, line=2


     if nump GT 0 then begin
        for t=0, nump-1 do begin
           arrow, txs[t],  tys[t], mypeaks[t], data_peakvals[t], /data, color=175
           if txs[t] GT mypeaks[t] then begin
              xyouts, txs[t], tys[t], strcompress(/rem, string(mypeaks[t], format='(F10.1)'))+$
                      ' Hz', charsize=1.25, align=0, color=175
           endif else begin
              xyouts, txs[t], tys[t], strcompress(/rem, string(mypeaks[t], format='(F10.1)'))+$
                      ' Hz', charsize=1.25, align=1, color=175
           endelse
        endfor
     endif

  endelse



end
