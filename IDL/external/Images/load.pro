	PRO LOAD, TABLE_NUMBER, SILENT=SILENT, DISABLE=DISABLE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	LOAD
; Purpose     : 
;	Load predefined color tables.
; Explanation : 
;	The image display device is selected (unless DISABLE is set), and
;	LOADCT is called to display the color tables.  See LOADCT in the IDL
;	User's Library for more information.
; Use         : 
;	LOAD  [, TABLE]
; Inputs      : 
;	None required.
; Opt. Inputs : 
;	TABLE	= The number of the pre-defined color table to load, from 0 to
;		  15.  If this value is omitted, a menu of the available tables
;		  is printed and the user is prompted to enter a table number.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	SILENT	= If set, the Color Table message is suppressed.
;	DISABLE	= If set, then TVSELECT is not used.
; Calls       : 
;	TVSELECT, TVUNSELECT
; Common      : 
;	None, but calls LOADCT, which uses the common block COLORS.
; Restrictions: 
;	Works from the file: $IDL_DIR/colors1.tbl.
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
;	The color tables of the currently-selected device are modified.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	William Thompson, April 1992, added SILENT and DISABLE keywords.
; Written     : 
;	William Thompson, GSFC.
; Modified    : 
;	Version 1, William Thompson, GSFC, 13 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 13 May 1993.
;-
;
	ON_ERROR,2
;
	TVSELECT, DISABLE=DISABLE
	IF N_PARAMS(0) EQ 0 THEN LOADCT, SILENT=SILENT		$
			    ELSE LOADCT, SILENT=SILENT, TABLE_NUMBER
	TVUNSELECT, DISABLE=DISABLE
;
	RETURN
	END
