**********************************************************************
*		DoEdFill
**********************************************************************
* Description:
*	Find entry that starts with search string. If there is more
*	than one such entry, then push the substring that is common
*	to all matches.
*
* Register usage:
*
* B[A] = first char in search; used as search length upon exiting
* D[A] = address of most recently tested entry
*
* R0:	->current entry
* R1:	->search
* R2:	->first match (length field)
* R3:	->final match (length field)
*		also used as match type
*		0: no match, search pattern too long, or null
*		1: exact match
*		2: multiple match				
* R4: 	config address
*
* Notes:	Search can be sped up with a 1st char hash table
*		Jazz's HPTAB uses this type of hash; extable does not
*		This is a complete rewrite to support extable.
**********************************************************************
* NULLNAME DoEdFill
::
  FINDTAB DROP GetTabCfg		( ensure extable exists )
  CODE
sMATCH+		EQU	0

		GOSBVL	=POP2#
		R0=A			-> number of entries
		R4=C			CONFIG
		
		GOSBVL	=PopASavptr
		A=A+CON	A,10
		R1=A			-> $search
		
		C=R4
		GOSUB	DoEFcfg
		
		C=0	A
		R2=C			first match
		R3=C			last match

		C=R0
		D0=C			D0 -> number of entries
		D0=D0+	5		D0 -> offset to entry table
		C=DAT0	A
		AD0EX
		C=C+A	A
		D0=C
		R0=C			R3[A] -> start of entry table
		C=R1
		D1=C
		D1=D1-	5		D1 -> $searchlen
		C=DAT1	A
		D1=D1+	5
		C=C-CON	A,5
		CSRB.F	A
		B=C	A		B[A] = number of chars
		?C=0	A
		GOYES	DoEFnull$
		LC(5)	MAXENTRLEN
		?B>C	A
		GOYES	DoEFnull$	too long; push null$
		C=DAT1	B
		BSL	A
		BSL	A
		B=C	B

		ST=0	sMATCH+		search for first match
		GOSUB	DoEFsrchlp
		GONC	DoEFfound	found first match
DoEFnull$	B=0	A		no match at all; push null$
		GOTO	DoEFpush$

DoEFfound	C=D	A		save ->first match to R2
		R2=C

		ST=1	sMATCH+
-		C=R0
		D0=C			
		GOSUB	DoEFskip	now find last match
		GOC	DoEFnomore
		C=D	A
		R3=C			update final match
		GONC	-

DoEFnomore	C=R3			did we actually get 2nd match?
		?C=0	A
		GOYES	DoEFsingle
		D1=C
		LC(5)	2		2: multiple matches
		R3=C	A
		C=R2
		D0=C
		B=0	A
-		D0=D0+	2
		D1=D1+	2
		A=DAT0	B
		C=DAT1	B
		?A#C	B
		GOYES	DoEFpush$
		B=B+1	A
		GONC	-
		
DoEFsingle	C=R2
		D0=C
		C=0	A
		C=C+1	A
		R3=C	A		single match
		C=DAT0	B
		B=C	A
		
DoEFpush$	C=B	A
		GOSBVL	=MAKE$
		A=A-CON	A,5		A[A] = nibbles + 5
		C=A	A
		A=R2
		AD0EX
		AD1EX			D1 -> string output
		D0=D0+	2		D0 -> start of entry name
		GOSBVL	=MOVEDOWN
		A=R0
		GOSBVL	=GPPushA
		GOSBVL	=SAVPTR
		C=R4		
		GOSUB	DoEFuncfg
		A=R3
		GOVLNG	=PUSH#ALOOP
**********************************************************************
DoEFsrchlp	D0=D0+	5		skip addr
		C=D0
		D=C	A
		C=DAT0	4
		?C=0	B
		RTNYES			reached end; exit
		CSR	A
		CSR	A
		?C>B	B
		RTNYES			end search
		?C=B	B		first char match?
		GOYES	DoEFtestall
DoEFskip	C=0	A
		C=DAT0	B
		C=C+1	A
		C=C+C	A		C[A] = 2 + entry len
		AD0EX
		A=A+C	A
		AD0EX
		GOTO	DoEFsrchlp
DoEFtestall	A=R1			D1 -> search string
		D1=A
		C=D0
		R0=C			save D0
		D0=D0+	2
		C=B	A		use size of search
		CSR	A
		CSR	A
		A=C	B
		GOSBVL	=CompareACbBytes
		RTNNC			found a match
		?ST=1	sMATCH+		searching for more?
		RTNYES			if so, return
		GONC	DoEFskip	no, contine 1st match search
**********************************************************************
DoEFcfg		C=R4
		?C=0	A
		RTNYES
		PC=C
**********************************************************************
DoEFuncfg	C=R4
		?C=0	A
		RTNYES
		P=	1
		PC=C
  ENDCODE
;
**********************************************************************
