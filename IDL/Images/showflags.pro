	PRO SHOWFLAGS
;+
; Project     : SOHO - CDS
;
; Name        : 
;	SHOWFLAGS
; Purpose     : 
;	Show the settings controlled by SET/UNSET/ENABLEFLAG.
; Explanation : 
;	Shows the flag fields in the !IMAGE structure as set by the routines
;	SETFLAG, UNSETFLAG, and ENABLEFLAG.
; Use         : 
;	SHOWFLAGS
; Inputs      : 
;	None.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	None.
; Calls       : 
;	TRIM
; Common      : 
;	None.
; Restrictions: 
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
;	None.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	William Thompson, June 1991.
;	W.T.T., Nov. 1991, added support for MIN, MAX, VMIN, VMAX, TOP and
;			   COMBINED.
;	William Thompson, August 1992, renamed BADPIXEL to MISSING.
; Written     : 
;	William Thompson, GSFC, June 1991.
; Modified    : 
;	Version 1, William Thompson, GSFC, 12 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 12 May 1993.
;-
;
	NSET = 0
;
	IF !IMAGE.NOSQUARE THEN BEGIN
		PRINT,'NOSQUARE is set.'
		NSET = NSET + 1
	ENDIF
;
	IF !IMAGE.SMOOTH THEN BEGIN
		PRINT,'SMOOTH is set.'
		NSET = NSET + 1
	ENDIF
;
	IF !IMAGE.NOBOX THEN BEGIN
		PRINT,'NOBOX is set.'
		NSET = NSET + 1
	ENDIF
;
	IF !IMAGE.NOSCALE THEN BEGIN
		PRINT,'NOSCALE is set.'
		NSET = NSET + 1
	ENDIF
;
	IF !IMAGE.MISSING.SET THEN BEGIN
		PRINT,'MISSING is set to ' + TRIM(!IMAGE.MISSING.VALUE)
		NSET = NSET + 1
	ENDIF
;
	IF !IMAGE.SIZE.SET THEN BEGIN
		PRINT,'SIZE is set to ' + TRIM(!IMAGE.SIZE.VALUE)
		NSET = NSET + 1
	ENDIF
;
	IF !IMAGE.NOEXACT THEN BEGIN
		PRINT,'NOEXACT is set.'
		NSET = NSET + 1
	ENDIF
;
	IF !IMAGE.XALIGN.SET THEN BEGIN
		PRINT,'XALIGN is set to ' + TRIM(!IMAGE.XALIGN.VALUE)
		NSET = NSET + 1
	ENDIF
;
	IF !IMAGE.YALIGN.SET THEN BEGIN
		PRINT,'YALIGN is set to ' + TRIM(!IMAGE.YALIGN.VALUE)
		NSET = NSET + 1
	ENDIF
;
	IF !IMAGE.RELATIVE.SET THEN BEGIN
		PRINT,'RELATIVE is set to ' + TRIM(!IMAGE.RELATIVE.VALUE)
		NSET = NSET + 1
	ENDIF
;
	IF !IMAGE.MIN.SET THEN BEGIN
		PRINT,'MIN is set to ' + TRIM(!IMAGE.MIN.VALUE)
		NSET = NSET + 1
	ENDIF
;
	IF !IMAGE.MAX.SET THEN BEGIN
		PRINT,'MAX is set to ' + TRIM(!IMAGE.MAX.VALUE)
		NSET = NSET + 1
	ENDIF
;
	IF !IMAGE.VMIN.SET THEN BEGIN
		PRINT,'Velocity MIN is set to ' + TRIM(!IMAGE.VMIN.VALUE)
		NSET = NSET + 1
	ENDIF
;
	IF !IMAGE.VMAX.SET THEN BEGIN
		PRINT,'Velocity MAX is set to ' + TRIM(!IMAGE.VMAX.VALUE)
		NSET = NSET + 1
	ENDIF
;
	IF !IMAGE.TOP.SET THEN BEGIN
		PRINT,'TOP is set to ' + TRIM(!IMAGE.TOP.VALUE)
		NSET = NSET + 1
	ENDIF
;
	IF !IMAGE.COMBINED THEN BEGIN
		PRINT,'COMBINED is set.'
		NSET = NSET + 1
	ENDIF
;
	IF NSET EQ 0 THEN PRINT,'No flags are set.'
;
	RETURN
	END
