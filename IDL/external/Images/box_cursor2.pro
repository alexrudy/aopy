; $Id: box_cursor2.pro,v 1.1.1.1 2011/10/19 16:28:55 LAB Exp $

PRO box_cursor2, x0, y0, nx, ny, INIT = init, FIXED_SIZE = fixed_size, $
	message = message, color=color
;+
; NAME:
;       BOX_CURSOR2
;
; PURPOSE:
;       Emulate the operation of a variable-sized box cursor (also known as
;       a "marquee" selector).
;
; CATEGORY:
;       Interactive graphics.
;
; CALLING SEQUENCE:
;       BOX_CURSOR2, x0, y0, nx, ny [, INIT = init] [, FIXED_SIZE = fixed_size]
;
; INPUTS:
;       No required input parameters.
;
; OPTIONAL INPUT PARAMETERS:
;       x0, y0, nx, and ny give the initial location (x0, y0) and 
;       size (nx, ny) of the box if the keyword INIT is set.  Otherwise, the 
;       box is initially drawn in the center of the screen.
;
; KEYWORD PARAMETERS:
;       INIT:  If this keyword is set, x0, y0, nx, and ny contain the initial
;       parameters for the box.
;
;       FIXED_SIZE:  If this keyword is set, nx and ny contain the initial
;       size of the box.  This size may not be changed by the user.
;
;       MESSAGE:  If this keyword is set, print a short message describing
;       operation of the cursor.
;
;       COLOR:  Index of color to be used to draw the cursor, default:
;               !d.n_colors-1 
;
; OUTPUTS:
;	x0:  X value of lower left corner of box.
;	y0:  Y value of lower left corner of box.
;	nx:  width of box in pixels.
;	ny:  height of box in pixels. 
;
;	The box is also constrained to lie entirely within the window.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	A box is drawn in the currently active window.  It is erased
;	on exit.
;
; RESTRICTIONS:
;	Works only with window system drivers.
;
; PROCEDURE:
;	The graphics function is set to 6 for eXclusive OR.  This
;	allows the box to be drawn and erased without disturbing the
;	contents of the window.
;
;	Operation is as follows:
;	Left mouse button:   Move the box by dragging.
;	Middle mouse button: Resize the box by dragging.  The corner
;		nearest the initial mouse position is moved.
;	Right mouse button:  Exit this procedure, returning the 
;			     current box parameters.
;
; MODIFICATION HISTORY:
;	DMS, April, 1990.
;	DMS, April, 1992.  Made dragging more intutitive.
;	June, 1993 - Bill Thompson
;			prevented the box from having a negative size.
;       September 1, 1994 -- Liyun Wang
;                            Added the COLOR keyword
;-

   DEVICE, get_graphics = old, set_graphics = 6 ;Set xor

   IF N_ELEMENTS(color) EQ 0 THEN color = !d.n_colors -1

   IF KEYWORD_SET(MESSAGE) THEN BEGIN
      PRINT, "Drag Left button to move box."
      PRINT, "Drag Middle button near a corner to resize box."
      PRINT, "Right button when done."
   ENDIF

   IF KEYWORD_SET(init) EQ 0 THEN BEGIN ;Supply default values for box:
      IF KEYWORD_SET(fixed_size) EQ 0 THEN BEGIN
         nx = !d.x_size/8       ;no fixed size.
         ny = !d.x_size/8
      ENDIF
      x0 = !d.x_size/2 - nx/2
      y0 = !d.y_size/2 - ny/2
   ENDIF

   button = 0
   GOTO, middle

   WHILE 1 DO BEGIN
      old_button = button
      cursor, x, y, 2, /dev	;Wait for a button
      button = !err
      IF (old_button EQ 0) AND (button NE 0) THEN BEGIN
         mx0 = x		;For dragging, mouse locn...
         my0 = y		
         x00 = x0               ;Orig start of ll corner
         y00 = y0
      ENDIF
      IF !err EQ 1 THEN BEGIN   ;Drag entire box?
         x0 = x00 + x - mx0
         y0 = y00 + y - my0
      ENDIF
      IF (!err EQ 2) AND (KEYWORD_SET(fixed_size) EQ 0) THEN BEGIN ;New size?
         IF old_button EQ 0 THEN BEGIN ;Find closest corner
            mind = 1e6
            FOR i=0,3 DO BEGIN
               d = FLOAT(px(i)-x)^2 + FLOAT(py(i)-y)^2
               IF d LT mind THEN BEGIN
                  mind = d
                  corner = i
               ENDIF
            ENDFOR
            nx0 = nx            ;Save sizes.
            ny0 = ny
         ENDIF
         dx = x - mx0 & dy = y - my0 ;Distance dragged...
         CASE corner OF
            0: BEGIN x0 = x00 + dx & y0 = y00 + dy
            nx = nx0 -dx & ny = ny0 - dy & ENDCASE
            1: BEGIN y0 = y00 + dy
            nx = nx0 + dx & ny = ny0 - dy & ENDCASE
            2: BEGIN nx = nx0 + dx & ny = ny0 + dy & ENDCASE
            3: BEGIN x0 = x00 + dx
            nx = nx0 -  dx & ny = ny0 + dy & ENDCASE
         ENDCASE
      ENDIF
      PLOTS, px, py, col=color, /dev, thick=1, lines=0 ;Erase previous box
      EMPTY                     ;Decwindow bug

      IF !err EQ 4 THEN BEGIN   ;Quitting?
         DEVICE,set_graphics = old
         RETURN
      ENDIF
      
middle:

      IF nx LT 0 THEN BEGIN
         x0 = x0 + nx
         nx = -nx
      ENDIF
      IF ny LT 0 THEN BEGIN
         y0 = y0 + ny
         ny = -ny
      ENDIF

      x0 = x0 > 0
      y0 = y0 > 0
      x0 = x0 < (!d.x_size-1 - nx) ;Never outside window
      y0 = y0 < (!d.y_size-1 - ny)

      px = [x0, x0 + nx, x0 + nx, x0, x0] ;X points
      py = [y0, y0, y0 + ny, y0 + ny, y0] ;Y values

      PLOTS,px, py, col=color, /dev, thick=1, lines=0 ;Draw the box
      wait, .1                  ;Dont hog it all
   ENDWHILE
END
