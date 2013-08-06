	PRO TVPLOT_TRACE,P1,P2,P3,P4,P5,P6,P7,DISABLE=DISABLE,PSYM=PSYM, $
		COLOR=COLOR
;+
; Project     : SOHO - CDS
;
; Name        : 
;	TVPLOT_TRACE
; Purpose     : 
;	Plots traces over images displayed with EXPTV or a similar procedure.
; Explanation : 
;	A number of system variables are changed to allow overplotting on the 
;	image display screen.  These system variables are then changed back to
;	their original values.
; Use         : 
;	TVPLOT_TRACE, [ XTRACE, ]  YTRACE  [, ARRAY, MX, MY, JX, JY ]
; Inputs      : 
;	YTRACE	 = Trace.
; Opt. Inputs : 
;	XTRACE	 = Array of X values corresponding to Y values in YTRACE.
;
;	ARRAY	 = Image to plot trace over.
;	MX, MY	 = The size of the image on the display screen.
;	JX, JY	 = The position of the lower left-hand corner of the image on 
;		   the display screen.
;
;	If the last five optional parameters are not passed, then they are
;	retrieved with GET_TV_SCALE.  It is anticipated that these optional
;	parameters will only be used in extremely rare circumstances.
;
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	DISABLE  = If set, then TVSELECT not used.
;	PSYM	 = Plotting symbol.
;	COLOR	 = Plotting color.
; Calls       : 
;	GET_TV_SCALE, TVSELECT, TVUNSELECT
; Common      : 
;	None.
; Restrictions: 
;	ARRAY must be two-dimensional.
;
;	It is important that the user select the graphics device/window, and
;	image region before calling this routine.  For instance, if the image
;	was displayed using EXPTV,/DISABLE, then this routine should also be
;	called with the /DISABLE keyword.  If multiple images are displayed
;	within the same window, then use SETIMAGE to select the image before
;	calling this routine.
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
;	The values of MX, MY and JX, JY are printed to the terminal screen.
; Category    : 
;
; Prev. Hist. : 
;	W.T.T., Oct. 1987.
;	W.T.T., Feb. 1991, modified to use TVSELECT, TVUNSELECT.
;	William Thompson, May 1992, modified to use GET_TV_SCALE.
;	William Thompson, Nov 1992, removed call to INIT_SC1_SC4.
; Written     : 
;	William Thompson, GSFC, October 1987.
; Modified    : 
;	Version 1, William Thompson, GSFC, 11 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 11 May 1993.
;-
;
        ON_ERROR,2
;
;  Check the number of parameters.
;
	CASE N_PARAMS() OF
		1:  BEGIN
			XTRACE = INDGEN(N_ELEMENTS(P1))
			YTRACE = P1
			END
		2:  BEGIN
			XTRACE = P1
			YTRACE = P2
			END
		6:  BEGIN
			XTRACE = INDGEN(N_ELEMENTS(P1))
			YTRACE = P1
			S = SIZE(P2)
			IF S(0) NE 2 THEN MESSAGE,	$
				'ARRAY must be two-dimensional'
			SX = S(1)
			SY = S(2)
			MX = P3
			MY = P4
			JX = P5
			JY = P6
			END
		7:  BEGIN
			XTRACE = P1
			YTRACE = P2
			S = SIZE(P3)
			IF S(0) NE 2 THEN MESSAGE,	$
				'ARRAY must be two-dimensional'
			SX = S(1)
			SY = S(2)
			MX = P4
			MY = P5
			JX = P6
			JY = P7
			END
		ELSE:  BEGIN
			PRINT,'*** TVPLOT_TRACE must be called with 1-7 parameters:'
			PRINT,'      [ XTRACE, ]  YTRACE  [, ARRAY, MX, MY, JX, JY ]'
			RETURN
			END
	ENDCASE
;
;  Check the dimensions of XTRACE and YTRACE.
;
	IF N_ELEMENTS(XTRACE) LT 2 THEN BEGIN
		PRINT,'*** Variable must be a vector, name= XTRACE, routine TVPLOT_TRACE.'
		RETURN
	END ELSE IF N_ELEMENTS(YTRACE) LT 2 THEN BEGIN
		PRINT,'*** Variable must be a vector, name= YTRACE, routine TVPLOT_TRACE.'
		RETURN
	ENDIF
;
;  If necessary, scale ARRAY to the image display screen. 
;
	IF N_PARAMS(0) LT 6 THEN GET_TV_SCALE,SX,SY,MX,MY,JX,JY,DISABLE=DISABLE
;
;  Check the dimensions of MX, MY, JX and JY.
;
	IF N_ELEMENTS(MX) EQ 0 THEN BEGIN
		PRINT,'*** Variable not defined, name= MX, routine TVPLOT_TRACE.'
		RETURN
	END ELSE IF N_ELEMENTS(MX) GT 1 THEN BEGIN
		PRINT,'*** Variable must be scalar, name= MX, routine TVPLOT_TRACE.'
		RETURN
	END ELSE IF N_ELEMENTS(MY) EQ 0 THEN BEGIN
		PRINT,'*** Variable not defined, name= MY, routine TVPLOT_TRACE.'
		RETURN
	END ELSE IF N_ELEMENTS(MY) GT 1 THEN BEGIN
		PRINT,'*** Variable must be scalar, name= MY, routine TVPLOT_TRACE.'
		RETURN
	END ELSE IF N_ELEMENTS(JX) EQ 0 THEN BEGIN
		PRINT,'*** Variable not defined, name= JX, routine TVPLOT_TRACE.'
		RETURN
	END ELSE IF N_ELEMENTS(JX) GT 1 THEN BEGIN
		PRINT,'*** Variable must be scalar, name= JX, routine TVPLOT_TRACE.'
		RETURN
	END ELSE IF N_ELEMENTS(JY) EQ 0 THEN BEGIN
		PRINT,'*** Variable not defined, name= JY, routine TVPLOT_TRACE.'
		RETURN
	END ELSE IF N_ELEMENTS(JY) GT 1 THEN BEGIN
		PRINT,'*** Variable must be scalar, name= JY, routine TVPLOT_TRACE.'
		RETURN
	ENDIF
;
	IF (MX LE 0) OR (MY LE 0) THEN BEGIN
		PRINT,'*** Unable to expand array, routine TVPLOT_TRACE.'
		RETURN
	ENDIF
	IX = MX / SX
	IY = MY / SY
;
;  Select the image display device or window.
;
	TVSELECT, DISABLE=DISABLE
;
;  Set the system variables, and save the current values.  The borders of the
;  plot, !SC1-!SC4, are set to the edges of the image.
;
	NOERAS = !NOERAS   &  !NOERAS = -1
	XSTYLE = !X.STYLE  &  !X.STYLE = 5
	YSTYLE = !Y.STYLE  &  !Y.STYLE = 5
	POSITION = !P.POSITION
	XWINDOW  = !X.WINDOW
	YWINDOW  = !Y.WINDOW
	!SC1 = JX
	!SC2 = JX + MX - 1
	!SC3 = JY
	!SC4 = JY + MY - 1
;
;  If XTRACE array is its own INDGEN, then the scale parameters !CXMIN, !CXMAX
;  and !XS are set by the image.  Otherwise they are set by the minimum and
;  maximum values of XTRACE. 
;
	CXMIN = !CXMIN  &  CXMAX = !CXMAX
	CYMIN = !CYMIN  &  CYMAX = !CYMAX
	XS = !X.S  &  YS = !Y.S
	BANG_C = !C
;
	IF TOTAL((XTRACE-INDGEN(N_ELEMENTS(XTRACE)))^2) EQ 0 THEN BEGIN
		!CXMIN = -0.5
		!CXMAX = SX - 0.5
	END ELSE BEGIN
		!CXMIN = MIN(XTRACE) < 0
		!CXMAX = MAX(XTRACE) > 0
	ENDELSE
	IF !CXMIN EQ !CXMAX THEN BEGIN
		!CXMIN = 0
		!CXMAX = 1
	ENDIF
	!X.S = [!SC1*!CXMAX - !SC2*!CXMIN, !SC2 - !SC1] / $
		(!D.X_SIZE*(!CXMAX - !CXMIN))
;
;  If YTRACE array is its own INDGEN, then the scale parameters !CYMIN, !CYMAX
;  and !YS are set by the image.  Otherwise they are set by the minimum and
;  maximum values of YTRACE. 
;
	IF TOTAL((YTRACE-INDGEN(N_ELEMENTS(YTRACE)))^2) EQ 0 THEN BEGIN
		!CYMIN = -0.5
		!CYMAX = SY - 0.5
	END ELSE BEGIN
		!CYMIN = MIN(YTRACE) < 0
		!CYMAX = MAX(YTRACE) > 0
	ENDELSE
	IF !CYMIN EQ !CYMAX THEN BEGIN
		!CYMIN = 0
		!CYMAX = 1
	ENDIF
	!Y.S = [!SC3*!CYMAX - !SC4*!CYMIN, !SC4 - !SC3] / $
		(!D.Y_SIZE*(!CYMAX - !CYMIN))
	BANG_C = !C
;
;  Make sure the optional plotting keywords are defined.
;
	IF N_ELEMENTS(COLOR) EQ 0 THEN COLOR = !COLOR
	IF N_ELEMENTS(PSYM)  EQ 0 THEN PSYM  = !PSYM
;
;  Plot the trace and restore the system parameters.
;
	OPLOT,XTRACE,YTRACE,PSYM=PSYM,COLOR=COLOR
	!P.POSITION = POSITION
	!X.WINDOW = XWINDOW
	!Y.WINDOW = YWINDOW
	!CXMIN = CXMIN  &  !CXMAX = CXMAX
	!CYMIN = CYMIN  &  !CYMAX = CYMAX
	!X.S = XS  &  !Y.S = YS
	!NOERAS = NOERAS
	!X.STYLE = XSTYLE  &  !Y.STYLE = YSTYLE
	TVUNSELECT, DISABLE=DISABLE
;
	RETURN
	END
