**********************************************************************
* Name:		Peek
* Interface	( hxs_addr hxs_len -> $nibbles )
* Description:	Hidden command to peek a few nibbles
* Notes:	The built-in xPEEK command executes an FPTR, which by
*		design covers #40000-#7FFFF. Therefore peeking into
*		this memory block gives erroneous data. Here, we
*		remove use of register B
**********************************************************************
NULLNAME PEEK
tNAME PEEK Peek
::
  0LASTOWDOB! CK2NOLASTWD
  CK&DISPATCH1
  #BB
  CODE
		D1=D1+	5		pop len
		D=D+1	A
		GOSBVL	=SAVPTR
		C=D1
		R1=C			save ->hxs (address to peek)
		D1=D1-	5
		C=DAT1	A
		CD1EX
		D1=D1+	5+5		skip prolog and length of hxs
		C=DAT1	A
		R2=C			R2[A] = len
		C=C+C	A		x2 for chars
		GOSBVL	=MAKE$N
		
		C=R2
		C=C-1	A
		GOC	peek_exit
		D=C	A		D[A] = nibble count (0-based)
				
		A=R1
		AD1EX
		A=DAT1	A
		AD1EX
		D1=D1+	5+5		skip prolog and length of hxs
		A=DAT1	A		A[A] = address
		AD1EX
		
-		A=0	A
		A=DAT1	P		A[P] = nibble
		D1=D1+	1
		LC(2)	'0'
		A=A+C	B
		LC(1)	10
		?A<C	P		adjust for A-F
		GOYES	+
		A=A+CON	B,7
+		DAT0=A	B		write chr
		D0=D0+	2
		D=D-1	A
		GONC	-		get next nibble
peek_exit	GOSBVL	=GETPTR
		A=R0.F	A
		DAT1=A	A
		GOVLNG	=Loop
  ENDCODE
;

**********************************************************************
* Name:		FPTR->
* Interface	( fptr -> $ hxs_next_addr )
* Description:	Hidden command to disassemble FPTR with validity check
*		This is mainly for ED
**********************************************************************
NULLNAME FPTR@
tNAME FPTR@ FPTR\8D
::
  CK1NoBlame
  CHECKME
  NULLNAME Fptr@
  ::
    CODE
		CD0EX
		D0=C
		RSTK=C			save D0
		A=DAT1	A
		AD0EX
		A=DAT0	A
		LC(5)	=DOFLASHP
		?C=A	A		do we have fptr?
		GOYES	+               yes

fptr_typeerr	C=RSTK			no, restore D0 and error out
		D0=C
		LC(5)	=argtypeerr
		GONC	fptr_doerr
		
+		D0=D0+	5
		C=0	A
		C=DAT0	3
		A=C	A
		C=0	P
		?C=0	A		do we have valid id? (0-15)
		GOYES	+		yes

fptr_inverr	LC(5)	#11		no, invalid FPTR
fptr_doerr	GOVLNG	=ErrjmpC
		
+		C=A	A
		C=C+1	P
		LC(5)	#4021D		table len addr for id = 0-14
		GONC	+
		LC(5)	#6021D		table len addr for id = 15
+		RSTK=C
		LC(5)	=FROMPTAB0_15
		C=C+A	A
		A=A+A	A
		A=A+A	A
		C=A+C	A		C[A] = bankswitcher adr
		D0=D0+	3
		A=0	A
		A=DAT0	4		A[4] = fptr cmd
		D0=C
		C=DAT0	A		C[A] = bankswitcher
		?C#0	A		do we have a valid switcher?
		GOYES	+		yes

		C=RSTK			no, pop table address
		GONC	fptr_inverr	and error out

+		LC(5)	#FF000		config size
		CONFIG
		C=DAT0	A		get config adr
		CONFIG
		D0=C
		DAT0=C	B		set bank 2
		UNCNFG			remove bankswitcher
		C=RSTK			pop table address
		D0=C
		C=DAT0	A		get cmd count
		?C<A	A		cmd value too large?
		GOYES	fptr_uncfgerr	yes, restore bank 2 and exit
		
		D0=D0+	5
		CD0EX
		C=C+A	A
		A=A+A	A
		A=A+A	A
		A=A+C	A		A[A] = addr of addr of fptr
		AD0EX
		A=DAT0	A		A[A] = addr of fptr
		
		R0=A
		AD0EX
		A=DAT0	A
		D0=D0+	5
		CD0EX
		?A=C	A
		GOYES	+		pco? yes, continue
		AD0EX
		A=DAT0	A
		LC(5)	=PRLG		prologed? yes, continue
		?A=C	A
		GOYES	+
		AD0EX			get real address for Dob
		R0=A		
+		GOSUB	fptr_rstbank	restore bank

		C=RSTK
		D0=C			get original D0
		GOSBVL	=SAVPTR
		GOVLNG	=PUSH#LOOP

fptr_uncfgerr	GOSUB	fptr_rstbank
		GOTO	fptr_inverr

fptr_rstbank	LC(5)	#FF000
		CONFIG
		D0=(5)	=CurROMBank2
		C=DAT0	A
		CONFIG
		D0=C
		DAT0=C	B
		UNCNFG
		RTN		
    ENDCODE

    ' Dob ROT

    ( #addr Dob fptr )
    CODE
		CD0EX
		RSTK=C			save D0
		A=DAT1	A
		CD1EX			save D1 in C[A]
		AD1EX
		D0=(5)	=FlashPtrBkp
		A=DAT1	8		copy prolog and fptr id
		DAT0=A	8
		CD1EX			restore D1
		D0=D0+	5+3
		A=0	A
		DAT0=A	4		create EVAL via FPTR
		D0=D0-	5+3		D0 ->FlashPtrBkp
		C=RSTK
		CD0EX			C[A] = FlashPtrBkp
		D1=D1+	5
		D=D+1	A
		A=C	A
		PC=(A)
    ENDCODE
  ;
;

**********************************************************************
* Name:		Entr>Fptr
* Interface:	( entry# -> fptr )
* Description:	Converts "^<entry>" to fptr
**********************************************************************
NULLNAME Entr>Fptr
CODE
  		GOSBVL	=PopASavptr
		AD1EX
		D1=D1+	5
		A=DAT1	A
  		R1=A
 		LC(5)	5+3+4
		GOSBVL	=GETTEMP
		AD0EX
		R0=A
		AD0EX
		LC(5)	=DOFLASHP
		DAT0=C	A
		D0=D0+	5		skip prolog
		A=R1
		C=0	A
		C=A	P
		DAT0=C	X		write id number
		ASR	A
		D0=D0+	3
		DAT0=A	4		write cmd number
		A=R0	A
		GOVLNG	=GPPushALp
ENDCODE
**********************************************************************
* Name:		Ent11111@
* Interface:	( #entry_addr -> #entry_addr' )
* Description:	Converts an #11111 type of entry to its real address
* Notes:	Assumes default ROM view
*		Entries between !REDIMUSER and $5x7 (excluding $5x7)
*		are SysRPL entries in pure ML (but are not PCOs).
*		Likewise for LineW through !*triand (excluding !*triand)
*		We also extract the relevant addresses for these
**********************************************************************
NULLNAME Ent11111@
CODE
      		A=DAT1	A
		AD1EX
		C=A	A		save D1 in C[A]
		D1=D1+	5
		A=DAT1	A
		R0=A			R0 = #addr
		AD1EX
		A=DAT1	A		peek underneath address
		D1=C

		C=R0
		C=C+CON	A,5
		?A=C	A		PCO?
		GOYES	ent1x5exit

		LC(5)	=PRLG
		?A=C	A		prolog'd object?
		GOYES	ent1x5exit

		LC(5)	#11111		do we have special handler?
		?A=C	A
		GOYES	+

		A=R0
*		LC(5)	=!REDIMUSER	check non-PCO SysRPL entries
		LC(5)	=LineW
		A=A-C	A
		GOC	ent1x5exit
		A=A+C	A
		LC(5)	=$5x7
		A=A-C	A
		GONC	ent1x5exit
		A=A+C	A
		GOTO	entpushadr

ent1x5exit	GOVLNG	=Loop		no, quit

+		A=R0			yes, time to check boundaries
		LC(5)	=DispEditLine	first FlashPtr
		A=A-C	A
		GOC	+
		A=A+1	A
		C=A	A
		A=A+A	A
		A=A+A	A
		A=A+C	A
		LC(5)	#40222		use fptr entries table
		A=A+C	A
entpushadr	CD1EX
		AD1EX
		A=DAT1	A		may need to check ob type

* could have SysRPL entry (neither pco nor prolog ob); so we may need
* to add in yet another check for valid Dob results

		CD1EX
		GOTO	disadr11111
		
+		A=A+C	A
		LC(5)	=TopicVar1!	boundary for indirection
		A=A-C	A
		GONC	ent1x5exit	no, quit
		A=A+C	A
		LC(5)	=!*triand	first VGER1 RPL entry
		A=A-C	A
		GOC	ent1x5exit
		LC(5)	=Vger1RplEntryi		index of RPL entries
		C=C+A	A
		A=A+A	A
		A=A+A	A
		C=C+A	A
		CD0EX
		A=DAT0	A
		CD0EX
disadr11111	R0=A
		D1=D1+	5		pop old #addr
		D=D+1	A
		GOSBVL	=SAVPTR
		GOVLNG	=PUSH#LOOP
ENDCODE
