**********************************************************************
*		Jazz Assembler
**********************************************************************

**********************************************************************
*		Main Program
**********************************************************************
ASSEMBLE
	CON(1)	#8
RPL
xNAME ASS
::
  "Unavailable" TOTEMPOB
  CODE
		LOOP

PopStat1	GOSBVL	=D1=DSKTOP
		D1=D1+	10
		A=DAT1	A
		D1=D1-	10
		A=A+CON	A,10		* Skip prolog & len fields
		A=0	B		* Clear page
		LC(5)	#100		* Next page
		A=A+C	A
		R2=A.F	A
		RTNCC

		INCLUDE	ass/save.a
  ENDCODE
;
