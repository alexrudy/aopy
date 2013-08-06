	PRO TVPRINT,FILENAME,WINDOW=WINDOW,DISABLE=DISABLE,	$
		LANDSCAPE=LANDSCAPE,PORTRAIT=PORTRAIT,REVERSE=REVERSE,	$
		NOBOX=NOBOX,TEX=TEX,NOPRINT=NOPRINT,COLOR=COLOR,QUEUE=QUEUE, $
		PCL=PCL
;+
; Project     : SOHO - CDS
;
; Name        : 
;	TVPRINT
; Purpose     : 
;	Sends the contents of a window to a PostScript printer.
; Explanation : 
;	Reads the contents of a graphics window and creates and prints a
;	PostScript file.  The routine TVREAD is called to read the window.  It
;	is (optionally) converted to a grey scale, and EXPTV is used to write
;	this to a PostScript file.
; Use         : 
;	TVPRINT  [, FILENAME ]
; Inputs      : 
;	None required.
; Opt. Inputs : 
;	FILENAME  = Name of the PostScript file that will be created and
;		    printed (and saved).  If not passed, then TEMPORARY.ps is
;		    used (but not saved).
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	WINDOW	  = Which window to read from.  If passed, then overrides the
;		    TVSELECT routine.
;	DISABLE	  = If set, then the current graphics device/window is read.
;		    Otherwise, TVSELECT is called to select the image display
;		    device/window.  Ignored if WINDOW keyword is passed.
;	PORTRAIT  = If set, then plot done in portrait mode, using all of the
;		    paper.
;	LANDSCAPE = If passed, then plot done in landscape mode, using all of
;		    the paper.  This is the default mode.
;	TEX	  = If set, then plot done in encapsulated landscape mode,
;		    to be compatible with TeX.  If this keyword is passed, then
;		    an explicit filename must be passed.  The file is not
;		    printed.
;	COLOR	  = If set, then a color PostScript file is created.  The
;		    default is to convert to a greyscale image.
;	REVERSE	  = If set, then plot is done in inverse video.  In other
;		    words, white areas on the screen will appear dark, and visa
;		    versa.  Ignored if COLOR is set.
;	NOBOX	  = If set, then a box is not drawn around the printed image of
;		    the X-window.  The default is to draw a box.
;	NOPRINT	  = If set, then the PostScript file is created, but not
;		    printed.  This requires that an explicit filename be
;		    passed.
;	QUEUE	  = Print queue to send file to.
;	PCL	  = If set, then an HP LaserJet PCL file will be created
;		    instead of a PostScript file.  In this case, the default
;		    file extension will be ".pcl" instead of ".ps".  The TEX
;		    and COLOR keywords will be ignored.
; Calls       : 
;	EXPTV, FORM_FILENAME, PCL, PCLCLOSE, PCLPLOT, PS, PSCLOSE, PSPLOT,
;	SETIMAGE, TVREAD
; Common      : 
;	None.
; Restrictions: 
;	Device must be capable of the TVRD function.  Window must be completely
;	visible, with no portion off the end of the screen.
;
;	NOTE:  This routine does not do a good job on line graphics.  It works
;	best with images.
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
;	A temporary file, "TEMPORARY.ps" will be created and deleted, unless an
;	explicit filename is passed.
;
;	The SETIMAGE routine is called to reset to the default.  Any SETIMAGE
;	setting is lost.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	William Thompson, May 1992, from XPRINT.
;	William Thompson, June 1992, added color support.
;	William Thompson, December 1992, modified to use a better and faster
;		translation from colors to grey-scale, as suggested by Alan
;		Youngblood.
; Written     : 
;	William Thompson, GSFC, May 1992.
; Modified    : 
;	Version 1, William Thompson, 11 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, 24 August 1993.
;		Added PCL keyword.
; Version     : 
;	Version 2, 24 August 1993.
;-
;
	ON_ERROR,2
;
;  Choose whether or not the filename should end in ".ps" or ".pcl".
;
	IF KEYWORD_SET(PCL) THEN EXTENSION = '.pcl' ELSE EXTENSION = '.ps'
;
;  Form the output filename.  If not passed, then use "TEMPORARY.ps".  Also
;  decide whether the file is temporary or not.
;
	IF N_PARAMS() EQ 1 THEN BEGIN
		FILE = FORM_FILENAME(FILENAME,EXTENSION)
		DELETE = 0
	END ELSE IF KEYWORD_SET(TEX) THEN BEGIN
		PRINT,'*** A filename must be passed when using the ' +	$
			'/TEX switch, routine TVPRINT.'
		RETURN
	END ELSE IF KEYWORD_SET(NOPRINT) THEN BEGIN
		PRINT,'*** A filename must be passed when using the ' +	$
			'/NOPRINT switch, routine TVPRINT.'
		RETURN
	END ELSE BEGIN
		FILE = "TEMPORARY" + EXTENSION
		DELETE = 1
	ENDELSE
;
;  Read in the image, and convert to a grey scale.
;
	IMAGE = TVREAD(RED,GREEN,BLUE,WINDOW=WINDOW,DISABLE=DISABLE)
	IF NOT KEYWORD_SET(COLOR) THEN BEGIN
		BWTABLE = BYTSCL(0.3*RED + 0.59*GREEN + 0.11*BLUE)
		IMAGE = BWTABLE(IMAGE)
	ENDIF
;
;  If the keyword REVERSE is set, then do the plot in inverse video.
;
	IF KEYWORD_SET(REVERSE) AND NOT KEYWORD_SET(COLOR) THEN	$
		IMAGE = MAX(IMAGE) - IMAGE
;
;  Open the PostScript file, and display the image.
;
	IF KEYWORD_SET(PCL) THEN BEGIN
		PCL,FILE,PORTRAIT=PORTRAIT,LANDSCAPE=LANDSCAPE
		SETIMAGE
	END ELSE BEGIN
		PS,FILE,PORTRAIT=PORTRAIT,LANDSCAPE=LANDSCAPE,TEX=TEX,	$
			COLOR=COLOR
		SETIMAGE
		IF KEYWORD_SET(COLOR) THEN TVLCT,RED,GREEN,BLUE
	ENDELSE
	EXPTV,IMAGE,/NOSCALE,/NOEXACT,NOBOX=NOBOX
;
;  If either the TEX or NOPRINT keyword is set, then simply close the file.
;  Otherwise, print the file and, if temporary, delete it.
;
	IF KEYWORD_SET(TEX) OR KEYWORD_SET(NOPRINT) THEN BEGIN
		IF KEYWORD_SET(PCL) THEN PCLCLOSE ELSE PSCLOSE
	END ELSE BEGIN
		IF KEYWORD_SET(PCL) THEN	$
			PCLPLOT,FILE,DELETE=DELETE,QUEUE=QUEUE	ELSE	$
			PSPLOT,FILE,DELETE=DELETE,QUEUE=QUEUE
	ENDELSE
;
	RETURN
	END
