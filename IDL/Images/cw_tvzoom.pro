; Copyright (c) 1992, Research Systems, Inc.  All rights reserved.
;	Unauthorized reproduction prohibited.
;+
; Project     :	SOHO - CDS
;
; Name        :	
;	CW_TVZOOM
;
; Purpose     :	
;	Compound widget for displaying zoomed images. (cf CW_ZOOM).
;
; Explanation :	
;	This compound widget displays an original image in one window
;	and another window in which a portion of the original window
;	is displayed.  The user may select the center of the zoom
;	region, the zoom scale, the interpolation style, and the method
;	of indicating the zoom center.
;
; Use         :	
;	widget = CW_TVZOOM(parent)
;
;	WIDGET_CONTROL, id, SET_VALUE=value can be used to change the
;		original, unzoomed image displayed by the widget.
;		The value may not be set until the widget has been
;		realized.
;
;	WIDGET_CONTROL, id, GET_VALUE=var can be used to obtain the current
;		zoomed image displayed by the widget.
;
; Inputs      :	
;       PARENT - The ID of the parent widget.
;
; Opt. Inputs :	
;
; Outputs     :	
;       The ID of the created widget is returned.
;
; Opt. Outputs:	
;	None.
;
; Keywords    :	
;	FRAME - Nonzero to have a frame drawn around the widget. The
;		default is FRAME=0.
;	MAX -   The maximum zoom scale.  The default is 20.  The scale
;		must be greater than or equal to 1.
;	MIN -   The minimum zoom scale.  The default is 1.  The scale
;		must be greater than or equal to 1.
;	RETAIN - Controls the setting for backing store for the original
;		image window and zoom window.  If backing store is provided,
;		a window which was obscured will be repaired when it becomes
;		exposed.  Set RETAIN=0 for no backing store.  Set RETAIN=1
;		for "request backing store from server".  This is the default.
;		Set RETAIN=2 for IDL to provide backing store.
;	SAMPLE - Zero for bilinear interpolation, non-zero for nearest
;		neighber interpolation.  Bilinear interpolation gives
;		higher quality results, but requires more time.  The
;		default is SAMPLE=0.
;	SCALE - The initial integer scale factor to use for the zoomed image.
;		The default is SCALE=4.  The scale must be greater than or
;		equal to 1.
;	TRACK - Zero if the zoom window should be updated only when the mouse
;		is pressed. Non-zero if the zoom window should be updated
;		continuously as the cursor is moved across the original
;		image. Note: On slow systems, /TRACK performance can be
;		inadequate. The default is TRACK=0.
;	UVALUE - Supplies the user value for the widget.
;	XSIZE - The width of the window for the original image.
;		The default is 500.
;	YSIZE - The height of the window for the original image.
;		The default is 500.
;	REDUCTION - An amount to reduce the resolution when displaying the
;		original image.  The zoomed image is taken from the full
;		resolution original image.  Must be greater than or equal to 1.
;		The default is 1.
;	X_SCROLL_SIZE - The width of the visible part of the original image.
;		This may be smaller than the actual width controlled by
;		the XSIZE keyword.  The default is 0, for no scroll bar.
;	Y_SCROLL_SIZE - The height of the visible part of the original image.
;		This may be smaller than the actual height controlled by
;		the YSIZE keyword.  The default is 0, for no scroll bar.
;	X_ZSIZE - The width of the window for the zoomed image.
;		The default is 250.
;	Y_ZSIZE - The height of the window for the zoomed image.
;		The default is 250.
;
; Calls       :	
;	None.
;
; Common      :	
;	CW_TVZOOM_BLK: Private to this module.
;
; Restrictions:	
;	Must have widget capability.
;
;	In general, the SERTS image display routines use several non-standard
;	system variables.  These system variables are defined in the procedure
;	IMAGELIB.  It is suggested that the command IMAGELIB be placed in the
;	user's IDL_STARTUP file.
;
;	Some routines also require the SERTS graphics devices software,
;	generally found in a parallel directory at the site where this software
;	was obtained.  Those routines have their own special system variables.
;
; Side effects:	
;	When the "Report Zoom to Parent" button is pressed, this widget
;	will generate an event structures containing several data fields.
;		x_zsize, y_zsize:	size of the zoomed image
;		x0, y0:			lower left corner in original image
;		x1, y1:			upper right corner in original image
;	This event is a report to the parent that allows retrieval of the
;	zoomed image using WIDGET_CONTROL.
;
; Category    :	
;	Utilities, Image_display.
;
; Prev. Hist. :	
;	June 30, 1992, ACY
;	May 18, 1993, William Thompson, GSFC, added keyword REDUCTION, changed
;		call to TVSCL to call TV instead.  Renamed tto CW_TVZOOM.
;
; Written     :	
;	ACY, RSI, 30 June 1993.
;
; Modified    :	
;	Version 1, William Thompson, GSFC, 25 October 1993.
;		Incorporated into CDS library.
;
; Version     :	
;	Version 1, 25 October 1993.
;-

;-----------------------------------------------------------------------------

PRO zoom_set_value, id, value

  COMMON cw_tvzoom_blk, state_base, state_stash, state

  ON_ERROR, 2						;return to caller

  ; Retrieve the state
  IF (id ne state_base) THEN $
    CW_LOADSTATE, id, state_base, state_stash, state

  ; Put the value into the state structure
  state.orig_image = value

  ; Get the window number from the draw widget.  This can only be done
  ; after the widget has been realized.
  WIDGET_CONTROL, state.draw, GET_VALUE=win_temp
  state.draw_win = win_temp(0)
  WIDGET_CONTROL, state.zoom, GET_VALUE=win_temp
  state.zoom_win = win_temp(0)

  ; Use TV to display an image in the draw widget.  Set the window for
  ; the TV command since there may be other draw windows.
  ;Save window number
  save_win = !D.WINDOW
  WSET, state.draw_win
  if state.reduction eq 1 then begin
	TV, value
  END ELSE BEGIN
	TV, congrid(value, !D.X_SIZE, !D.Y_SIZE)
  ENDELSE
  ;Restore window
  IF (save_win NE -1) THEN WSET, save_win

  draw_zoom, state.oldx, state.oldy

  CW_SAVESTATE, id, state_base, state

END

;-----------------------------------------------------------------------------

FUNCTION zoom_get_value, id

  COMMON cw_tvzoom_blk, state_base, state_stash, state

  ON_ERROR, 2                                           ;return to caller

  ; Retrieve the state
  IF (id ne state_base) THEN $
    CW_LOADSTATE, id, state_base, state_stash, state

  ; Get the value from the state structure

  RETURN, state.zoom_image
END

;-----------------------------------------------------------------------------

PRO draw_zoom, newx, newy

  COMMON cw_tvzoom_blk, state_base, state_stash, state

  ; compute size of rectangle in original image
  ; round up to make sure image fills zoom window
  rect_x = long(state.x_zm_sz / float(state.scale) + 0.999)
  rect_y = long(state.y_zm_sz / float(state.scale) + 0.999)

  ; compute location of origin of rect (user specified center)
  x0 = long(newx*state.reduction) - rect_x/2
  y0 = long(newy*state.reduction) - rect_y/2

  ; make sure rectangle fits into original image
  ;left edge from center
  x0 = x0 > 0
  ; limit right position
  x0 = x0 < (state.x_im_sz - rect_x)

  ;bottom
  y0 = y0 > 0
  y0 = y0 < (state.y_im_sz - rect_y)

  IF (state.scale EQ 1) THEN BEGIN
    IF (rect_x GT state.x_im_sz OR rect_y GT state.y_im_sz) THEN BEGIN
      ERASE
      IF (rect_x GT state.x_im_sz) THEN x0 = 0 & rect_x = state.x_im_sz
      IF (rect_y GT state.x_im_sz) THEN y0 = 0 & rect_y = state.y_im_sz
    ENDIF
    ;Save window number
    save_win = !D.WINDOW
    WSET, state.zoom_win
    TV, state.orig_image(x0:x0+rect_x-1,y0:y0+rect_y-1)
    ;Restore window
    IF (save_win NE -1) THEN WSET, save_win
  ENDIF ELSE BEGIN
    ;Make integer rebin factors.  These may be larger than the zoom image
    dim_x = rect_x * state.scale
    dim_y = rect_y * state.scale

    x1 = x0 + rect_x - 1
    y1 = y0 + rect_y - 1

    temp_image = rebin(state.orig_image(x0:x1,y0:y1), $
                       dim_x, dim_y, $
                       sample=state.sample)

    ;Save the zoomed image
    state.zoom_image = $
                     temp_image(0:state.x_zm_sz-1,0:state.y_zm_sz-1)

    ;Save the corners in original image
    state.x0 = x0
    state.y0 = y0
    state.x1 = x1
    state.y1 = y1

    ;Display the new zoomed image
    ;Save window number
    save_win = !D.WINDOW
    WSET, state.zoom_win
    TV, state.zoom_image
    ;Restore window
    IF (save_win NE -1) THEN WSET, save_win

 ENDELSE

END


;-----------------------------------------------------------------------------

FUNCTION zoom_event, event

  COMMON cw_tvzoom_blk, state_base, state_stash, state

  ; Retrieve the structure from the child that contains the sub ids
  parent=event.handler

  IF (parent NE state_base) THEN $
    CW_LOADSTATE, parent, state_base, state_stash, state

  CASE event.id OF
    state.draw: $
       IF state.track GT 0 OR event.press EQ 1 THEN BEGIN
          draw_zoom, event.x, event.y
          state.oldx = event.x
          state.oldy = event.y
       ENDIF

    state.slide: $
       BEGIN
          WIDGET_CONTROL, event.id, GET_VALUE = temp_scale
          IF (temp_scale LT 1) THEN temp_scale = 1
          state.scale = temp_scale
          draw_zoom, state.oldx, state.oldy
       END

    state.sample_base: $
       CASE event.value OF
          state.nn_id: BEGIN
			  state.sample = 1
			  draw_zoom, state.oldx, state.oldy
		       END
          state.bilin_id: BEGIN
                             state.sample = 0
                             draw_zoom, state.oldx, state.oldy
                	  END
       ENDCASE

    state.track_base: $
       CASE event.value OF
          state.notrack_id:  state.track = 0
          state.track_id:    state.track = 1
       ENDCASE
    state.report_id: RETURN, {ZOOM_EVENT, ID:parent, $
			TOP:event.top, HANDLER:0L, $
			x_zsize:state.x_zm_sz, y_zsize:state.y_zm_sz, $
			x0:state.x0, y0:state.y0, $
			x1:state.x1, y1:state.y1}
ENDCASE

; Swallow events, except for the REPORT event
RETURN, 0

END

;-----------------------------------------------------------------------------


FUNCTION cw_tvzoom, parent, $
		FRAME=frame, $
		MAX=max, $
		MIN=min, $
		RETAIN=retain, $
		SAMPLE=sample, $
		SCALE=scale, $
		TRACK=track, $
		UVALUE = uval, $
		XSIZE=xsize, $
		YSIZE=ysize, $
		REDUCTION=REDUCTION, $
		X_SCROLL_SIZE=x_scroll_size, $
		Y_SCROLL_SIZE=y_scroll_size, $
		X_ZSIZE=x_zsize, $
		Y_ZSIZE=y_zsize

  COMMON cw_tvzoom_blk, state_base, state_stash, state

  IF (N_PARAMS() NE 1) THEN MESSAGE, 'Incorrect number of arguments'

  ON_ERROR, 2						;return to caller

  ; Defaults for keywords
  IF (N_ELEMENTS(frame) EQ 0) THEN frame = 0L
  IF (N_ELEMENTS(max) EQ 0) THEN max = 20L
  IF (N_ELEMENTS(min) EQ 0) THEN min = 1L
  IF (N_ELEMENTS(retain) EQ 0) THEN retain = 1L
  IF (N_ELEMENTS(sample) EQ 0) THEN sample = 0L
  IF (N_ELEMENTS(scale) EQ 0) THEN scale = 4L
  IF (N_ELEMENTS(track) EQ 0) THEN track = 0L
  IF (N_ELEMENTS(uval) EQ 0)  THEN uval = 0L
  IF (N_ELEMENTS(xsize) EQ 0) THEN xsize = 500L
  IF (N_ELEMENTS(ysize) EQ 0) THEN ysize = 500L
  IF (N_ELEMENTS(reduction) EQ 0) THEN reduction = 1
	REDUCT = float(reduction) > 1
  IF (N_ELEMENTS(x_scroll_size) EQ 0) THEN x_scroll_size = 0L
  IF (N_ELEMENTS(y_scroll_size) EQ 0) THEN y_scroll_size = 0L
  IF (N_ELEMENTS(x_zsize) EQ 0) THEN x_zsize = 250L
  IF (N_ELEMENTS(y_zsize) EQ 0) THEN y_zsize = 250L


  base = WIDGET_BASE(parent, $
			EVENT_FUNC = 'zoom_event', $
			FRAME = frame, $
			FUNC_GET_VALUE='ZOOM_GET_VALUE', $
			PRO_SET_VALUE='ZOOM_SET_VALUE', $
			/ROW, $
			UVALUE = uval)

  lcol = WIDGET_BASE(base, /COLUMN)

  ; A widget called 'draw' is created.
  draw = WIDGET_DRAW(lcol, $
	/BUTTON_EVENTS, $	;generate events when buttons pressed
	/MOTION_EVENTS, $
	/FRAME, $
	RETAIN = retain, $
	XSIZE = xsize/reduct, $
	YSIZE = ysize/reduct, $
	X_SCROLL_SIZE = x_scroll_size, $
	Y_SCROLL_SIZE = y_scroll_size)

  rcol = WIDGET_BASE(base, /COLUMN)

  ; The REPORT button:
  report = WIDGET_BUTTON(rcol, $
		VALUE = 'REPORT ZOOM TO PARENT')

  ; A label containing some instructions:
  wdrlabel = WIDGET_LABEL(rcol, $
	   VALUE = 'Press left button to zoom.')

  ; A widget called 'zoom' is created.
  zoom = WIDGET_DRAW(rcol, $
        /FRAME, $
        RETAIN = retain, $
        XSIZE = x_zsize, $
        YSIZE = y_zsize)

  IF (min LT 1) THEN min = 1
  IF (max LT 1) THEN max = 1
  slide = WIDGET_SLIDER(rcol, $
                        MINIMUM = min, $
                        MAXIMUM = max, $
                        VALUE = scale, $
                        TITLE = 'Zoom Scale', $
                        /FRAME)

  ;make sure sample is 0 or 1
  IF (sample GT 0) THEN sample = 1
  sample_base = cw_bgroup(rcol, ['Bilinear', 'Nearest Neighbor'], $
		/COLUMN, $
		/EXCLUSIVE, $
		/FRAME, $
		IDS=sample_ids, $
		LABEL_TOP = 'Interpolation Style', $
		/NO_RELEASE, $
		/RETURN_ID, $
		SET_VALUE = sample)

  ;make sure track is 0 or 1
  IF (track GT 0) THEN track = 1
  track_base = cw_bgroup(rcol, ['Button Press Only', 'Track Cursor'], $
		/COLUMN, $
		/EXCLUSIVE, $
		/FRAME, $
		IDS=track_ids, $
		LABEL_TOP = 'Cursor Input Style', $
		/NO_RELEASE, $
		/RETURN_ID, $
		SET_VALUE = track)

  new_state = {	orig_image:	BYTARR(xsize,ysize), $
		zoom_image:	BYTARR(x_zsize,y_zsize), $
		draw:		draw, $
		zoom:		zoom, $
		slide:		slide, $
		sample_base:	sample_base, $
		bilin_id:	sample_ids(0), $
		nn_id:		sample_ids(1), $
		track_base:	track_base, $
		notrack_id:	track_ids(0), $
		track_id:	track_ids(1), $
		report_id:	report, $
		draw_win:	-1L, $
		zoom_win:	-1L, $
		x_im_sz:	xsize, $
		y_im_sz:	ysize, $
		reduction:	reduct, $
		retain:		1L, $
		track:		track, $
		scale:		scale, $
		sample:		sample, $
		x_zm_sz:	x_zsize, $
		y_zm_sz:	y_zsize, $
		oldx:		xsize / 2L /reduct, $
		oldy:		ysize / 2L /reduct, $
		x0:		0L, $
		y0:		0L, $
		x1:		0L, $
		y1:		0L $
		}

  CW_SAVESTATE, base, state_base, new_state
  RETURN, base

END
