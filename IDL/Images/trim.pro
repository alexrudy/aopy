	FUNCTION TRIM, NUMBER, FORMAT, FLAG
;+
; Project     : SOHO - CDS
;
; Name        : 
;	TRIM()
; Purpose     : 
;	Converts numbers to strings, without trailing zeros.
; Explanation : 
;	Converts numbers into a string representation, and trims off leading
;	and/or trailing blanks.  Differs from STRTRIM in that trailing zeros
;	after the period are also trimmed off, unless NUMBER is already a
;	string, or an explicit format is passed.
; Use         : 
;	Result = TRIM( NUMBER  [, FORMAT ]  [, FLAG ] )
; Inputs      : 
;	NUMBER	= Scaler variable or constant.  May be of any ordinary type,
;		  including string.  However, structures are not allowed.
; Opt. Inputs : 
;	FORMAT	- Format specification for STRING function.  Must be a string
;		  variable, start with the "(" character, end with the ")"
;		  character, and be a valid FORTRAN format specification.  If
;		  NUMBER is complex, then FORMAT will be applied separately to
;		  the real and imaginary parts.
;
;	FLAG	- Flag passed to STRTRIM to control the type of trimming:
;
;			FLAG = 0	Trim trailing blanks.
;			FLAG = 1	Trim leading blanks.
;			FLAG = 2	Trim both leading and trailing blanks.
;
;		  The default value is 2.  If NUMBER is complex, then FORMAT
;		  will be applied separately to the real and imaginary parts.
;
; Outputs     : 
;	Function returns as a string variable representing the value NUMBER.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	None.
; Calls       : 
;	None.
; Common      : 
;	None.
; Restrictions: 
;	NUMBER must not be an array.  NUMBER must not be a structure.
;	FORMAT must be a valid format specification, and must not be passed
;		if NUMBER is of type string.
;	FLAG must not be of string type, or an array.
; Side effects: 
;	None.
; Category    : 
;	Utilities, Strings.
; Prev. Hist. : 
;	William Thompson	Applied Research Corporation
;	May, 1987		8201 Corporate Drive
;				Landover, MD  20785
;
;	William Thompson, Feb. 1992, added support for complex numbers, and
;				     fixed Unix problem with lowercase "e".
; Written     : 
;	William Thompson, GSFC, May 1987.
; Modified    : 
;	Version 1, William Thompson, GSFC, 9 April 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 9 April 1993.
;-
;
	ON_ERROR,2
;
;  Check the type of the variable NUMBER.
;
	S = SIZE(NUMBER)
	TYPE = S(S(0) + 1)
;
;  If NUMBER is complex, then process the real and imaginary parts separately.
;
	IF TYPE EQ 6 THEN BEGIN
		RNUMBER = FLOAT(NUMBER)
		INUMBER = IMAGINARY(NUMBER)
		CASE N_PARAMS() OF
			1:  BEGIN
				RNUMBER = TRIM(RNUMBER)
				INUMBER = TRIM(INUMBER)
				END
			2:  BEGIN
				RNUMBER = TRIM(RNUMBER,FORMAT)
				INUMBER = TRIM(INUMBER,FORMAT)
				END
			3:  BEGIN
				RNUMBER = TRIM(RNUMBER,FORMAT,FLAG)
				INUMBER = TRIM(INUMBER,FORMAT,FLAG)
				END
		ENDCASE
		RETURN, '(' + RNUMBER + ',' + INUMBER + ')'
	ENDIF
;
;  If only NUMBER was passed, then return the desired result.
;
	IF N_PARAMS(0) EQ 1 THEN BEGIN
		IF TYPE EQ 7 THEN BEGIN
			TRM = STRTRIM(NUMBER,2)
			GOTO,RETURN
		END ELSE BEGIN
			IF NUMBER EQ 0 THEN BEGIN
				TRM = '0'
				GOTO,RETURN
			END ELSE BEGIN
				TRM = STRTRIM( STRING(NUMBER), 2 )
				GOTO,REMOVE
			ENDELSE
		ENDELSE
	ENDIF
;
;  Check the type of the variable FORMAT.
;
	S = SIZE(FORMAT)
	TYPE_FORMAT = S(S(0) + 1)
;
;  If only two parameters were passed, then decide whether FORMAT or FLAG was
;  passed, and return the desired result. 
;
	IF N_PARAMS(0) EQ 2 THEN BEGIN
		IF TYPE_FORMAT EQ 7 THEN BEGIN
			TRM = STRTRIM( STRING(NUMBER,FORMAT), 2 )
			GOTO,RETURN
		END ELSE BEGIN
			FLAG = FORMAT
			IF TYPE EQ 7 THEN BEGIN
				TRM = STRTRIM( NUMBER, FLAG )
				GOTO,RETURN
			END ELSE BEGIN
				IF NUMBER EQ 0 THEN BEGIN
					TRM = '0'
					GOTO,RETURN
				END ELSE BEGIN
					TRM = STRTRIM( STRING(NUMBER), FLAG )
					GOTO,REMOVE
				ENDELSE
			ENDELSE
		ENDELSE
	ENDIF
;
;  All parameters were passed.  Act accordingly.
;
	TRM = STRTRIM( STRING(NUMBER,FORMAT), FLAG )
	GOTO,RETURN
;
;  Remove any trailing zeros.  First, check to make sure that the string 
;  contains a period.
;
REMOVE:
	TRM = STRUPCASE(TRM)
	IF STRPOS(TRM,'.') EQ -1 THEN GOTO,RETURN
;
;  Find and remove any exponential.
;
	LEN = STRLEN(TRM)
	EXP_POS = STRPOS(TRM,'E')
	IF EXP_POS EQ -1 THEN EXP = '' ELSE BEGIN
		EXP = STRMID(TRM,EXP_POS,LEN)
		TRM = STRMID(TRM,0,EXP_POS)
		LEN = STRLEN(TRM)
	ENDELSE
;
;  Keep removing trailing zeros until done.
;
	WHILE STRMID(TRM,LEN-1,1) EQ '0' DO BEGIN
		TRM = STRMID(TRM,0,LEN-1)
		LEN = LEN - 1
	ENDWHILE
;
;  If the last character is a period, remove it as well.
;
	IF STRMID(TRM,LEN-1,1) EQ '.' THEN BEGIN
		TRM = STRMID(TRM,0,LEN-1)
		LEN = LEN - 1
	ENDIF
;
;  Restore the exponential.
;
	TRM = TRM + EXP
;
;  Return the trimmed string TRM.
;
RETURN:
	RETURN,TRM
	END
