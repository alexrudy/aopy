	PRO DEANZA,RESET=RESET,NO_RESET=NO_RESET
;+
; NAME:
;	DEANZA
; PURPOSE:
;	Sets the graphics device to the DEANZA display.
; CALLING SEQUENCE:
;	DEANZA
; PARAMETERS:
;	None.
; OPTIONAL KEYWORD PARAMETERS:
;	RESET	 = If set, then the image display is reset.  The display is
;		   reset automatically the first time this routine is called.
;	NO_RESET = If set, then the image display is not reset, even if this is
;		   the first time this routine is called.  Overrides the RESET
;		   keyword.
; COMMON BLOCKS:
;	DEANZA_DEVICE contains DEANZA_SET.
; SIDE EFFECTS:
;	The first time this routine is called, the image display device is
;	reset unless the NO_RESET keyword is set.
; RESTRICTIONS:
;	It is best if the routines SCREEN, REGIS, etc. are used to change the
;	plotting device.
; PROCEDURE:
;	Calls SETPLOT, and then (possibly) DEVICE,/RESET.
; MODIFICATION HISTORY:
;	William Thompson, July 1991.
;-
;
	COMMON DEANZA_DEVICE, DEANZA_SET
;
	IF N_ELEMENTS(DEANZA_SET) EQ 0 THEN DEANZA_SET = 0
	SETPLOT,'DEANZA'
	IF ((NOT DEANZA_SET) OR KEYWORD_SET(RESET)) AND		$
		(NOT KEYWORD_SET(NO_RESET)) THEN DEVICE,/RESET
	DEANZA_SET = 1
;
	RETURN
	END
