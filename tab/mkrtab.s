**********************************************************************
*		JAZZ - RPL.TAB creation & splitting
**********************************************************************

**********************************************************************
* Name:		xRTB->
* Interface:	( --> $ )
* Desc:		Converts RPL.TAB to a readable string
* Notes:	Output terminates with \n which is entry condition
*		for ->RTB
**********************************************************************
ASSEMBLE
	CON(1)	8
RPL
xNAME RTB\8D
::
  CK0
  CHECKME
  GetRplTab DUPNULL$? case :: [#] errNoRPLtab DO#EXIT ;

* R0
* R1
* R2
* R3	->RPL.TAB
* R4

CODE
		GOSBVL	=SAVPTR
		A=DAT1	A
		R3=A			->RPL.TAB
		GOSUB	RtCalcTab$	B[A] = needed size
		C=B	A
		GOSBVL	=MAKE$
		CD0EX
		D1=C			->out
		GOSUB	RtCopyTab$	Copy entries 1 by one
		GOVLNG	=GPOverWrR0Lp	Done

****************************************
* Calculate needed size for output $
****************************************
RtCalcTab$	GOSUB	RtGetTb		D0 = C[A] = ->entry1  D[A]=->rtbend
		B=0	A		No output yet
		C=C+CON	A,5		->name1
--		?C>=D	A
		RTNYES			Reached end of rtab
		D0=C
		B=B+CON	A,5+1+1		+address +tab +newline
		C=0	A
		C=DAT0	1
		B=B+C	A		+chars in entry name
		?CBIT=1	3		More than 8 chars in name?
		GOYES	+		Yep, only 1 tab
		B=B+1	A		2 tabs needed to align
+		AD0EX
		C=C+C	A		nibs in name
		C=C+A	A		skip name
		C=C+CON	A,1+5		skip namlen & addr
		GONC	--
****************************************
* Output entries to $ in D1
****************************************
RtCopyTab$
		GOSUB	RtGetTb		D0 = C[A] = ->entry1  D[A]=->rtbend

--		CD0EX
		D0=C
		?C>=D	A
		RTNYES			End of rtab - done
		A=DAT0	A
		B=A	A		entry addr
		D0=D0+	5
		C=0	A
		C=DAT0	1		chars in entry name
		RSTK=C
		D0=D0+	1
		C=C+C	A		nibs in entry name
		GOSBVL	=MOVEDOWN	copy entry name
		C=RSTK			chars in entry name
		LAASC	'\t'
		DAT1=A	B
		D1=D1+	2
		?CBIT=1	3		More than 8 chars in name?
		GOYES	+		Yep - 1 tab is enough
		DAT1=A	B		Need 2 tabs for alignment
		D1=D1+	2
+		D1=D1+	10		Output address backwards
		P=	15
		LC(1)	16-5
		P=	0
-		LCASC	'9'		Convert B[0] to asc in C[B]
		CBEX	P
		?C<=B	P
		GOYES	+
		C=C+CON	B,7
+		D1=D1-	2		Output hex as asc
		DAT1=C	B
		BSR	A
		C=C+1	S
		GONC	-		Loop 5 hex chars
		D1=D1+	10		Skip the address
		LCASC	'\n'		New line
		DAT1=C	B
		D1=D1+	2
		GONC	--		And try new entry
* In:	R3[A]   = ->rtab
* Out:	D[A]    = ->rtabend
*	D0=C[A] = ->entry1

RtGetTb		A=R3
		A=A+CON	A,5
		D0=A
		C=DAT0	A
		C=C+A	A
		D=C	A
		LC(5)	5+4+96*5	* lenght + magic + 96 offsets
		C=C+A	A
		D0=C
		RTN
*********************************
ENDCODE
;

**********************************************************************
* Name:		x->RTB
* Interface:	( $ --> )
* Desc:		Converts $ to RPL.TAB format
* Notes:	Allowed entry lines are of format:
*		[=]name[whitespace][EQU #]address[newline]
*		^^^                ^^^^^^^
*		optional	   optional
*		Especially note that the last char in input must be \n
**********************************************************************
ASSEMBLE
	CON(1)	8
RPL
xNAME \8DRTB
::
  CK1&Dispatch
  THREE
 ::
  DUPNULL$? case SETNONEXTERR		( Empty input )

CODE
		GOSBVL	=SAVPTR
		GOSUB	RtCheckNL	( Check last char is \n )
		GOSUB	RtCalcNeed$	( Calc needed room )
		GOSBVL	=MAKE$N
		AD0EX
		D1=A			->out
		GOSUB	RtCopyNames	Copy entry names into rtab
		GOSUB	RtSetHead	Create offset table
		GOVLNG	=GPOverWrR0Lp	Done
****************************************
* Error if \n is not last in input
****************************************
RtCheckNL	GOSUB	RtGetStr	D0 = ->$body	C[A] = ->$end
		D0=C
		D0=D0-	2
		A=DAT0	B
		LCASC	'\n'
		?A=C	B
		RTNYES
		LC(5)	=SETTYPEERR
		GOLONG	getptrevalc
****************************************
* Calculate needed room for rtab
* Out:	C[A] = nibbles
****************************************
RtCalcNeed$	GOSUB	RtGetStr	D0 = ->$body	C[A] = ->$end
		R4=C			->$end
		D=0	A		Need
--		GOSUB	RtParseLine
		GOC	+		Invalid line - ignore
		C=R1.F	S		chars in entry name
		P=C	15
		C=0	A
		CPEX	0		chars
		C=C+C	A		nibs
		C=C+CON	A,1+5		+len +addr
		D=D+C	A
		GOC	++		Memory error!
+		C=R4.F	A		->$end
		AD0EX
		D0=A
		?A<C	A
		GOYES	--		Loop until last line parsed
		?D=0	A
		GOYES	++		Memory error if no valid lines
		LC(5)	4+96*5		magic + 96 offsets
		C=C+D	A		need'
		RTNNC
++		GOVLNG	=GPMEMERR	Overflow in memory calculation
****************************************
* Copy entries into ->out
****************************************
RtCopyNames	GOSUB	RtGetStr	D0 = ->$body	C[A] = ->$end
		D=C	A		->$end
		AD1EX
		LC(5)	4+96*5		magic + 96 offsets
		A=A+C	A
		AD1EX			->out_entry1
--		GOSUB	RtParseLine
		GOC	+		Invalid line
		A=R2.F	A		Output entry addr
		DAT1=A	A
		D1=D1+	5
		C=R1
		DAT1=C	S		Output entry namelen
		D1=D1+	1
		CD0EX			->entry name
		B=C	A		Saved ->input
		C=0	A
		CSLC			Chars
		C=C+C	A		Nibbles
		GOSBVL	=MOVEDOWN
		C=B	A
		D0=C			->input
+		CD0EX
		D0=C
		?C<D	A
		GOYES	--		Loop all lines
		RTNCC			Done parsing
****************************************
* Create offset table in rtab
****************************************
RtSetHead	A=R0.F	A		->RPL.TAB
		A=A+CON	A,5
		D1=A
		C=DAT1	A		rtablen
		C=C+A	A
		D=C	A		->rtabend
		D1=D1+	5		->rtabhead
		LC(5)	5+4+96*5
		A=A+C	A
		D0=A			->entry1
		LC(4)	TABMAGIC	Output magic
		DAT1=C	4
		D1=D1+	4
		LCASC	' '
		B=C	B		Initial 1st char
--		D0=D0+	5+1		Skip entry addr & namelen
		C=0	A		Default offset
		A=DAT0	B
-		?A=B	B
		GOYES	+		Found 1st entry with given 1st char
		DAT1=C	A		No entry with this 1st char
		D1=D1+	5
		B=B+1	B
		GONC	-		Try with new 1st char
+		D0=D0-	1+5		Back to addr
		AD0EX
		D0=A
		CD1EX
		D1=C
		A=A-C	A		Offset to entry address field
		DAT1=A	A		Output offset
		D1=D1+	5
		B=B+1	B		New 1st char
		GOSUB	SkipToB		Find that entry
		GONC	--		And write offset for it
* No more entries, finish up
		LC(2)	#80
		C=C-B	B		Undone offsets
		A=0	A
--		C=C-1	B
		GOC	+		Done
		DAT1=A	A		No such names
		D1=D1+	5
		GONC	--		Clear all remaining offsets
+		D1=D1-	5		Fix last offset to be offset
		CD1EX			to the end of rtab
		D1=C
		D=D-C	A
		C=D	A		Offset to end
		DAT1=C	A
		RTN			Done
*********************************
* Skip to entry with 1st char B[B]
****************************************
SkipToB		CD0EX
		D0=C
		?C>=D	A
		RTNYES			End of rtab - no such entry
		D0=D0+	5+1		Skip addr & namelen
		A=DAT0	B
		?A>=B	B
		GOYES	+		Reached bigger char - no match
		D0=D0-	1		->namelen
		C=0	A
		C=DAT0	1		namelen
		D0=D0+	1
		AD0EX			Skip name
		A=A+C	A
		A=A+C	A
		AD0EX
		GONC	SkipToB
+		D0=D0-	1+5		Back to address field
		RTNCC			Found some name
****************************************
* Get $ from stk1 into D0
****************************************
RtGetStr	GOSBVL	=D0=DSKTOP
		A=DAT0	A		->$
		A=A+CON	A,5
		D0=A
		C=DAT0	A		$len
		C=C+A	A		->$end
		D0=D0+	5		->$body
		RTN
*********************************
* In:	D0=->start of line
* Out:	D0=->end of line
*	CS: No match
*	CC	R1[A]=->entry name
*		R1[S]=entry chars
*		R2[A]=entry addr
*********************************
RtParseLine	A=DAT0	B
		LCASC	'*'
		?A#C	B
		GOYES	+
rtskp*		GOSUB	RtNextLine	Skip comment line
		RTNSC			Bad line

+		LCASC	'='
		?A#C	B
		GOYES	+
		D0=D0+	2		Skip "="
+
* Now count chars in name
		AD0EX
		R1=A.F	A		->name
		AD0EX
		C=0	S		No chars yet
		LCASC	' '
--		C=C+1	S
		GOC	rtskp*		Too long name - ignore line
		A=DAT0	B
		D0=D0+	2
		?A>C	B
		GOYES	--		Loop until whitespace
		D0=D0-	2		->whitespace
		C=C-1	S
		?C=0	S
		GOYES	rtskp*		Nullname - ignore line
		R1=C.F	S	chars
		GOSUB	RtSkpWhite	Skip to next black char
		RTNC			Found newline instead - bad line
		LCSTR	'EQU'
		A=DAT0	6
		P=	6-1
		?A#C	WP
		GOYES	+		Not "EQU" - try address
		D0=D0+	6		Skip "EQU"
		P=	0
		GOSUB	RtSkpWhite	Skip to next black char
		RTNC			Found newline instead - bad line
		A=DAT0	B
		LCASC	'#'
		?A#C	B
		GOYES	rtskp*		Found "EQU" with no "#" - bad line
		D0=D0+	2		Skip "#"
+

		P=	0		Now try parsing a hex address
		B=0	W		number
		A=0	S		digits
--		A=DAT0	B
		D0=D0+	2
		LCASC	' '
		?A<=C	B
		GOYES	++		Got white - check result
		LCASC	'0'
		A=A-C	B
		GOC	gortskp*	Got non-digit - bad line
		LC(2)	'9'-'0'
		?A<=C	B
		GOYES	+		Got digit - add it
		LC(2)	'A'-'0'
		A=A-C	B
		GOC	gortskp*	Got non-digit - bad line
		A=A+CON	B,10		Get #A-#F
		LC(2)	#F
		?A<=C	B
		GOYES	+		Got digit - add it
gortskp*	GOTO	rtskp*
+		A=A+1	S		digits++
		GOC	gortskp*	Too many digits - bad line
		BSL	W
		B=A	P		New result
		GONC	--		Loop until bad/white

++		D0=D0-	2		Back to white
		?A=0	S
		GOYES	gortskp*	No digits - bad line
		A=B	A
		R2=A.F	A		entry address
*		GOTO	RtNextLine
*********************************	
RtNextLine	LCASC	'\n'
--		A=DAT0	B
		D0=D0+	2
		?A#C	B
		GOYES	--
		RTNCC
*********************************	
RtSkpWhite	A=DAT0	B
		D0=D0+	2
		LCASC	'\n'
		?A=C	B
		RTNYES			Found newline
		LCASC	' '
		?A<=C	B
		GOYES	RtSkpWhite
		D0=D0-	2		Back to the black char
		RTNCC			Found non-newline
****************************************
ENDCODE
 ;
;
**********************************************************************
