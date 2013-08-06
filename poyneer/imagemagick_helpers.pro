pro imh_text, fname, x, y, string, center=cflag, color=colorflag, bold=boldflag, big=bigflag
  if keyword_set(boldflag) then $
     cmd = 'mogrify   -draw  " font Times-BoldItalic ' else $
        cmd = 'mogrify   -draw  " font Times '
  if keyword_set(colorflag) then cmd = cmd + ' fill ' + colorflag + ' '
  if keyword_set(bigflag) then $
     cmd = cmd + ' font-size 24 ' else $
        cmd = cmd + ' font-size 14 '
  if keyword_set(cflag) then cmd = cmd + ' gravity center '
  cmd = cmd +  ' text '+$
        strcompress(/rem, string(round(x)))+ ',' + $            ;;; x pixel location
        strcompress(/rem, string(round(y)))+ ' ' + "'" + $      ;; y pixel location - from top
        string + "'" + '" ' + $                                 ;;;; text string 
        ' ' + fname
  spawn, cmd
end


pro imh_circle, fname, x, y, rad, color=colorflag, dash=dashflag
  cmd = 'mogrify   -draw  " fill none '
  if keyword_set(dashflag) then cmd = cmd + 'stroke-dasharray 5 3 '
  if keyword_set(colorflag) then cmd = cmd + 'stroke ' + colorflag + ' ' 
  cmd = cmd +   ' circle '+$
        strcompress(/rem, string(round(x)))+ ',' + $            ;;; x pixel location
        strcompress(/rem, string(round(y)))+ ' ' + $            ;;; x pixel location
        strcompress(/rem, string(round(x + rad)))+ ',' + $      ;;; x pixel location
        strcompress(/rem, string(round(y)))+ ' ' + '" ' + $     ;;;; text string 
        ' ' + fname
  spawn, cmd
end

pro imh_line, fname, x0, y0, x1, y1, color=colorflag, dash=dashflag
  cmd = 'mogrify   -draw  " fill none '
  if keyword_set(dashflag) then cmd = cmd + 'stroke-dasharray 5 3 '
  if keyword_set(colorflag) then cmd = cmd + 'stroke ' + colorflag + ' ' 
  cmd = cmd +  '  line '+$
        strcompress(/rem, string(round(x0)))+ ',' + $            ;;; x pixel location
        strcompress(/rem, string(round(y0)))+ ' ' + $            ;;; x pixel location
        strcompress(/rem, string(round(x1)))+ ',' + $            ;;; x pixel location
        strcompress(/rem, string(round(y1)))+ ' ' + '" ' + $     ;;;; text string 
        ' ' + fname
  spawn, cmd
end

pro imh_dot, fname, x, y, rad
  cmd = 'mogrify   -draw  "fill black circle '+$
        strcompress(/rem, string(round(x)))+ ',' + $            ;;; x pixel location
        strcompress(/rem, string(round(y)))+ ' ' + $            ;;; x pixel location
        strcompress(/rem, string(round(x + rad)))+ ',' + $            ;;; x pixel location
        strcompress(/rem, string(round(y)))+ ' ' + '" ' + $                                 ;;;; text string 
        ' ' + fname
  spawn, cmd

  cmd = 'mogrify   -draw  "fill white circle '+$
        strcompress(/rem, string(round(x)))+ ',' + $            ;;; x pixel location
        strcompress(/rem, string(round(y)))+ ' ' + $            ;;; x pixel location
        strcompress(/rem, string(round(x + rad/2)))+ ',' + $            ;;; x pixel location
        strcompress(/rem, string(round(y)))+ ' ' + '" ' + $                                 ;;;; text string 
        ' ' + fname
  spawn, cmd
end

pro imh_rect, fname, x0, y0, x1, y1, color=colorflag
  cmd = 'mogrify   -draw  " fill none '
  if keyword_set(colorflag) then cmd = cmd + 'stroke ' + colorflag + ' ' 
  cmd = cmd +  '  rectangle '+$
        strcompress(/rem, string(round(x0)))+ ',' + $            ;;; x pixel location
        strcompress(/rem, string(round(y0)))+ ' ' + $            ;;; x pixel location
        strcompress(/rem, string(round(x1)))+ ',' + $            ;;; x pixel location
        strcompress(/rem, string(round(y1)))+ ' ' + '" ' + $     ;;;; text string 
        ' ' + fname
  spawn, cmd
end
