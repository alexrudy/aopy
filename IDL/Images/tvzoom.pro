;+
; Project     : SOHO - CDS
;
; Name        : 
;	TVZOOM
; Purpose     : 
;	Zooms into the current image display window.
; Explanation : 
;	Display part of an image (or graphics) from the current window expanded
;	in another window.  The cursor is used to mark the center of the zoom.
;	This routine differs from the standard ZOOM routine in that the
;	currently selected image display window (TVDEVICE) is used.
;
;	If TVZOOM is called with the optional IMAGE parameter, then a widget is
;	created which allows the user to roam the image at true resolution,
;	instead of just the displayed resolution.
;
; Use         : 
;	TVZOOM
;	TVZOOM, IMAGE  [, X0, X1, Y0, Y1 ]
; Inputs      : 
;	None required.
; Opt. Inputs : 
;	IMAGE
; Outputs     : 
;	No explicit outputs.  A new window is created and optionally destroyed
;	when the procedure is exited.
; Opt. Outputs: 
;	X0, X1, Y0, Y1 = The coordinates of the corners of the zoomed image.
; Keywords    : 
;	FACT	   = Zoom expansion factor, default = 4.
;	INTERP	   = Set to interpolate, otherwise pixel replication is used.
;	XSIZE	   = X size of new window, if omitted, 250.
;	YSIZE	   = Y size of new window, default = 250.
;	CONTINUOUS = Keyword param which, if set obviates the need to press the
;		     left mouse button.  The zoom window tracks the mouse.
;		     Only works well on fast computers.
;	KEEP	   = Keep the zoom window after exiting the procedure.
;	ZOOM_WINDOW= When used with KEEP, returns the index of the zoom window.
;		     Otherwise, if KEEP is not set, then -1 is returned.
;	NEW_WINDOW = Normally, if ZOOM is called with /KEEP and then called
;		     again, it will use the same window to display the zoomed
;		     image.  Calling ZOOM with /NEW_WINDOW forces it to create
;		     a new window for this purpose.
;	DISABLE	   = If set, then TVSELECT is not called.
;	RECURSIVE  = An internally used keyword to signal that TVZOOM is
;		     calling itself recursively.  This is used to support
;		     Microsoft Windows.  This keyword should not be used
;		     externally to TVZOOM.
;
;	    If the optional IMAGE parameter is passed, then the following
;	    keyword parameters can be used to adjust the scale of the image:
;
;	NOSCALE  = If set, then the image is not scaled.
;	MISSING	 = Value flagging missing pixels.  These points are scaled to
;		   zero.
;	MAX	 = The maximum value of IMAGE to be considered in scaling the
;		   image, as used by BYTSCL.  The default is the maximum value
;		   of IMAGE.
;	MIN	 = The minimum value of IMAGE to be considered in scaling the
;		   image, as used by BYTSCL.  The default is the minimum value
;		   of IMAGE.
;	TOP	 = The maximum value of the scaled image array, as used by
;		   BYTSCL.  The default is !D.N_COLORS-1.
;	VELOCITY = If set, then the image is scaled using FORM_VEL as a
;		   velocity image.  Can be used in conjunction with COMBINED
;		   keyword.  Ignored if NOSCALE is set.
;	COMBINED = Signals that the image is to be displayed in one of two
;		   combined color tables.  Can be used by itself, or in
;		   conjunction with the VELOCITY or LOWER keywords.
;	LOWER	 = If set, then the image is placed in the lower part of the
;		   color table, rather than the upper.  Used in conjunction
;		   with COMBINED keyword.
; Calls       : 
;	TVSELECT, TVUNSELECT, ZOOM, CW_TVZOOM
; Common      : 
;	TVZOOM_COMMON is an internal common block.
; Restrictions: 
;	Only works with color systems.  Using TVZOOM with the optional IMAGE
;	parameter requires that the graphics device supports widgets.
;
;	When the optional IMAGE parameter is passed, then TVZOOM should be
;	called with the same intensity scaling keyword settings that the image
;	was originally displayed with.  There may still be some difference in
;	intensity between the original and zoomed images if the original image
;	was not displayed at full resolution.
;
;	This version of TVZOOM uses a version of ZOOM that is distributed with
;	IDL starting with version 3.1.1.
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
;	When TVZOOM is reusing a zoom window from a previous call to
;	TVZOOM,/KEEP, then the XSIZE and YSIZE parameters are reset to the
;	actual size of the window.
;
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	W.T.T., Mar. 1990.
;	W.T.T., Feb. 1991, modified to use TVSELECT, TVUNSELECT.
; Written     : 
;	William Thompson, GSFC, March 1990.
; Modified    : 
;	Version 1, William Thompson, GSFC, 5 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 3 June 1993.
;		Added option of passing IMAGE array directly to routine.
;		Added DISABLE keyword.
;		Added RECURSIVE keyword.
;		Added dummy widget routines, added /NOSCALE to recursive call.
; Version     : 
;	Version 2, 3 June 1993.
;-
;
;  The following dummy routines allow TVZOOM to work with IDL VMS executables
;  that do not support widgets.  They are only there to allow TVZOOM to compile
;  correctly--they will never be executed.
;
	FUNCTION WIDGET_BASE,TITLE=TITLE,COLUMN=COLUMN
	END
	FUNCTION WIDGET_TEXT,BASE,VALUE=VALUE,XSIZE=XSIZE
	END
;
;******************************************************************************
;			 TVZOOM widget event handler.
;******************************************************************************
;
	PRO TVZOOM_EVENT, EVENT
;
	COMMON TVZOOM_COMMON,XX0,YY0,XX1,YY1,ZOOM_WINDOW,ZOOMED_IMAGE
;
	WIDGET_CONTROL, GET_UVALUE=VALUE, EVENT.ID
	IF VALUE EQ 'Zoom' THEN BEGIN
		XX0 = EVENT.X0
		YY0 = EVENT.Y0
		XX1 = EVENT.X1
		YY1 = EVENT.Y1
		WIDGET_CONTROL, GET_VALUE=ZOOMED_IMAGE, EVENT.ID
		WIDGET_CONTROL, /DESTROY, EVENT.TOP
	ENDIF
;
	END
;
;******************************************************************************
;			    Main TVZOOM procedure.
;******************************************************************************
;
	PRO TVZOOM, IMAGE, X0, X1, Y0, Y1, XSIZE=XS, YSIZE=YS, FACT=FACT, $
		INTERP=INTERP, CONTINUOUS=CONT, NOSCALE=NOSCALE,	$
		MISSING=MISSING, MAX=MAX, MIN=MIN, TOP=TOP,		$
		VELOCITY=VELOCITY, COMBINED=COMBINED, LOWER=LOWER, KEEP=KEEP, $
		ZOOM_WINDOW=ZOOM_WIN,NEW_WINDOW=NEW_WIN,DISABLE=DISABLE, $
		RECURSIVE=RECURSIVE
;
	ON_ERROR,2              ;Return to caller if an error occurs
	COMMON TVZOOM_COMMON,XX0,YY0,XX1,YY1,ZOOM_WINDOW,ZOOMED_IMAGE
;
;  If not passed, then set XSIZE and YSIZE to their default values.
;
	IF N_ELEMENTS(XS) NE 1 THEN XS = 250L
	IF N_ELEMENTS(YS) NE 1 THEN YS = 250L
;
;  Make sure that the ZOOM_WINDOW parameter is defined.  The value -1 stands
;  for no current zoom window.  The NEW_WINDOW keyword forces a new window to
;  be used.
;
	IF KEYWORD_SET(NEW_WIN) THEN ZOOM_WINDOW = -1
	IF N_ELEMENTS(ZOOM_WINDOW) EQ 0 THEN ZOOM_WINDOW = -1
;
;  Make sure that the zoom window does in fact exist.
;
	IF ZOOM_WINDOW GE 0 THEN BEGIN
		DEVICE, WINDOW_STATE=WIN_STATE
		IF NOT WIN_STATE(ZOOM_WINDOW) THEN ZOOM_WINDOW = -1
	ENDIF
;
;  If a zoom window already exists, then get the size of the window.
;
	IF ZOOM_WINDOW GE 0 THEN BEGIN
		OLD_WINDOW = !D.WINDOW
		WSET, ZOOM_WINDOW
		XS = !D.X_SIZE
		YS = !D.Y_SIZE
		WSET, OLD_WINDOW
	ENDIF
;
;  If IMAGE was not passed, then simply call ZOOM.  However, if the graphics
;  device is Microsoft windows, then read the image from the window and use
;  the widget version of TVZOOM on that image.
;
	IF N_PARAMS() EQ 0 THEN BEGIN
		IF !D.NAME EQ 'WIN' THEN BEGIN
			A = TVREAD(DISABLE=DISABLE)
			TVZOOM, A, XSIZE=XS, YSIZE=YS, FACT=FACT,	$
				INTERP=INTERP, CONTINUOUS=CONT, KEEP=KEEP, $
				ZOOM_WINDOW=ZOOM_WIN, NEW_WINDOW=NEW_WIN, $
				/RECURSIVE,/NOSCALE
		END ELSE BEGIN
			TVSELECT, DISABLE=DISABLE
			ZOOM, XSIZE=XS, YSIZE=YS, FACT=FACT, INTERP=INTERP, $
				CONTINUOUS=CONT, KEEP=KEEP,	$
				ZOOM_WINDOW=ZOOM_WIN, NEW_WINDOW=NEW_WIN
			TVUNSELECT, DISABLE=DISABLE
		ENDELSE
;
;  Otherwise, if IMAGE was passed, then check the IMAGE array.
;
	END ELSE BEGIN
		S = SIZE(IMAGE)
		IF S(0) NE 2 THEN MESSAGE, 'IMAGE must be two-dimensional.
;
;  Get the scale of the displayed image.  Calculate the reduction value.
;
		IF NOT KEYWORD_SET(RECURSIVE) THEN BEGIN
			GET_TV_SCALE,SX,SY,MX,MY,IX,IY,DISABLE=DISABLE
			IF (SX NE S(1)) OR (SY NE S(2)) THEN MESSAGE,	$
			    'IMAGE size does not agree with displayed image'
			REDUCTION = (FLOAT(SX)/MX) > (FLOAT(SY)/MY) > 1
		END ELSE BEGIN
			SX = S(1)
			SY = S(2)
			REDUCTION = 1
		ENDELSE
;
;  Call CW_TVZOOM to display the zoomed image.
;
		IM = IMAGE
		BSCALE,IM,NOSCALE=NOSCALE,MISSING=MISSING,MAX=MAX,MIN=MIN, $
			TOP=TOP,VELOCITY=VELOCITY,COMBINED=COMBINED,LOWER=LOWER
		BASE = WIDGET_BASE(TITLE='TVZOOM',/COLUMN)
		TEXT = 'Exit with "Report Zoom to Parent" button'
		TEMP = WIDGET_TEXT(BASE,VALUE=TEXT,XSIZE=STRLEN(TEXT))
		ZOOMW = CW_TVZOOM(BASE,UVALUE='Zoom',XSIZE=SX,YSIZE=SY,	$
			REDUCTION=REDUCTION,SAMPLE=(1-KEYWORD_SET(INTERP)), $
			TRACK=CONT,X_ZSIZE=XS,Y_ZSIZE=YS)
		OLD_WINDOW = !D.WINDOW
		WIDGET_CONTROL,BASE,/REALIZE
		WIDGET_CONTROL,ZOOMW,SET_VALUE=IM
		XMANAGER,'TVZOOM',BASE
		WSET, OLD_WINDOW
;
;  Retrieve the coordinates of the zoomed image.
;
		X0 = XX0
		Y0 = YY0
		X1 = XX1
		Y1 = YY1
;
;  If the KEEP keyword was set, then display the zoomed image in the zoom
;  window.
;
		IF KEYWORD_SET(KEEP) THEN BEGIN
;
;  Store the value of the current window.  If a zoom window hasn't been created
;  yet, then create it.  Otherwise, switch to the zoom window.
;
			OLD_WINDOW = !D.WINDOW
			IF ZOOM_WINDOW LT 0 THEN BEGIN	;Make new window?
				WINDOW,/FREE,XSIZE=XS,YSIZE=YS,	$
					TITLE='Zoomed Image'
				ZOOM_WINDOW = !D.WINDOW
			ENDIF ELSE BEGIN
				WSET, ZOOM_WINDOW
			ENDELSE
;
;  Display the zoomed image in the window, and reset to the undisplayed window.
;
			TV, ZOOMED_IMAGE
			WSET, OLD_WINDOW
;
;  If KEEP was not set, and a zoom window already exists, then destroy it.
;  This maintains compatibility with the behavior of the standard ZOOM routine.
;
		END ELSE BEGIN
			IF ZOOM_WINDOW GE 0 THEN WDELETE, ZOOM_WINDOW
			ZOOM_WINDOW = -1
		ENDELSE
;
;  Return the index of the zoom window to the user.
;
		ZOOM_WIN = ZOOM_WINDOW
	ENDELSE
;
	RETURN
	END
