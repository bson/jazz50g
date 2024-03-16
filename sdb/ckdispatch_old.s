	CODE
sst_dspt1	GOSUB	sstprepdsp
		ST=1	sOK2NDPASS	make a second pass w/o tags if nec.
		CD0EX			C=Io (original I pointer)
		D0=C			Restore D0
		RSTK=C			Save Io for 2nd pass
sst_dspt0	ST=0	sOKSTRIPTAGS	Don't strip tags on 1st pass
sstdsp_2nd	CD1EX			C[A] = D
** C[A] = D; D0 -> typei, ->typei, or ->SEMI
** Io may be on hardware stack
** Save D on hardware stack. If [D0] = SEMI then ERROR, else
** fetch typei
sstdsp_nxtypei	RSTK=C			RSTK: (Io) | D
		D1=C			D1 = D
		A=DAT0	A
		LC(5)	=SEMI
		?C#A	A
		GOYES	+
		GOTO	sstdsp_DO2ND	[D0] = SEMI => ERROR
** typei may be an embedded bint ot a pointer to a bint
+		LC(5)	=DOBINT
		?C#A	A
		GOYES	+		Not in-line BINT
		D0=D0+	5		D0 -> bint body
		C=DAT0	A		C[A] = typei
		GONC	sstdsp_ninline
+		AD0EX			D0 -> typei object; A[A] = I
		D0=D0+	5
		C=DAT0	A		C[A] = typei
		D0=A
sstdsp_ninline	D0=D0+	5		D0 -> desti
** D0 -> desti; RSTK: D; D1 = current SP; C[A] = current typei
** Loop if wildcard. Else, fetch prologue to test for from type table
sstdsp_nxtnib	?C#0	P
		GOYES	+		Not wild card
		GOTO	sstdsp_wildOK	Accept as wild
+		ST=0	sXTABLE		Select first half table
		C=C+1	P		Set CRY if F
		GONC	sstdsp_matchi
		ST=1	sXTABLE		Select second half table
		CSR	A		Get the next typei nibble
sstdsp_matchi	RSTK=C			RSTK: D | current typei
** Note: typei from 1st half table is now incremented by 1
		A=0	A
		A=C	P
		C=A	A		A[A], C[A] = type nib in [0]
		A=A+A	A
		A=A+A	A
		A=A+C	A		A[A] = 5 * type nib (table offset)
** Load appropriate constant according to which half table is needed
		LC(5)	(=MTCHTBL)-10	1st half table
		?ST=0	sXTABLE
		GOYES	+
		LC(5)	(=MTCHTBL)+70	2nd half able
+		A=A+C	A		A[A] = ->table position
		AD1EX
		C=DAT1	A		C[A] = prologue to test for
		D1=A
** D0-> desti; RSTK: (Io) | D | current typei;
** C[A] = prologue to test for (or 0 if testing sym)
** Fetch actual prologue and determine if match

		RSTK=C
		C=DAT1	A		C[A] = ->ob on stack
		CD1EX
		A=DAT1	A		A[A] = actual prologue
		D1=C

** Han:	added check for #11111 pointers
		LC(5)	#11111		if prologue = #11111, treat it
		?C#A	A		like a program
		GOYES	+
		LA(5)	=DOCOL
+
		C=RSTK			C[A] = prologue to match
		?C=A	A
		GOYES	sstdsp_nibOK	match
		?C=0	A
		GOYES	sstdsp_CK&D40	Sstdsp_Matching sym
** Han:	added array class check
		C=C+1	A
		GONC	sstdsp_tagoff?
* Check for DOARRY and DOMATRIX
		LC(5)	=DOARRY
		?C=A	A
		GOYES	sstdsp_nibOK
		LC(3)	=DOMATRIX
		?C=A	A
		GOYES	sstdsp_nibOK
sstdsp_tagoff?	?ST=1	sOKSTRIPTAGS	if OK to remove tags
		GOYES	sstdsp_remtags	...then process tagged object
** D0 -> desti; RSTK: (Io) | D | trash
** This typei will not match the stack configuration. Therefore,
** get D off hardware stack and loop t get next typei.
sstdsp_ifail	C=RSTK			RSTK = (Io) | D
		GOSBVL	=SKIPOB		SKIPOB allows embedded desti objects
		C=RSTK			C[A] = D
		GOTO	sstdsp_nxtypei
** Have matched this nibble to a stack entry. Get next nibble to
** match. If all done, then complete success; else try to match next
** nibble to next stack entry.
** D0-> desti; RSTK: D | current typei; D1 = SP
sstdsp_nibOK	C=RSTK			C[A] = current typei
sstdsp_wildOK	D1=D1+	5		D1 -> next stack position
		CSR	A		Shift in next nib to C[0]
		?C=0	A
		GOYES	+		All done
		GOTO	sstdsp_nxtnib	Loop
** Compete success, return dispatched ob in rstk and loop
+		C=RSTK
		D1=C			D1 = D
		C=B	A
		CD0EX
		D0=D0-	5
		DAT0=C	A		Save new "D0"
		C=R4			restore D0
		D0=C			and loop
		D0=D0+	10		Skip the error trap to get lams right!
		GOVLNG	=Loop
** Sstdsp_Matching sym here
sstdsp_CK&D40	LC(5)	=DOSYMB
		?C=A	A
		GOYES	sstdsp_nibOK	symb matches
		LC(3)	=DOIDNT
		?C=A	A
		GOYES	sstdsp_nibOK	id matches
		LC(2)	=DOLAM
		?C=A	A
		GOYES	sstdsp_nibOK	lam matches
** Han:	added ZINT
		LC(3)	=DOINT		zint matches
		?C=A	A
		GOYES	sstdsp_nibOK
		GOTO	sstdsp_tagoff?	Not symb, so go try removing tag
** Convert tagged object to its object for possible match.
** At this point, we have D0-> desti, D1-> current stack ob,
** RSTK = D | typei (Io is not on the stack since this is the second pass).
** If the current stack ob is tagged, it will be replaced by
** the tagee by advancing the current object pointer on the stack
** to the tagee in the body of the tagged object.  Then execution jumps
** back to sstdsp_matchi, where the tagee is matched against the current typei.
sstdsp_remtags	LC(5)	=DOTAG		compare actual prologue
		?C#A	A
		GOYES	sstdsp_ifail	not tagged - fail
		C=DAT1	A		C[A] = ->ob
		CD1EX			C[A] = Stack Pointer, D1-> ob
		D1=D1+	5		D1-> tag nameform
		A=0	A
		A=DAT1	B		A[A] = nameform lenght
		A=A+A	A		A[A] = lenght in nibs
		D1=D1+	2		D1-> name filed
		CD1EX			C[A]-> name field, D1 = SP
		C=C+A	A		C[A]-> tagee
** Now determine whether tagee is a hard ROM pointer object.  If so,
** copy the pointer to the stack.  Otherwise, put a pointer to the
** tagee on the stack.
		CD1EX			C[A] = SP, D1= ->tagee
		RSTK=C			RSTK = D | typei | SP
		C=DAT1	A		C[A] = tagee[0-4]
		R0=C.F	A		R0[A] = tagee[0-4]
		CD1EX			C[A] = ->tagee, D1 = tagee[0-4]
		R1=C.F	A		R1[A] = ->tagee
		A=DAT1	A		A[A] = prologue start
		LC(5)	=PRLG		C[A] = PRLG
		?A=C	A
		GOYES	+		Not pointer ob
		A=R0.F	A		A[A] = tagee[0-4] = pointer ob
		GONC	sstdsp_newob
+		A=R1.F	A		A[A] = ->tagee
sstdsp_newob	C=RSTK			C[A] = SP
		D1=C			D1 = SP
		DAT1=A	A		replace tagged ob with tagee ob/ptr
		C=RSTK			C[A] = typei, RSTK = D
		GOTO	sstdsp_matchi	try the match again
** Restore D0 & do type error
-		C=R4
		D0=C
*		GOVLNG	(=SETTYPEERR)+5
		GOVLNG	=SetTypeErr
sstdsp_DO2ND	?ST=0	sOK2NDPASS
		GOYES	-		2nd pass not allowed - give up
		ST=1	sOKSTRIPTAGS	Strip tags this pass
		ST=0	sOK2NDPASS	No third pass
		C=RSTK			Pop old D
		C=RSTK			Pop Io
		D0=C			Restore Io to D0
		GOTO	sstdsp_2nd	Try again
* Dispatch preparation code
sstprepdsp	C=B	A
		CD0EX
		R4=C			Save D0 to R4[A]
		D0=D0-	5		Get topmost stream to D0 for
		C=DAT0	A		dispatching
		D0=C
		RTN
	ENDCODE
