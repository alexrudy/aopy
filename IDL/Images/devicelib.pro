	PRO DEVICELIB
;+
; Project     : SOHO - CDS
;
; Name        : 
;	DEVICELIB
; Purpose     : 
;	Definitions needed for the SERTS graphics device library.
; Explanation : 
;	Defines variables and common blocks needed for the SERTS graphics
;	device library.  Adds system variables !BCOLOR and !ASPECT.
; Use         : 
;	DEVICELIB
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
;	None.
; Common      : 
;	None.
; Restrictions: 
;	This routine should be called only once, preferably in the startup
;	procedure.
; Side effects: 
;	System variables may be changed to their default values.
; Category    : 
;	Utilities,
; Prev. Hist. : 
;	William Thompson, 10 November 1992.
; Written     : 
;	William Thompson, GSFC, 10 November 1992.
; Modified    : 
;	Version 1, William Thompson, GSFC, 23 June 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 23 June 1993.
;-
;
;  !BCOLOR used in some plotting and image display routines.  Hangover from IDL
;  version 1.
;
	DEFSYSV,'!BCOLOR',0
	MESSAGE,'Added system variable !BCOLOR',/INFORMATIONAL
;
;  !ASPECT is the aspect ratio of the plotting device, expressed as the pixel
;  height over the pixel width.  Used by SCALE_TV and by SETSCALE.
;
	DEFSYSV,'!ASPECT',1.0
	MESSAGE,'Added system variable !ASPECT',/INFORMATIONAL
;
	RETURN
	END
