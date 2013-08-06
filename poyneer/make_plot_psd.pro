;;; Written by lisa A. Poyneer

pro make_plot_psd, hz, modal_psds, k, l, fully=fullyflag, fullx=fullxflag, over=overflag

  per_len = n_elements(hz)


  if keyword_set(fullyflag) then $
     yrange=[min(modal_psds[k,l,*]), max(modal_psds[k,l,*])] else $
        yrange = [1e-3, 1e3]
  
  if keyword_set(fullxflag) then $
     xrange=[-1,1]*max(abs(hz)) else $
        xrange = [-1,1]*50.
  
  if keyword_set(overflag) then begin
     oplot, shift(hz, per_len/2), shift(modal_psds[k,l,*], per_len/2), color=overflag
  endif else begin

     plot, shift(hz, per_len/2), shift(modal_psds[k,l,*], per_len/2), $
           /ylog, xrange=xrange, xtitle='Frequency (hz)', $
           ytitle='nm^2 per spatial frequency per hz', $
           title=strcompress('Fmodes: K:' + $
                             string(round(k)) + ', L: ' + string(round(l))), $
           yrange=yrange
     oplot, [0,0], yrange, line=1
  endelse


end
