	PRO IVAS,RESET=RESET,NO_RESET=NO_RESET
;+
; NAME:
;	IVAS
; PURPOSE:
;	Sets the graphics device to the IVAS display.
; CALLING SEQUENCE:
;	IVAS
; PARAMETERS:
;	None.
; OPTIONAL KEYWORD PARAMETERS:
;	RESET	 = If set, then the image display is reset.  The display is
;		   reset automatically the first time this routine is called.
;	NO_RESET = If set, then the image display is not reset, even if this is
;		   the first time this routine is called.  Overrides the RESET
;		   keyword.
; COMMON BLOCKS:
;	IVAS_DEVICE contains IVAS_SET.
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
	COMMON IVAS_DEVICE, IVAS_SET
;
	IF N_ELEMENTS(IVAS_SET) EQ 0 THEN IVAS_SET = 0
	SETPLOT,'IVAS'
	IF ((NOT IVAS_SET) OR KEYWORD_SET(RESET)) AND		$
		(NOT KEYWORD_SET(NO_RESET)) THEN DEVICE,/RESET	$
		ELSE DEVICE,/NO_RESET
	IVAS_SET = 1
;
	RETURN
	END
