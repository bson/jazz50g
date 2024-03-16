**********************************************************************
*		DISASSEMBLER PASS1: SCAN LABELS
**********************************************************************

**********************************************************************
* Name:		ScanLabsXY
* Interface:	( $labels #x #y --> $labels )
* Description:	Scans range X-Y for labels doing PCO/RPL checks
*		Start mode is decided at #x
**********************************************************************
NULLNAME ScanLabsXY
::
  CODE
		GOSBVL	=SAVPTR
		GOSBVL	=POP2#
		R0=C.F	A		* Save #y
		D0=A
		GOSUBL	PC=RPL?		* CS if valid ob
		GONC	sclblxy_ml	* Start ml scan
		A=R0.F	A		* A[A]=global end  C[A]=obend
		?A<C	A		* gend < obend? 
		GOYES	sclbmin
		R0=C.F	A		* fix obend to smaller value
sclbmin		GOSBVL	=PUSH#		* Push rpl end address
		GOVLNG	=DOTRUE		* TRUE - range in rpl

sclblxy_ml	GOVLNG	=GPPushFLoop	* FALSE - range in ml
  ENDCODE

  ( $labels #x #y #rplend TRUE )
  ( $labels #x #y FALSE )

  case
  ::
    2SWAP 3PICK			( --> #y #rplend $labels #x #rplend )
    AddLabsRPL			( --> #y #rplend $labels )
    UNROTSWAP			( --> $labels #rplend #y )
    2DUP#< case ScanLabsXY	( continue? )
    2DROP
  ;
		
  DUP4UNROLL			( --> #y $labels #x #y )
* Use RPL/PCO detection
  TRUE AddLabsXY		( --> #y $labels	#cont TRUE / FALSE )
  NOTcase SWAPDROP		( --> $labels )
  ROT				( --> #$labels #cont #y )
  COLA ScanLabsXY
;

**********************************************************************
* Name:		ScanLabels
* Interface:	( -->  $labels )
* Description:	Scans X-Y for machine language labels according to
*		status flags & X-Y in status buffer
* Notes:	Assumes object is at a fixed location
**********************************************************************
NULLNAME ScanLabels
::
   NULL$TEMP	( --> $labels )
   CODE
		GOSBVL	=SAVPTR
		D0=(5)	(=IRAM@)-4
		A=DAT0	A
		D0=A
		D0=(4)	#100+(dMODES)
		C=DAT0	X
		ST=C
		?ST=0	sCODEOK		* Code not allowed?
		GOYES	SCgpflp		* Then don't scan labels

		?ST=0	sSPECIAL
		GOYES	+
		D0=(2)	dDISMODE
		A=DAT0	B
		LC(2)	typDISPCO
		?A=C	B		* DISPCO mode?
		GOYES	SCgpflp		* Then don't scan labels

+		D0=(2)	dCURADDR
		A=DAT0	A
		D0=(2)	dENDADDR
		C=DAT0	A
		R0=A
		R1=C		
		GOSBVL	=PUSH2#		* Push start & end addresses
		GOVLNG	=DOTRUE
SCgpflp		GOVLNG	=GPPushFLoop	* Done
  ENDCODE
  NOT?SEMI
  COLA
**********************************************************************
* Name:		AddLabsRPL
* Interface:	( $labels #x #y --> $labels' )
* Description:	Scans X-Y for machine language labels according to
*		status flags & X-Y in status buffer
* Notes:	Assumes object is at a fixed location
**********************************************************************
NULLNAME AddLabsRPL
::
CODE
		GOSBVL	=POP2#
		R0=A			* R0[A]=pc
		R1=C			* R1[C]=endaddr
		GOSBVL	=SAVPTR
		C=R1
		D=C	A		* D[A]=endaddr
		C=R0
		D0=C			* D0=pc
		GONC	SCrplend?_1	* Start by checking if endaddr>=start

SCrpl		A=DAT0	A
		LC(5)	=DOCODE
		?A=C	A
		GOYES	SCcode
		LC(5)	=SEMI
		?A=C	A
		GOYES	SCsemi
		GOSUB	SCcomp?
		GOC	SCcomp
		LC(5)	=DOTAG
		?A=C	A
		GOYES	SCtagged
		LC(4)	=DORRP
		?A=C	A
		GOYES	SCrrp

* No code to scan in the current object

		GOSBVL	=SKIPOB
SCrplend?	CD0EX
SCrplend?_1	D0=C
		?C<D	A		* pc < endaddr?
		GOYES	SCrpl
		GOVLNG	=GPPushFLoop	* No more checking to do

* Scan composite

SCsemi
SCcomp		D0=D0+	5		* Skip prolog
		GONC	SCrplend?
SCtagged	D0=D0+	5		* Skip DOTAG
		C=0	A
		C=DAT0	B
		C=C+1	B
		C=C+C	A
		AD0EX
		C=C+A	A
		GONC	SCrplend?_1

* Scan code object

SCcode		D0=D0+	5		* Skip DOCODE
		C=DAT0	A		* C[A] = codelen
		AD0EX
		C=C+A	A		* C[A] = rplstart (=codeend)
		R0=C
		C=D	A		* endaddr
		R1=C
		A=A+CON	A,5		* A[A] = code start
		R2=A

		GOSBVL	=PUSH2#		* Push start & end for rpl
		GOSBVL	=SAVPTR
		A=R2
		R0=A
		GOVLNG	=Push#TLoop	* Push code start & TRUE

* Scan rrp. Check if empty rrp..
SCrrp		AD0EX
		GOSUBL	LastRamWord
		A=DAT0	A
		?A=0	A
		GOYES	SCcomp		* Skip the 0-link & continue
* Push so that: ( --> $buffer #end #rrpend #ob #obend )
		CD0EX
		R2=C			->offset
		A=A+C	A		->lastramword
		D0=A
		GOSBVL	=TRAVERSE+	->lastob
		GOSBVL	=SKIPOB		->rrpend
		AD0EX
		AR1EX			R1[A] = ->rrpend
		R0=A			R0[A] = ->end
		GOSBVL	=PUSH2#
		GOSBVL	=SAVPTR
		C=R2
		D0=C			->offset
		D0=D0+	5+5		->ob1name
		GOSBVL	=TRAVERSE+	->ob1
		AD0EX
		R0=A			->ob1
		D0=A
		GOSBVL	=SKIPOB		->ob1end
		AD0EX
		R1=A			->ob1end
		GOSBVL	=PUSH2#
		A=PC
		LC(5)	(scrrpentry)-(*)
		A=A+C	A
		D0=A
		LOOP

* Test if pc contains a composite object
SCcomp?		A=DAT0	A
		LC(5)	=DOCOL		* #02D9D
		?A=C	A
		RTNYES
		LC(4)	=DOLIST		* #02A74
		?A=C	A
		RTNYES
		LC(2)	=DOSYMB		* #02AB8
		?A=C	A
		RTNYES
		LC(2)	=DOEXT		* #02ADA
		?A=C	A
		RTNYES
		LC(2)	=DOMATRIX	* #02686		* New
		?A=C	A
		RTNYES
		RTNCC
ENDCODE
	( --> $buffer FALSE / $buffer #rpl #rplend #code TRUE )
	NOT?SEMI		( Done )
	4ROLLSWAP		( --> #rpl #rplend $buf #code )
	4PICK			( --> #rpl #rplend $buf #code #rpl )
* No RPL/PCO detection in code objects
	FALSE AddLabsXY		( --> #rpl #rplend $buf' )
	UNROT COLA AddLabsRPL	( Restart the loop )
;
;
ASSEMBLE
scrrpentry
RPL
* First check that rrpend is not bigger than end
	( --> $buffer #end #rrpend #ob #obend )
	2SWAP 2DUP#< IT DROPDUP 5UNROLL 5UNROLL
	( --> #end #rrpend $buffer #ob #obend )
ASSEMBLE
scrrploop
RPL
* Note that in the following rrpend is not necessarily true rrpend, but
* a smaller end value. Thus using rrpend in the check below is correct
	4PICK 2DUP#< ITE	( Check obend <= rrpend )
	  DROP			( keep obend )
	  SWAPDROP		( use rrpend instead )

	DUP 4UNROLL	( --> #end #rrpend #obend $buffer #ob #obend )
	AddLabsRPL	( --> #end #rrpend #obend $buffer )
	UNROT 2DUP#>	( --> #end $buffer #rrpend #obend rrpend>obend? )
* rrpend <= obend we have the last ob to scan
	NOTcase :: SWAPDROP ROT 2DUP#< case AddLabsRPL 2DROP ;
* Fetch next object to scan in rrp
	ROTSWAP		( --> #end #rrpend $buffer #obend )
	CODE
		GOSBVL	=POP#
		GOSBVL	=SAVPTR
		D0=A
		D0=D0+	5		Skip link
		GOSBVL	=TRAVERSE+
		AD0EX
		R0=A			->nextob
		D0=A
		GOSBVL	=SKIPOB
		CD0EX
		R1=C			->nextobend
		GOSBVL	=PUSH2#
		A=PC
		LC(5)	(scrrploop)-(*)
		A=A+C	A
		D0=A
		LOOP
	ENDCODE

**********************************************************************
* Name:		AddLabsXY
* Interface:	( $buffer #x #y FALSE --> $buffer' )
*		( $buffer #x #y TRUE --> $buffer FALSE )
*		( $buffer #x #y TRUE --> $buffer #cont TRUE )
* Description:	Scans machine language and adds labels used to buffer
* Notes:
*		[X,Y] must be a fixed area
*		$buffer must be in tempob
*		new labels are added to the end of the buffer
* If TRUE is given as argument then the scanner will interrupt if it
* finds a possible switch to rpl mode. Also if TRUE is given then
* PCO detection is enabled (the 5 nibbles are just skipped)
* Should a possible switch to RPL be found then the address of that
* swicth is pushed to the stack along with TRUE.
* sGUESS from status buffer determines whether GOSUB/GOSUBL
* calls should be checked for possible data.
**********************************************************************
NULLNAME AddLabsXY
CODE

*sBRANCH	EQU 7
sCONTHERE	EQU 8
*sGUESS		EQU 9
sCALL		EQU 10	\ No conflict since ST is saved during GC
sGARB		EQU 10	/
sDETECT		EQU 11

* Fetch status flags
		AD1EX
		D1=(5)	(=IRAM@)-4
		C=DAT1	A
		D1=C
		D1=(4)	#100+(dMODES)
		C=DAT1	A
		ST=C
		AD1EX

* Pop detection flag

		ST=0	sDETECT
		GOSBVL	=popflag	* CS if detection enabled
		GONC	gotdetectf
		ST=1	sDETECT
gotdetectf

		GOSBVL	=POP2#		* A[A]=pc C[A]=endaddr
		R1=A			* R1[A]=pc
		R2=C			* R2[A]=endaddr
		GOSBVL	=SAVPTR
		A=DAT1	A
		R0=A			* R0[A]=->$labels
		D1=A
		D1=D1+	5
		C=DAT1	A
		AD1EX
		C=C+A	A		* C[A]=->$endlabels
		D1=C			* D1 = ->labels
		D=0	A		* Free = 0!!!!!!
		A=R1
		D0=A			* D0=pc
		C=R2
		B=C	A		* B[A]=endaddr

* Note that we do not expand the buffer in any way, it is expanded
* only if a label is used.
* If a label is found the current status is saved, the buffer is expanded,
* the status is restored and label addition is tried again as if nothing
* happened. Out of memory recognition is automatic.
* This of course requires the code to be in a fixed location!!!

**********************************************************************
* Now:
*	R0	->$labels	* For SHRINK$
*	D1	->labels	* Current location to add to
*	D0	->pc		* Current location in code
*	B[A]	->endaddr	* End address of scan
*	D[A]	free		* Size counter for buffer (decreasing)
**********************************************************************

MSCloop
		ST=0	sCONTHERE
		GOSUB	?MSCdetect	* Exit if rpl boundary, pc+5 if PCO
		GONC	MSCnobr		* Jump to end test if PCO skipped
		GOSUB	MSClabel	* Get normal label for next
		?ST=1	sCONTHERE
		GOYES	MSCnobr		* Ignore skip, new PC was set
		GOSUB	SKIPML
		?ST=0	sBRANCH
		GOYES	MSCnobr
		GOSUB	MSCgoyes	* Get goyes label
MSCnobr		CD0EX
		D0=C
		?C<B	A
		GOYES	MSCloop

		CD1EX
		D0=C

* NOTE!!!!!!!!!!!!!!!!!!!!!!!!!!!!
* Shrink$ cannot be used since X & Y bints are created after the label buffer

		GOSUBL	SHRINK$		* Shrink up to D0
		?ST=0	sDETECT
		GOYES	MSCgplp		* No detect - just leave $labels
		GOVLNG	=GPPushFLoop	* No #cont since end was reached
MSCgplp		GOVLNG	=GETPTRLOOP

* Add GOYES label to buffer (ignore if RTNYES)

MSCgoyes	D0=D0-	2		* Back to offset
		CD0EX			* C[A] = offset start
		D0=C
		A=0	A
		A=DAT0	B		* A[B]=offset
		D0=D0+	2		* Skip goyes again
		?A=0	B		* Ignore if rtnyes
		RTNYES
		GOTO	MSClab2		* Add label:A[A]=offset C[A]=start

* Add label to buffer if instruction uses one

MSClabel	ST=0	sCALL		* Flag non-call
		A=DAT0	6		* A[5-0]=pcnibs (6 for GOLONG)
		LC(1)	4		* 4aa = GOC/RTNC
		?A=C	P
		GOYES	MSCgoc
		C=C+1	P		* 5aa = GONC/RTNNC
		?A=C	P
		GOYES	MSCgonc
		C=C+1	P		* 6aaa = GOTO
		?A=C	P
		GOYES	MSCgoto
		C=C+1	P		* 7aaa = GOSUB
		?A=C	P
		GOYES	MSCgosub
		LC(2)	#C8		* 8Caaaa = GOLONG
		?A=C	B
		GOYES	MSCgolong
		LC(2)	#E8		* 8Eaaaa = GOSUBL
		?A=C	B
		GOYES	MSCgosubl
		RTNCC			* No label used

**********************************************************************
* GONC		Special: 500:RTNNC
**********************************************************************
MSCgonc		ASR	A
		GOC	MSCgoc_1
**********************************************************************
* GOC		Special: 400:RTNC	420:NOP3
**********************************************************************
MSCgoc		ASR	A		* A[B]=offset
		LC(2)	2
		?A=C	B
		RTNYES			* NOP3 - ignore
MSCgoc_1	C=0	A
		C=A	B
		A=C	A
		CD0EX
		D0=C
		C=C+1	A		* Start address

MSClab2		?A=0	A		* Ignore if 0 offset
		RTNYES			* (RTNYES RTNC RTNNC)
		?ABIT=0	7
		GOYES	MSClab2+
		A=-A	B
		A=-A	A
MSClab2+	GOTO	MSCoffset
**********************************************************************
* GOTO 6aaa	Special: 6300:NOP4	6400x:NOP5
**********************************************************************
MSCgoto		ASL	A		* Clear high nibble
		ASR	A
		ASR	A		* A[X]=offset
		LC(3)	3
		?A=C	X
		RTNYES			* NOP4 - ignore
		C=C+1	A
		?A=C	X		* NOP5 - ignore
		RTNYES
*		P=	1-1		* Fix for GOTO
		GONC	MSClab3
*********************************************************************
* GOSUB 7aaa
**********************************************************************
MSCgosub	ST=1	sCALL		* Flag call
		ASL	A		* Clear high nibble
		ASR	A
		ASR	A		* A[X]=offset
		P=	4-1		* Fix for GOSUB
MSClab3		?ABIT=0	11
		GOYES	MSClab3+
		A=-A	X
		A=-A	A
MSClab3+	GOTO	MSCoff&fix

**********************************************************************
* GOLONG 8Caaaa		NOP6 does not exist!
**********************************************************************
MSCgolong	P=	2-1		* Fix
		GOC	MSClab4
**********************************************************************
* GOSUBL 8Eaaaa
**********************************************************************
MSCgosubl	ST=1	sCALL		* Flag call
		P=	6-1		* Fix

MSClab4		C=P	15
		ASR	W
		ASR	A		* A[3-0]=offset
		?ABIT=0	15
		GOYES	MSClab4+
		P=	3
		A=-A	WP
		A=-A	A
MSClab4+	P=C	15


* A[A]=offset

MSCoff&fix	CD0EX			* Get start addr
		D0=C
		C+P+1			* Fix start

* A[A]=offset C[A]=start address


MSCoffset	P=	0
		A=A+C	A		* A[A]=target

		CD1EX			* C[A]=->labels
		CDEX	A		* D[A]=->labels
		RSTK=C			* RSTK=free
		
		C=R0.F	A		* C[A]=->$labels
		D1=C
		D1=D1+	5		* Skip DOCSTR

LADDlp		D1=D1+	5
		CD1EX
		?C>=D	A		* Reached current location?
		GOYES	LADDok		* Yes - add label
		CD1EX
		C=DAT1	A		* C[A]=old label
		?A#C	A
		GOYES	LADDlp
* Found same label, do nothing
LADDok		C=RSTK
		CDEX	A		* D[A]=free
		D1=C			* D1=->labels
		GONC	LADDguess?
* Code continues if LADDok was jumped to (no previous match)
LADDnow		D=D-CON	A,5		* free-
		GOC	LADDout
		DAT1=A	A		* add label to $labels
		D1=D1+	5
		GONC	LADDguess?
LADDout		D=D+CON	A,5		* fix back
		GOTO	LADDgc

* Now check if we should skip guess-data area

LADDguess?	?ST=0	sCALL		* Only for GOSUB and GOSUBL!
		RTNYES
		?ST=0	sGUESS
		RTNYES

		CD0EX
		D0=C
		?A<=C	A		* Negative call - ignore
		RTNYES
		D0=A
		A=DAT0	B
		RSTK=C			"D0"
		LCHEX	70		"C=RSTK"
		?A=C	B
		GOYES	+		Should skip!
		C=RSTK
		D0=C			Return as usual
		RTN
* Now check if we have embedded code at which to continue
* Currently checks only the 2 RPL GC variants:
* :: GARBAGE [COLA] CODE
* If not of above type then continue at target
* Now: D0 = end address, RSTK = original D0 (address of the call)
+		C=RSTK
		CD0EX			call
		RSTK=C			target
		A=DAT0	B
		LC(1)	7
		D0=D0+	4		Skip GOSUB
		?A=C	P
		GOYES	+
		D0=D0+	2		Skip GOSUBL
+		A=DAT0	10
		C=A	W
		LC(N)	10
		CON(5)	=DOCOL
		CON(5)	=GARBAGE
		?A=C	W
		GOYES	+
-		C=RSTK
		D0=C			target
		RTN			Skip C=RSTK too.. (no sCONTHERE)
+		D0=D0+	10
		A=DAT0	10
		LC(5)	=DOCODE
		?A=C	A
		GOYES	scanrplgc
		LC(N)	10
		CON(5)	=COLA
		CON(5)	=DOCODE
		?A#C	W
		GOYES	-		No RPL GC, continue at target
		D0=D0+	5		Skip COLA
scanrplgc	D0=D0+	5		Skip DOCODE
		C=RSTK			Drop target
		ST=1	sCONTHERE	And continue without skip
		ST=0	sCALL		No longer a call (prevents coming back)
		A=DAT0	A
		CD0EX
		D0=C
		D0=D0+	5		Skip REL
		GOTO	MSCoffset	And add it
**********************************************************************
* Now:
* 	A[A]	label		* Label to add to the buffer
* General:
*	R0	->$labels	* For Shrink$
*	D1	->labels	* Current location to add to
*	D0	->pc		* Current location in code
*	B[A]	->endaddr	* End address of scan
*	D[A]	free		* Size counter for buffer (decreasing)
* D[A] is < 5
**********************************************************************

* Save status

LADDgc		R1=A		* R1[A]=label
		AD0EX
		R2=A		* R2[A]=pc
		A=B	A
		R3=A		* R3[A]=endaddr
		AD1EX		* A[A] = ->labels (current location)
		C=R0		* C[A] = ->$labels
		A=A-C	A	* Convert to offset
		R4=A		* R4[A] = ->$labels - ->labels

		C=ST
		RSTK=C		* Save ST flags

* Now maximize the string on stack level 1

		ST=0	sGARB
EXagain		GOSBVL	=ROOM
		A=C	A
		LC(5)	30+5+1	* Leave mimimum 30 nibbles 
		A=A-C	A
		GONC	EX$ok
		GOSBVL	=DOGARBAGE
		GONC	EXagain

EX$ok		A=A+CON	A,5	* Expand atlast 5 nibbles
		B=A	A	* B[A]=nibbles
		GOSBVL	=D1=DSKTOP
		A=DAT1	A
		R0=A		* R0[A]=->$labels (new)
		A=A+CON	A,5
		D0=A
		C=DAT0	A	* C[A] = $len (old)
		A=A+C	A	* A[A] = $end (old)
		C=C+B	A	* C[A] = $len (new)
		DAT0=C	A
		D0=A		* D0 = $end (old)
		C=DAT0	A	* C[A] = link (old)
		C=C+B	A	* C[A] = link (new)
		DAT0=C	A
		C=B	A	* C[A]=nibbles
		GOSBVL	=MOVERSU

* Now restore status

		A=R0		* A[A]=->$labels
		C=R4		* C[A]=offset for ->labels
		C=C+A	A
		D1=C		* D1=->labels
		A=A+CON	A,5
		D0=A
		C=DAT0	A
		A=A+C	A	* A[A]=->$endlabels (new)
		CD1EX		* C[A]=->labels
		D1=C
		C=A-C	A
		D=C	A	* D[A]=free (new)

		A=R3
		B=A	A	* B[A]=endaddr
		A=R2
		D0=A		* D0=pc
		A=R1		* A[A]=label
		C=RSTK
		ST=C		* Restore status
		GOTO	LADDnow	* This time we can add the label for sure

**********************************************************************
* ML->RPL and ML->PCO detection
* If RPL found then Shrink, push #cont, push true, exit
* If PCO found then pc+=5, Return CC
* Else CS
**********************************************************************
?MSCdetect	?ST=0	sDETECT
		RTNYES
		GOSUB	PC=ML>RPL?
		GOC	MSCtorpl	* Start rpl mode
		GOSUB	PC=PCO?
		GOC	MSCpco
		RTNSC			* Not PCO - return SC
MSCpco		D0=D0+	5
		RTNCC			* CC - flag PCO skipped

* Shrink, push #cont, push true, exit

MSCtorpl	CD1EX
		CD0EX
		RSTK=C			* RSTK = #cont
		GOSUBL	SHRINK$
		C=RSTK
		R0=C
		GOVLNG	=Push#TLoop

* Set carry if PC points to a PCO

PC=PCO?		A=DAT0	A
		CD0EX
		D0=C
		C=C+CON	A,5
		?A=C	A
		RTNYES
		RTNCC

* Set carry if PC points to a RPL object

PC=PRLG?	A=DAT0	A		@PC
*		LC(5)	#7F000		Protect from reading bank switch
*		?A<C	A		( Han: still a problem? )
*		GOYES	+
*		LC(5)	=RAMSTART	#80000
*		?A<C	A
*		GOYES	PCcc
*+
		C=A	A
		CD0EX
		A=DAT0	A
		D0=(5)	=PRLG
		CD0EX
		?A=C	A
		RTNYES
PCcc		RTNCC

* Set carry if PC points to a valid RPL object
* Returns end address in C[A] if valid ob
* If DupAndThen followed by PRLG/PCO then ok and endaddr = pc+5

PC=RPL?		GOSUB	PC=DupAndThen?
		GOC	PCrpldup
		GOSUB	PC=PRLG?
		RTNNC			* No prolog - return CC
PCvalid?	CD0EX
		RSTK=C
		CD0EX
		GOSUBL	SafeSkipOb	* Sets CRY if invalid
		C=RSTK
		CD0EX
		GOC	PCcc
		RTNSC			* Valid ob
PCrpldup	CD0EX			* Return DupAndThen as valid rpl
		D0=C			* Return pc+5 as rpl end
		C=C+CON	A,5
		RTNSC

* Set carry if PC points to a ml->rpl prolog (ob valid)
*	{ DOBINT DOCOL DOLIST DOSYMB DOCODE DOGROB }
* Alse set carry if pc points to DupAndThen + PRLG/PCO

* Han:	test all objects with proper prologue
PC=ML>RPL?	GOSUB	PC=PRLG?
		GOC	PCvalid?
*		GOTO	PC=DupAndThen?

*** old code
*		A=DAT0	A
*		LC(5)	=DOINT		* 02614
*		?A=C	A
*		GOYES	PCvalid?
*		LC(2)	=DOFLASHP	* 026AC
*		?A=C	A
*		GOYES	PCvalid?
*		LC(3)	=DOBINT		* 02911
*		?A=C	A
*		GOYES	PCvalid?
*		LC(3)	=DOCOL		* 02D9D
*		?A=C	A
*		GOYES	PCvalid?
*		LC(2)	=DOCODE		* 02DCC
*		?A=C	A
*		GOYES	PCvalid?
*		LC(3)	=DOLIST		* 02A74
*		?A=C	A
*		GOYES	PCvalid?		
*		LC(2)	=DOSYMB		* 02AB8
*		?A=C	A
*		GOYES	PCvalid?
*		LC(3)	=DOGROB		* 02B1E
*		?A=C	A
*		GOYES	PCvalid?
*		LC(3)	=DOROMP		* 02E92
*		?A=C	A
*		GOYES	PCvalid?
		
* Fall through to PC=DupAndThen?

* Test if DupAndThen + PRLG/PCO

PC=DupAndThen?	A=DAT0	A
		LC(5)	=DupAndThen
		?A#C	A
		GOYES	PCnotdup
		D0=D0+	5
		GOSUB	PC=PRLG?
		GOC	PCisdup
		GOSUB	PC=PCO?
		GOC	PCisdup
		D0=D0-	5
PCnotdup	RTNCC
PCisdup		CD0EX			* Return endaddr in C[A]
		D0=C
		D0=D0-	5
		RTNSC
ENDCODE
**********************************************************************
