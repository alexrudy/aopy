	PRO IMAGELIB
;+
; Project     : SOHO - CDS
;
; Name        : 
;	IMAGELIB
; Purpose     : 
;	Defines variables/common blocks for the SERTS IMAGE library.
; Explanation : 
;	Adds system variable !IMAGE.
; Use         : 
;	IMAGELIB
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
;	procedure.  DEVICELIB should also be called, because these routines use
;	some of the routines from the graphics devices utilities subdirectory.
; Side effects: 
;	System variables may be changed to their default values.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	William Thompson, 5 December 1991.
;	WIlliam Thompson, 10 November 1992, added !BCOLOR.
; Written     : 
;	William Thompson, GSFC, 5 December 1991.
; Modified    : 
;	Version 1, William Thompson, GSFC, 23 June 1993.
;		Incorporated into CDS library.  Removed overlap with DEVICELIB
;		routine.
; Version     : 
;	Version 1, 23 June 1993.
;-
;
;  !IMAGE is a structure containing all the parameters used to modify the
;  behavior of the image display routines.
;
	IMAGE = {IM_CH_1, SET: 0, VALUE: 0.0}
	DEFSYSV,'!IMAGE',{IMAGE_CHAR,	NOSQUARE: 0,		$
			 		SMOOTH:	  0,		$
					NOBOX:	  0,		$
					NOSCALE:  0,		$
					MISSING:  {IM_CH_1},	$
					SIZE:	  {IM_CH_1},	$
					NOEXACT:  0,		$
					XALIGN:	  {IM_CH_1},	$
					YALIGN:	  {IM_CH_1},	$
					RELATIVE: {IM_CH_1},	$
					MIN:	  {IM_CH_1},	$
					MAX:	  {IM_CH_1},	$
					VMIN:	  {IM_CH_1},	$
					VMAX:	  {IM_CH_1},	$
					TOP:	  {IM_CH_1},	$
					COMBINED: 0}
	MESSAGE,'Added system variable !IMAGE',/INFORMATIONAL
;
	RETURN
	END
