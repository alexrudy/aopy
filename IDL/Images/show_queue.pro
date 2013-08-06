	PRO SHOW_QUEUE, QUEUE, COLOR=COLOR
;+
; Project     : SOHO - CDS
;
; Name        : 
;	SHOW_QUEUE
; Purpose     : 
;	Show the contents of a print queue.
; Explanation : 
;	Spawns the proper command to the operating system to display the
;	contents of print queues.
; Use         : 
;	SHOW_QUEUE  [, QUEUE ]
; Inputs      : 
;	None required.
; Opt. Inputs : 
;	QUEUE	= Name of queue to be listed.  If not passed, then the
;		  environment variable PSLASER (or PSCOLOR) is checked for the
;		  name of the print queue.
; Outputs     : 
;	The information about the print queue is printed to the terminal
;	screen.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	COLOR	= If set, then the environment variable PSCOLOR is checked for
;		  the name of the print queue rather then PSLASER.  Ignored if
;		  QUEUE is passed.
; Calls       : 
;	TRIM
; Common      : 
;	None.
; Restrictions: 
;	In general, the SERTS graphics devices routines use the special system
;	variables !BCOLOR and !ASPECT.  These system variables are defined in
;	the procedure DEVICELIB.  It is suggested that the command DEVICELIB be
;	placed in the user's IDL_STARTUP file.
;
; Side effects: 
;	None.
; Category    : 
;	Utilities, Devices.
; Prev. Hist. : 
;	William Thompson, July 1992.
; Written     : 
;	William Thompson, GSFC, July 1992.
; Modified    : 
;	Version 1, William Thompson, GSFC, 27 April 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 27 April 1993.
;-
;
	ON_ERROR,2
	STRING_TYPE = 7
;
;  If passed, then check the value of QUEUE.
;
	IF N_PARAMS() EQ 1 THEN BEGIN
		IF N_ELEMENTS(QUEUE) EQ 0 THEN MESSAGE,'QUEUE undefined'
		IF N_ELEMENTS(QUEUE) NE 1 THEN MESSAGE,		$
			'QUEUE must not be an array'
		SQ = SIZE(QUEUE)
		IF SQ(1) NE STRING_TYPE THEN MESSAGE,		$
			'QUEUE must be of type string'
;
;  Otherwise, check the logical name/environment variable PSLASER to get the
;  name of the queue.  A queue name is required in VMS.
;
	END ELSE BEGIN
		IF KEYWORD_SET(COLOR) THEN PRINTER = "PSCOLOR" ELSE   $
			PRINTER = "PSLASER"
		PSLASER = GETENV(PRINTER)
		IF PSLASER NE "" THEN BEGIN
			QUEUE = PSLASER
		END ELSE IF !VERSION.OS EQ "vms" THEN BEGIN
			MESSAGE,'Logical name ' + PRINTER +		$
				' or parameter QUEUE must be defined'
		ENDIF
	ENDELSE
;
; Format the correct command, depending on the operating system.
;
	IF !VERSION.OS EQ "vms" THEN BEGIN
		PSLASER = TRIM(STRUPCASE(QUEUE))
		COM_LINE = "SHOW QUEUE " + TRIM(STRUPCASE(QUEUE))
	END ELSE BEGIN
		COMMAND = 'lpq'
		IF N_ELEMENTS(QUEUE) EQ 1 THEN COMMAND = COMMAND + ' -P ' + $
			TRIM(QUEUE)
	ENDELSE
	PRINT,'$ ' + COMMAND
	SPAWN,COMMAND
;
	RETURN
	END
