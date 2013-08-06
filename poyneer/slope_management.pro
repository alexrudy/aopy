;; CVS header information for IDL files
;; $Revision: 1.1 $
;; $Author: poyneer1 $
;; $Date: 2012/11/19 23:29:32 $

;; --------------------------------------------------------
;; This work was performed under the auspices of the U.S. Department of 
;; Energy by the University of California, Lawrence Livermore National 
;; Laboratory under contract No. W-7405-Eng-48.
;; OR 
;; This work performed under the auspices of the U.S. Department of Energy 
;; by Lawrence Livermore National Laboratory under Contract DE-AC52-07NA27344.

;; Developed by Lisa A. Poyneer 2001-2012
;; No warranty is expressed or implied.
;; --------------------------------------------------------

pro slope_management, subapmask, xs, ys, print=pflag, extend=eflag


;;;;;; compilation of two slope manahgement schemes

  dims = size(subapmask)
  if dims[0] NE 2 then begin
     print, 'Subapmask must be 2D'
     return
  endif
  if dims[1] NE dims[2] then begin
     print, 'Subapmask must be square'
     return
  endif


  dimsx = size(xs)
  if dimsx[0] NE 2 then begin
     print, 'X slopes must be 2D'
     return
  endif
  if dimsx[1] NE dimsx[2] then begin
     print, 'X slopes must be square'
     return
  endif
  if dims[1] NE dimsx[1] then begin
     print, 'X slopes must be same size as subapmask'
     return
  endif


  dimsy = size(ys)
  if dimsy[0] NE 2 then begin
     print, 'Y slopes must be 2D'
     return
  endif
  if dimsy[1] NE dimsy[2] then begin
     print, 'Y slopes must be square'
     return
  endif
  if dims[1] NE dimsy[1] then begin
     print, 'Y slopes must be same size as subapmask'
     return
  endif

  n = dims[1]*1.

  ;;;ok - passed all initial tests.


  xs0 = xs
  ys0 = ys

  xs = xs*subapmask
  ys = ys*subapmask


  if keyword_set(eflag) then begin
   ;;; *********************************************
   ;;; *********************************************
   ;;; ************* Extension *********************
   ;;; *********************************************
   ;;; *********************************************


     xin = subapmask
     yin = subapmask
     xinsh = shift(xin, 0, -1)
     yinsh = shift(yin, -1, 0)

     loops1 = xin + yin + xinsh + yinsh

;for every 3 entry, set that gradient based on the others.....

     FOR k=0, N-1 DO BEGIN
        FOR l=0, N-1 DO BEGIN
           IF loops1[k,l] EQ 3 THEN BEGIN
              flag = 0
              sum = 0
              IF xin[k,l] EQ 0 THEN $
                 flag = 1 else $
                    sum = sum + xs[k,l]

              IF xinsh[k,l] EQ 0 THEN $
                 flag = 2 else $
                    sum = sum - xs[k,l+1]
              
              IF yin[k,l] EQ 0 THEN $
                 flag = 3 else $
                    sum = sum - ys[k,l]
              
              IF yinsh[k,l] EQ 0 THEN $
                 flag = 4 else $
                    sum = sum + ys[k+1,l]

              CASE flag OF
                 1: BEGIN
                    xs[k,l] = -sum
                    xin[k,l] = 1
                 END			
                 2: BEGIN
                    xs[k,l+1] = sum
                    xin[k,l+1] = 1
                 END			
                 3: BEGIN
                    ys[k,l] = sum
                    yin[k,l] = 1
                 END			
                 4: BEGIN
                    ys[k+1,l] = -sum
                    yin[k+1, l] = 1
                 END			
              ENDCASE
           ENDIF
        ENDFOR
     ENDFOR

     xout = 1-xin
     yout = 1-yin

;now find top, bottom, left, right
     xtop0 = xin     
     yleft0 = yin    
     xbot0 = xin     
     yright0 = yin   

     xtop = make_array(N,N)
     yleft = make_array(N,N)
     xbot = make_array(N,N)
     yright = make_array(N,N)

     FOR k=0, N-1 DO BEGIN
        ;find first 1 in each column (going down) of xtop
        ;find first 1 in row (going right) in yleft
        ;find last 1 in each column of xbot
        ;find last 1 in each rw of yright
        found1 = 0
        found2 = 0
        found3 = 0
        found4 = 0
        FOR l=0, N-1 DO BEGIN
           l2 = N-1-l
           IF found1 EQ 0 THEN BEGIN		
              IF xtop0[k,l] EQ 1 THEN BEGIN
                 xtop[k,l] = 1
                 found1 = 1
              ENDIF
           ENDIF
           IF found2 EQ 0 THEN BEGIN		
              IF xbot0[k,l2] EQ 1 THEN BEGIN
                 xbot[k,l2] = 1
                 found2 = 1
              ENDIF
           ENDIF
           IF found3 EQ 0 THEN BEGIN		
              IF yleft0[l,k] EQ 1 THEN BEGIN
                 yleft[l,k] = 1
                 found3 = 1
              ENDIF
           ENDIF
           IF found4 EQ 0 THEN BEGIN		
              IF yright0[l2,k] EQ 1 THEN BEGIN
                 yright[l2,k] = 1
                 found4 = 1
              ENDIF
           ENDIF		
        ENDFOR
     ENDFOR

;now take thse values and propagate out through whole grid.

     FOR k=0, N-1 DO BEGIN
        toploc = where(xtop[k,*] EQ 1, is_top)
        IF is_top EQ 1 THEN BEGIN
           val = xs[k,toploc[0]]
           FOR l=0, toploc[0]-1 DO BEGIN
              xs[k,l] = val
              xin[k,l] = 1
           ENDFOR		
        ENDIF
        botloc = where(xbot[k,*] EQ 1, is_bot)
        IF is_bot EQ 1 THEN BEGIN
           val = xs[k,botloc[0]]
           FOR l=botloc[0]+1, N-1 DO BEGIN
              xs[k,l] = val
              xin[k,l] = 1
           ENDFOR		
        ENDIF
        leftloc = where(yleft[*,k] EQ 1, is_left)
        IF is_left EQ 1 THEN BEGIN
           val = ys[leftloc[0], k]
           FOR l=0, leftloc[0]-1 DO BEGIN
              ys[l,k] = val
              yin[l,k] = 1
           ENDFOR		
        ENDIF
        rightloc = where(yright[*,k] EQ 1, is_right)
        IF is_right EQ 1 THEN BEGIN
           val = ys[rightloc[0], k]
           FOR l=rightloc[0]+1, N-1 DO BEGIN
              ys[l,k] = val
              yin[l,k] = 1
           ENDFOR		
        ENDIF

     ENDFOR

;now need to fix the seams due to spatial periodicity....

     FOR k = 0, N-1 DO BEGIN
        xs[N-1, k] = -Total(xs[0:N-2, k])
        ys[k,N-1] = -Total(ys[k, 0:N-2])
     ENDFOR
     return

  endif else begin

   ;;; *********************************************
   ;;; *********************************************
   ;;; ************* Edge Correction ***************
   ;;; *********************************************
   ;;; *********************************************


     ;;; first do rows

     rowsum = total(xs, 1)
     sub_rowsum = total(subapmask, 1)

     for j=0, n-1 do begin
        if sub_rowsum[j] GT 0 then begin
           ;;;;; there are subs in this row to fix
           nzlocs = where(subapmask[*,j] NE 0., num)
           ;;; exploit where returning in order to get left and right
           left_loc = nzlocs[0]
           if left_loc EQ 0 then begin
              print, 'Left edge of row ', j, ' is at k =0'
              print, 'This is not enought space to extend!'
              print, 'REturning doing nothing...'
              xs = xs0 & return
           endif else begin
              xs[left_loc-1,j] = -0.5*rowsum[j]
           endelse
           right_loc = nzlocs[num-1]
           if right_loc EQ (n-1) then begin
              print, 'Right edge of row ', j, ' is at k = (n-1)'
              print, 'This is not enought space to extend!'
              print, 'REturning doing nothing...'
              xs = xs0 & return
           endif else begin
              xs[right_loc+1,j] = -0.5*rowsum[j]
           endelse
        endif
     endfor
     
     ;;; then do columns

     colsum = total(ys, 2)
     sub_colsum = total(subapmask, 2)

     for j=0, n-1 do begin
        if sub_colsum[j] GT 0 then begin
           ;;;;; there are subs in this col to fix
           nzlocs = where(subapmask[j,*] NE 0., num)
           ;;; exploit where returning in order to get bottom and right
           bottom_loc = nzlocs[0]
           if bottom_loc EQ 0 then begin
              print, 'Bottom edge of col ', j, ' is at k =0'
              print, 'This is not enought space to extend!'
              print, 'REturning doing nothing...'
              xs = xs0 & ys = ys0 & return
           endif else begin
              ys[j, bottom_loc-1] = -0.5*colsum[j]
           endelse
           right_loc = nzlocs[num-1]
           if right_loc EQ (n-1) then begin
              print, 'Right edge of col ', j, ' is at k = (n-1)'
              print, 'This is not enought space to extend!'
              print, 'REturning doing nothing...'
              xs = s0 & ys = ys0 & return
           endif else begin
              ys[j, right_loc+1] = -0.5*colsum[j]
           endelse
        endif
     endfor
     
     return

  endelse
end
