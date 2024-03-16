**********************************************************************
* Name:		CK&DISPATCH1
*
* Abstract:	Emulation of CK&DISPATCH1
*
*		The sym and arry class have changed in ROM 2.15. Sym
*		now includes DOINT, and arry now includes DOMATRIX.
*		MTCHTBL now has #FFFFF for the arry prologue. The sym
*		class still maintains #00000 for its prologue. Note
*		CK&DPISPATCH1 not only strips tags, it will now also
*		convert integers to real numbers when the dispatch
*		type is DOREAL. Conversion occurs only after finding
*		the correct dispatch type. A final pass then converts
*		any integers to real numbers or generates an error
*		for overflows/underflows depending on system flags.
*
* Notes:	DO NOT USE ++ LABELS!
**********************************************************************
CODE

*sOKSTRIPTAGS	EQU 2			OK to remove tags
*sXTABLE		EQU 3			dispatch table selection
*sOK2NDPASS	EQU 4			OK to try again w/o tags
sAPPROX		EQU 6			OK to treat integers as reals
sINT>REAL	EQU 7			convert integer to real
sSYMARRYLIST	EQU 8			unmatched arg is a list
sFAKE%		EQU 9			integer was treated as real
sGARBAGE	EQU 10			garbage collected
sINTPASS	EQU 11			one more pass to parse integer

sst_dspt1	GOSUB	sstprepdsp
		ST=1	sAPPROX
		ST=1	sOK2NDPASS	make 2nd pass w/out flags if nec.
		CD0EX			C=Io (original I pointer)
		D0=C			restore D0
		RSTK=C			save Io for 2nd pass

sst_dspt0	ST=0	sOKSTRIPTAGS	don't strip tags on 1st pass
		ST=0	sINT>REAL	don't convert integer to real
		ST=0	sSYMARRYLIST	sym/arry class not list type
		ST=0	sFAKE%		no fake %'s used
		ST=0	sINTPASS	no extra pass for for integers

sstdsp_2nd	CD1EX
sstdsp_nxtypei	RSTK=C			RSTK:	Io | ->data
		D1=C
* D0 -> typei, ->typei, or SEMI
		A=DAT0	A
		LC(5)	=SEMI
		?C#A	A		reached end of dispatch list?
		GOYES	+
		GOTO	sstdsp_DO2ND	yes, check for 2nd pass
+		LC(5)	=DOBINT
		?C#A	A
		GOYES	+
		D0=D0+	5
		C=DAT0	A		inline bint; C[A] = typei
		GONC	sstdsp_ninline
+		AD0EX
		D0=D0+	5
		C=DAT0	A		bint in ROM; C[A] = typei
		D0=A

sstdsp_ninline	D0=D0+	5		D0 -> dispatchee
sstdsp_nxtnib	?C#0	P		arg = wildcard?
		GOYES	+
		GOTO	sstdsp_wildOK
+		ST=0	sXTABLE
		C=C+1	P		set carry if F
		GONC	sstdsp_matchi
		ST=1	sXTABLE
		CSR	A		and adjust C[A] = typei

sstdsp_matchi	RSTK=C			RSTK: Io | ->data | typei
		A=0	A
		A=C	P
		C=A	A
		A=A+A	A
		A=A+A	A
		A=A+C	A
		LC(5)	(=MTCHTBL)-10	#20E76
		?ST=0	sXTABLE		get 2nd half of table?
		GOYES	+
		LC(5)	(=MTCHTBL)+70	#20EC6
+		A=A+C	A
		AD1EX
		C=DAT1	A		C[A] = prologue to test
		D1=A			restore D1
		RSTK=C			RSTK: Io | ->data | typei | prologue
		C=DAT1	A
		CD1EX
		A=DAT1	A		A[A] = prologue of current arg
		D1=C

		LC(5)	#11111		if prologue = #11111, treat it
		?C#A	A		like a program
		GOYES	+
		LA(5)	=DOCOL

+		C=RSTK			C[A] = test prologue
		RSTK=C
		?C=A	A		do we have a match?
		GOYES	sstdsp_matched	yes

* no match; if test prologue = #00000, then test against sym class
		?C#0	A		skip test against sym class?
		GOYES	sstdsp_chkarry	yes, skip to arry class test
		LC(5)	=DOSYMB
		?C=A	A
		GOYES	sstdsp_matched
		LC(3)	=DOIDNT
		?C=A	A
		GOYES	sstdsp_matched
		LC(2)	=DOLAM
		?C=A	A
		GOYES	sstdsp_matched
		LC(3)	=DOINT
		?C#A	A
		GOYES	sstdsp_tagoff?
sstdsp_matched	GOTO	sstdsp_nibOK

* no match, if test prologue = #FFFFF, then test against arry class
sstdsp_chkarry	C=C+1	A		skip test against arry class?
		GONC	sstdsp_tagoff?	yes, skip to tag strip test
		LC(5)	=DOARRY
		?C=A	A
		GOYES	sstdsp_matched
		LC(3)	=DOMATRIX
		?C=A	A
		GOYES	sstdsp_matched
*		GOTO	sstdsp_tagoff?

sstdsp_tagoff?	?ST=0	sOKSTRIPTAGS	don't strip tags?
		GOYES	+
		LC(5)	=DOTAG		is arg tagged?
		?C#A	A
		GOYES	+
		GOTO	sstdsp_remtags	yes, strip tags; sstdsp_matchi

* No match so far. If we got here from sstdsp_arry, ensure that lists
* are invalid. For speed, skip integer>real conversion until final pass
+		LC(5)	=DOLIST
		?C#A	A
		GOYES	+
		ST=1	sSYMARRYLIST	got list for sym or arry
+		?ST=0	sINT>REAL	skip integer conversion?
		GOYES	+		yes, skip for now

		GOTO	sstdsp_int>%	no, convert then sstdsp_matchi

+		?ST=0	sAPPROX		do not allow integer as real?
		GOYES	sstdsp_dofail
		LC(5)	=DOINT
		?C#A	A
		GOYES	sstdsp_dofail

* we currently have an integer; if test prologue was DOREAL, then
* allow integer as valid arg and set sFAKE%
		C=RSTK			get test prologue
		RSTK=C
		A=C	A
		LC(5)	=DOREAL
		?C#A	A
		GOYES	sstdsp_dofail
		ST=1	sFAKE%		integer was treated as %
		GONC	sstdsp_nibOK

sstdsp_dofail	ST=0	sFAKE%		next dispatch, so reset flag
		C=RSTK			pop test prologue
		C=RSTK			pop typei
sstdsp_ifail	GOSBVL	=SKIPOB		skip dispatchee
		C=RSTK			pop ->data
		GOTO	sstdsp_nxtypei

sstdsp_nibOK	C=RSTK			pop test prologue
		C=RSTK			pop typei
sstdsp_wildOK	D1=D1+	5		D1 -> next arg
		CSR	A		get next typei
		?C=0	A		are we done?
		GOYES	sstdsp_end?
		GOTO	sstdsp_nxtnib

sstdsp_end?	?ST=0	sFAKE%		no integers treated as %?
		GOYES	+		then exit
		ST=0	sFAKE%
		ST=1	sINTPASS	trigger extra pass
		D1=D1-	5
		GONC	sstdsp_ifail

** Success, return dispatchee in return stack and loop
+		C=RSTK
		D1=C			D1 = D
		C=B	A
		CD0EX
		D0=D0-	5
		DAT0=C	A		Save new "D0"
		C=R4			restore D0
		D0=C			and loop
		D0=D0+	10		Skip error trap to get lams right!
		GOVLNG	=Loop

* Dispatch preparation code
sstprepdsp	C=B	A
		CD0EX
		R4=C			Save D0 to R4[A]
		D0=D0-	5		Get topmost stream to D0 for
		C=DAT0	A		dispatching
		D0=C
		RTN

* Second pass done, check for final pass if we need to convert an
* integer to real. No final pass if we encountered a list whie needing
* an array or matrix.
sstdsp_error?	?ST=1	sAPPROX		allow integers as reals?
		GOYES	+
sstdsp_err	C=R4
		D0=C
		GOVLNG	=SetTypeErr	arg type error
+		?ST=1	sINTPASS	one more pass?
		GOYES	+
		?ST=1	sSYMARRYLIST	got list for sym/arry class?
		GOYES	sstdsp_err
+		ST=0	sAPPROX		do not allow integer as real
		ST=1	sINT>REAL	convert integer to real
		C=RSTK			pop ->data
		C=RSTK			pop Io (original D0)
		GOTO	+		final pass (CC not guaranteed)

* Check for second pass
sstdsp_DO2ND	?ST=0	sOK2NDPASS	already in 2nd pass?
		GOYES	sstdsp_error?
		ST=1	sOKSTRIPTAGS	2nd pass; strip tags this time
		ST=0	sOK2NDPASS	no 3rd pass
		ST=0	sFAKE%		no fake %'s used
		C=RSTK			pop data pointer
		C=RSTK			pop Io
		RSTK=C			RSTK: Io
+		D0=C			restore D0
		GOTO	sstdsp_2nd	do 2nd pass

* Remove tags, then jumps back to sstdsp_matchi
sstdsp_remtags	C=DAT1	A
		CD1EX			C[A] = addr of tagged obj
		D1=D1+	5		skip DOTAG prologue
		A=0	A
		A=DAT1	B		A[A] = tag name len
		A=A+A	A		A[A] = tag name len in nibs
		D1=D1+	2		skip to tag name
		CD1EX
		C=C+A	A
		CD1EX			D1 = ->tagee
		RSTK=C			RSTK: ... | ->tagobj
		C=DAT1	A
		R0=C.F	A		R0[A] = tagee[0-4]
		CD1EX			D1 = tagee[0-4]
		R1=C.F	A		R1[A] = ->tagee
		A=DAT1	A
		LC(5)	=PRLG		not in ROM if tagee[0-4] = PRLG
		?C=A	A		get true tagee pointer
		GOYES	+
		A=R0.F	A
		GONC	sstdsp_newob	CC gauranteed
+		A=R1.F	A
sstdsp_newob	C=RSTK			pop ->tagobj
		D1=C
		DAT1=A	A		replace ->tagobj with ->tagee
		C=RSTK			pop test prologue
		C=RSTK			pop typei
		GOTO	sstdsp_matchi

* Check for integer; no integer then jump to sstdsp_dofail;
* otherwise, convert to real number and then jump to sstdsp_matchi
sstdsp_int>%	LC(5)	=DOINT
		?C=A	A
		GOYES	+
		GOTO	sstdsp_dofail
+		CD1EX
		RSTK=C			RSTK: ... | ->int
		D1=C
		C=DAT1	A
		D1=C
		D1=D1+	5
		A=DAT1	A		A[A] = integer len. + 5
* if len = 6, then integer = 0
		A=A-CON	A,7
		GONC	+
		LC(5)	=%0
		A=C	A
		C=RSTK			pop ->int
		D1=C
		DAT1=A	A		change ->int to =%0
		C=RSTK			pop prologue
		C=RSTK			pop typei
		GOTO	sstdsp_matchi

+		R0=A.F	A		R[0] = intlen - 1
		AD1EX			A[A] -> intlen
		C=RSTK			pop ->int
		R1=C.F	A		R1[A] = ->int
		C=RSTK			pop prologue
		C=RSTK			pop typei
		R2=C.F	A		R2[A] = typei
		C=RSTK
		D1=C			D1 -> data
		GOSBVL	=SAVPTR
		D1=A			D1 -> intlen
		A=R0.F	A
		D1=D1+	5		D1 -> digits
		C=0	A
		LC(1)	12-1		zero-based
		?C<A	A		more than 12 digits?
		GOYES	sstdsp_large%	yes, skip to large % handler

* handle small integers
		C=C-A	A
		D=C	A		D[A] = num of digits to pad
		C=DAT1	W

-		CSL	W		padd least sig. digits w/ 0's
		D=D-1	A
		GONC	-
		CSL	W		shift mantissa into position
		CSL	W

		D1=D1-	5		D1 -> intlen
		C=DAT1	X
		C=C-CON	X,7		read exponent
		A=C	W		A[W] = mantissa | exponent
		LC(1)	9
		?C>=A	P		adjust exponent? (HEX to DEC)
		GOYES	+
		A=A+CON	B,6		#A - #F -> #10 - #15
+		GOTO	sstdsp_dopush%

sstdsp_large%	CD1EX
		C=C+A	A
		CD1EX
		D1=D1-	14		D1 -> most sig. digits
		C=DAT1	W
		SETDEC
		C=C+C	X		check least sig. digits
		GONC	+		CS -> round up
		C=C+1	M
		GONC	+
		CSR	M		carry occured, shift right
		P=	14		and account for carry
		LC(1)	1
+		SETHEX
		D=C	W		D[W] = real body
		C=A	A		C[A] = exponent (in HEX)
		A=0	W
		B=0	W
		B=B+1	A
		SETDEC
-		SB=0			compute expon. by powers of 2
		CSRB.F	A
		?SB=0
		GOYES	+
		A=A+B	W		A[A] = current exponent total
+		B=B+B	W		current power of 2
		?C#0	A		any bits left?
		GOYES	-
		?P=	0		did we round up earlier?
		GOYES	+
		P=	0		yes, reset P
		A=A+1	W		and add 1 to exponent
+		SETHEX
		C=0	W
		LC(3)	#499		max exponent allowed
		?C>=A	W		overflow?
		GOYES	+		no, continue

		GOTO	sstdsp_overflow

+		C=D	W		get real body
		C=A	X		get real exponent (in DEC)
		A=C	W		A[W] = mantissa | exponent

sstdsp_dopush%	ST=0	sGARBAGE
		SETHEX
		?A#0	M		non-zero real?
		GOYES	+
		A=0	W
+		R0=A			R0[W] = mantissa | exponent
		P=	13		-10 < % < 10 ?
		?A=0	WP
		GOYES	sstdsp_pushROM%	yes, push ROM pointer to %
		P=	0		no, create % in TEMPOB
-		GOSBVL	=ROOM
		A=C	A
		LC(5)	5+16+5+1	header, body, pointer, +1
		?C<=A	A		do we have enough room
		GOYES	sstdsp_skipgc	yes, skip GC
		?ST=0	sGARBAGE
		GOYES	+
		GOVLNG	=GPMEMERR	GC'd and still no room!
+		ST=1	sGARBAGE
		GOSBVL	=GARBAGECOL
		GOTO	-		try again
sstdsp_skipgc	LC(2)	5+16		5 for header, 16 for real obj
		GOSBVL	=CREATETEMP
		AD0EX			A[A] -> real (in TEMPOB)
		D0=A			D0 -> real (in TEMPOB)
		LC(5)	=DOREAL		write prologue and body
		DAT0=C	A
		D0=D0+	5
		C=R0
		DAT0=C	W

sstdsp_push%	GOSBVL	=GETPTR
		CD1EX
		RSTK=C			RSTK: Io | ->data
		C=R1.F	A		get original D1 ( ->int )
		D1=C			restore D1
		DAT1=A	A		change ->int to ->real
		C=R2.F	A		C[A] = typei
		GOTO	sstdsp_matchi	try dispatching again

* %'s in ROM: %0, %1, ..., %9, %-1, %-2, ..., %9 in that order
sstdsp_pushROM%	C=A	W
		P=C	14
		C=P	0
		?A=0	S		negative number?
		GOYES	+
		P=	8		if so, add offset of 9-1
		C+P+1
+		A=C	A
		A=A+A	A
		A=A+A	A
		A=A+C	A
		CSL	A
		A=A+C	A		A[A] = offset to % ptr
		P=	0
		LC(5)	=%0
		A=A+C	A
		GOTO	sstdsp_push%

* The code in ROM 2.15 actually contains 2 bugs, which we fix here.
* The first bug is in testing the overflow flag with ?ABIT=1 0, which
* determines if the overflow flag is set. The ROM code then skips
* over the error jump if the overflow flag is set! The second bug is
* that the pointer to the max real constant is loaded into C[A], but
* it needs to be in A[A].
sstdsp_overflow	D0=(5)	(=SystemFlags)+5
		A=DAT0	B

* test if overflow flag (-21) is cleared!
*		?ABIT=0	0		overflow = error flag cleared?

* this is what is in ROM:
		?ABIT=1	0

		GOYES	+
		GOSBVL	=GETPTR
		LC(5)	=ofloerr	no, generate overflow error
		GOVLNG	=GPErrjmpC
+		LC(5)	=%MAXREAL
		?D=0	S		negative max real?
		GOYES	+
		LC(5)	=%-MAXREAL
+		D0=(5)	(=SystemFlags)+6
		A=DAT0	B
		ABIT=1	0
		DAT0=A	B		set overflow indicator (-25)
* missing opcode in ROM 2.15; uncomment to "fix" the bug
*		A=C	A		copy pointer to A[A] for push
		GOTO	sstdsp_push%		
ENDCODE

