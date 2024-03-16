ASSEMBLE
**********************************************************************
* dis/disinstra.a	old code for EntryAddr?
**********************************************************************
* Search address from RPL.TAB
* Entry:	A[A]=address R3[A]=->tab R3[A1]=->dtab	P=0 HEX
* Exit:		CC:match	D0=->namelen	P=0 HEX
*		CS:no match (or no RPL.TAB)	 	P=0 HEX
* Uses:		B[A] C[W] D[A] D0 P CRY		(A[A] not modified!!)
* Stack:	1
* Notes:	If no RPL.TAB is present CS is returned. If RPL.TAB and
*		DIS.TAB are both present a fast routine is used.
**********************************************************************
EntryAddr?	C=R3
		?C=0	A		* Fail if no tab
		RTNYES

*		D0=C			* D0 = ->tab

*		CSR	W
*		CSR	W
*		CSR	W
*		CSR	W
*		CSR	W		* C[A] = ->dtab
*		?C#0	A
*		GOYES	entradrfast	* dtab exists - use fast search

*		C=R3			* configure entries lib
		GOSBVL	=CSRW5
		GOSBVL	=CSRW5
		?C=0	A
		GOYES	+
		GOSUB	eadrPC=C
+		C=R3
		D0=C			* D0 = ->tab
		GOSBVL	=CSRW5		* C[A] = ->dtab
		
***
*** old code for slow search
***

*entradrslow	D0=D0+	5
*		C=DAT0	A		* C[A]=tablen
*		AD0EX
*		C=C+A	A
*		D=C	A		* D[A]=tabend
*
*		LC(5)	RTAB_REL	#1E9	* Skip to 1st name
*		A=A+C	A
*		AD0EX
*		GONC	entryadr10
*entryadrlp	P=C	5
*		D0=D0+	4
*		CD0EX
*		C+P+1
*		C+P+1

* Note that the loop assumes the end address in D[A] is *EXACT*
* Thus comparing XS field for equality is ok
* XS field comparison saves 4 cycles 15/16 times, loses 14 1/16 times
* For my CST the savings was 320 ticks (18434 -> 18110)

* For real savings a tab format is needed with an address sorted REL(5) list

*		D0=C
***		?C>=D	A
***		GOYES	entradrno
*		?C=D	XS		* same page?
*		GOYES	entrypgfix

*		D0=C
*entryadr10	C=DAT0	6		* Read address & name len
*		?C#A	XS		* For my own tab better than [B]
*		GOYES	entryadrlp

*		?C#A	A
*		GOYES	entryadrlp
*entryadris	D0=D0+	5		* Skip to name lenght (CC)
*entryadrno	P=	0
*		RTN

* Speed up fix:

*entrypgfix	?C>=D	A
*		GOYES	entryadrno
*		D0=C
*		C=DAT0	6		* Read address & name len
*		?C#A	XS		* For my own tab better than [B]
*		GOYES	entryadrlp
*		?C#A	A
*		GOYES	entryadrlp
*		GONC	entryadris

****************************************
* Fast version of entry address search
* Entry:	A[A]=addr C[A]=->dtab R3[A]=->tab
* The routine finds the match which is lowest in dtab.
****************************************
entradrfast	ACEX	A
		D=C	A		* D[A] = addr
		D0=A			* D0 = ->dtab
		D0=D0+	5+5+4		* Skip to N
		C=DAT0	A
		B=C	A
		B=B-1	A		* B[A] = END	(0;N-1 array)
		A=0	A		* A[A] = START		

		D0=D0+	5
		CD0EX
		RSTK=C			* RSTK = ->dtab offset1

eadrflp		C=A	A
		C=C+B	A
		CSRB.F	A		* C[A] = MID

		CD0EX
		C=RSTK
		RSTK=C
		AD0EX
		C=C+A	A
		A=A+A	A
		A=A+A	A
		A=A+C	A		* A[A] = midloc in dtab
		AD0EX
		C=DAT0	A		* C[A] = offs for MID
		AD0EX
		A=R3.F	A		* A[A] = ->tab
		A=A+C	A		* A[A] = ->addr for MID
		AD0EX
		C=DAT0	A		* C[A] = addr for MID

		?A=B	A		* START = END?
		GOYES	eadrthis?	* Check if we found a match
		?D<=C	A
		GOYES	eadrDN		* Scan lower half

		A=A+B	A		* START = (START+END)/2 + 1
		ASRB.F	A
		A=A+1	A
		GONC	eadrflp

eadrDN		B=B+A	A		* END = (START+END)/2
		BSRB.F	A
		GONC	eadrflp

eadrthis?
		CDEX	A
		A=C	A		* Restore addr to A[A]
		C=RSTK			* Pop ->dtab
		C=D	A
		D0=D0+	5		* Skip to name
		?A#C	A		* Matching addresses?
		RTNYES			* No - CS
		RTN			* Yes - CC


**********************************************************************
* ass/assrpl.a	old code for Entry?
**********************************************************************
* Find symbol from RPL.TAB
* Input: 	D0 = ->word	B[A] = toklen-1		R3[A] = ->rtab
* Output: 	CS: No match
*		CC: Match	A[A] = entry_addr
* Uses:		A[W] C[W] D[A]
* Stack:	1
**********************************************************************
Entry?		C=0	A
		LC(1)	15		Too long to be in tab?
		?B>=C	A
		RTNYES			Yes - ignore
*		C=R3.F	A		Tab exists?
		C=R3
		?C=0	A
		RTNYES			No - ignore

* configure bank if needed
		AD0EX			use A to save D0
*		C=R3			->rtab ->cfg
		GOSBVL	=CSRW5
		?C=0	A
		GOYES	+
		GOSUB	Entry?PC=C	configure
+		AD0EX			restore D0
		C=R3.F	A

		CD1EX			D1 = ->tab
		RSTK=C			Save ->buf to RSTK

		B=B+1	A		Increase to get true toklen

		D1=D1+	14		Skip to reltab

		A=0	A
		A=DAT0	B		A[A] = 1st char
		LCASC	'~'		Check limits ' ' - '~'
		?A>C	B
		GOYES	SrchAdrFail
		LCASC	' '
		A=A-C	B
		GOC	SrchAdrFail
		C=A	A
		A=A+A	A
		A=A+A	A
		A=A+C	A		A[A] = (chr-spc)*5
		CD1EX
		C=C+A	A
		D1=C			D1 = ->1stchrtab
		A=DAT1	A
		?A#0	A		Do entries of 1stchr exist?
		GOYES	+	---+	Yes - continue
SrchAdrFail	C=RSTK		   |	No - restore ->buf
		D1=C		   |	and return CS


* restore bank; failed search so use A[A] to temp-save D0
		AD0EX
		GOSUB	EntResetBank
		AD0EX

		B=B-1	A	   |	Restore to toklen-1
		RTNSC		   |
+		C=C+A	A	<--+	C[A] = ->1stchr
-		D1=D1+	5	<--+	Find the next tab field
		A=DAT1	A	   |
		?A=0	A	   |
		GOYES	-	---+
		CD1EX			D1 = ->1stchr
		C=C+A	A		C[A] = ->1stchrend
		D=C	A		D[A] = ->1stchrend
		D1=D1+	5		Skip entr_address
SrchAdrLp	C=DAT1	B		C[0] = entr_len
		?C=B	P		Matching lenght?
		GOYES	SrchTst1	Yes - compare bodies
		D1=D1+	1+5-2		Skip name lenght and addr
SrchAdrCont	P=C	0
		CD1EX
		C+P+1
		C+P+1
		D1=C
		P=	0
		?C<D	A		->next < ->1stchrend ?
		GOYES	SrchAdrLp	Yes - continue search
		GONC	SrchAdrFail	No - restore ->buf and return CS

* Test if equal bodies

SrchTst1	D1=D1+	1
		C=C+C	B		Compare with P= 2*chars-1
		C=C-1	B
		P=C	0
		?CBIT=1	4
		GOYES	SrchTstLong	Test long names
SrchTstShrt	A=DAT0	WP
		C=DAT1	WP
		?A=C	WP
		GOYES	SrchAdrOK	Got match!
SrchTstNot	C=B	B		toklen
		D1=D1+	5-2		Skip next address
		GONC	SrchAdrCont
SrchAdrOK	P=	0
		D1=D1-	6		Back to ->entr_addr
		A=DAT1	A		A[A] = entr_addr
		C=RSTK			C[A] = ->buf
		D1=C			D1 = ->buf

* restore bank; successful search; A[A] = entr_addr
		CD0EX
		D=C	A
		GOSUB	EntResetBank
		C=D	A
		CD0EX

		B=B-1	A		Restore to toklen-1
		RTNCC

SrchTstLong	A=DAT0	W
		C=DAT1	W
		?A#C	W
		GOYES	SrchTstNot
		D0=D0+	16
		D1=D1+	16
		A=DAT0	WP
		C=DAT1	WP
		D0=D0-	16
		D1=D1-	16
		?A#C	WP
		GOYES	SrchTstNot
		GONC	SrchAdrOK	Got match!
RPL

**********************************************************************
* tab/ea.s	old code for #>Entr and Entr>#
**********************************************************************
( # --> $ )
NULLNAME #>Entr
CODE
		GOSBVL	=POP#
		R2=A
		GOSBVL	=SAVPTR
		GOSUB	FindTab		C[A] -> cfg; A[A] ->libnum
		GONC	+
undeferr	LC(5)	#204		"Undefined name"
		GOVLNG	=GPErrjmpC	
+		D=C	A		preserve C[A]
		GOSBVL	=CSLW5
		R3=C
		C=D	A
		GOSUB	ftGetTabDis	R0 -> rtab; R1 ->dtab
		C=R1.F	A
		GOSBVL	=CSLW5
		C=R0.F	A
		R3=C			R3[W] = ->rtab ->dtab ->cfg
		A=R2

		GOSUB	entryadr?	CC: D0=->namelen
		GONC	+
		GOSUB	entrstbank1
		GOTO	undeferr
+		C=0	A
		C=DAT0	1
		D0=D0+	1
		AD0EX
		R1=A			R1 = ->name
		C=C+C	A
		R2=C			R2 = nibbles in name
		GOSBVL	=MAKE$N		D0 = ->$body
		A=R1
		AD0EX			D0 = ->name
		D1=A			D1 = ->$body
		C=R2
		GOSBVL	=MOVEDOWN
		GOSUB	entrstbank1
		A=R0			Push $name
		GOVLNG	=GPPushALp

entryadr?	B=A	A		addr
		A=PC
		LC(5)	(EntryAddr?)-(*)
		C=C+A	A
		A=B	A		addr
		PC=C

entrstbank1	C=R3
		GOSBVL	=CSRW5
entrstbank2	GOSBVL	=CSRW5
		?C=0	A
		RTNYES
		P=	1
		PC=C
ENDCODE

( $ --> # )
NULLNAME Entr>#
CODE
		GOSBVL	=PopASavptr
		R2=A
		GOSUB	FindTab		C[A] -> cfg; A[A] ->libnum
		GONC	+
		GOTO	undeferr	
+		D=C	A		preserve C[A]
		GOSBVL	=CSLW5
		R3=C
		C=D	A
		GOSUB	ftGetTabDis	R0 -> rtab; R1 ->dtab
		C=R0.F	A
		R3=C			R3[W] = ->rtab ->cfg
		A=R2

		D0=A
		D0=D0+	5
		C=DAT0	A
		C=C-CON	A,5
		CSRB.F	A
		B=C	A		B[B]=toklen
		B=B-1	A
		GONC	+		Null string
		GOTO	undeferr
+		D0=D0+	5
		GOSUB	callEntry?	Whoa! Out of range for GOSUBL
		C=R3
		GONC	+
		GOSUB	entrstbank2
		GOTO	undeferr
+		GOSUB	entrstbank2
*		R0=A			R0[A] = addr
		GOVLNG	=PUSH#ALOOP
callEntry?
		ADDR	Entry?,C
		PC=C			CC: Match, A[A] = addr
ENDCODE
