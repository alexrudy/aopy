	PRO PCL,FILENAME,LANDSCAPE=LANDSCAPE,PORTRAIT=PORTRAIT
;+
; Project     : SOHO - CDS
;
; Name        : 
;	PCL
; Purpose     : 
;	Sets graphics device to HP LaserJet PCL file.
; Explanation : 
;	This procedure sets the system variables needed to write HP LaserJet
;	PCL plot files.  The plot is done in landscape mode, using most of the
;	paper.
;
;	SETPLOT is called to save and set the system variables, and DEVICE is
;	called to set the plot window size and orientation, and to open the
;	file.
;
;	If the plot file is already open, then calling PCL without any
;	parameters or keywords allows the user to write into the already opened
;	file, in the same mode as before.
;
; Use         : 
;	PCL  [, FILENAME ]
;
;	PCL				;Open PCL plot file
;	   ... plotting commands ...	;Create plot
;	PCLPLOT				;Close & plot file, reset to prev. dev.
;	   or
;	PCLCLOSE			;Close w/o printing,  "    "   "    "
;
; Inputs      : 
;	None required.
; Opt. Inputs : 
;	FILENAME - Name of PCL plot file to be opened.  If not passed, and no
;		   filename was previously passed, "idl.pcl" is assumed.
; Outputs     : 
;	A message is printed to the screen.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	LANDSCAPE = If set, then plotting is done in LANDSCAPE mode (default).
;	PORTRAIT  = If set, then plotting is done in PORTRAIT mode.  PORTRAIT
;		    takes precedent over LANDSCAPE.
; Calls       : 
;	SETPLOT, FORM_FILENAME
; Common      : 
;	PCL_FILE which contains PCL_FILENAME, the name of the plotting file,
;	and LAST_DEVICE, which is the name of the previous graphics device.
; 
;	Also calls SETPLOT, which uses common block PLOTFILE.
; 
; Restrictions: 
;	Only the routines PCLPLOT and PCLCLOSE can be used to close the PCL
;	plot file.  It is best if the routines TEK, REGIS, etc. (i.e. those
;	routines that use SETPLOT) are used to change the plotting device.
;
;	In general, the SERTS graphics devices routines use the special system
;	variables !BCOLOR and !ASPECT.  These system variables are defined in
;	the procedure DEVICELIB.  It is suggested that the command DEVICELIB be
;	placed in the user's IDL_STARTUP file.
;
; Side effects: 
;	If the FILENAME parameter, or either the LANDSCAPE or PORTRAIT
;	keywords, is passed then DEVICE is called to open a new file.  Any
;	previously opened PCL plot file would be closed.
; 
;	If a new file is opened, then the DEVICE routine is called with the
;	/LANDSCAPE or /PORTRAIT switch to set the size and orientation of the
;	plot window.
; 
;	If not the first time this routine is called, then system variables
;	that affect plotting are reset to previous values.  If it is the first 
;	time the routine is called, !FANCY is set to 1.
;
;	In UNIX, if a new file is opened with the same name as an existing
;	file, then the old file is lost.
; 
; Category    : 
;	Utilities, Devices.
; Prev. Hist. : 
;	None.
; Written     : 
;	William Thompson, GSFC, 15 June 1993.
; Modified    : 
;	Version 1, William Thompson, GSFC, 15 June 1993.
;		Based on QMS.PRO
; Version     : 
;	Version 1, 15 June 1993.
;-
;
	COMMON PCL_FILE, PCL_FILENAME, LAST_DEVICE
	RESET = 0
;
;  The filename has been passed.
;
	IF N_PARAMS(0) EQ 1 THEN BEGIN
		PCL_FILENAME = FORM_FILENAME(FILENAME,'.pcl')
		RESET = 1
;
;  No filename has yet been passed, or the filename is blank.  Use idl.pcl.
;
	END ELSE IF N_ELEMENTS(PCL_FILENAME) EQ 0 THEN BEGIN
		PCL_FILENAME = "idl.pcl"
		RESET = 1
	END ELSE IF PCL_FILENAME EQ "" THEN BEGIN
		PCL_FILENAME = "idl.pcl"
		RESET = 1
	ENDIF
;
;  Store the name of the current plotting device in the common block.
;
	IF !D.NAME NE 'PCL' THEN LAST_DEVICE = !D.NAME
;
;  Set the plotting device.
;
	SETPLOT,'PCL'
;
;  Determine whether landscape or portrait mode is to be used.
;
	IF N_ELEMENTS(PORTRAIT) NE 0 THEN BEGIN
		DEVICE,/PORTRAIT
		RESET = 1
	END ELSE IF N_ELEMENTS(LANDSCAPE) NE 0 THEN BEGIN
		DEVICE,/LANDSCAPE
		RESET = 1
	END ELSE IF RESET THEN DEVICE,/LANDSCAPE
;
;  Set the filename.
;
	IF RESET THEN DEVICE,FILENAME=PCL_FILENAME
	PRINT,'Plots will now be written to the file ' + PCL_FILENAME
;
	RETURN
	END
