**********************************************************************
*		Entry Catalog Definitions
**********************************************************************
* The actual entry catalog code
*
* Statck Diagram:	( RTAB DTAB CFG NTAB $ #STAT #N --> ? )
*
* Register assignments:			Register used in:
*
* B[A]	general purpose counter		ECDispEC, ECMatch?
* D[X]	display row handler		ECDispEC
*
*	[A]	[A1]	[A2]
* R0					EcPrepUpdate, EClexico
* R1	->STR	STARTN	BLANKROWS	(almost everywhere)
* R2	N	LOC	LOCN		(almost everywhere)
* R3					ECDispEC
* R4					ECMatch?
*
*	STR	= 2+2*24 nibbles for search len and str data
**********************************************************************
ASSEMBLE
eTIMER2ON	EQU (sTIMER2ON)	 0 Flag used by system time utilities
eBLINK		EQU (sBLINK)	 1 Blink flag for input line
eLEXICO		EQU (sINPDEC)	 2 Lexico mode flag
eLMATCH		EQU (sFIND)	 3 Match mode flag
eBPOFF		EQU (sBPOFF)	 4 Supported beep flag
eGREP		EQU (sOVERWR)	 6 Grep mode flag
eCURSOR		EQU (sCURSOR)	 7 Cursor state flag
eDELAY		EQU (sDELAY)	 8 Delay flag for keyrepeat
eREPEAT		EQU (sREPEAT)	 9 Key repeat enable flag
* PUSH# uses ST10
eDISPOK		EQU (sDISPOK)	11 Display validity flag

=EDGREPEC	EQU 2^(eLEXICO)+2^(eLMATCH)+2^(eGREP)
=EDSCANEC	EQU 2^(eLEXICO)


* stack: ( RTAB DTAB CFG NTAB $ #STAT #N -> )
* DO NOT CHANGE ORDER BELOW!
		ABASE	#80100	inside RAMBUFF
EC_DATA		ALLOC	0	inside RAMBUFF
EC_RTAB		ALLOC	5	addr of RTAB
EC_DTAB		ALLOC	5	addr of DTAB
EC_N		ALLOC	5	N
EC_NTAB		ALLOC	5	addr of NTAB
EC_CONFIG	ALLOC	5	configuration routine
EC_BOUNCE	ALLOC	5	BounceTiming
EC_MAXN		ALLOC	5	max number of entries - 1
EC_RPREVN	ALLOC	5	RTAB[PrevN] (pointer to entry)
EC_PREVN	ALLOC	5	PrevN (for lexico mode)
EC_REPSTK	ALLOC	2*2	two repeat keys
EC_KEYTIME	ALLOC	16
EC_NOTYPE	ALLOC	1
EC_STATUS	ALLOC	3	status flags
EC_RSTK1	ALLOC	5
EC_RSTK2	ALLOC	5
EC_RSTK3	ALLOC	5
EC_RSTK4	ALLOC	5
EC_DATAEND	ALLOC	0
EC_DATSIZE	EQU	(EC_DATAEND)-(EC_DATA)
RPL


**********************************************************************
*		Entry Catalogue Code
**********************************************************************
CODE
* uncomment to debug RSTK usage; Saturn emulation often leaves garbage
* return address even on real hardware
*		C=RSTK
*		C=RSTK
*		C=RSTK
*		C=RSTK
*		C=RSTK
*		C=RSTK
*		C=RSTK
*		C=RSTK
		
		A=0	W
		LC(5)	EC_N
		CD0EX
		RSTK=C			save D0
* N
		GOSBVL	=POP#	
		DAT0=A	A		save in EC_N
		R2=A
* status flags
		GOSBVL	=POP#
		C=A	A
		ST=C
* search string
		A=DAT1	A
		A=A+CON	A,10
		D1=D1+	5
		D=D+1	A
		R1=A
* NTAB		
		A=DAT1	A
		D1=D1+	5
		D=D+1	A
		LC(5)	=ZERO		Verify valid NTAB
		?A#C	A
		GOYES	+
		A=0	A
		ST=0	eLEXICO		just in case ...
		GONC	++
+		A=A+CON	A,10		skip prolog, len
++		D0=D0+	5
		DAT0=A	A		save in EC_NTAB

* config routine for extable library
		GOSBVL	=POP#
		D0=D0+	5
		DAT0=A	5		save in EC_CONFIG
		C=A	A
		?C=0	A		do we need to configure?
		GOYES	+
		GOSUB	EcPC=C		if so, do it

* DTAB, RTAB
+		GOSBVL	=POP#
		D0=(5)	EC_DTAB
		DAT0=A	A		save in EC_DTAB
		GOSBVL	=POP#
		D0=D0-	5
		DAT0=A	A		save in EC_RTAB

		C=RSTK
		CD0EX			restore D0

* usage: ECGET reg,0/1,var
ECGET	MACRO
	D$2=(5)		$3
	$1=DAT$2	A
ECGET	ENDM

* Arguments now popped; save pointers and then update variables
		GOSBVL	=SAVPTR
		ECGET	C,0,EC_RTAB
		CD0EX
		C=DAT0	A		C[A] = MAXN
		C=C-1	A		counting from 0
		D1=(5)	EC_MAXN
		DAT1=C	A		save MAXN
		D0=D0+	5		D0 -> offset to entry table
		A=DAT0	A
		CD0EX
		C=C+A	A
		D1=(2)	EC_RTAB
		DAT1=C	A		write new ->RTAB
		D1=(2)	EC_RPREVN
		DAT1=C	A		initialize RTAB[PrevN]

		D0=(5)	=BounceTiming
		C=DAT0	A
		D1=(5)	EC_BOUNCE
		DAT1=C	A		save BounceTiming
		C=0	A
		DAT0=C	A		set new timing to 0
		NIBHEX	80BF2
		
		D1=(5)	EC_PREVN
		LC(5)	(EC_DATAEND)-(EC_PREVN)
		GOSBVL	=WIPEOUT
		
		GOSBVL	=getBPOFF	Get system beep flag
		GOSUBL	InitClk		Initialize clock
		GOSUBL	EcSetIoAnn	Show search mode annunciator

		?ST=0	eGREP		if entry mode is grep, try update
		GOYES	+
		GOSUB	grepon
+
		ST=0	eREPEAT		make sure restart is proper
		ST=0	eDELAY		if info has been lost
		ST=0	eDISPOK

**
** Main display/keywait/dokey loop
**

ECLOOP		GOSUBL	EcDispEC	Update display if necessary
		ST=0	eBLINK		No blink in regular keywait
		GOSUBL	EcWaitKey	Wait for key
		GOSUBL	EcAdjustKey	Adjust for shifts
ECLOOP1		ST=1	eREPEAT		Assume repeat on for the key
		ST=0	eDISPOK		Assume display will be invalid
		GOSUB	DoECKey		Do the key
		GOTO	ECLOOP		And restart the loop

**********************************************************************
* Dispatch to keyhandling subroutine given keycode
**********************************************************************

DoECKey		A=PC
		LC(5)	(ECKeyTab)-(*)
		A=A+C	A
		D0=A

EcDispatchKey
-		A=DAT0	X		Read next key in table
		D0=D0+	7		Skip to next slot (assuming no match)
		?A=0	X
		GOYES	+		End of table - dispatch
		?A#B	X
		GOYES	-		No match - continue loop
+		D0=D0-	4		Back to the offset field of the slot
		A=0	A
		A=DAT0	4		Offset
		?ABIT=0	15		Expand signed offset to A[A]
		GOYES	+
		P=	4-1
		A=-A	WP
		A=-A	A
		P=	0
+		CD0EX			And dispatch to target
		A=A+C	A
		PC=A	
**********************************************************************

**********************************************************************

ECKEY	MACRO
	CON(3)	$1			Keycode with shifts
	CON(4)	($2)-(*)		Signed offset to target
ECKEY	ENDM

ECKeyTab
		ECKEY	(UPCODE)+(NS),ECup
		ECKEY	(DOWNCODE)+(NS),ECdn
		ECKEY	(UPCODE)+(LS),ECpgup
		ECKEY	(DOWNCODE)+(LS),ECpgdn
		ECKEY	(UPCODE)+(RS),ECfarup
		ECKEY	(DOWNCODE)+(RS),ECfardn
		ECKEY	(MODECODE)+(NS),ECpgup
		ECKEY	(STOCODE)+(NS),ECpgdn
		ECKEY	(APPSCODE)+(NS),ECfarup
		ECKEY	(VARCODE)+(NS),ECfardn

		ECKEY	(RIGHTCODE)+(NS),ECview
		ECKEY	(LEFTCODE)+(NS),ECviewadr

		ECKEY	(32)+(NS),ECfind
		ECKEY	(Sfkey6)+(NS),ECfind
		ECKEY	(NXTCODE)+(NS),ECnext
		ECKEY	(NXTCODE)+(LS),ECprev

		ECKEY	(EEXCODE)+(NS),ECgrep
		ECKEY	(Sfkey1)+(NS),EClexico
		ECKEY	(Sfkey2)+(NS),EClMatch
		ECKEY	(Sfkey3)+(NS),ECtype?
		ECKEY	(ENTERCODE)+(NS),ECpshent
		ECKEY	(tickCODE)+(NS),ECpshent
		ECKEY	(ENTERCODE)+(LS),ECpshadr
		ECKEY	(EVALCODE)+(NS),ECpshadr
		ECKEY	(ENTERCODE)+(RS),ECpshname
		ECKEY	(SYMBCODE)+(NS),ECpshname

		ECKEY	(=0CODE)+(NS),ECloc
		ECKEY	(=1CODE)+(NS),ECloc
		ECKEY	(=2CODE)+(NS),ECloc
		ECKEY	(=3CODE)+(NS),ECloc
		ECKEY	(=4CODE)+(NS),ECloc
		ECKEY	(=5CODE)+(NS),ECloc
		ECKEY	(=6CODE)+(NS),ECloc
		ECKEY	(=7CODE)+(NS),ECloc
		ECKEY	(=8CODE)+(NS),ECloc
		ECKEY	(=9CODE)+(NS),ECloc
		ECKEY	(ONCODE)+(NS),ECExit

		ECKEY	(SHIFTCODE),EcModLS
		ECKEY	(ALTCODE),EcModRS
		ECKEY	(CHSCODE)+(NS),EcTogBeep
		ECKEY	(ONCODE)+(RS),ECOFF

		ECKEY	0,BadECKey
**********************************************************************
* Not valid key for EC - setup error flags & beep
**********************************************************************
BadECKey	ST=1	eDISPOK		Display is still valid
		ST=0	eREPEAT		Repeat is not ok
		?ST=1	eBPOFF		Beep if it is enabled
		RTNYES
		LC(2)	#FB
		GOVLNG	=RCKBp
**********************************************************************
* Exit key
**********************************************************************
ECExit		ST=0	eLMATCH		No strict match anymore
		GOSUBL	EcSetIoAnn	So we can clear the annunciator
		GOSUB	EcBounce		
		GOVLNG	=GPPushFLoop
**********************************************************************
* Restore user's BounceTiming and reset rom view
**********************************************************************
EcBounce	ECGET	C,0,EC_BOUNCE
		D0=(4)	=BounceTiming
		DAT0=C	A
		NIBHEX	80BF2
*		RTN		
EcRomView	ECGET	C,0,EC_CONFIG
		?C=0	A
		RTNYES
		P=	1
EcPC=C		PC=C
**********************************************************************
* Move up one line
**********************************************************************
ECup		ST=1	eDISPOK		Display will be ok - fast scroll
		?ST=1	eGREP
		GOYES	ecgrepup
		A=R2			N
		A=A-1	A
		RTNC			Already at the top - no work
		R2=A			Save new N
ecupdisdn	GOSUBL	EcDispDn	Scroll display down
		D=0	A
		GOLONG	EcDispAdrRow	And display the new line

ecgrepup	GOSUB	EcUpdate-
		GONC	+
		GOTO	BadECKey	no more prior matches
+		C=R2
		RSTK=C
		A=R1			get previous last row N
		GOSUB	ASLC5
		C=A	A
		ASLC
		?CBIT=0	15		
		GOYES	ecuplstrow	if >0 then update last row
				
		A=A+1	A		if <0 then decrease blank rows
		?A#0	A		
		GOYES	ecupR1dn	if blank row, store N and update
		ECGET	A,0,EC_MAXN	last row = prev N; start at end
		A=A+1	A

ecuplstrow	R2=A.F	A
		GOSUB	EcUpdate-	Get prev N for last row
		A=R1
		GOSUB	ASLC5		and store it in R1[A3]
		ASLC
		A=R2.F	A		

ecupR1dn	ASRC
		GOSUB	ASRC5
		R1=A
		C=RSTK
		R2=C.F	A
		GOTO	ecupdisdn	Ok, scroll and disp 1st line
**********************************************************************
* Move to top of entry table
**********************************************************************
ECfarup		?ST=1	eGREP
		GOYES	ecgrepfarup
		R2=A			N
		?A=0	A		No need to update if at top
		GOYES	ecignfup
		A=0	A
		R2=A	A		Save new N
		RTN
ecignfup	ST=1	eDISPOK		Validate display
		RTN

ecgrepfarup	A=0	A
		R2=A
		GOTO	EcUpdate
**********************************************************************
* Move up one page
**********************************************************************
ECpgup		?ST=0	eGREP
		GOYES	+
		GOTO	BadECKey	No pgup in grep mode		
+		A=R2			N
ecpgup10	A=A-CON	A,13		Move up 13 entries
		GOC	ECfarup		Overflow - same code as for far-up

ecignup?	C=R2
		R2=A			Save new N
		?A#C	A
		RTNYES			If different then return
		ST=1	eDISPOK		Else no display update needed
		RTN
**********************************************************************
* Move to bottom of entry table
**********************************************************************
ECfardn		ECGET	A,0,EC_MAXN	MAXN
		A=A+1	A		MAXN+1
		?ST=0	eGREP
		GOYES	ecpgup10

             	R2=A.F	A
             	GOTO	EcUpdate-
**********************************************************************
* Move down one page
**********************************************************************
ECpgdn		?ST=0	eGREP
		GOYES	+
		GOTO	BadECKey	No pgdn in grep mode
+		ECGET	A,0,EC_MAXN	MAXN
		C=R2			N
		C=C+CON	A,13		Down one page
		?C>A	A		Dispatch to far-down if no more
		GOYES	ECfardn		Full pages
		R2=C	A		Save new N
		RTN
**********************************************************************
* Move down one line
**********************************************************************
ECdn		ST=1	eDISPOK		Validate display
		?ST=1	eGREP
		GOYES	ecgrepdn
		ECGET	A,0,EC_MAXN	MAXN
		C=R2			N
		C=C+1	A
		?C>A	A
		RTNYES			Ignore if already at the bottom
		RSTK=C
		C=C+CON	A,13-1
		R2=C	A		Set up last row
ecdspulst	GOSUBL	EcDispUp	Scroll display upwards
		LC(3)	#C00
		D=C	A
		GOSUBL	EcDispAdrRow	Display the new last row
ecdnend		C=RSTK
		R2=C	A		Save new N
		RTN
		
ecgrepdn	GOSUB	EcUpdate+
		GONC	+
		GOTO	BadECKey
+		C=R2
		RSTK=C			C[A] = N
		A=R1			Get prev N for last row
		GOSUB	ASLC5
		C=A	A
		ASLC
		?CBIT=0	15		if >=0 then update lst row
		GOYES	+
		A=A-1	A		else increase blank rows and
		GOTO	ecdnR1clr	save in R1; clear last line

+		R2=A.F	A
		GOSUB	EcUpdLast+	Get next N for last row
		GONC	ecdnR1up	update ok; save new N and update
		A=R1			else, store (-)1 blank row ...	
		GOSUB	ASLC5
		ASLC
		A=0	A
		A=A-1	A
ecdnR1clr	ASRC			in R1[A3] ...	
		GOSUB	ASRC5
		R1=A
		GOSUBL	EcDispUp	scroll disp up ...
		LC(3)	#C00
		D=C	A
		GOSUBL	dirowblank	and clear last row
		GOTO	ecdnend		Restore R2 and end
	
ecdnR1up	A=R1			Store new N for last row
		GOSUB	ASLC5
		ASLC
		A=R2.F	A	
		ASRC
		GOSUB	ASRC5
		R1=A			in R1[A3]
		GOTO	ecdspulst	and scroll+ update last row		
**********************************************************************
ASLC5		ASLC
		ASLC
		ASLC
		ASLC
		ASLC
		RTN
**********************************************************************
ASRC5		ASRC
		ASRC
		ASRC
		ASRC
		ASRC
		RTN
**********************************************************************
* Toggle TYPE? flag
**********************************************************************
ECtype?		ST=0	eREPEAT
		ECGET	C,0,EC_NOTYPE
		?C=0	P		no type flag = 0?
		GOYES	+
		C=0	A		no, so set to 0
-		DAT0=C	1
		RTN
+		LC(1)	1		yes, so set to non-zero
		GOC	-
**********************************************************************
* Switch grep flag
**********************************************************************
ECgrep		A=R1
		D0=A			D0 = ->STR
		A=DAT0	B		A[S] = strlen
		?A#0	B
		GOYES	grepok		Continue if nonnull string
		GOTO	BadECKey

grepok		ST=0	eREPEAT		No repeat
		?ST=0	eGREP		Toggle grep flag
		GOYES	grepon
		ST=0	eGREP
		RTN
grepon		ST=1	eGREP
		GOSUB	EcUpdate
		RTNNC
		GOSUB	EcUpdate-
		RTNNC
		ST=0	eGREP
		GOTO	BadECKey
**********************************************************************
* Find next match
**********************************************************************
ECnext		A=R1
		D0=A			D0 = ->STR
		A=DAT0	B
		?A=0	B
		GOYES	ecnxtbad	Error if no search string
		GOSUB	EcUpdate+	Skip to next match
		RTNNC			Done if found one
ecnxtbad	GOTO	BadECKey	Error - no match
**********************************************************************
* Find previous match
**********************************************************************
ECprev		A=R1
		D0=A			D0 = ->STR
		A=DAT0	B
		?A=0	B
		GOYES	ecnxtbad	Error if no search string
		GOSUB	EcUpdate-	Skip to previous match
		RTNNC			Done if found one
		GOC	ecnxtbad	Error - no match
**********************************************************************
* Call DOB/ED subprogram to view disassembly of entry
**********************************************************************
* We borrow the eBLINK status flag to determine whether to push the
* entry address, or the address to which the entry points. eBLINK
* gets reset upon re-entry into DoEC
**********************************************************************
ePTRADR		EQU	eBLINK

ECviewadr	ST=1	ePTRADR		get adr at entry
		GOTO	Ecview+

ECview		ST=0	ePTRADR

Ecview+		GOSUBL	N>Entr		D0 = ->entry slot N
		A=DAT0	A
		R0=A
		GOSBVL	=PUSH#		Push entry address
		GOSBVL	=SAVPTR
		C=0	A		Push operation code : view

		?ST=0	ePTRADR		View addr or view @addr
		GOYES	+
		C=C+1	A
+
		R0=C
		GOSBVL	=PUSH#
		GOSBVL	=SAVPTR
		C=0	A		Push status flags
		C=ST
		R0=C
		GOSBVL	=PUSH#
		GOSBVL	=SAVPTR
		ST=0	eLMATCH		Update annunciators
		GOSUBL	EcSetIoAnn
		GOSUB	EcBounce
		C=R2
		R0=C
		GOSBVL	=GETPTR		Push N
		GOSBVL	=PUSH#
		GOVLNG	=PushTLoop	Push TRUE - job to do
**********************************************************************
* Push current entry name & address
**********************************************************************
ECpshent	GOSUBL	N>Entr		D0 = ->entry slot N
		D0=D0+	5		Skip address part
		A=0	A
		A=DAT0	B		A[A] = chars in name
		A=A+A	A
		LC(5)	5+2+15		+ DOTAG + namelen + addressobject
		C=C+A	A
		GOSBVL	=GETTEMP
		CD0EX
		R0=C			R0[A] = ->obhect
		D1=C
		LC(5)	=DOTAG		Output DOTAG
		DAT1=C	A
		D1=D1+	5
		GOSUBL	N>Entr		D0 = ->entry slot N
		D0=D0+	5		Skip address part
		C=0	A
		C=DAT0	B		C[A] = chars in name
		D0=D0+	2
		DAT1=C	B		Output tagname length
		D1=D1+	2
		C=C+C	A		Copy tagname
		GOSBVL	=MOVEDOWN
		GOTO	ecunadrent	Common code for address part
**********************************************************************
* Push current entry address
**********************************************************************
ECpshadr	LC(5)	15		DOHSTR + length + address
		GOSBVL	=GETTEMP
		CD0EX
		R0=C			R0[A] = ->hstr
		D1=C

ecunadrent	GOSUBL	N>Entr		D0 = ->entry slot N
		LC(5)	=DOHSTR		Output DOHSTR
		DAT1=C	A
		D1=D1+	5
		LC(5)	5+5		Output HSTR size
		DAT1=C	A
		D1=D1+	5
		A=DAT0	A		Output address
		DAT1=A	A
		D1=D1+	5
		GONC	ecunent		Common code to push
**********************************************************************
* Push entry name
**********************************************************************
ECpshname	GOSUBL	N>Entr		D0 = ->entry slot N
		D0=D0+	5
		C=0	A
		C=DAT0	B		chars in name
		GOSBVL	=MAKE$		Create string for it
		CD0EX
		D1=C
		GOSUBL	N>Entr		D0 = ->entry slot N
		D0=D0+	5
		C=0	A
		C=DAT0	B		C[A] = chars in name
		D0=D0+	2
		C=C+C	A		Copy entryname to string
		GOSBVL	=MOVEDOWN

ecunent		ST=0	eREPEAT		No repeat when pushing
		ST=1	eDISPOK
		A=R0			Push the string to stack
		GOSBVL	=GPPushA
		GOVLNG	=SAVPTR		And save the new pointers
**********************************************************************
ECloc
		ST=0	eGREP
		ST=0	eLEXICO
		C=0	W
		P=	5
		CPEX	15
		C=R2.F	A
		R2=C
		A=0	W
		GOTO	eclockey
locloop		GOSUB	GetLoc
		GOSUBL	ECentry?
		A=B	A
		R2=A.F	A
		GOSUB	EcDispEC12
		GOSUB	EcDispLoc
		ST=0	eBLINK
		GOSUBL	EcWaitKey
		GOSUBL	EcAdjustKey
eclockey
		ST=1	eREPEAT
		GOSUB	DoLocKey
		GOTO	locloop

DoLocKey
		GOSUB	LocNumKey?
		A=PC
		LC(5)	(ECLocKeyTab)-(*)
		A=A+C	A
		D0=A
		GOLONG	EcDispatchKey

ECLocKeyTab
		ECKEY	(ENTERCODE)+(NS),LocExit
		ECKEY	(ONCODE)+(NS),LocExit
		ECKEY	(TANCODE)+(NS),LocDEL
		ECKEY	(BACKCODE)+(NS),LocBS
		ECKEY	0,BadLocKey
		
**********************************************************************
LocDEL
**********************************************************************
LocExit		ST=0	eREPEAT
		ST=0	eDISPOK
		GOTO	ECLOOP
**********************************************************************
LocBS		A=R2
		A=A+1	S
		P=	15
		LC(1)	5
		P=	0
		?A>=C	S
		GOYES	LocExit
		P=	10-1
		ASR	WP
		P=	0
		A=R2.F	A
		R2=A
		RTN
**********************************************************************
BadLocKey
		C=B	A
		RSTK=C
		GOSUB	EcDispEC
		C=RSTK
		B=C	A
		GOTO	ECLOOP1
**********************************************************************
LocNumKey?
		LC(3)	#100
		?B#C	XS		Not NS?
		RTNYES	
		GOSUB	+
		CON(2)	=0CODE
		CON(2)	=1CODE
		CON(2)	=2CODE
		CON(2)	=3CODE
		CON(2)	=4CODE
		CON(2)	=5CODE
		CON(2)	=6CODE
		CON(2)	=7CODE
		CON(2)	=8CODE
		CON(2)	=9CODE
		CON(2)	=Sfkey1
		CON(2)	=Sfkey2
		CON(2)	=Sfkey3
		CON(2)	=Sfkey4
		CON(2)	=Sfkey5
		CON(2)	=Sfkey6
+		C=RSTK
		D0=C
		A=0	A
-		C=DAT0	B
		D0=D0+	2
		?B=C	B
		GOYES	+
		A=A+1	P
		GONC	-
		RTN			Not numkey

+		C=RSTK			Pop ret
		C=R2
		GOSBVL	=CSRW5
		CSL	A
		C=C+A	A
		GOSBVL	=CSLW5
		C=R2.F	A
		?C=0	S
		GOYES	+
		C=C-1	S
+		R2=C
		RTN
**********************************************************************
EcDispLoc	LC(1)	13-1
		GOSUB	EcSetRow
		GOSUB	EcClrRow
		D1=D1+	1
		GOSUB	+
		GOSUB	GetLoc
		GOLONG	EcDispAddr
+		GOSUBL	EcDisp:
		ASC(1)	'Loc:'
**********************************************************************
GetLoc		A=R2
		GOSBVL	=ASRW5
		A=R2.F	S
-		A=A-1	S
		RTNC
		ASL	A
		GONC	-
**********************************************************************
ECfind
* Set alpha mode	
		GOSUBL	EcGetAnns
		ABIT=1	6
		DAT0=A	B
		D0=(5)	=ANNCTRL
		A=DAT0	B
		ABIT=1	2
		DAT0=A	B
		
		ST=0	eGREP
		A=R2
		GOSBVL	=ASLW5
		A=R1.F	A
		R1=A
		D0=A
		A=0	A
		DAT0=A	B
		ST=0	eCURSOR
--
		GOSUB	EcDispEC12
		GOSUB	EcDispFind
		GOSUBL	EcSetCursor
		ST=1	eBLINK
		GOSUBL	EcWaitKey
		GOSUBL	EcAdjustKey
		GOSUBL	EcClrCursor
		ST=1	eREPEAT
		GOSUB	DoECFKey
		GOTO	--
**********************************************************************
DoECFKey	A=R1
		D1=A
		GOSUBL	EcChrKey?
		GONC	DoECFNonChr
		GOTO	DoECFChrKey
DoECFNonChr
		A=PC
		LC(5)	(ECFKeyTab)-(*)
		A=A+C	A
		D0=A
		GOLONG	EcDispatchKey
**********************************************************************
ECFKeyTab
		ECKEY	(BACKCODE)+(NS),ECFbs
		ECKEY	(BACKCODE)+(ANS),ECFbs
		ECKEY	(TANCODE)+(NS),ECFdel
		ECKEY	(ONCODE)+(NS),ECFexit
		ECKEY	(ONCODE)+(ANS),ECFexit
		ECKEY	(ENTERCODE)+(NS),ECFexit
		ECKEY	(ENTERCODE)+(ANS),ECFexit
		ECKEY	(NXTCODE)+(NS),ECFnext

		ECKEY	(32)+(NS),EcModA
		ECKEY	(32)+(ANS),EcModA
		
		ECKEY	(LSCODE),EcModLS
		ECKEY	(RSCODE),EcModRS
		ECKEY	(CHSCODE)+(NS),EcTogBeep
		ECKEY	(ONCODE)+(RS),ECOFF
		ECKEY	0,ECFBadKey
**********************************************************************
ECFexit		ST=0	eREPEAT
		ST=0	eDISPOK
* Clr alpha mode	
		GOSUBL	EcGetAnns
		ABIT=0	6
		DAT0=A	B
		D0=(5)	=ANNCTRL
		A=DAT0	B
		ABIT=0	2
		DAT0=A	B
		GOLONG	ECLOOP
**********************************************************************
ECFdel		A=0	A
		DAT1=A	B
**********************************************************************
ECFbs		A=R1
		GOSBVL	=ASRW5	START N
		R2=A.F	A
		A=DAT1	B
		A=A-1	B
		GOC	ECFexit
		DAT1=A	B
		?A=0	B
		GOYES	ECFexit
		GOTO	EcUpdate
**********************************************************************
ECFBadKey	?ST=1	eBPOFF
		RTNYES
		LC(2)	#FB
		GOVLNG	=RCKBp
**********************************************************************
ECFnext		GOSUB	EcUpdate+
		RTNNC
		GOTO	ECFBadKey
**********************************************************************
* Entry:	C[B]=chr	D1 -> STR
* Exit:		STR updated if new length at most 24
**********************************************************************
DoECFChrKey
* To Upper
		A=C	B
		LCASC	'a'
		?A<C	B
		GOYES	+
		LCASC	'z'
		?A>C	B
		GOYES	+
		ABIT=0	5
+		ASL	A		A[2-3] = char
		ASL	A
		A=DAT1	B		A[0-1] = str length
		A=A+1	B
		LC(2)	MAXENTRLEN	max chars allowed
		?A>C	B
		GOYES	ECFBadKey
		DAT1=A	B		save new length
		C=0	A
		C=A	B
		C=C+C	A		offset for new char
		AD1EX
		A=A+C	A
		AD1EX
		ASR	A		get uppercased char
		ASR	A
		DAT1=A	B		and save
		GOSUB	EcDispFind
		GOSUB	EcUpdate
		RTNNC
		GOTO	ECFBadKey
**********************************************************************
EcUpdLast+	C=R2
		C=C+1	A		N++
		R2=C
**********************************************************************
EcUpdLast	ECGET	A,0,EC_MAXN
		R0=A
		GOTO	EcUpdate!
**********************************************************************
EcUpdate+	C=R2			Save N
		R0=C
		C=C+1	A		N++
		R2=C
		GOTO	EcUpdate!
**********************************************************************
EcUpdate	C=R2			Save N
		R0=C
**********************************************************************
EcUpdate!	GOSUB	EcPrepUpdate
		GOC	++		Too big N  (was RTNC)
		?ST=0	eLEXICO		If lexico mode, use N>Entr
		GOYES	EcupdNoLex	  to get next entry.
					Slower but does work ...

		C=R2.F	A
--		GOSUB	N>Entr
		GOC 	++
		D1=D1-	2
		C=DAT1	B
		B=C	B
		D1=D1+	2
		GOSUB	EcMatch?
		RTNNC	Match
		C=R2.F	A
		C=C+1	A
		R2=C.F	A
		GONC	--
		
EcupdNoLex
--		D0=C			->entry_offset
		A=DAT0	A		address
*		?A=0	A
*		GOYES	++		No more offsets
		RSTK=C			C[A] = DTAB[N]
		A=A+C	A
		D0=A			->entry
		GOSUB	EcMatch?
		C=RSTK
		RTNNC			Match
		RSTK=C
		D0=(5)	EC_MAXN
		C=DAT0	A
		A=R2.F	A
		A=A+1	A		N++
		?A>C	A
		GOYES	+
		C=RSTK
		R2=A.F	A
		C=C+CON	A,5		->next offset
		GONC	--

+		C=RSTK
++		C=R0.F	A
		R2=C
		RTNSC
**********************************************************************
EcUpdate-
		C=R2
		R0=C
		C=C-1	A
		RTNC
		R2=C
EcUpdate!!
		GOSUB	EcPrepUpdate
		RTNC			Too big N

		?ST=0	eLEXICO
		GOYES	EcupdNoLex-

		C=R2
--		GOSUB	N>EntLex	If lexico mode, use N>EntLex
		D1=D1-	2		B[A] modified by N>EntLex
		C=DAT1	B		  so fix it here
		B=C	B
		D1=D1+	2
		GOSUB	EcMatch?	(like N>Entr but no useless check
		RTNNC	Match		  on offset)
		C=R2.F	A
		C=C-1	A
		R2=C.F	A
		GONC	--
		GOTO	++

EcupdNoLex-
--		RSTK=C			->entry_offset
		D0=C
		A=DAT0	A		offset
		A=A+C	A
		D0=A			->entry
		GOSUB	EcMatch?
		C=RSTK
		RTNNC	Match
		C=C-CON	A,5
		A=R2.F	A
		A=A-1	A
		R2=A.F	A
		GONC	--

++		C=R0
		R2=C
		RTNSC
**********************************************************************
* Description:	Prepare registers for matching
* Entry:	R2[A] = current N;	R1[A] -> $search
* Exit:		CS: N too large (failed update)
*		CC: update successful
*		A[B] = $searchlen;	D1 -> $search
*		C[A] -> entry;
* Uses:		A[A], C[A], B[B], D0, D1, R1[A], R2[A]
**********************************************************************
EcPrepUpdate	ECGET	A,0,EC_MAXN
		D0=(2)	EC_DTAB
		C=DAT0	A
		D0=C

		C=R2.F	A
		?C>A	A
		RTNYES			Too Big N
		A=C	A
		A=A+A	A
		A=A+A	A
		C=C+A	A
		AD0EX
		C=C+A	A		->entry_offset
		A=R1.F	A
		D1=A			->STR
		A=DAT1	B		strlen
		B=A	B
		D1=D1+	2		->str
		RTNCC
**********************************************************************
* Entry:	D0 -> entry (len), D1 -> str, B[B] = num of chars
* Exit:		CC: match		CS: no match
* Uses:		A[A], C[A], B[B], D[B], D0, D1, R1[A], R4[A]
*********************************************************************
EcMatch?	D0=D0+	5
		C=0	A
		C=DAT0	B		entrylen
		?B>C	B
		RTNYES			Too short for submatch
		D0=D0+	2

--		D=C	B
		A=DAT0	B
		D0=D0+	2
		LCASC	'a'		Convert to upper case
		?A<C	B
		GOYES	+
		LCASC	'z'
		?A>C	B
		GOYES	+
		ABIT=0	5
+		C=DAT1	B
		?A=C	B
		GOYES	eccmprest	First char matches, try rest

eccmp20		?ST=1	eLMATCH		Test only first chars
		RTNYES
		C=D	B
		C=C-1	B		entrylen--
		?C>=B	B		Still enough for submatch?
		GOYES	--		Yes
		RTNSC			Nope - no match

ecretmatch	RTNCC

eccmprest	CD0EX
		R4=C	A		->char1
		CD0EX
--		B=B-1	B
		?B=0	B
		GOYES	ecretmatch
		A=DAT0	B
		D0=D0+	2
		LCASC	'a'		To upper case
		?A<C	B
		GOYES	+
		LCASC	'z'
		?A>C	B
		GOYES	+
		ABIT=0	5
+		D1=D1+	2
		C=DAT1	B
		?A=C	B
		GOYES	--
		C=R4.F	A
		D0=C			->char1
		A=R1.F	A		Restore strlen
		D1=A
		A=DAT1	B
		D1=D1+	2
		B=A	A
		GOTO	eccmp20
**********************************************************************
EcDispFind	LC(1)	13-1
		GOSUB	EcSetRow
		GOSUB	EcClrRow
		D1=D1+	1
		GOSUB	dspfnd
		A=R1	A
		D0=A
		A=DAT0	B
		B=A	B
		D0=D0+	2
-		B=B-1	B
		RTNC
		C=DAT0	B
		D0=D0+	2
		GOSUB	EcDispChr
		GONC	-

dspfnd		GOSUB	EcDisp:
		ASC(1)	'Find:'	
**********************************************************************
EcDispEC12	LC(1)	12-1
		GOTO	EcDispECN

EcDispEC	?ST=1	eDISPOK
		RTNYES
		LC(1)	13-1		Rows

EcDispECN	D=0	A		D[XS]	= current row
		D=C	P		D[0]	= rows left
		A=R2			save N during display update
		D0=(5)	EC_N
		DAT0=A	A
		D0=(2)	EC_RSTK1	as well as RSTK 1-4 due to
		P=	16-4		some modes using many calls
-		C=RSTK
		DAT0=C	A
		D0=D0+	5
		P=P+1
		GONC	-

-		C=D	A
		RSTK=C			save row counter
		GOSUB	EcDispAdrRow	Display row
		GOC	ecdispnomore	No more entries?
		C=R2	A
		C=C+1	A		entrynum++
		R2=C	A
		C=RSTK
		D=C	A
		D=D+1	XS		row++
		D=D-1	P		rows--
		GONC	-
		GOC	ecdispexit

ecdispnomore	C=RSTK			get row counter
		D=C	A
		C=0	A		store -D[0] in R1
		C=D	P
		C=-C	A
		R2=C.F	A
-		GOSUB	dirowblank	and clear next lines
		D=D+1	XS
		D=D-1	P
		GONC	-

ecdispexit	A=R1			Store in R1 N for last
		GOSUBL	ASLC5		row
		ASLC
		A=R2.F	A		(or # of blank row)
		A=A-1	A		
		ASRC
		GOSUBL	ASRC5
		R1=A
		ECGET	C,0,EC_N	restore original N
		R2=C.F	A
		D0=(2)	EC_RSTK4	restore RSTK (reverse order)
		P=	16-4
-		C=DAT0	A
		RSTK=C
		D0=D0-	5
		P=P+1
		GONC	-
		RTN

**********************************************************************
EcDispAdrRow	?ST=0	eGREP
		GOYES	+
		GOSUB	EcUpdLast
		GOC	dirowblank

+		GOSUB	N>Entr
		GONC	+

dirowblank	GOSUB	SetECRow
		GOSUB	EcClrRow
		RTNSC			let EcDispEc know we failed

+		GOSUB	SetECRow
		GOSUB	EcClrRow
		A=DAT0	A
		GOSBVL	=ASLW5		A[A1]=ADDR
		AD1EX
		R3=A	W
		AD1EX
		D1=D1+	1		1 SPC
		A=DAT0	A
		D0=D0+	5
		GOSUB	EcDispAddr

		D1=D1+	1		1 SPC
		C=DAT0	B
		D0=D0+	2
		B=C	B
		LC(2)	33-(1+5+1)	display only what fits
		?B<=C	B
		GOYES	+
		B=C	B
+		B=B-1	B
		GOC	+
-		C=DAT0	B
		D0=D0+	2
		GOSUB	EcDispChr
		B=B-1	B
		GONC	-

+		ECGET	C,0,EC_NOTYPE
		?C=0	P		notype option cleared?
		GOYES	+
		RTN			set, so do not display types
+		C=R3	W
		D1=C
		D1=D1+	16
		D1=D1+	12		5 CHARS LEFT
		LCASC	' '		SPC; 4 CHARS LEFT
		GOSUB	EcDispChr
		GOSBVL	=CSRW5
		D0=C
		GOSUB	EcDispType
		RTNCC			let EcDispEC know we succeeded
**********************************************************************
EcClrRow	LC(5)	34*6
		GOSBVL	=WIPEOUT
		LC(5)	34*6
		GOTO	EcDispLoc-
**********************************************************************
SetECRow	C=D	XS
		CSR	X
		CSR	B
EcSetRow	P=C	0		row * 6 * 34 = row * #CC
		C=0	A
		C=P	0
		CPEX	1
		C=C+C	A		#22*
		C=C+C	A		#44*
		A=C	A
		C=C+C	A		#88*
		C=C+A	A		#CC*
		
		D1=(5)	=ADISP
		A=DAT1	A
		A=A+C	A
		LC(5)	1*34+20		skip prolog/len/dims/1st row
		A=A+C	A
		D1=A
		RTN
**********************************************************************
EcDispType	A=DAT0	A		first 5 nibbles
		LC(5)	#11111		Han:	check for #11111
		?A#C	A
		GOYES	+
		GOSUB	EcDisp:
		ASC(1)	'@1x5'

* Han:	this is deprecated; bankswitcher is unconfiged by default
*+		LC(5)	#7E000		Protect from GX bank switch!
*		?A>=C	A
*		GOYES	ectypedat	

+		AD0EX
		C=DAT0	A
		D0=A
		A=C	A		first 5 nibbles at address
		LC(5)	=PRLG
		?A=C	A
		GOYES	ectypeob

ectypedat	A=DAT0	A
		D0=D0+	5
		CD0EX
		?A=C	A
		GOYES	ectypepco

		CD0EX			restore D0
		D0=D0-	5
		AD0EX
		LC(5)	=LineW		if addr is between =LineW and
		?A<C	A		$5x7, then SysRPL entry
		GOYES	ectypeml
		LC(5)	=$5x7
		?A>=C	A
		GOYES	ectypeml		
		GOSUB	EcDisp:
		ASC(1)	'SRPL'		

ectypeml	GOSUB	EcDisp:
		ASC(1)	'ML'
ectypepco	GOSUB	EcDisp:
		ASC(1)	'PCO'

ectypeob	A=DAT0	A
		GOSUB	+
		CON(5)	=DOBINT
		ASC(1)	'#'
		CON(5)	=DOREAL
		ASC(1)	'%'
		CON(5)	=DOEREL
		ASC(1)	'%%'
		CON(5)	=DOCMP
		ASC(1)	'C%'
		CON(5)	=DOECMP
		ASC(1)	'C%%'
		CON(5)	=DOCHAR
		ASC(1)	'CHR'
		CON(5)	=DOARRY
		ASC(1)	'[]'
		CON(5)	=DOLNKARRY
		ASC(1)	'[L]'
		CON(5)	=DOCSTR
		ASC(1)	'$'
		CON(5)	=DOHSTR
		ASC(1)	'HXS'
		CON(5)	=DOLIST
		ASC(1)	'{}'
		CON(5)	=DORRP
		ASC(1)	'RRP'
		CON(5)	=DOSYMB
		ASC(1)	'SYMB'
		CON(5)	=DOEXT
		ASC(1)	'EXT'
		CON(5)	=DOTAG
		ASC(1)	'TAG'
		CON(5)	=DOGROB
		ASC(1)	'GROB'
		CON(5)	=DOLIB
		ASC(1)	'LIB'
		CON(5)	=DOBAK
		ASC(1)	'BAK'
		CON(5)	=DOEXT0
		ASC(1)	'EXT0'
		CON(5)	=DOEXT1
		ASC(1)	'APTR'		'EXT1' for HP48SX only
		CON(5)	=DOEXT2
		ASC(1)	'EXT2'
		CON(5)	=DOEXT3
		ASC(1)	'EXT3'
		CON(5)	=DOEXT4
		ASC(1)	'EXT4'
		CON(5)	=DOCOL
		ASC(1)	'::'
		CON(5)	=DOCODE
		ASC(1)	'CODE'
		CON(5)	=DOIDNT
		ASC(1)	'ID'
		CON(5)	=DOLAM
		ASC(1)	'LAM'
		CON(5)	=DOROMP
		ASC(1)	'ROMP'
		CON(5)	=DOFLASHP	new ob types for HP49 series
		ASC(1)	'FPTR'
		CON(5)	=DOMINIFONT
		ASC(1)	'MFNT'
		CON(5)	=DOLNGREAL
		ASC(1)	'L%'
		CON(5)	=DOLNGCMP
		ASC(1)	'LC%'
		CON(5)	=DOMATRIX
		ASC(1)	'[M]'
		CON(5)	=DOINT
		ASC(1)	'INT'
		CON(5)	0		needed for very rare mismatch

+		C=RSTK
		D0=C
-		C=DAT0	A
		?C#0	A		trap very rare mis-match here
		GOYES	+
		GOTO	ectypeml
+		D0=D0+	5
		?A=C	A
		GOYES	EcDispName
		C=0	A
		C=DAT0	1
		C=C+C	A
		AD0EX
		A=A+C	A
		AD0EX
		D0=D0+	1
		GONC	-
**********************************************************************
EcDisp:		C=RSTK
		D0=C
**********************************************************************
EcDispName	A=DAT0	S
		D0=D0+	1
		A=A-1	S
		RTNC
-		C=DAT0	B
		D0=D0+	2
		GOSUB	EcDispChr
		A=A-1	S
		GONC	-
		RTN
**********************************************************************
EcDispAddr	GOSUBL	ASRC5
		GOSUB	EcDispSNib
		GOSUB	EcDispSNib
		GOSUB	EcDispSNib
		GOSUB	EcDispSNib
*		GOTO	EcDispSNib	
**********************************************************************
EcDispSNib	ASLC
EcDispNib	LCASC	'9'
		ACEX	P
		?C<=A	P
		GOYES	EcDispChr
		C=C+CON	A,7
**********************************************************************
EcDispChr	A=0	A
		A=C	B
		A=A+A	X
		C=A	X
		A=A+A	X
		A=A+C	X
		LC(5)	=MINI_FONT
		C=C+A	A
		CD0EX
		A=DAT0	6
		D0=C
-		DAT1=A	P
		D1=D1+	16
		D1=D1+	16
		D1=D1+	2
		P=P+1
		?P#	6	
		GOYES	-
		P=	0
EcDispLoc+1	LC(5)	34*6-1
EcDispLoc-	AD1EX
		A=A-C	A
		AD1EX
		RTNCC
**********************************************************************
EcInvChrs	C=C-1	S
		RTNC
		GOSUB	EcInvChr
		GONC	EcInvChrs
**********************************************************************
EcInvChr	P=	16-6
-		A=DAT1	B
		A=-A-1	B
		DAT1=A	1
		D1=D1+	16
		D1=D1+	16
		D1=D1+	2
		P=P+1
		GONC	-
		GOC	EcDispLoc+1
**********************************************************************
EcDispDn	LC(1)	14-1
		GOSUB	EcSetRow
		LC(5)	6*34
		A=A-C	A
		D0=A
		LC(5)	12*6*34
		GOVLNG	=MOVEUP
**********************************************************************
EcDispUp	LC(1)	1-1
		GOSUB	EcSetRow
		LC(5)	6*34
		A=A+C	A
		D0=A
		LC(5)	12*6*34
		GOVLNG	=MOVEDOWN
**********************************************************************
* Descripton:	Convert index N to entry
* Entry:	R2[A]=N
* Exit:		CC: D0=->ENTR	In non-lexico mode, A[A]= ->DTAB[N]
*		CS: TOO BIG N
* Uses:		A[A] B[A] C[A] D0 R2
**********************************************************************
N>Entr		C=R2
		ECGET	A,0,EC_MAXN
		?C>A	A
		RTNYES			Too Big N

		?ST=1	eLEXICO
		GOYES	N>EntLex

		A=C	A
		A=A+A	A
		A=A+A	A
		A=A+C	A
		D0=(2)	EC_DTAB
		C=DAT0	A
		C=C+A	A
		D0=C			D0 -> Nth entry in dtab
		A=DAT0	A		A[A] = offset to Nth entry
		C=C+A	A
		AD0EX			A[A] = DTAB[N]
		D0=C
		RTNCC

N>EntLex	ECGET	A,0,EC_PREVN
		D0=(2)	EC_NTAB
		C=DAT0	A
		A=A+A	A
		C=C+A	A		C[A] -> Nth length
		CD0EX
		C=R2
		ASRB.F	A
		C=C-A	A		C[A] = N - PrevN
		B=C	A
		C=0	A
		A=0	A
		GOC	N>EntRlp

N>Entlp		B=B-1	A		Loop from PrevN to N,
		GOC	EndEntlp	Add length of entries between
		A=DAT0	B		  PrevN and N.
		A=A+A	B
		C=C+A	A
		C=C+CON	A,7
		D0=D0+	2	
		GONC	N>Entlp

N>EntRlp	D0=D0-	2		Loop from PrevN downto N
 		A=DAT0	B		Add length of entries between
		A=A+A	B
		C=C-A	A		  PrevN end N. (negative values)
		C=C-CON	A,7
		B=B+1	A
		GONC	N>EntRlp

EndEntlp	ECGET	A,0,EC_RPREVN	Update RTAB[PrevN]
		C=C+A	A
		DAT0=C	A
		D0=(2)	EC_PREVN	Update PrevN with current N
		A=R2
		DAT0=A	A
		D0=C
		RTNCC
**********************************************************************
* Description:	Determines if ADDR is an entry; if no match, get the
*		next closest address
* In:		A[A]=ADDR
* Out:		A[A]=ADDR C[A]=FADDR B[A]=N
*		CS: fail	CC: success
* Uses:		A[A] B[A] C[A] D[A] R3 D0
**********************************************************************
ECentry?	ECGET	C,0,EC_MAXN
		B=C	A
		C=A	A
		D=C	A
		A=0	A
		D0=(2)	EC_DTAB
		C=DAT0	A
		R3=C			R3[A] = ->dtab

ECentrylp?	C=A	A
		C=C+B	A
		CSRB.F	A		C[A] = MID
		CD0EX
		C=R3			D0 = MID; C[A] = ->offset1
		AD0EX			D0 = START; A[A] = MID
		C=C+A	A
		A=A+A	A
		A=A+A	A
		A=A+C	A
		AD0EX			D0 -> middle of entry table
		C=DAT0	A		C[A] = offset to entry
		AD0EX			D0 = START; A[A] ->offset[MID]
		A=A+C	A
		AD0EX			A[A] = START; D0 ->entry
		C=DAT0	A		C[A] = addr of entry[MID]
		?A=B	A		is search over?
		GOYES	ECretent?	yes, check for match
		?D<=C	A		otherwise adjust START or END
		GOYES	ECentup
		A=A+B	A
		ASRB.F	A		adjust START
		A=A+1	A
		GONC	ECentrylp?
ECentup		B=B+A	A
		BSRB.F	A		adjust END
		GONC	ECentrylp?

ECretent?	DCEX	A
		A=C	A
		C=D	A
		D0=D0+	5		D0 -> len field of entry
		?C#A	A		matching address?
		RTNYES
		RTN
**********************************************************************
EcModA		GOSUB	EcGetAnns
		?ABIT=1	6
		GOYES	+
		ABIT=1	6
		GONC	++
+		ABIT=0	6
		GOC	++

EcModLS		GOSUB	EcGetAnns
		?ABIT=1	4
		GOYES	+
		ABIT=1	4
		ABIT=0	5
		GONC	++
+		ABIT=0	4
		GOC	++

EcModRS		GOSUB	EcGetAnns
		?ABIT=1	5
		GOYES	+
		ABIT=1	5
		ABIT=0	4
		GONC	++

+		ABIT=0	5

++		DAT0=A	B
		ST=1	eREPEAT
		ST=1	eDISPOK	
		RTN

EcGetAnns	D0=(5)	=ANNUNCIATORS
		A=DAT0	B
		RTN
**********************************************************************
ECOFF		ST=0	eREPEAT
		GOLONG	EcDeepSleep
**********************************************************************
EcTogBeep	ST=0	eREPEAT
		ST=1	eDISPOK
		D0=(5)	(SystemFlags)+13
		C=DAT0	B
		?ST=0	eBPOFF
		GOYES	ecbeepon
		CBIT=0	3
		DAT0=C	B
		ST=0	eBPOFF
		RTN
ecbeepon	CBIT=1	3
		DAT0=C	B
		ST=1	eBPOFF
		RTN

**********************************************************************
EClexico	ST=0	eREPEAT
		ECGET	A,0,EC_NTAB
		?A#0	A		if no NTAB -> BadECKey
		GOYES	+
		GOLONG	BadECKey
+		?ST=0	eLEXICO		if switching mode, must keep
		GOYES	lexicoon	same current entry, so :	

* lexico off; turn it on and convert N to index for DTAB
		GOSUB	N>Entr		C[A] = D0; D0 -> entry
		R0=C.F	A
		A=DAT0	A		
		GOSUB	ECentry?
		C=B	A
		R2=C	A
		ST=0	eLEXICO
*		RTN
* adjust for entries with same addresses
		GOSUB	N>Entr		A[A] = DTAB[N]; C[A] ->entry
		AD0EX
		A=R0
		B=A	A		B[A] = ->entry in lexico mode
-		?C=B	A
		RTNYES
		D0=D0+	5
		C=D0
		A=DAT0	A
		C=C+A	A
*		?C>B	A		gone too far?
*		RTNYES
		A=R2			no, update N to next entry
		A=A+1	A
		R2=A.F	A
		GONC	-
		RTN			safety (N=0)		

* lexico on; turn it off and convert N to index for NTAB
lexicoon	GOSUB	N>Entr		C[A] = D0; D0 -> entry
		B=C	A
		ECGET	C,0,EC_RTAB
		
* now search entry table; each entry has the following layout:
* 	CON(5) addr
* 	CON(2) namelen
* 	NIBASC 'entryname'
* D[A] = index for NTAB
		A=0	A
		D=0	A
-		?C=B	A		matched addr of RTab[PrevN]?
		GOYES	+
		D0=C
		D0=D0+	5		skip addr
		A=DAT0	B
		C=C+A	A
		C=C+A	A		2 * (num of chars)
		C=C+CON	A,7		addr, namelen
		D=D+1	A
		GONC	-
		
+		C=D	A
		R2=C.F	A
		ST=1	eLEXICO
		RTN

**********************************************************************
EClMatch
		ST=0	eREPEAT
		?ST=1	eLMATCH
		GOYES	EcLmatchoff
	
		ST=1	eLMATCH
		GOSUB	EcSetIoAnn
		A=R1
		D0=A
		A=DAT0	B
		?A=0	B		is search string empty?
		RTNYES
		GOLONG	EcUpdate

EcLmatchoff	ST=0	eLMATCH
*		GOTO	EcSetIoAnn

EcSetIoAnn	GOSUB	EcGetAnns
		D1=(5)	=ANNCTRL
		C=DAT1	B
		CBIT=0	5
		ABIT=0	1
		?ST=0	eLMATCH
		GOYES	+
		ABIT=1	1
		CBIT=1	5
+		DAT1=C	B
		DAT0=A	B
		RTN

**********************************************************************
EcClrCursor	?ST=0	eCURSOR
		RTNYES
		GONC	EcTogCursor

EcSetCursor	?ST=1	eCURSOR
		RTNYES

EcTogCursor	?ST=1	eCURSOR
		GOYES	+
		ST=1	eCURSOR
		GONC	++
+		ST=0	eCURSOR
++
		C=R1.F	A
		D1=C
		A=0	A
		A=DAT1	B

* skip prologue, length, dimensions
* skip top row of pixels, 12 rows of text, then " Find:"		
		LC(5)	20+1*34+12*6*34+6
		A=A+C	A

		D1=(5)	=ADISP
		C=DAT1	A
		A=A+C	A
		D1=A
		
		P=	16-6
-		A=DAT1	B
		A=-A-1	B
		DAT1=A	1
		D1=D1+	16
		D1=D1+	16
		D1=D1+	2
		P=P+1
		GONC	-
		RTNCC


**********************************************************************
* 		EcWaitKey		( see ED )
**********************************************************************
* Wait for a keypress.
* Entry:	eREPEAT		is repeat enabled?	sREPEAT
*		eBLINK		is blink enabled?	sBLINK
*		eDELAY		delay keypress?		sDELAY
* Exit:		C[A] = keycode
* Note:		Han: can probably be reorganized to use ED's WaitKey
*		(would need to redo entry into EC to match ED, though)
**********************************************************************
--		GOVLNG	=AllowIntr  <---+	Got key, done
-		GOTO	EcTimeoutLp  <--|--+	No
					|  |
EcWaitKey				|  |
		ST=0	15		|  |
		GOSUB	EcPopKey	|  |
		GONC	--	--------+  |	Got key
		?ST=0	eREPEAT		   |	Repeat on?
		GOYES	-	-----------+	Yes - delay, repeat

		D0=(5)	EC_KEYTIME
		A=DAT0	W
		C=0	W
		LC(3)	8192*15/1000-26
		?ST=0	eDELAY
		GOYES	+
		LC(3)	8192*40/100-26
+		A=A+C	W
		DAT0=A	W

		D1=(5)	=DISABLE_KBD
		LC(1)	1
		DAT1=C	1

-		GOSBVL	=BITMAP	 <------+	Keys down in A
		?ABIT=1	0		|	Check bit for ATTN
		GOYES	++              |
		?A=0	W		|	Any keys down?
		GOYES	++		|	No - exit (CS)
		D1=(5)	=KSTATEVGER	|	Get KEYSTATE
		C=DAT1	W		|	(last keyboard save)
		?A=C	W		|  	Any change in keyboard?
		GOYES	+	-----------+	No - check delay time
		C=A	P		|  |
		GOSBVL	=SrvcKbdAB	|  |
		GOSUB	EcPopKey	|  |
		GONC	++		|  |	Yes - exit (CC)
+		GOSBVL	=GetTimChk  <------+	No - check delay time
		D0=(5)	EC_KEYTIME
		A=DAT0	W		|
		?C<A	W		|	Delay done?
		GOYES	-	--------+	No - do over

		GOSBVL	=setannun
		GOSUB	EcRepKey?		Check for repeat keys

++		D1=(5)	=DISABLE_KBD
		A=0	P
		DAT1=A	1
		GOC	EcTimeoutLp		No key!

		RSTK=C				Save key
		D1=(5)	=TIMERCTRL.1
		LC(1)	6			Timer1 on/rupts
		DAT1=C	1
		D1=(2)	=TIMER2			Check timer2
		A=DAT1	A
		LC(1)	1
		?ABIT=0	8			Less than 256 ticks?
		GOYES	+	--------+	Yes - timer1 = 1
		LC(1)	0		|	No - timer1 = 0
+		D1=(2)	=TIMER1	 <------+
		DAT1=C	1			Set timer1
		C=RSTK				Key in C[A]

		ST=1	15
		ST=0	14
		RTI				Got key, done

EcTimeoutLp	C=0	W
		LC(6)	=DFLT_TIMEOUT
		R0=C
		GOSBVL	=settimeout	Set timeout
		GOSBVL	=Timer1On
		?ST=0	eBLINK		Blink enabled?
		GOYES	EcWaitNow	No
		LC(3)	=BLINKMASK	Yes, set blink flag
		GOSBVL	=setflag

EcResetT1Cnt	D1=(5)	=T1COUNT	Set cursor count
		LC(1)	8
		DAT1=C	1

EcWaitNow	GOSBVL	=clrbusy	Not busy anymore
		GOSBVL	=setannun	Update annunciators
		GOSBVL	=AllowIntr

		D1=(5)	=CARDCTL
		LC(1)	8
		DAT1=C	1		[ECDT RCDT SMP SWINT]=[1000]
		RSI			Avoid ShutDn if Key down
		?ST=1	13		Interrupted?
		GOYES	+  -----+	Yes - Skip ShutDn
		SHUTDN		|	Light Sleep: Keys, Timers Active
				|
+		ST=0	13  <---+
		GOSUBL	adjkey		No keys down?  Clear KEYSTATE
		ST=0	15		Interrupts off
		GOSUB	EcPopKey
		GONC	+			Got key
		GOSBVL	=chk_timeout		Timeout?
		GOC	Ecgosleep			yes, sleep
		?ST=0	eBLINK			Blink enabled?
		GOYES	EcWaitNow			No - skip blink
		D1=(5)	=T1COUNT        Check cursor count
		C=DAT1	S
		?C#0	S		Count = zero?
		GOYES	EcWaitNow	No - skip blink
		GOSUBL	EcTogCursor	Blink
		GOTO	EcResetT1Cnt	Go reset blink count

Ecgosleep	GOSUB	EcDeepSleep	Nighty night
		ST=0	15
		GOTO	EcTimeoutLp	Go back and reset timeout

+		RSTK=C			Save key
		LC(3)	=BLINKMASK		Clear blink flag
		GOSBVL	=clrflag
		GOSBVL	=clrtimeout
		GOSBVL	=showbusy	Busy now
		C=RSTK
		GOVLNG	=AllowIntr	Got key, done

**********************************************************************
* Uses #80110 --> for saving data
**********************************************************************
EcDeepSleep	GOSUBL	EcRomView	unconfigure tables

		D0=(5)	EC_STATUS	save status
		C=ST
		DAT0=C	X
		D0=D0+	3
		P=	16-4
-		C=RSTK			save RSTK
		DAT0=C	A
		D0=D0+	5
		P=P+1
		GONC	-

		C=R0			save R0 through R4
		DAT0=C	W
		D0=D0+	16
		C=R1
		DAT0=C	W
		D0=D0+	16
		C=R2
		DAT0=C	W
		D0=D0+	16
		C=R3
		DAT0=C	W
		D0=D0+	16
		C=R4
		DAT0=C	W

* Nighty night
		GOSUB	+
		CON(5)	=DOCOL
		CON(5)	=TurnOff
		CON(5)	=COLA
		CON(5)	=DOCODE
		REL(5)	->ECend
		GOTO	EcDeepCont
+		C=RSTK
		GOSUBL	getptrevalc	subroutine is in edcode.s
* Restore registers and return
EcDeepCont	GOSBVL	=SAVPTR

		D0=(5)	(EC_RSTK4)+5	restore RSTK
		P=	16-4
-		D0=D0-	5
		C=DAT0	A
		RSTK=C
		P=P+1
		GONC	-
		D0=D0-	3		get status
		C=DAT0	X
		ST=C

		D0=(2)	(EC_RSTK4)+5	restore R0 through R4
		C=DAT0	W
		R0=C
		D0=D0+	16
		C=DAT0	W
		R1=C
		D0=D0+	16
		C=DAT0	W
		R2=C
		D0=D0+	16
		C=DAT0	W
		R3=C
		D0=D0+	16
		C=DAT0	W
		R4=C
				
		D0=(2)	EC_CONFIG
		C=DAT0	A
		?C=0	A
		RTNYES
		PC=C			reconfigure tables

**********************************************************************
EcPopKey	GOSBVL	=chk_attn	ATTN pressed?
		GONC	+		No ATTN key - try keybuffer
		C=0	A		Clear ATTN
		DAT1=C	A
		LC(2)	ONCODE		And return [ATTN]
		GOC	++
+		GOSBVL	=POPKEY
		RTNC			CS: No regular key
++		ST=1	eDELAY		Must delay next key
		RSTK=C			Save the keycode
		B=C	A
		LC(2)	#3F		Mask out modifiers
		B=B&C	B
		?B=0	B		Modifier key?
		GOYES	+		Yes - skip save

		D0=(5)	=EC_REPSTK
Ecgotkey	A=DAT0	B		Get last key saved
		C=B	A
		DAT0=C	B		Save new key
		D0=D0+	2
		DAT0=A	B		Save old key

+		D0=(5)	EC_KEYTIME	D0 -> old keytime
		GOSBVL	=GetTimChk	Save time of keypress
		DAT0=C	W		

		C=RSTK
		RTNCC			CC: Got key

**********************************************************************
EcRepKey?
		D1=(5)	=KSTATEVGER
		A=DAT1	W
		C=0	W
		C=A	P
		DAT1=C	W		Clear KEYSTATE
		GOSBVL	=SrvcKbdAB	Gives max 3 modified keys
		GOSBVL	=POPKEY		Pop first down key
		RTNC			CS: No repeat key
		
		B=C	A		Keycode in B[A]
		LC(2)	#C0		Save modifiers
		C=C&B	B
		D=C	A		in D[B]
		LC(2)	#3F		Mask out modifiers
		B=B&C	B		in B[B]
		?B=0	B		Modifier key only?
		RTNYES			Yes - CS

		D0=(5)	EC_REPSTK
-		GOSBVL	=POPKEY		Any more keys down?
		GONC	+		Yes

* Valid keycode (minus modifier) in B[B], modifier in D[B]
		C=B	A		Key code (minus modifier)
		C=C!D	B		Add modifier
		ST=0	eDELAY		No delay for this key
		RSTK=C			Save the keycode
		GOTO	Ecgotkey	Got key, go save

* Come here if we have more than one key down.

+		A=C	A		New keycode in A[B]
		LC(2)	#3F		Mask out modifier
		C=C&A	B
		A=DAT0	A		Get last two saved keys
		?C=A	B		C[B] same as last key?
		GOYES	-		Yes - keep B[B], try again
		?B=A	B		B[B] same as last key?
		GOYES	+		Yes - go save to B[B]
		ASR	A		No match for last key.
		ASR	X		Try next to last key.
		?B#A	B		B[B] same as next to last
		GOYES	-		No - keep B[B], try again
+		B=C	A		save C[B] to B[B]
		GOTO	-		Try again

**********************************************************************
*		DO NOT MOVE THIS CALL! This must follow EcRepKey?
EcAdjustKey	GOLONG	AdjustKey
**********************************************************************
EcChrKey?	GOLONG	EdChrKey?
**********************************************************************
->ECend
ENDCODE

