**********************************************************************
*		SKIP MACHINE LANGUAGE
**********************************************************************

**********************************************************************
* Name:		FindObEnd
* Interface:	( #x --> #x #y TRUE / #x FALSE )
* Description:	Find end address of valid rpl object / PCO
*		Returns false if invalid ob / not PCO
*		Leading DupAndThen + PRLG/PCO is skipped
**********************************************************************
* Han:	Readjusted... PCOs do not necessarily end at another
*	PCO or RPL. Rewrote to treat PCOs and normal ML alike -- we
*	still look for the another PCO or RPL, but we also check for
*	calls that might end ML, whichever comes first. Otherwise, we
*	may end up disassembling a HUGE block of memory.

*	PCOs are always called by indirection; some routines that
*	were formerly PCOs in the HP48 have their address block
*	(*)+5 replaced by a different address. Entries between
*	!REDIMUSER and $5x7 (not including $5x7) are not PCOs.

NULLNAME FindObEnd
CODE
		GOSBVL	=SAVPTR
		GOSBVL	=POP#
		D0=A
		GOSUBL	PC=DupAndThen?
		GONC	findendnow
		D0=D0+	5		* Skip DupAndThen

findendnow	GOSUBL	PC=PCO?
		GOC	findpcoend
		GOSUBL	PC=RPL?		* uses SafeSkipOb
*		GONC	mlend
		GONC	findmlend
*		GOC	gotrplend
*		D0=D0+	5
*		CD0EX

gotrplend	R0=C			* R0[A]=rplend
gotendexit	GOVLNG	=Push#TLoop	* Push rplend & TRUE

findpcoend	D0=D0+	5		* Skip PCO

findmlend	C=D0
		R1=C
pcoendlp	GOSUBL	SKIPML		* Skip instr
		GOSUBL	PC=PCO?
		GOC	gotpcoend	* Found end as a PCO address
		GOSUBL	PC=ML>RPL?
		GONC	pcoendlp
gotpcoend	CD0EX			* C[A]=pco end address
*		GOTO	gotrplend

		R0=C
		C=R1			* now compare against FINDMLEND
		D0=C
		GOSUB	FINDMLEND
		CD0EX
		A=R0
		?C<A	A
		GOYES	gotrplend
		GONC	gotendexit

*mlend
**		GOVLNG	=GPPushFLoop	* Uncomment to disallow ml
*		GOSUB	FINDMLEND	* Skip to end of ml
*		CD0EX
*		GOTO	gotrplend

**********************************************************************
* Name:		FINDMLEND
* Input:	D0 = ->ml
* Output:	D0 = ->mltail
* Description:	Guesses end address of ml subroutine
* Uses:		A[A] B[A] C[A,S] D0 P=0 CRY
* Algorithm:
*	1) Include all normal instructions
*	2) If forward branch then cont at target
*		GOYES	aa
*		GOC	4aa		RTNC	400
*		GONC	5aa		RTNNC	500
*	3) If small forward jump then cont at target
*		GOTO	6aaa
*	4) If backward jump to addr < startaddr then end
*	5) End if found:
*		GOVLNG	8Daaaaa		RTNSXM	00
*		GOLONG	8Caaaa		RTN	01	
*		PC=(A)	808C		RTNSC	02
*		PC=(C)	808E		RTNCC	03
*		PC=A	81B2		RTI	0F
*		PC=C	81B3
*		APCEX	81B6
*		CPCEX	81B7
*
*		new:	81B16		(ARM_LOOP overwrite)
*		new:	80B00		RPL2
*
*	6) End if found branch + backward GONC
*	   Example:
*		GOYES	BackWard	(Or RTNYES)
*		GONC	BackWard
*	   Note that forward GOYES is followed
*	   Actually implemented as 2 consecutive branches..
*		GOC	BackWard
*		GONC	BackWard	will also stop disass
**********************************************************************

MAXGOTO	EQU 128		* Maximum +offset for GOTO to continue

FINDMLEND	AD0EX
		B=A	A		* B[A] = startaddr
		AD0EX

FMcont		ST=0	sBRANCH		* Start with no branch
		A=DAT0	A		* A[A] = 1st 5 nibs

* Test if terminating instruction

*		C=0	B
		C=0	A
		?A#C	P
		GOYES	FMnortn		* Not RTN instruction
		?A=C	B		* RTNSXM?
		GOYES	FMend2
		LC(2)	#10		* RTN
		?A=C	B
		GOYES	FMend2
		LC(2)	#20		* RTNSC
		?A=C	B
		GOYES	FMend2
		LC(2)	#30		* RTNCC
		?A=C	B
		GOYES	FMend2
		LC(2)	#F0		* RTI
		?A#C	B
		GOYES	FMnortn
FMend2		D0=D0+	2		* Skip 2 & done
		RTN

FMnortn
		LC(2)	#D8		* Check for 8xxxx type
		?A#C	P
		GOYES	FMnoterm        * not 8xxxx, bypass

		?A=C	B		* GOVLNG
		GOYES	FMend7
		LC(2)	#C8		* GOLONG
		?A=C	B
		GOYES	FMend6
		C=A	A		* Copy to get [A] tests
		LC(4)	#C808		* PC=(A)
		?A=C	A
		GOYES	FMend4
		LC(4)	#E808		* PC=(C)
		?A=C	A
		GOYES	FMend4
		LC(4)	#2B18		* PC=A
		?A=C	A
		GOYES	FMend4
		LC(4)	#3B18		* PC=C
		?A=C	A
		GOYES	FMend4
		LC(4)	#6B18		* APCEX
		?A=C	A
		GOYES	FMend4
		LC(4)	#7B18		* CPCEX
		?A=C	A
		GOYES	FMend4
* Han:	Test for special ARM rewrite of =Loop : 81B164808C
		LC(5)	#61B18
		?A=C	A
		GOYES	FMend10
		LC(5)	#00B08		* RPL2
		?A#C	A
		GOYES	FMnoterm
		D0=D0+	5
		RTN
FMend10		D0=D0+	3		* skip 10
FMend7		D0=D0+	1		* Skip 7
FMend6		D0=D0+	2		* Skip 6
FMend4		D0=D0+	4		* Skip 4
		RTN			* Found end addr


FMnoterm

* Test if small GOTO
		LC(1)	6		* GOTO ?
		?A#C	P
		GOYES	FMnogoto
		D0=D0+	1		* Skip the 6
		ASR	A
		C=0	A
		C=A	X		* C[X] = offset
		?CBIT=1	11		* Backward jump?
		GOYES	FMgoto-
		LA(3)	MAXGOTO
		?A>C	X
		GOYES	FMcontoff	* Short goto - include it
FMgotoend	D0=D0+	3		* To long jump - include & end
		RTN
FMgoto-		C=-C	X
		C=-C	A
		AD0EX
		D0=A
		D0=D0+	3		* Skip goto
		A=A+C	A
		?A<B	A
		RTNYES			* target < start - done
		GOTO	FMcont		* Continue

FMnogoto

* Test if branch
		LC(3)	4		* GOC ?
		?A=C	P
		GOYES	FMgoc
		C=C+1	X
		?A=C	P		* GONC ?
		GOYES	FMgoc

* Test if GOYES
		GOSUBL	SKIPML
		?ST=0	sBRANCH
		GOYES	FMcont0		* Skipped ok
		D0=D0-	2
		A=DAT0	B
		GONC	FMbr

FMgoc		D0=D0+	1
		ASR	X		* A[B]=offset
FMbr		?A=0	B
		GOYES	FMbr2		* Just skip RTNC/RTNNC
		?ABIT=1	7		* Negative branch?
		GOYES	FMbr2		* Yep - skip it
		C=0	A
		C=A	B
FMcontoff	AD0EX			* Skip to target
		A=A+C	A
		AD0EX
		GOTO	FMcont		* Continue scan
FMcont4		D0=D0+	2
FMcont2		D0=D0+	2
FMcont0		GOTO	FMcont

* Here we have the instr after RTNYES/GOYES/GONC/GOC (backward!)
* Check if it is followed by a backward jump

FMbr2		D0=D0+	2		* Skip the branch
		A=DAT0	A		* Read the next instr
		LC(1)	4
		?A=C	P
		GOYES	FMbrbr		* Found GOC
		C=C+1	P
		?A#C	P
		GOYES	FMcont0		* Not GONC - continue
FMbrbr		D0=D0+	1
		ASR	X
		?ABIT=0	7		* Positive branch?
		GOYES	FMbr		* Yep - just continue
		D0=D0+	2		* Skip the offset field
		RTN			* And we're done

**********************************************************************

ENDCODE

**********************************************************************
* Description: Skip #n ml instructions at #start
* Interface:	( #start #n --> #end )
* Notes: Assumes GOYES is not the first instruction
**********************************************************************
NULLNAME SkipMLN
CODE
		GOSBVL	=POP2#		* A[A]=pc C[A]=N
		RSTK=C
		GOSBVL	=SAVPTR
		C=RSTK
		D=C	A		* D[A]=N
		D0=A			* D0=pc
		GOSUB	SKIPMLN		* Skip D[A] instructions
		AD0EX
		GOVLNG	=PUSH#ALOOP	* Push pc'

**SKIPMLN**************************************************************
* Skip N machine language instructions. Starts from a non GOYES/RTNYES
* GOYES is included as a part of the instruction.
* Sets sBRANCH if GOYES was skipped too (the last skipped instr)
* Input:	D0=pc	D[A]=N
* Output:	D0=pc'	A[A]=pc	C[A]=len	P=0 CC
* Uses:		A[A] C[A] D[A] C[S] D0 P CRU
* Stack:	2
**********************************************************************

SKIPMLN		D=D-1	A
		GOC	SMNdone		* None to skip
SMNlp		GOSUB	SKIPML		* D0=pc'
		?ST=0	sBRANCH
		GOYES	SMNnobr		* No test skipped
		D0=D0-	2		* Back to GOYES/RTNYES
		D=D-1	A
		GOC	SMNdone
		D0=D0+	2		* Now skip GOYES too
SMNnobr		D=D-1	A
		GONC	SMNlp		* Loop N times
SMNdone		RTNCC


**SKIPML**************************************************************
* Calculate lenght of machine language instruction.
* GOYES is included as a part of the instruction.
* Sets sBRANCH if GOYES was skipped too.
* Input:	D0=pc
* Output:	D0=pc'	A[A]=pc		C[A]=len	P=0 CC
* Uses:		A[A] C[A] C[S] D0 P CRY
* Stack:	1
**********************************************************************

bBRANCH		EQU 8		* OR code for branch instructions

SKIPML		ST=0	sBRANCH		* Assume no branch
		P=	0		* Make sure zero
		A=0	A
		A=DAT0	1
		GOSUB	SMdsptch
		CON(1)	0		* 0x: 2 or 4
		CON(1)	0		* 1x: 3,4,6,7
		CON(1)	2		* 2x: P= n
		CON(1)	0		* 3x: LCHEX
		CON(1)	3		* 4x: RTNC/GOC
		CON(1)	3		* 5x: RTNNC/GONC
		CON(1)	0		* 6x: GOTO / NOP5
		CON(1)	4		* 7x: GOSUB
		CON(1)	0		* 8x: 3,4,5,6,7
		CON(1)	5!(bBRANCH)	* 9x: ?XXX
		CON(1)	3		* Ax: mixed
		CON(1)	3		* Bx: mixed
		CON(1)	2		* Cx: add,sub
		CON(1)	2		* Dx: reg copy
		CON(1)	2		* Ex: add,sub etc
		CON(1)	2		* Fx: shift, neg

		A=A-1	P
		GONC	SMnot0x
		GOSUB	SMdsp1		* Instr is 0x
		NIBHEX	2222222222222242

SMnot0x		A=A-1	P
		GONC	SMnot1x
		GOSUB	SMdsp1		* Instr is 1x
		CON(1)	3		* 10x: r=ss
		CON(1)	3		* 11x: ss=r
		CON(1)	3		* 12x: rssEX
		CON(1)	3		* 13x: d=r d=rS rdEX rdXS
		CON(1)	3		* 14x: DATn=s A,B  s=DATn A,B
		CON(1)	4		* 15x: DATn=s fs  s=DATn fs
		CON(1)	3		* 16x: D0=D0+ d
		CON(1)	3		* 17x: D1=D1+ d
		CON(1)	3		* 18x: D0=D0- d
		CON(1)	4		* 19x: D0=(2) nn
		CON(1)	6		* 1Ax: D0=(4) nnnn
		CON(1)	7		* 1Bx: D0=(5) nnnnn
		CON(1)	3		* 1Cx: D1=D1- d
		CON(1)	4		* 1Dx: D1=(2) nn
		CON(1)	6		* 1Ex: D1=(4) nnnn
		CON(1)	7		* 1Fx: D1=(5) nnnnn

SMnot1x		A=A-1	P
		A=A-1	P
		GONC	SMnot3x

		D0=D0+	1		* LCHEX nn.n = 3cnn..n
		A=DAT0	1
		D0=D0-	1
		A=A+CON	A,3		* Add instr nib size, A[A]=len

SMload		CD0EX			*         C[A]=pc
		D0=C			* D0=pc
		C=C+A	A		*         C[A]=pc'
		CD0EX			* D0=pc'  C[A]=pc
		ACEX	A		* A[A]=pc C[A]=len
		RTNCC

SMnot3x		A=A-1	P
		A=A-1	P
		A=A-1	P
		GONC	SM8x

		D0=D0+	1		* GOTO / NOP5
		C=0	A
		C=DAT0	X
		D0=D0-	1
		LA(5)	4		* Offset for NOP5
		?A#C	X
		GOYES	SMload		* Lenght is 4
		A=A+1	X		* NOP5 lenght is 5
		GONC	SMload

SM8x		GOSUB	SMdsp1		* Instr is 8x
		CON(1)	0		* 80x: 3,4,5,7,n
		CON(1)	0		* 81x: 3,4,5,6
		CON(1)	3		* 82x: CLRHSN n
		CON(1)	5!(bBRANCH)	* 83x: ?HS=0 n
		CON(1)	3		* 84x: ST=0 n
		CON(1)	3		* 85x: ST=1 n
		CON(1)	5!(bBRANCH)	* 86x: ?ST=0 n
		CON(1)	5!(bBRANCH)	* 87x: ?ST=1 n
		CON(1)	5!(bBRANCH)	* 88x: ?P# n
		CON(1)	5!(bBRANCH)	* 89x: ?P= n
		CON(1)	5!(bBRANCH)	* 8Ax: ?XXX
		CON(1)	5!(bBRANCH)	* 8Bx: ?XXX
		CON(1)	6		* 8Cx: GOLONG
		CON(1)	7		* 8Dx: GOVLNG
		CON(1)	6		* 8Ex: GOSUBL
		CON(1)	7		* 8Fx: GOSBVL

		A=A-1	P
		GONC	SM81x
		GOSUB	SMdsp2		* Instr is 80x
		CON(1)	3		* 800x:	OUT=CS
		CON(1)	3		* 801x: OUT=C
		CON(1)	3		* 802x: A=IN
		CON(1)	3		* 803x: C=IN
		CON(1)	3		* 804x: UNCNFG
		CON(1)	3		* 805x: CONFIG
		CON(1)	3		* 806x: C=ID
		CON(1)	3		* 807x: SHUTDN
		CON(1)	0		* 808x: Misc
		CON(1)	3		* 809x: C+P+1
		CON(1)	3		* 80Ax: RESET
		CON(1)	3		* 80Bx: BUSCC
		CON(1)	4		* 80Cx: C=P d
		CON(1)	4		* 80Dx: P=C d
		CON(1)	3		* 80Ex: SREQ?
		CON(1)	4		* 80Fx: CPEX d

*		A=A-1	P
*		GONC	SM80Btx
SM808x		GOSUB	SMdsp3		* Instr is 808x
		CON(1)	4		* 8080x: INTON
		CON(1)	5		* 8081x: RSI
		CON(1)	0		* 8082x: LAHEX
		CON(1)	4		* 8083x: BUSCB
		CON(1)	5		* 8084x: ABIT=0 d
		CON(1)	5		* 8085x: ABIT=1 d
		CON(1)	7!(bBRANCH)	* 8086x: ?ABIT=0 d
		CON(1)	7!(bBRANCH)	* 8087x: ?ABIT=1 d
		CON(1)	5		* 8088x: CBIT=0 d
		CON(1)	5		* 8089x: CBIT=1 d
		CON(1)	7!(bBRANCH)	* 808Ax: ?CBIT=0 d
		CON(1)	7!(bBRANCH)	* 808Bx: ?CBIT=1 d
		CON(1)	4		* 808Cx: PC=(A)
		CON(1)	4		* 808Dx: BUSCD
		CON(1)	4		* 808Ex: PC=(C)
		CON(1)	4		* 808Fx: INTOFF

		D0=D0+	4		* Instr is LAHEX: 8082cn
		A=DAT0	1		* A[A]=sizenib
		D0=D0-	4
		A=A+CON	A,6		* Add instr nib size, A.A=len
		GOTO	SMload		* Use LCHEX calculations for rest

* Han:	new opcodes 80B type
SM80Btx		GOSUB	SMdsp4		* Instr is 80Btx
		CON(1)	0		* 80Bt0: RPL2, BEEP2, etc.
		CON(1)	5		* 80Bt1: OFF, GETTIME, etc.
		CON(1)	0		* 80Bt2: HS=1 fs or ARM code
		CON(1)	0		* 80Bt3: ?HS=1 fs if t=8 or ARM code
		CON(1)	5		* 80Bt4: none; assume len = 5
		CON(1)	5		* 80Bt5: REMON, REMOFF, etc.
		CON(1)	5		* 80Bt6: ACCESSSD, PORTTAG?
		CON(1)	6		* 80Bt7: SETFLD (80BF7h)
		CON(1)	7		* 80Bt8: r=r_s fs (new opcodes)
		CON(1)	5		* 80Bt9: none; assume len = 5
		CON(1)	5		* 80BtA: none; assume len = 5
		CON(1)	5		* 80BtB: none; assume len = 5
		CON(1)	5		* 80BtC: none; assume len = 5
		CON(1)	5		* 80BtD: none; assume len = 5
		CON(1)	5		* 80BtE: ARMSYS
		CON(1)	5		* 80BtF: ARMSAT

		A=A-1	P
		GONC	+
		GOTO	SMarmla5?	* check vs 80B10
+		GOTO	SMckHS		* handle both 80Bt2 and 80Bt3

SM81x		GOSUB	SMdsp2		* Instr is 81x
		CON(1)	3		* 810x: ASLC
		CON(1)	3		* 811x: BSLC
		CON(1)	3		* 812x: CSLC
		CON(1)	3		* 813x: DSLC
		CON(1)	3		* 814x: ASRC
		CON(1)	3		* 815x: BSRC
		CON(1)	3		* 816x: CSRC
		CON(1)	3		* 817x: DSRC
		CON(1)	6		* 818x: r=r+CON rfs,d
		CON(1)	5		* 819x: rSRB.F
		CON(1)	6		* 81Ax: ss=r.F r=ss.F rssEX.F
		CON(1)	0		* 81Bx: PC instructions
		CON(1)	3		* 81Cx: ASRB
		CON(1)	3		* 81Dx: BSRB
		CON(1)	3		* 81Ex: CSRB
		CON(1)	3		* 81Fx: DSRB

* Han:	81Bx len 4 if x=2,3,4,5,6,7
*	We have ARM overwrites for all other values of x
*	( see 81B dissassembler in dis/disinstr.a )
		GOSUB	SMdsp3
		NIBHEX	5044444465565555
		
		GOTO	SMarmla5?	* x=1 -> ARM_LOOP; skip 10	

SMdsp4		D0=D0+	4		* Fetch 5th & dispatch
		A=DAT0	1
		D0=D0-	4
		GONC	SMdsptch

SMdsp3		D0=D0+	3		* Fetch 3rd & dispatch
		A=DAT0	1
		D0=D0-	3
		GONC	SMdsptch

SMdsp2		D0=D0+	2		* Fetch 2nd & dispatch
		A=DAT0	1
		D0=D0-	2
		GONC	SMdsptch

SMdsp1		D0=D0+	1		* Fetch 1st nibble, then dispatch
		A=DAT0	1
		D0=D0-	1

SMdsptch	C=RSTK
		RSTK=C			* RSTK = ->tab
		C=C+A	A
		CD0EX
		C=DAT0	S		* C[S] = size
		CD0EX
		?C#0	S
		GOYES	SMgotit
		C=RSTK			* Continue at ->Tab + 16
		C=C+CON	A,16
		PC=C

SMgotit		C=RSTK			* Pop ->Tab
		C=0	A
		CSLC			* C[0] = len
		?CBIT=0	3		* Not branch?
		GOYES	SMgotnobr
		CBIT=0	3		* Clear the bit
		ST=1	sBRANCH		* Set branch
SMgotnobr	AD0EX
		D0=A			* D0=pc
		A=A+C	A		* A[A]=pc'
		AD0EX			* A[A]=pc D0=pc'
		RTNCC

* Han:	80B10 replaces LA(5) (?); treat like LA(5)
*	81B16 replaces Loop; also skip 10 nibbles
SMarmla5?
		D0=D0+	3
		A=DAT0	1
		D0=D0-	3
		A=A-1	P
		LC(1)	5
		?A#0	P		* not LA(5) overwrite?
		GOYES	+
		C=C+C	P
+		A=C	P
		GOTO	SMload
		
* Han:	handle 80Btx (x=2 or x=3) together
SMckHS		LC(1)	8		* check if 80B8x
		D0=D0+	3
		A=DAT0	1
		D0=D0-	3
		?C=A	P		* HS-type opcode?
		GOYES	+
		LC(1)	5		* nope, regular 80Btx
		A=C	P
		GONC	++
+		LC(1)	6		* have 80B8xh, x=2 or x=3 (branch)
		A=C	P
		D0=D0+	4
		C=DAT0	1
		D0=D0-	4
		?CBIT=0	0		* non-branch type?
		GOYES	++
		ST=1	sBRANCH
++		GOTO	SMload
**********************************************************************
ENDCODE
