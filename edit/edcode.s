**********************************************************************
*		Jazz String Editor ( Main Code )
**********************************************************************
* Entry:	( $ #pos $fstack $buff )
* Internally used:
*		R0,R1
*		R2[A] = ->fstack
*		R3    = lastkeytime	(can be used if sREPEAT is set!)
*		R4[A] = ->data
* Notes:	see gentries.a for flags
**********************************************************************

  CODE

FMTWIDTH	EQU 32	Format to 32 chars wide

		ABASE	0
CURSX		ALLOC	2	Cursor X position on screen
CURSY		ALLOC	1	Cursor Y position on screen
XOFF		ALLOC	5	Cursor X-scroll offset
WANTX		ALLOC	5	Wanted X-position
SAVEX		ALLOC	2	Cursor X Temporary save during input
SAVEY		ALLOC	1	Cursor Y Temporary save during input
SAVEPOS		ALLOC	5	Cursor POS Temporary save during input
LASTKEY		ALLOC	3	Last pressed key
EDARG		ALLOC	5	Repeat count
CCCHR		ALLOC	2	Current char in character browser
EDMODE		ALLOC	3	ST flag save
EDCNTRWID	ALLOC	1	Counter width. High bit set if decimal counter
EDCNTR		ALLOC	8	Counter
* Start/End addresses:
STR		ALLOC	5	Start of edit string
CUT		ALLOC	5	Start of CUT string	00000 = No cut
MEMEND		ALLOC	5	End of allocated memory
* Screen addresses:
CURPOS		ALLOC	5	Cursor position
TOPPOS		ALLOC	5	Position of 1st char on topmost displayed row
* Updatable, STR<=LOC<=STREND
* 00000 = none
UPDSTR		ALLOC	0	Start of updateable pointers
STREND		ALLOC	5	End of edit string
BLK		ALLOC	5	Start position of block
BLKEND		ALLOC	5	End position of block

MARKX		ALLOC	5	Last different cursor position
MARK0		ALLOC	5	Mark 0 position
MARK1		ALLOC	5	Mark 1 position
MARK2		ALLOC	5	Mark 2 position
MARK3		ALLOC	5	Mark 3 position
MARK4		ALLOC	5	Mark 4 position
MARK5		ALLOC	5	Mark 5 position
MARK6		ALLOC	5	Mark 6 position
MARK7		ALLOC	5	Mark 7 position
MARK8		ALLOC	5	Mark 8 position
MARK9		ALLOC	5	Mark 9 position
UPDEND		ALLOC	0	End of updateable pointers
* #94
FNDMAX		EQU 20		Max lenght of find string
FNDLEN		ALLOC	2	Lenght of find string
FND$		ALLOC	2*(FNDMAX)	Find string storage

INPMAX		EQU 20		Max lenght of input
INPOFF		ALLOC	2	Offset to input display on row (past prompt)
INPLEN		ALLOC	2	Input string lenght
INP$		ALLOC	2*(INPMAX)	Input string storage

SAVEX2		ALLOC	2	Cursor X Temporary save during ChrCat
SAVEY2		ALLOC	1	Cursor Y Temporary save during ChrCat
* #ED
bRECORD		EQU 0		Recording macro
bEXEC		EQU 1		Executing macro
MACMAX		EQU 50		Maximum number of macro keys
MACMODE		ALLOC	1	Macro mode storage
MACLEN		ALLOC	2	Number of macro keys
MACRUN		ALLOC	2	Run position in list of macro keys
MACKEYS		ALLOC	3*(MACMAX)
* #188
EDRSTK		ALLOC	4*5	Save for ml RSTK if needed
* #1AC
REPSTACK	ALLOC	4	Key repeat stack, 2 keys
EDSPEED		ALLOC	1	Speed flag (0/F = slow/fast)
EDKEYTIME	ALLOC	5	Save for =BounceTiming

		GOSBVL	=SAVPTR
		CLRST
		GOSUBL	InitDisp
		GOSUBL	InitBuf		Init variables, memory etc
* DOB subroutine restarts here
EdDobEntry	GOSBVL	=getBPOFF	Establish beep flag
		GOSUBL	InitClk		Initialize clock

EdLoop		GOSUBL	DispEd		Display screen
		GOSUBL	SetCurs		Show cursor position
		ST=1	sBLINK		Wait for key with blink
		GOSUBL	WaitKey
		GOSUBL	AdjustKey	Modify according to shift mode
		GOSUB	SaveKey		Save as last key
		GOSUB	SaveMacro	Save as macro key if necessary
		GOSUBL	SetMarkX	Save current position
		GOSUBL	ClrCurs		Cursor off

		ST=1	sREPEAT		Repeat enabled by default
argrep		ST=1	sDISPOK		Display is OK
		ST=0	sLINBAD		Line is OK
		GOSUB	DoEdKey		Do key

BackToEd	GOSUB	MacroRun?	Running a macro?
		GOC	nomrun		Nope
		GOSUBL	DispEd		Yes - show display
		GOSUB	RclMacKey	Get next key
		GOTO	argrep		And do it

nomrun		GOSUB	ArgRepeat?	Repeating a key?
		GOC	noarun		Nope
		GOSUBL	DispEd		Yes - show display
		GOSUB	RclKey		Recall the key
		GOSBVL	=chk_attn	Abort if ATTN pressed
		GONC	argrep
		GOSUB	BadEdKey	Beep for ATTN
noarun

BackToEdMain	GOSUBL	UpdMark0	Update last cursor position
		GOTO	EdLoop		Loop
**********************************************************************
* Clear key-repeat counter
**********************************************************************
EdClrArg	C=R4.F	A
		D1=C
		D1=(2)	EDARG
		C=0	A
		DAT1=C	A
		RTN
**********************************************************************
* Is key-repeat on?
**********************************************************************
ArgRepeat?	GOSUB	RclKey		Don't repeat modifiers
		?B=0	XS
		RTNYES
		D1=(2)	EDARG		Check if ARG <> 0
		C=DAT1	A
		C=C-1	A
		RTNC			ARG = 0, no repeat
		DAT1=C	A		Decrement
		?C=0	A		ARG = 1 means no repeat too
		RTNYES
		RTNCC
**********************************************************************
* Recall last pressed key
**********************************************************************
RclKey		C=R4.F	A
		D1=C
		D1=(2)	LASTKEY
		C=DAT1	X
		B=C	X
		RTN
**********************************************************************
* Save key as last pressed key (for repeat and macro save)
**********************************************************************
SaveKey		C=R4.F	A
		D1=C
		D1=(2)	LASTKEY
		C=B	X
		DAT1=C	X
		RTN
**********************************************************************
* Is a macro sequence running?
**********************************************************************
MacroRun?	C=R4.F	A
		D1=C
		D1=(2)	MACMODE
		C=DAT1	1
		?CBIT=0	bEXEC
		RTNYES			Not running
		D1=(2)	MACLEN		Not running if last key in sequence
		A=DAT1	B		was just executed
		D1=(2)	MACRUN
		C=DAT1	B
		?C>A	B
		GOYES	macrunend
		RTNCC			Running!
macrunend	D1=(2)	MACMODE		last key was just done, finish
		C=DAT1	B		macro run
		CBIT=0	bEXEC
		DAT1=C	1
		RTNSC
**********************************************************************
* Get next macro key in sequence, assuming macro run is on
**********************************************************************
RclMacKey	C=R4.F	A
		D1=C
		D1=(2)	MACRUN
		C=0	A
		C=DAT1	B
		C=C+1	B		run position++
		DAT1=C	B
		D1=(2)	MACKEYS		Fetch the key from sequence
		AD1EX
		A=A+C	A
		A=A+C	A
		A=A+C	A
		AD1EX
		D1=D1-	6		Counteract the increment
		A=DAT1	X
		B=A	X		B[A] = key
		RTN
**********************************************************************
* Clear macro sequence
**********************************************************************
EdClrMac	C=R4.F	A
		D1=C
		D1=(2)	MACMODE
		C=DAT1	1
		CBIT=0	bEXEC
		DAT1=C	1
		?CBIT=0	bRECORD
		RTNYES			Not recording, no need to clear
		CBIT=0	bRECORD
		DAT1=C	1
		D1=(2)	MACLEN		Error occurred during record,
		C=0	A		can't have partial saves
		DAT1=C	B
* Show warning
		RTN
**********************************************************************
* Add a new key to macro sequence
**********************************************************************
SaveMacro	?B=0	XS		Ignore modifiers!
		RTNYES
		C=R4.F	A
		D1=C
		D1=(2)	MACMODE
		C=DAT1	1
		?CBIT=0	bRECORD
		RTNYES			Record off - no save
		D1=(2)	MACLEN		Check for overflow
		A=0	A
		A=DAT1	B
		LC(2)	MACMAX
		?A>=C	B
		GOYES	macsaver	Overflow!
		A=A+1	B
		DAT1=A	B		lenght++
		D1=(2)	MACKEYS		Save key to it's position in sequence
		CD1EX
		C=C+A	A
		C=C+A	A
		C=C+A	A
		CD1EX
		D1=D1-	3
		C=B	X
		DAT1=C	X
		RTNCC	
macsaver	A=0	A		Clear macro modes due to error
		DAT1=A	B		Lenght = 0
		D1=(2)	MACMODE
		DAT1=A	1		RECORD = 0
* Show warning
		RTN
**********************************************************************
* Key dispatchee to start macro execution
**********************************************************************
EdExecMac	C=R4.F	A
		D1=C
		D0=C
		D0=(2)	MACLEN
		A=DAT0	B
		?A=0	B
		GOYES	exemer		No macro exists - error
		D1=(2)	MACMODE
		C=DAT1	1
		?CBIT=0	bRECORD
		GOYES	exmac5		Not recording - ok to exec
		A=A-1	B		Terminate recording first
		DAT0=A	B		lenght--
		?A=0	B
		GOYES	exemer
		CBIT=0	bRECORD		Record off
exmac5		CBIT=1	bEXEC		Exec on
		DAT1=C	1
		D1=(2)	MACRUN		Start from first key in sequence
		LC(2)	1
		DAT1=C	B
		RTN
exemer		GOTO	BadEdKey
**********************************************************************
* Start recording new macro
**********************************************************************
EdStartMac	ST=0	sREPEAT
		C=R4.F	A
		D1=C
		D1=(2)	MACMODE
		C=DAT1	1
		?CBIT=1	bEXEC
		GOYES	macster
		?CBIT=1	bRECORD
		GOYES	macster
		CBIT=1	bRECORD
		DAT1=C	1
		C=0	A
		D1=(2)	MACLEN
		DAT1=C	B
		RTN
macster		GOTO	BadEdKey
**********************************************************************
* Terminate macro record
**********************************************************************
EdEndMac	ST=0	sREPEAT
		C=R4.F	A
		D1=C
		D1=(2)	MACMODE
		C=DAT1	1
		?CBIT=0	bRECORD
		GOYES	macener
		?CBIT=1	bEXEC
		GOYES	macener
		CBIT=0	bRECORD
		DAT1=C	1
		D1=(2)	MACLEN	Pop end-key
		C=DAT1	B
		C=C-1	B
		GOC	macener
		DAT1=C	B
		RTN
macener		GOTO	BadEdKey
**********************************************************************
* Execute main loop key
**********************************************************************
DoEdKey		GOSUBL	EdStrKey?	String keys first so
		GONC	+		other programs can use EdChrKey?
		GOLONG	DoEdStrKey
+		GOSUBL	EdChrKey?
		GONC	+
		GOLONG	DoEdChrKey
+		GOSUBL	DispatchKey:

EDKEY	MACRO
	CON(3)	$1
	CON(4)	($2)-(*)
EDKEY	ENDM

* Shift modes

*NS	EQU #100
*LS	EQU #200
*RS	EQU #300
*ANS	EQU #400
*ALS	EQU #500
*ARS	EQU #600


EdKeyTab
* Han:	move the more common keys up top for quick dispatch

		EDKEY	(LSCODE),EdModLS
		EDKEY	(RSCODE),EdModRS
		EDKEY	(32)+(NS),AlphaOn
		EDKEY	(32)+(ANS),AlphaOff
		EDKEY	(32)+(LS),TogCase
		EDKEY	(32)+(ALS),TogCase
		EDKEY	(32)+(RS),TogOver
		EDKEY	(32)+(ARS),TogOver

		EDKEY	(UPCODE)+(NS),EdUp
		EDKEY	(UPCODE)+(LS),EdPgUp
		EDKEY	(UPCODE)+(RS),EdFarUp
		EDKEY	(UPCODE)+(ANS),EdUp
		EDKEY	(UPCODE)+(ALS),EdPgUp
		EDKEY	(UPCODE)+(ARS),EdFarUp
		EDKEY	(LEFTCODE)+(NS),EdLt
		EDKEY	(LEFTCODE)+(LS),EdWordLt
		EDKEY	(LEFTCODE)+(RS),EdFarLt
		EDKEY	(LEFTCODE)+(ANS),EdLt
		EDKEY	(LEFTCODE)+(ALS),EdWordLt
		EDKEY	(LEFTCODE)+(ARS),EdFarLt
		EDKEY	(DOWNCODE)+(NS),EdDn
		EDKEY	(DOWNCODE)+(LS),EdPgDn
		EDKEY	(DOWNCODE)+(RS),EdFarDn
		EDKEY	(DOWNCODE)+(ANS),EdDn
		EDKEY	(DOWNCODE)+(ALS),EdPgDn
		EDKEY	(DOWNCODE)+(ARS),EdFarDn
		EDKEY	(RIGHTCODE)+(NS),EdRt
		EDKEY	(RIGHTCODE)+(LS),EdWordRt
		EDKEY	(RIGHTCODE)+(RS),EdFarRt
		EDKEY	(RIGHTCODE)+(ANS),EdRt
		EDKEY	(RIGHTCODE)+(ALS),EdWordRt
		EDKEY	(RIGHTCODE)+(ARS),EdFarRt

		EDKEY	(TANCODE)+(NS),EdDel
		EDKEY	(TANCODE)+(LS),EdDelWrdLt
		EDKEY	(TANCODE)+(RS),EdDelWrdRt

		EDKEY	(BACKCODE)+(NS),EdBS
		EDKEY	(BACKCODE)+(ANS),EdBS
		EDKEY	(BACKCODE)+(LS),EdDelLine
		EDKEY	(BACKCODE)+(ALS),EdDelLine
		EDKEY	(BACKCODE)+(RS),EdDelRt
		EDKEY	(BACKCODE)+(ARS),EdDelRt

*		set begin/end of block
		EDKEY	(APPSCODE)+(RS),SetBlk
		EDKEY	(APPSCODE)+(ARS),SetBlk
		EDKEY	(MODECODE)+(RS),SetBlkEnd
		EDKEY	(MODECODE)+(ARS),SetBlkEnd

*		copy/paste
		EDKEY	(NXTCODE)+(RS),CopyBlk
		EDKEY	(NXTCODE)+(ARS),CopyBlk
		EDKEY	(VARCODE)+(RS),CopyBlk
		EDKEY	(VARCODE)+(ARS),CopyBlk

*		cut (and copy to clibboard)
		EDKEY	(STOCODE)+(RS),DelBlk
		EDKEY	(STOCODE)+(ARS),DelBlk

*		set block from cursor to start/end
		EDKEY	(APPSCODE)+(LS),SetBlkUp
		EDKEY	(MODECODE)+(LS),SetBlkDown

*		delete and do not save to clipboard
		EDKEY	(Sfkey4)+(NS),EdDelNoClip

*		delete everything except what is selected
		EDKEY	(VARCODE)+(LS),EdDelNoBlk

*		swap current buffer with clipboard
		EDKEY	(STOCODE)+(NS),EdSwapClip

		EDKEY	(ENTERCODE)+(NS),EdExit
		EDKEY	(ENTERCODE)+(ANS),EdIndNL
		EDKEY	(ENTERCODE)+(LS),DoEdAss

*		special indented environments
		EDKEY	(PCODE)+(ALS),EdIndPrg
		EDKEY	(PLUSCODE)+(ALS),EdIndList
		EDKEY	(PLUSCODE)+(ARS),EdIndRpl
		EDKEY	(TIMESCODE)+(ALS),EdIndArr
		EDKEY	(tickCODE)+(LS),EdIndMat
		EDKEY	(tickCODE)+(RS),EdIndSym

		EDKEY	(EVALCODE)+(RS),EdChrCat
		EDKEY	(EVALCODE)+(LS),EdInputChr

		EDKEY	(SYMBCODE)+(NS),EdECat
		EDKEY	(SYMBCODE)+(RS),DoEdDob
		EDKEY	(SYMBCODE)+(LS),DoEdDobAdr
		EDKEY	(EVALCODE)+(NS),EdFill
			
		EDKEY	(INVCODE)+(NS),EdReverse
		EDKEY	(APPSCODE)+(NS),EdToHex
		EDKEY	(VARCODE)+(NS),EdToAsc

		EDKEY	(=0CODE)+(RS),GoMark0
		EDKEY	(=1CODE)+(LS),SetMark1
		EDKEY	(=1CODE)+(RS),GoMark1
		EDKEY	(=2CODE)+(LS),SetMark2
		EDKEY	(=2CODE)+(RS),GoMark2
		EDKEY	(=3CODE)+(LS),SetMark3
		EDKEY	(=3CODE)+(RS),GoMark3
		EDKEY	(=4CODE)+(LS),SetMark4
		EDKEY	(=4CODE)+(RS),GoMark4
		EDKEY	(=5CODE)+(LS),SetMark5
		EDKEY	(=5CODE)+(RS),GoMark5
		EDKEY	(=6CODE)+(LS),SetMark6
		EDKEY	(=6CODE)+(RS),GoMark6
		EDKEY	(=7CODE)+(LS),SetMark7
		EDKEY	(=7CODE)+(RS),GoMark7
		EDKEY	(=8CODE)+(LS),SetMark8
		EDKEY	(=8CODE)+(RS),GoMark8
		EDKEY	(=9CODE)+(LS),SetMark9
		EDKEY	(=9CODE)+(RS),GoMark9

		EDKEY	(XCODE)+(NS),EdInputRow
		EDKEY	(DIVCODE)+(LS),EdInputPos
		EDKEY	(DIVCODE)+(RS),EdInputArg
		EDKEY	(TOOLCODE)+(NS),EdExecMac
		EDKEY	(TOOLCODE)+(LS),EdStartMac
		EDKEY	(TOOLCODE)+(RS),EdEndMac
		EDKEY	(Sfkey1)+(NS),EdInitCntr
		EDKEY	(Sfkey2)+(NS),EdOutCntr

		EDKEY	(MODECODE)+(NS),EdStatus

		EDKEY	(Sfkey6)+(NS),EdFind
		EDKEY	(Sfkey6)+(RS),EdRepl
		EDKEY	(Sfkey6)+(LS),EdRepl?
		EDKEY	(NXTCODE)+(NS),EdFindNext
		EDKEY	(NXTCODE)+(LS),EdFindPrev
		EDKEY	(Sfkey5)+(NS),EdFindDelim
		EDKEY	(Sfkey5)+(RS),EdReplSPos
		EDKEY	(Sfkey5)+(LS),EdRepl?SPos

f_formkey	IF fEDFORMAT
		EDKEY	(Sfkey3)+(NS),EdFormat
f_formkey	ENDIF

		EDKEY	(HISTCODE)+(NS),DoEdStk
		EDKEY	(HISTCODE)+(LS),PushStk1
		EDKEY	(STOCODE)+(LS),RclStk1

		EDKEY	(EEXCODE)+(NS),TogBeep
		EDKEY	(CHSCODE)+(NS),TogSpeed
		EDKEY	(ONCODE)+(NS),EdON
		EDKEY	(ONCODE)+(RS),EdOFF

		EDKEY	0,BadEdKey
**********************************************************************
* Dispatch from keytable in return stack
**********************************************************************
DispatchKey:	C=RSTK
		D0=C
DispatchKey	C=R4.F	A
		D1=C
edkeylp		A=DAT0	X
		D0=D0+	7
		?A=0	X
		GOYES	gotkey4
		?A#B	X
		GOYES	edkeylp
gotkey4		D0=D0-	4
		A=0	A
		A=DAT0	4
		?ABIT=0	15
		GOYES	gotPkey4
		P=	4-1
		A=-A	WP
		A=-A	A
		P=	0
gotPkey4	CD0EX
		A=A+C	A
		PC=A	
**********************************************************************
* Bad key - error
**********************************************************************
BadEdKey	ST=0	sREPEAT		No repeat
		GOSUB	EdClrArg	No repeat count
		GOSUB	EdClrMac	No macro save
ErrBeep		?ST=1	sBPOFF		Fart
		RTNYES
		LC(2)	#FB
		GOVLNG	=RCKBp

**********************************************************************
* Modifier keys
**********************************************************************

*	EdModA		GOSUB	GetAnns
*			?ABIT=1	6
*			GOYES	clrmoda
*			ABIT=1	6
*			GONC	edmodok
*	clrmoda		ABIT=0	6
*			GOC	edmodok

EdModLS		GOSUB	GetAnns
		?ABIT=1	4
		GOYES	clrmodls
		ABIT=1	4
		ABIT=0	5
		GONC	edmodok
clrmodls	ABIT=0	4
		GOC	edmodok

EdModRS		GOSUB	GetAnns
		?ABIT=1	5
		GOYES	clrmodrs
		ABIT=1	5
		ABIT=0	4
		GONC	edmodok
clrmodrs
		ABIT=0	5
* Note: REPEAT IS ENABLED! This allows changing between f.ex up and up+LS
edmodok		ST=1	sREPEAT
		DAT0=A	B
		RTN

GetAnns		D0=(5)	=ANNUNCIATORS
*		D0=(5)	=aANNUNCIATORS
*		A=DAT0	A
*		D0=A
		A=DAT0	B
		RTN
**********************************************************************
* Set alpha annunciator on
**********************************************************************
AlphaOn		GOSUB	GetAnns
		ABIT=1	6
		DAT0=A	B
		D0=(5)	=ANNCTRL
		A=DAT0	B
		ABIT=1	2
		DAT0=A	B
		RTN
**********************************************************************
* Cleat alpha annunciator
**********************************************************************
AlphaOff	GOSUB	GetAnns
		ABIT=0	6
		DAT0=A	B
		D0=(5)	=ANNCTRL
		A=DAT0	B
		ABIT=0	2
		DAT0=A	B
		RTN
**********************************************************************
* Show editor status page
**********************************************************************
EdStatus	GOSUBL	EdClrArg	Don't repeat again and again..
		GOSUBL	ClrDisp		No room for text

		GOSUBL	GetDispRow1
		D1=D1+	10
		GOSUBL	Disp:Ret
		CSTRING	'Editor Status'
		GOSUBL	GetText
		B=C	A
		P=	3-1
		GOSUBL	DispRow:Ret
		CSTRING	'Text size   : '
		GOSUBL	Disp2Dec6B
		D1=D1+	3
		GOSUB	DispINS

		GOSUBL	GetCut
		B=C	A
		A=R4	A
		LC(5)	EDSPEED
		A=A+C	A
		D1=A
		C=DAT1	S			Speed flag
		D=C	S
		P=	4-1
		GOSUBL	DispRow:Ret
		CSTRING	'Clip size   : '
		GOSUBL	Disp2Dec6B
		D1=D1+	3
		GOSUB	DispFAST

		GOSUBL	GetFree
		B=C	A
		P=	5-1
		GOSUBL	DispRow:Ret
		CSTRING	'Free memory : '
		GOSUBL	Disp2Dec6B
		D1=D1+	3
		GOSUB	DispCASE

		GOSUBL	GetWork
		B=C	A
		P=	6-1
		GOSUBL	DispRow:Ret
		CSTRING	'Work memory : '
		GOSUBL	Disp2Dec6B
		D1=D1+	3
		GOSUB	DispBEEP

		GOSUBL	GetCurPos
		D1=(2)	STR
		A=DAT1	A
		C=C-A	A
		B=C	A
		P=	8-1
		GOSUBL	DispRow:Ret
		CSTRING	'Cursor pos  : '
		GOSUBL	Disp2Dec6B

		P=	9-1
		GOSUBL	DispRow:Ret
		CSTRING	'Cursor X    : '
		C=R4.F	A
		D0=C
		D0=(2)	CURSX
		C=0	A
		C=DAT0	B
		D0=(2)	XOFF
		A=DAT0	A
		C=C+A	A
		C=C+1	A
		GOSUBL	DispDec6

		P=	10-1
		GOSUBL	DispRow:Ret
		CSTRING	'Cursor line : '
		C=R4.F	A
		D0=C
		D0=(2)	STR
		A=DAT0	A
		D0=(2)	CURPOS
		C=DAT0	A
		D0=A
		C=C-A	A
		CSRB.F	A
		B=C	A
		D=0	A
		LCASC	'\n'
dsplinlp	B=B-1	A
		GOC	dsplin10
		A=DAT0	B
		D0=D0+	2
		?A#C	B
		GOYES	dsplinlp
		D=D+1	A
		GONC	dsplinlp
dsplin10	D=D+1	A
		C=D	A
		GOSUBL	DispDec6

		P=	12-1
		GOSUBL	DispRow:Ret
		CSTRING	'Fstack lvl  : '
		C=R2.F	A
		CD0EX
		C=0	A
		C=DAT0	B
		C=C+1	A
		GOSUBL	DispDec6
		
		P=	13-1
		GOSUBL	DispRow:Ret
		CSTRING	'Bank2 view  : '
		C=R2.F	A
		CD0EX
		C=0	A
		C=DAT0	B
		D0=D0+	2
		AD0EX
		C=C+A	A
		CD0EX
		C=0	A
		C=DAT0	1
		GOSUBL	DispDec6

		
		ST=0	sREPEAT
		ST=0	sBLINK
		GOSUBL	WaitKey
		GOSUBL	ClrDisp
		ST=0	sDISPOK
		RTN

DispINS		?ST=1	sOVERWR
		GOYES	dspins10
		GOSUBL	Disp:Ret
		CSTRING	'Insert'
		RTN
dspins10	GOSUBL	Disp:Ret
		CSTRING	'Overwrite'
		RTN

DispFAST	GOSUBL	Disp:Ret
		CSTRING	'Fast: '
		?D#0	S
		GOYES	dspfast10
dspfast10	GOTO	DispON/OFF

DispCASE	GOSUBL	Disp:Ret
		CSTRING	'Case: '
		?ST=1	sLOWCS
		GOYES	dspcase10
dspcase10	GOTO	DispON/OFF

DispBEEP	GOSUBL	Disp:Ret
		CSTRING	'Beep: '
		?ST=0	sBPOFF
		GOYES	dspbeep10
dspbeep10
*		GOTO	DispON/OFF

DispON/OFF	GONC	dspoff
		GOSUBL	Disp:Ret
		CSTRING	'ON'
		RTN
dspoff		GOSUBL	Disp:Ret
		CSTRING	'OFF'
		RTN
**********************************************************************
* Exit ED
**********************************************************************
EdExit		GOSUB	ShrinkEd
		GOSUB	EdResetBTime
		GOVLNG	=GPPushFLoop
**********************************************************************
* Reset BounceTiming
**********************************************************************		
EdResetBTime
		A=R4.F	A		restore keytime
		LC(5)	EDKEYTIME
		A=A+C	A
		D0=A
		C=DAT0	A
		D0=(5)	=BounceTiming
		DAT0=C	A
		NIBHEX	80BF2		unsupported keytime opcode
		RTN		
**********************************************************************
* Shrink edit buffer
**********************************************************************
ShrinkEd	GOSUBL	GetCutFree
		D0=A
		B=A	A
		A=DAT0	A
		A=A-C	A	Fix link
		DAT0=A	A

		D1=(2)	STR
		A=DAT1	A
		D0=A
		D0=D0-	5
		A=DAT0	A	Fix $len
		A=A-C	A
		DAT0=A	A

		A=B	A
		GOVLNG	=MOVERSD
**********************************************************************
* Pass control to call an EC sub program
**********************************************************************
EdFill		ST=1	sFILL
		GOTO	+	
EdECat		ST=0	sFILL

+		GOSUBL	EdThisWord	R0[A]=chars
		GONC	EdCatThisWord   A word is found

		D1=(2)	STR		Not At start of buf ?
		C=DAT1	A
		AD0EX
		D0=A
		?A<=C	A
		GOYES	EdCatpsh$0	yes -> push NULL$

		D0=D0-	2		At end of word ?
		A=DAT0	B
		LCASC	' '
		?A<=C	B
		GOYES	EdCatpsh$0	No -> push NULL$
	
		GOSUBL	SafeThisWord	R0[A]=chars
		GONC	EdCatThisWord   Use just-prev word

EdCatpsh$0 	?ST=0	sFILL
		GOYES	+
		GOSUB	ErrBeep
		D=0	A
		D=D-1	A
-		D=D-1	X
		GONC	-	
		GOTO	BadEdKey

+		C=0	A		push NULL$
		R0=C.F	A
		GOTO	EdCatpsh$	
		

* Check word for probable errors
EdCatThisWord	B=C	A		Word lenght
*		LC(5)	15
		LC(5)	25		longest is 24 chars; plus "="
		?B<=C	A
		GOYES	+		Length OK
		D1=(2)	CURPOS		 else goto end of this word ...
		CD0EX
		A=B	A
		A=A+A	A
		C=C+A	A
		DAT1=C	A
		GONC	EdCatpsh$0	and push NULL$
	
+		A=DAT0	B		Is wrd starting with '='
		LCASC	'='
		?A#C	B
		GOYES	+
		D0=D0+	2		yes -> don't take care of it
		C=R0
		C=C-1	A
		R0=C
+		AD0EX
		R1=A.F	A		->entry
		D1=(2)	CURPOS		Use start of word as new CURPOS
		DAT1=A	A
EdCatpsh$	GOSUB	ShrinkEd
		C=R0	A
		R2=C	A		chars
		GOSBVL	=MAKE$
		C=R1.F	A		->word
		CD0EX
		CD1EX
		C=R2			chars
		C=C+C	A
		GOSBVL	=MOVEDOWN	->word

		A=R0	A
		GOSBVL	=GPPushA	push word
		GOSBVL	=SAVPTR

		C=0	A
		?ST=0	sFILL
		GOYES 	+
		C=C+1	A		C[0]=1 if Fill mode
+		GOSUB	GetAnns
		?ABIT=0	6
		GOYES	+
		C=C+1	XS		C[XS]=1 if alpha mode
+		R0=C
		GOSBVL	=PUSH#		push submode and alpha mode
		GOSBVL	=SAVPTR
		GOSUB	AlphaOff

		GOSUB	EdResetBTime	Reset BounceTiming
		
		GOSUBL	GetCurPos	Push curpos and dobmode, exit
		D1=(2)	STR
		A=DAT1	A
		C=C-A	A
		CSRB.F	A
		R0=C	A		curpos
		LC(5)	edEC
		R1=C	A		mode
		GOSBVL	=PUSH2#
		GOVLNG	=PushTLoop
	
**********************************************************************
* Pass control to STK system rpl sub program
**********************************************************************
DoEdStk		GOSUB	ShrinkEd
		GOSUB	EdResetBTime	Reset BounceTiming
		GOSUBL	GetCurPos	Push mode in R1 and curpos in R0
		D1=(2)	STR
		A=DAT1	A
		C=C-A	A
		CSRB.F	A
		R0=C			curpos
		LC(5)	edSTK
		R1=C			mode
		GOSBVL	=PUSH2#
		GOVLNG	=PushTLoop
**********************************************************************
* Pass control to ASS system rpl sub program
**********************************************************************
DoEdAss		GOSUB	ShrinkEd
		GOSUB	EdResetBTime	Reset BounceTiming
		LC(5)	edASS
		R0=C
		GOVLNG	=Push#TLoop
**********************************************************************
* Pass control to DOB system rpl sub program
**********************************************************************
* We can safely use the sLAM status flag to determine whether to push
* the entry address, or the address to which the entry points since
* the subroutines using sLAM and sDOBADR are mutually exclusive.
**********************************************************************
EdRstFstack
		C=R2
		D1=C
		C=DAT1	B
		C=C-1	B
		DAT1=C	B
		GOTO	BadEdKey

EdCkFstack
		C=R2			about to call Dob; check fstack
		D1=C
		C=0	A
		C=DAT1	B
		C=C+1	B
		GONC	+
		C=C-1	B
		RTNSC

+		DAT1=C	B		we're ok; stack_count++
		D1=D1+	2		skip stack size
		AD1EX
		C=C+A	A
		CD1EX			go to corresponding nibble
*		D1=D1-	1		assume same rom view
*		C=DAT1	1		copy current view
*		D1=D1+	1
		C=0	A
		LC(1)	1		assume default rom view
		DAT1=C	1		save as new view
		RTNCC
		
sDOBADR		EQU	sLAM

DoEdDobAdr	ST=1	sDOBADR
		GOTO	DoEdDob+

DoEdDob		ST=0	sDOBADR

DoEdDob+	GOSUB	EdCkFstack
		GOC	edoberr1
		GOSUBL	EdThisWord	R0[A]=chars
		GONC	+
edoberr1	GOTO	EdRstFstack	BadEdKey

* Check word for probable errors
+		B=C	A		Word lenght
		LC(5)	15
		?B>C	A
		GOYES	edoberr1	Too long word for sure

		GOSUB	+
		ASC(1)	'ID'
		REL(3)	EDdobIDNT
		ASC(1)	'PTR'
		REL(3)	EDdobPTR
		ASC(1)	'GROB'
		REL(3)	EDvvGROB
		ASC(1)	'ROMPTR'
		REL(3)	EDdobROMPTR
		ASC(1)	'FPTR'
		REL(3)	EDdobFPTR
		ASC(1)	'FPTR2'
		REL(3)	EDdobFPTR2
		ASC(1)	'INCLOB'
		REL(3)	EDdobINCLOB
		ASC(1)	'INCLUDE'
		REL(3)	EDdobINCLUDE
		ASC(1)	'ROMPTR2'
		REL(3)	EDdobRPTR2
		CON(1)	0
		REL(3)	EDdobNORMAL
+		C=RSTK
		D1=C
		C=DAT0	W
		D=C	W			word to match
-		P=	0	<-------+
		C=DAT1	B		|
		?C=0	P		|
		GOYES	+	---+	|	Last entry, default dob
		C=C+C	A	   |	|
		P=C	0	   |	|
		P=P-1		   |	|	2*chars-1
		C=0	A	   |	|
		C=DAT1	1	   |	|	chars
		D1=D1+	1	   |	|
		A=DAT1	WP	   |	|
		CD1EX		   |	|
		C+P+1		   |	|
		CD1EX		   |	|
		D1=D1+	3	   |	|	->next slot
		?C#B	B	   |	|
		GOYES	-	---|----+	Different lenght - next slot
		C=A	WP	   |	|
		?C#D	WP	   |	|
		GOYES	-	---|----+	No match - next slot
		D1=D1-	4	   |
+		D1=D1+	1	<--+
		P=	0
		A=0	A
		A=DAT1	X
		CD1EX
		A=A+C	A			CC always (forward offsets)
		PC=A

* Tokens producing IDNT or LAM DOB

EDdobINCLUDE	ST=1	sLAM
		GONC	EDdobname
EDdobIDNT
EDdobINCLOB	ST=0	sLAM

EDdobname	GOSUBL	EdNextWord
		GOC	edoberr2
		AD0EX
		R1=A			->name
		LA(5)	#100
		?C>=A	A
		GOYES	edoberr2	Too long id
		GOSUB	ShrinkEd
		C=R0			chars
		C=C+C	A		nibbles
		C=C+CON	A,7		+header
		GOSBVL	=GETTEMP
		A=R1			->name
		AD0EX			D0 = ->name
		D1=A			D1 = ->id
		AR0EX			A[A]=chars  R0[A] = ->id
		LC(5)	=DOIDNT
		?ST=0	sLAM
		GOYES	+
		LC(5)	=DOLAM
+		DAT1=C	A
		D1=D1+	5
		DAT1=A	B
		D1=D1+	2
		C=A	A
		C=C+C	A		nibbles
		GOSBVL	=MOVEDOWN
		GOTO	EdPushDobOb		

edoberr2	GOTO	EdRstFstack	BadEdKey

* ROMPTR token DOB

EDdobROMPTR	GOSUB	DobNextParse
		GOC	edoberr2
		LC(5)	#FFF
		?A>C	A
		GOYES	edoberr2
		R3=A	A		romid
		GOSUB	DobNextParse
		GOC	edoberr2
		LC(5)	#FFF
		?A>C	A
		GOYES	edoberr2
		R1=A	A		rompnum
		GOSUB	ShrinkEd
		LC(5)	5+6
		GOSBVL	=GETTEMP
		AD0EX
		R0=A
		D0=A
		LC(5)	=DOROMP
		DAT0=C	A
		D0=D0+	5
		A=R3	A		romid
		DAT0=A	X
		D0=D0+	3
		A=R1	A		rompnum
		DAT0=A	X
		GOTO	EdPushDobOb		

EDdobFPTR	GOSUB	DobNextParse
		GOC	edoberr2
		LC(5)	#F
		?A>C	A
		GOYES	edoberr2
		R3=A	A		fptr id

		C=A	A		save a copy in fstack
		CPEX	0
		C=R2
		D1=C
		C=0	A
		C=DAT1	B
		D1=D1+	2
		AD1EX
		C=C+A	A
		CD1EX
		CPEX	0
		P=	0
		DAT1=C	1		
		
		GOSUB	DobNextParse
		GOC	edoberr3
		LC(5)	#FFFF
		?A>C	A
		GOYES	edoberr3
		R1=A	A		fptr cmd
		GOSUB	ShrinkEd
		LC(5)	5+3+4
		GOSBVL	=GETTEMP
		AD0EX
		R0=A
		D0=A
		LC(5)	=DOFLASHP
		DAT0=C	A
		D0=D0+	5
		A=R3	A		fptr id
		DAT0=A	X
		D0=D0+	3
		A=R1	A		fptr cmd
		DAT0=A	4
		GOTO	EdPushDobOb

* PTR token DOB
EDdobPTR	GOSUB	DobNextParse	A[A] = hex
		GONC	EDdobADDR
edoberr3	GOTO	EdRstFstack	BadEdKey

* Handle non-special words, eg "#hhhhh" "Lhhhhh" and "entry"

EDdobNORMAL	AD0EX
		R1=A	A		->name
		AD0EX
		A=DAT0	B
		LCASC	'#'		#hhhhh
		?A=C	B
		GOYES	+
		LCASC	'L'		Lhhhhh
		?A#C	B
		GOYES	EDdobENTRY
* Check hex entry address
+		C=R0	A		chars
		C=C-1	A
		GOC	edoberr3	No entry is plain "#"
		D0=D0+	2		Skip #
		GOSUB	DobHexParse
		GOC	EDdobENTRY
* Got good address, use it instead of name
EDdobADDR	?ST=0	sDOBADR
		GOYES	+
		AD0EX
		A=DAT0	A
+		R0=A	A		->addr instead of ->word
		GOSUB	ShrinkEd
		GOSBVL	=PUSH#		address
		GOTO	eddobpsh

EDdobFPTR2	GOSUBL	SafeNextWord
		GOC	edoberr4
		A=DAT0	B
		LCASC	'^'
		?A=C	B
		GOYES	EDdobENTRY.1
edoberr4	GOTO	EdRstFstack

EDdobRPTR2	GOSUBL	SafeNextWord
		GOC	edoberr4
		A=DAT0	B
		LCASC	'~'
		?A=C	B
		GOYES	EDdobENTRY.1
		GONC	edoberr4

* Got entry name, check it
EDdobENTRY	A=R1	A
		D0=A			->name
		A=DAT0	B
		LCASC	'='
		?A#C	B
		GOYES	EDdobENTRY.2
		D0=D0+	2
		C=R0
		C=C-1	A
		R0=C
EDdobENTRY.1	?C=0	A
		GOYES	edoberr4	Null entry
		AD0EX
		R1=A	A		->entry
EDdobENTRY.2	GOSUB	ShrinkEd
		C=R0	A
		R2=C	A		chars
		GOSBVL	=MAKE$
		C=R1.F	A		->word
		CD0EX
		CD1EX
		C=R2			chars
		C=C+C	A
		GOSBVL	=MOVEDOWN	->word

EdPushDobOb	A=R0	A
		GOSBVL	=GPPushA

eddobpsh	GOSBVL	=SAVPTR
		GOSUB	EdResetBTime	Reset BounceTiming
		GOSUBL	GetCurPos	Push curpos and dobmode, exit
		D1=(2)	STR
		A=DAT1	A
		C=C-A	A
		CSRB.F	A
		R0=C	A		curpos
		LC(5)	edDOB
		R1=C	A		mode
		GOSBVL	=PUSH2#
		GOVLNG	=PushTLoop

* Parse utility for EdDobRomp

DobNextParse	GOSUBL	SafeNextWord
		RTNC			CS: No more words
DobHexParse	LA(5)	5
		?C>A	A
		RTNYES			CS: Too long hex
		D=C	A
		B=0	A		No hex yet
-		A=DAT0	B
		D0=D0+	2
		LCASC	'0'
		A=A-C	B
		RTNC			CS: Non-hex
		LC(2)	9
		?A<=C	B
		GOYES	+
		LC(2)	'A'-'0'
		A=A-C	B
		RTNC			CS: Non-hex
		LC(2)	5
		?A>C	B
		RTNYES			CS: Non-hex
		A=A+CON	B,10
+		BSL	A		Add new digit
		B=A	P
		D=D-1	A
		?D#0	A
		GOYES	-
		A=B	A
		RTNCC

**********************************************************************
* Span subprogram to view grob under cursor
**********************************************************************

edvvgrberr      GOTO    edoberr3

EDvvGROB	ST=0	sDISPOK		Display won't be ok
		GOSUB	DobNextParse	A[A] = size
		GOC	edvvgrberr	No hex size - error
		B=A	A		B[A] = size
		GOSUBL	GetCutFree	C[A] = free nibbles
		A=C	A
*		LC(5)	34*64+1000
		LC(5)	34*80+1000
		C=C+B	A		need for safe operation
		?C>A	A
		GOYES	edvvgrberr	No memory to show it, error
		C=B	A
		RSTK=C			need
		GOSUBL	SafeNextWord	
		C=RSTK
		GOC	edvvgrberr	No body for the grob
		A=R0	A		bodylen
		?A#C	A
		GOYES	edvvgrberr	Invalid length in the body
		D=C	A		bodylen
		AD0EX
		R1=A	A		->body
		AD0EX
-		D=D-1	A		Check body is entirely hex
		GOC	+
		A=DAT0	B
		D0=D0+	2
		LCASC	'0'
		?A<C	B
		GOYES	edvvgrberr
		LC(1)	'9'
		?A<=C	B
		GOYES	-
		LCASC	'A'
		?A<C	B
		GOYES	edvvgrberr
		LCASC	'F'
		?A>C	B
		GOYES	edvvgrberr
		GONC	-

* Body is entirely hex, shrink, create grob and exit with
* ( grob #pos' #edgrob )

+		GOSUB	ShrinkEd
		C=R0	A		bodylength
		C=C+CON	A,10
		GOSBVL	=GETTEMP	D0 = ->body
		AD0EX
		D1=A
		AR0EX	A		R0 = ->grob	A[A]=bodylen
		LC(5)	=DOGROB
		DAT1=C	A
		D1=D1+	5
		A=A+CON	A,5
		DAT1=A	A
		D1=D1+	5
		A=A-CON	A,5
		B=A	A		bodylen
		C=R1	A
		D0=C			->body

-		B=B-1	A		chars--
		GOC	++
		A=DAT0	B
		D0=D0+	2
		LCASC	'0'
		A=A-C	B
		LC(2)	9
		?A<=C	B
		GOYES	+
		LC(2)	'A'-'0'-10
		A=A-C	B
+		DAT1=A	P
		D1=D1+	1
		GONC	-
++		A=R0	A
		GOSBVL	=GPPushA
		GOSBVL	=SAVPTR
		GOSUB	EdResetBTime	Reset BounceTiming
		C=R2			Reset fstack
		D1=C
		C=DAT1	B
		C=C-1	B
		DAT1=C	B				
		GOSUBL	GetCurPos	Push curpos and grobmode, exit
		D1=(2)	STR
		A=DAT1	A
		C=C-A	A
		CSRB.F	A
		R0=C	A		curpos
		LC(5)	edGROB
		R1=C	A		mode
		GOSBVL	=PUSH2#
		GOVLNG	=PushTLoop
**********************************************************************
* Turn calc off
**********************************************************************
EdOFF		GOSUBL	EdClrArg
		GOSUBL	EdDeepSleep
		RTN
**********************************************************************
* ON key just refreshes the display
**********************************************************************
EdON		ST=0	sDISPOK
		ST=0	sREPEAT
		RTN
**********************************************************************
* Toggle beep flag
**********************************************************************
TogBeep		ST=0	sREPEAT
*		D0=(5)	aSystemFlags
*		C=DAT0	A
*		C=C+CON	A,13
		D0=(5)	(SystemFlags)+13
*		D0=C
		C=DAT0	B
		?ST=0	sBPOFF
		GOYES	edbeepon
		CBIT=0	3
		DAT0=C	B
		ST=0	sBPOFF
		RTN
edbeepon	CBIT=1	3
		DAT0=C	B
		ST=1	sBPOFF
		RTN
**********************************************************************
* Toggle upper/lower case
**********************************************************************
TogCase		ST=0	sREPEAT		No repeat
		?ST=0	sLOWCS
		GOYES	edcaseon
		ST=0	sLOWCS
		RTN
edcaseon	ST=1	sLOWCS
		RTN
**********************************************************************
* Toggle insert/overwrite
**********************************************************************
TogOver		ST=0	sREPEAT		No repeat
		?ST=0	sOVERWR
		GOYES	edoveron
		ST=0	sOVERWR
		RTN
edoveron	ST=1	sOVERWR
		RTN
**********************************************************************
* Toggle speed 0/F
**********************************************************************
TogSpeed	ST=0	sREPEAT		No repeat
		AD1EX			->data
		LC(5)	EDSPEED
		A=A+C	A
		D1=A
		A=DAT1	S
		A=-A-1	S		0/F --> F/0
		DAT1=A	S
		RTN

**********************************************************************
* Delete current line
**********************************************************************
EdDelLine	GOSUBL	EdLineStart	Set start of block
		D1=(2)	BLK
		AD0EX
		DAT1=A	A
		GOSUBL	EdLine+		Set end of block
		D1=(2)	BLKEND
		AD0EX
		DAT1=A	A
		GOTO	DelBlk		Delete
**********************************************************************
* Delete rest of row
**********************************************************************
EdDelRt		GOSUBL	GetCurPos	Set start of block
		D1=(2)	BLK
		AD0EX
		DAT1=A	A
		GOSUBL	EdLineEnd	Set end of block
		D1=(2)	BLKEND
		AD0EX
		DAT1=A	A
		GOTO	DelBlk		Delete
**********************************************************************
* Set block start
**********************************************************************
SetBlk		GOSUBL	GetCurPos
		D1=(2)	BLK
		DAT1=C	A
		ST=0	sREPEAT
		ST=0	sDISPOK
		RTN
**********************************************************************
* Set block end
**********************************************************************
SetBlkEnd	GOSUBL	GetCurPos
		D1=(2)	BLKEND
		DAT1=C	A
		ST=0	sREPEAT
		ST=0	sDISPOK
		RTN
**********************************************************************
* Set block from start to here
**********************************************************************
SetBlkUp	D1=(2)	STR
		C=DAT1	A
		D1=(2)	BLK
		DAT1=C	A
		GOTO	SetBlkEnd
**********************************************************************
* Set block from here to end
**********************************************************************
SetBlkDown	D1=(2)	STREND
		C=DAT1	A
		D1=(2)	BLKEND
		DAT1=C	A
		GOTO	SetBlk
**********************************************************************
* Mark P chars
**********************************************************************
MarkCharsP	C=0	A
		CPEX	0
MarkChars	C=C+C	A
MarkCharsC	B=C	A
		GOSUBL	GetCurPos
		B=B+C	A	BLKEND
		D1=(2)	STREND
		A=DAT1	A
		?B>A	A
		RTNYES
		D1=(2)	BLK
		DAT1=C	A
		D1=(2)	BLKEND
		C=B	A
		DAT1=C	A
		RTNCC

**********************************************************************
* Delete all but block. Clip not modified !
**********************************************************************
EdDelNoBlk	GOSUBL	GetBlk
		GOC	delblkerr	
		ST=0	sDISPOK
		ST=0	sREPEAT
		A=A+C	A
		D1=(2)	CURPOS
		C=DAT1	A	
		R1=C.F	A
		DAT1=A	A
		D1=(2)	STREND
		C=DAT1	A
		C=C-A	A
		GOSUBL	EdRemoveC
		D1=(2)	STR
		A=DAT1	A
		D1=(2)	CURPOS
		DAT1=A	A
		D1=(2)	BLK
		C=DAT1	A
		C=C-A	A
		A=R1.F	A
		A=A-C	A
		R1=A.F	A
		GOSUBL	EdRemoveC
		GOSUB	SetNoBlk
		A=R1.F	A
		D0=A
		GOLONG	ToThisD0
**********************************************************************
* Delete block by moving it to the clip
**********************************************************************
EdDelNoClip	ST=1	sDELNOCLIP
		GOTO	+

delblkerr	GOLONG	BadEdKey

EdDelBlk	ST=0	sREPEAT		No repeat since there's only 1 block
DelBlk		ST=0	sDELNOCLIP	
+		ST=0	sDISPOK		Display will be invalid
		GOSUBL	GetBlk		Get delimiters
		GOC	delblkerr	No block marked!
		D1=(2)	CURPOS		Set cursor to start of block
		DAT1=A	A
		?ST=1	sDELNOCLIP
		GOYES	+
		GOSUB	Blk>Cut		Move block to cut
		GOC	slowdelblk	If failure then use slow memory swap
+		GOSUBL	GetBlk		Fast move was ok, get block
		GOSUBL	EdRemoveC	And remove it
eddelblk10	GOSUBL	ToThisPos	Move to the new position
SetNoBlk	C=R4.F	A		No block left
		D1=C
		C=0	A
		D1=(2)	BLK
		DAT1=C	A
		D1=(2)	BLKEND
		DAT1=C	A
		RTN

slowdelblk	GOSUBL	GetBlk		Use in-place memory swap to move
		D0=A			the block to cut
		A=A+C	A		->blockend
		D1=(2)	MEMEND
		C=DAT1	A
		D1=A
		C=C-A	A		Free memory
		GOSUBL	EdBLKswap	Swap memory
		GOSUBL	GetBlk		Calculate new positions
		D1=(2)	MEMEND
		A=DAT1	A
		A=A-C	A
		D1=(2)	CUT
		DAT1=A	A
		D=C	A
		GOSUBL	Update-D	Update pointers
		GOTO	eddelblk10	The rest is the same
**********************************************************************
* Copy block to cursor position and clip
**********************************************************************
copyblkerr	GOLONG	BadEdKey
CopyBlk		ST=0	sDISPOK
		GOSUBL	GetBlk
		GOC	copycut
		GOSUB	Blk>Cut
		GOC	copyblkerr
		GOSUB	SetNoBlk
copycut		GOSUBL	GetCut
		GOC	copyblkerr
		GOSUB	Cut>CurPos
		GOC	copyblkerr
		GOLONG	ToThisPos
**********************************************************************
* Copy clip to cursor position
**********************************************************************
Cut>CurPos	GOSUBL	GetCut
		RTNC
		GOSUBL	EdAllocC
		RTNC
		GOSUBL	GetCut
		AD0EX
		D1=A
		GOSBVL	=MOVEDOWN
		GOSUBL	GetCut
		D1=(2)	CURPOS
		A=DAT1	A
		A=A+C	A
		DAT1=A	A
		RTNCC
**********************************************************************
* Copy block to clip
**********************************************************************
Blk>Cut		GOSUBL	GetBlk
		RTNC
		D0=A		->BLK
		B=C	A	BLKSIZE
		GOSUBL	GetCutFree
		?C<B	A
		RTNYES
		D1=(2)	CUT
		A=A-B	A
		DAT1=A	A
		D1=A
		C=B	A
		GOVLNG	=MOVEDOWN CC

**********************************************************************
* Swap text and clip
**********************************************************************
swapcliperr	GOLONG	BadEdKey
EdSwapClip	ST=0	sREPEAT
		GOSUBL	GetCut
		GOC	swapcliperr
		ST=0	sDISPOK

		D=C	A
		GOSUBL	GetFree
		B=C	A
		GOSUBL	GetText
		?D<C	A
		GOYES	+

		GOSUB	edswpTCT	Text<=Cut	Try to move Cut once
		GONC	edswpUpdPtr
		GOSUB	edswpCTC		fail -> try to move Text once
		GONC	edswpUpdPtr	
		GOC	edswpLowMem

+		GOSUB	edswpCTC	Text>Cut	Try to move Text once
		GONC	edswpUpdPtr
		GOSUB	edswpTCT		fail -> try to move Cut once
		GONC	edswpUpdPtr

edswpLowMem	GOSUBL	GetCut		All failed, use (very) slow swap
		D0=A
		D1=(2)	STREND
		A=DAT1	A
		D1=A
		GOSBVL	=MOVEDOWN	Move cut to end of text
		GOSUBL	GetText
		D0=A
		A=A+C	A
		D1=(2)	MEMEND
		C=DAT1	A
		D1=A	A
		C=C-A	A
		GOSUBL	EdBLKswap	then rot text above cut+free

edswpUpdPtr
		GOSUBL	GetCut		Update end of STR and start of CUT
		B=C	A
		GOSUBL	GetText	
		D0=A
		A=A+B	A
		D1=(2)	STREND
		DAT1=A	A
		D1=(2)	MEMEND
		A=DAT1	A
		A=A-C	A
		D1=(2)	CUT
		DAT1=A	A	

		D1=(2)	BLK		Clear BLK and marks
		AD1EX
		C=0	A
-		AD1EX		<-------+
		DAT1=C	A		|
		D1=D1+	5		|
		AD1EX			|
		LC(2)	UPDEND		|
		?A<C	B		|
		GOYES	-	--------+
		GOLONG	ToThisD0


edswpTCT	GOSUBL	GetCut		Move Text, then Cut then Text	
		?C>B	A
		RTNYES			No room to move text

		B=C	A		Move up text by cut's size
		GOSUBL	GetText
		A=A+C	A
		D0=A
		A=A+B	A
		D1=A
		D=C	A			len of text
		GOSBVL	=MOVEUP	

		GOSUBL	GetCut		Move Cut to start of buf
		D0=A
		B=A	A
		B=B+C	A			end of buf
		D1=(2)	STR
		A=DAT1	A
		D1=A
		GOSBVL	=MOVEDOWN

		CD1EX			Move up text to end of Buf
		C=C+D	A
		D0=C
		A=B	A
		D1=A
		C=D	A
		GOVLNG	=MOVEUP		does RTNCC			
			
edswpCTC	GOSUBL	GetText		Move Cut, then Text then Cut
		?C>B	A	
		RTNYES			No room to move Cut
		
		B=C	A		Move Cut down by Text's size
		GOSUBL	GetCut
		D0=A
		A=A-B	A
		D1=A
		D=C	A			len of cut
		GOSBVL	=MOVEDOWN	

		GOSUBL	GetText		Move Text to end of Buf
		B=A	A			start of text
		A=A+C	A
		D0=A
		D1=(2)	MEMEND
		A=DAT1	A
		D1=A
		GOSBVL	=MOVEUP
		
		CD1EX			Move cut down to start of Buf
		C=C-D	A		
		D0=C
		A=B	A
		D1=A
		C=D	A
		GOVLNG	=MOVEDOWN	does RTNCC

**********************************************************************
* Update last cursor position to MARK0
**********************************************************************
UpdMark0	GOSUBL	GetCurPos
		D1=(2)	MARKX
		A=DAT1	A
		?A=C	A
		RTNYES			Cursor didn't move, don't update!
		D1=(2)	MARK0
		DAT1=A	A
		RTN
**********************************************************************
* Update mark X
**********************************************************************
SetMarkX	GOSUBL	GetCurPos
		D1=(2)	MARKX
		DAT1=C	A
		RTN
**********************************************************************
* Set mark position
**********************************************************************
SetMark9	P=P+1
SetMark8	P=P+1
SetMark7	P=P+1
SetMark6	P=P+1
SetMark5	P=P+1
SetMark4	P=P+1
SetMark3	P=P+1
SetMark2	P=P+1
SetMark1	P=P+1
		ST=0	sREPEAT	
SetMark0	C=0	A
		CPEX	0
		A=C	A
		A=A+A	A
		A=A+A	A
		A=A+C	A	5*N
		GOSUBL	GetCurPos
		D1=(2)	MARK0
		CD1EX
		C=C+A	A
		CD1EX
		DAT1=C	A
		RTN	
**********************************************************************
* Set cursor to mark
**********************************************************************
GoMark9		P=P+1
GoMark8		P=P+1
GoMark7		P=P+1
GoMark6		P=P+1
GoMark5		P=P+1
GoMark4		P=P+1
GoMark3		P=P+1
GoMark2		P=P+1
GoMark1		P=P+1
GoMark0		ST=0	sREPEAT
		C=0	A
		CPEX	0
		A=C	A
		A=A+A	A
		A=A+A	A
		A=A+C	A	5*N
		C=R4.F	A
		LC(2)	MARK0
		C=C+A	A
		D1=C
		C=DAT1	A
		?C=0	A
		GOYES	cantgomark
		D0=C
		GOLONG	ToThisD0
cantgomark	GOLONG	BadEdKey
**********************************************************************
* Insert stack level 1 string into cursor position
**********************************************************************
RclStk1		GOSUB	GetStk$
		GOC	rclerr
		GOSUBL	EdAlloc
		GOC	rclerr
* Got string alright, insert it into text
		GOSUBL	GetCurPos	
		D1=C
		GOSUB	GetStk$		C[A] = chars	D0 = ->text
		C=C+C	A
		GOSBVL	=MOVEDOWN
* Now remove it from stack
		GOSUB	GetStk$		B[A] = ->stklevel
		C=B	A
		D1=C			->stklevel
		GOSBVL	=D0=DSKTOP
		C=C-A	A		Nibbles to move
		A=B	A
		D0=A			->stklevel
		D1=D1+	5		Overwrite the inserted string
		GOSBVL	=MOVEUP
		GOSBVL	=GETPTR		Pop the vanished level
		D1=D1+	5
		D=D+1	A
		GOSBVL	=SAVPTR
*		D0=(5)	=aDEPTHSAVE	Also fix UStackDepth!!
*		A=DAT0	A
*		D0=A
		D0=(5)	=DEPTHSAVE
		A=DAT0	A
		A=A-CON	A,5
		DAT0=A	A
		ST=0	sDISPOK
		RTN
rclerr		GOLONG	BadEdKey

* Fetch first user stack level  =
GetStk$
*		D0=(5)	=aEDITLINE
*		C=DAT0	A
*		D0=C
		D0=(5)	=EDITLINE
		C=DAT0	A		->editline
*		D0=(5)	=aDEPTHSAVE
*		A=DAT0	A
*		D0=A
		D0=(4)	=DEPTHSAVE
		A=DAT0	A		depthsave
		C=C-A	A
		D0=C			->stklevel
		B=C	A		->stklevel
		A=DAT0	A
		D0=A			->ob
		A=DAT0	A
		LC(5)	=DOCSTR
		?A#C	A
		RTNYES
		D0=D0+	5
		C=DAT0	A		$len
		D0=D0+	5		->$body
		C=C-CON	A,5
		RTNC			CS: Too short
		?CBIT=1	0
		RTNYES			CS: Extra nibble
		CSRB.F	A		chars
		RTNCC			CC: String ok

**********************************************************************
* Push Blk or Cut to stack level 1
**********************************************************************
* Note: sREPEAT set to 0, so we can use R3
PushStk1	
		ST=0	sREPEAT
		GOSUBL	GetBlk		Get BLK
		GONC	+
		GOSUBL	GetCut		if none get CUT
-		GOC	rclerr	 	  if none -> badkey
		A=0	A		Set start to 0: start of CUT change
+		B=A	A		B : start of BLK/CUT
		R1=C			R1: size

		D=C	A
		C=0	A		
		LC(2)	21		Stack:5 Temp:5+1 CSTR:5+5	
		D=D+C	A		Free= size + 21
		GOSUBL	GetFree		Be sure there will be enough
		?C<D	A		ROOM to avoid garbage
		GOYES	-

		C=D	A		C=Free
		D1=(2)	MEMEND		Update MEMEND
		A=DAT1	A
		D0=A			->Link
		A=A-C	A
		DAT1=A	A

		A=DAT0	A		Update Link
		A=A-C	A
		DAT0=A	A

		D1=(2)	STR		Update $Len
		A=DAT1	A
		D0=A
		D0=D0-	5
		A=DAT0	A
		A=A-C	A
		DAT0=A	A

		D1=(2)	CUT		Update CUT
		A=DAT1	A
		R3=A
		A=A-C	A
		DAT1=A	A
		?B=0	A		Using CUT ?
		GOYES	+		YES-> use new satrt of CUT in A
		A=B	A		NO-> use start of BLK in B	

+		AR3EX			A=->old cut C=Free R3=start of BLK/CUT
		GOSBVL	=MOVERSD	shrink! (move also old CUT to new CUT)

		C=R1			Size of BLK/CUT
		GOSBVL	=MAKE$N		Make a string. Shouldn't garbage
						but does a ST=0	sDISPOK (10)
		A=R3		
		C=R1	
		AD0EX
		AD1EX
		GOSBVL	=MOVEDOWN	Copy BLK/CUT to this string

		A=R0	A
		GOSBVL	=GPPushA	Push it (just to take a slot in stack)
		GOSBVL	=SAVPTR
		GOSUB	GetStk$		B[A] = ->stklevel of DEPTHSAVE

		GOSBVL	=D1=DSKTOP 	Move down stack from DEPTHSAVE to
		D0=C				DSKTOP
		D0=D0+	5		
		B=B-C	A		Nibbles to move
		C=B	A
		GOSBVL	=MOVEDOWN

		D1=D1-	5		Put string just above DEPTHSAVE
		A=R0.F	A		  (i.e. above edited string)
		DAT1=A	A

*		D0=(5)	=aDEPTHSAVE	Also fix UStackDepth
*		A=DAT0	A
*		D0=A
		D0=(5)	=DEPTHSAVE
		A=DAT0	A
		A=A+CON	A,5
		DAT0=A	A

		GOLONG	SetNoBlk	Clear if any Block and end !

**********************************************************************
* Convert block or current char to hex
**********************************************************************
EdToHex		GOSUBL	GetBlk
		GONC	BlkToHex
		P=	1
		GOSUBL	MarkCharsP
		GONC	EdToHex
tohxerr		GOLONG	BadEdKey

BlkToHex	ST=0	sDISPOK
		D1=(2)	CURPOS
		DAT1=A	A
		GOSUBL	EdAllocC
		GOC	tohxerr
		GOSUBL	GetBlk
		AD0EX		BLK
		DAT1=A	A	New BLK
		D1=A		CURPOS
		B=C	A
tohxlp		B=B-1	A
		GOC	tohxok
		A=DAT0	1
		D0=D0+	1
		LCASC	'9'
		ACEX	P
		?C<=A	P
		GOYES	tohx9
		C=C+CON	B,7
tohx9		DAT1=C	B
		D1=D1+	2
		GONC	tohxlp
tohxok		GOLONG	ToThisPos
**********************************************************************
* Convert block or 2 chars to ascii
**********************************************************************
EdToAsc		GOSUBL	GetBlk
		GONC	BlkToAsc
		GOSUBL	GetCurPos
		A=DAT0	4
		GOSUB	Hex4ToAsc
		GOC	toascer
		P=	2
		GOSUBL	MarkCharsP
		GONC	EdToAsc
toascer		GOLONG	BadEdKey
BlkToAsc
		ST=0	sDISPOK
		CSRB.F	A	Chars
		?CBIT=1	0	Pairs?
		GOYES	toascer	Nope
		CSRB.F	A	Pairs
		B=C	A
		D0=A
		D=C	A
* Make sure chars are hex
vrhxlp		A=DAT0	4
		D0=D0+	4
		GOSUB	Hex4ToAsc
		GOC	toascer
		B=B-1	A
		?B#0	A
		GOYES	vrhxlp
* Convert block backwards
		AD0EX
		D0=A
		D1=A
toasclp		D0=D0-	4
		D1=D1-	2
		A=DAT0	4
		GOSUB	Hex4ToAsc
		DAT1=A	B
		D=D-1	A
		?D#0	A
		GOYES	toasclp
* Now:	D0=->BLK
*	D1=->BLK' = CURPOS'
* 1st delete extra chars from BLK

		GOSUBL	GetBlk
		D1=(2)	CURPOS
		DAT1=A	A
		D1=(2)	BLK
		CSRB.F	A
		A=A+C	A
		DAT1=A	A
		GOSUBL	EdRemoveC
		GOLONG	ToThisPos	
Hex4ToAsc
		GOSUB	HexChr?
		RTNC
		ASRC
		ASR	A
		GOSUB	HexChr?
		ASLC
		RTN

HexChr?		LCASC	'0'
		A=A-C	B
		RTNC
		LC(2)	'9'-'0'
		?A<=C	B
		GOYES	hxchok
		A=A-CON	B,7
		RTNC
		LC(1)	#0F
		?A>C	B
		RTNYES
hxchok		RTNCC
**********************************************************************

**********************************************************************
* 1) Reverse block, CUR=BLKEND
* 2) Reverse word, CUR=WORDEND
* 3) White/End -> Error
**********************************************************************
EdReverse
		ST=0	sDISPOK
		GOSUBL	GetBlk
		GOC	revword
		D1=(2)	CURPOS
		C=C+A	A	BLKEND
		DAT1=C	A
		D0=A		BLK
		D1=C		BLKEND
* In: D0-D1 = START-TAIL
RevChrs		D1=D1-	2
		AD0EX
		D0=A
		CD1EX
		D1=C
		?A>=C	A
		GOYES	revok
		A=DAT0	B
		C=DAT1	B
		DAT1=A	B
		DAT0=C	B
		D0=D0+	2
		GONC	RevChrs
revok		GOLONG	ToThisPos

revword		GOSUB	EdBlack+
		GOC	reverr
		D1=(2)	CURPOS
		A=DAT1	A
		AD0EX		D0=CURPOS
		DAT1=A	A
		D1=A		D1=WORDEND
		GOTO	RevChrs
reverr		GOLONG	BadEdKey
**********************************************************************
* Skip to end of word
**********************************************************************
EdBlack+	GOSUBL	GetCurPos
Black+		LCASC	' '
		A=DAT0	B
		?A<=C	B
		RTNYES		No black
blac+lp		D0=D0+	2
		A=DAT0	B
		?A>C	B
		GOYES	blac+lp
		C=R4.F	A
		D1=C
		D1=(2)	STREND
		C=DAT1	A
		AD0EX
		?A<=C	A
		GOYES	bl+eok
		A=C	A
bl+eok		D0=A
		RTNCC			
**********************************************************************
* Move cursor up
**********************************************************************
upisbad		GOLONG	BadEdKey
EdUp		GOSUB	EdLine-
		GOC	upisbad	Top Line
		ST=0	sSCROLL
		D1=(2)	CURSY	Update Y
		A=DAT1	S
		A=A-1	S
		DAT1=A	S
		GONC	upyok
		ST=1	sSCROLL
		A=0	S
		DAT1=A	S
		D1=(2)	TOPPOS
		AD0EX
		DAT1=A	A
		AD0EX
upyok		GOSUBL	ToThisWant
		GOSUB	NoScroll?
		RTNC
		GOLONG	ViewUp
NoScroll?
		?ST=0	sSCROLL
		RTNYES
		?ST=0	sDISPOK
		RTNYES
		RTN
**********************************************************************
* Move cursor down
**********************************************************************
dnisbad		GOLONG	BadEdKey
EdDn		GOSUB	EdLine+
		GOC	dnisbad		Bottom Line
		ST=0	sSCROLL
		D1=(2)	CURSY		Update Y
		A=DAT1	P
		A=A+1	P
		DAT1=A	P
		LC(1)	12	9	Max value
		?A<=C	P
		GOYES	dnyok
		ST=1	sSCROLL
		A=A-1	P
		DAT1=A	P
		D1=(2)	TOPPOS
		A=DAT1	A
		AD0EX
		DAT1=A	A		Save line
		GOSUB	Line+
		A=DAT1	A
		AD0EX			Restore line
		DAT1=A	A		Set new top
dnyok		GOSUBL	ToThisWant
		GOSUB	NoScroll?
		RTNC
		GOLONG	ViewDn
**********************************************************************
* Move cursor left
**********************************************************************
ltisbad		GOLONG	BadEdKey
EdLt		D1=(2)	STR
		A=DAT1	A
		D1=(2)	CURPOS
		C=DAT1	A
		?C<=A	A
		GOYES	ltisbad	Already start
		C=C-CON	A,2
		DAT1=C	A
		D0=C	New	Loc
		A=DAT0	B
		LCASC	'\n'
		?A=C	B
		GOYES	ltwrap
		LC(1)	'\t'
		?A=C	B
		GOYES	lttab
		GOSUBL	SetWantX
		A=A-1	A
		DAT1=A	A
		D1=(2)	CURSX
		A=DAT1	B
		A=A-1	B
		DAT1=A	B
		RTNNC
		A=0	B
		DAT1=A	B
		D1=(2)	XOFF
		C=DAT1	A
		C=C-1	A
		DAT1=C	A
		?ST=0	sDISPOK
		RTNYES
		GOLONG	ViewLt
		
ltwrap		D1=(2)	CURSY
		A=DAT1	S
		A=A-1	S
		DAT1=A	S
		GONC	ltwrap-
		ST=0	sDISPOK
		A=0	S
		DAT1=A	S
		D1=(2)	TOPPOS
		A=DAT1	A
		D0=A
		GOSUB	Line-
		AD0EX
		DAT1=A	A
		R0=A.F	A	ToThisX slower
		GOLONG	findnewX
ltwrap-
lttab		GOTO	ToThisX
**********************************************************************
* Move cursor right
**********************************************************************
rtisbad		GOLONG	BadEdKey
EdRt		D1=(2)	STREND
		A=DAT1	A
		D1=(2)	CURPOS
		C=DAT1	A
		D0=C		Old Pos
		C=C+CON	A,2
		?C>A	A
		GOYES	rtisbad	Already bottom
		DAT1=C	A
		A=DAT0	B
		LCASC	'\n'
		?A=C	B
		GOYES	rtwrap
		LC(1)	'\t'
		?A=C	B
		GOYES	rttab
		GOSUBL	SetWantX
		A=A+1	A
		DAT1=A	A
		D1=(2)	CURSX
		A=DAT1	B
		A=A+1	B
		DAT1=A	B
		LC(2)	32
		?A<=C	B
		RTNYES
edrt+		DAT1=C	B
		D1=(2)	XOFF
		C=DAT1	A
		C=C+1	A
		DAT1=C	A
		?ST=0	sDISPOK
		RTNYES
		GOLONG	ViewRt
rtwrap		D1=(2)	CURSY
		A=DAT1	P
		A=A+1	P
		DAT1=A	P
		LC(1)	13-1	9
		?A<=C	P
		GOYES	rtyok
		DAT1=C	P
		ST=0	sDISPOK
		D1=(2)	TOPPOS
		A=DAT1	A
		D0=A
		GOSUB	Line+
		AD0EX
		DAT1=A	A	Set new top
rtyok
rttab		GOTO	ToThisX
**********************************************************************
* Move cursor 1 page up
**********************************************************************
EdPgUp		GOSUB	GetCurPos
		LC(1)	13-1		10-1
		D=C	A
pguplp		GOSUB	Line-
		GOC	pgupnow
		D=D-1	P
		GONC	pguplp
		GOC	pgupnow
**********************************************************************
* Move cursor 1 page down
**********************************************************************
EdPgDn		GOSUB	GetCurPos
		LC(1)	13-1		10-1
		D=C	A
pgdnlp		GOSUB	Line+
		GOC	pgdnnow
		D=D-1	P
		GONC	pgdnlp
pgupnow
pgdnnow		GOLONG	SafeWantPos
**********************************************************************
* Move cursor 1 word left
**********************************************************************
EdWordLt	GOSUBL	EdStart?
		GOC	wordrterr
		D0=D0-	2
		GOSUBL	StartOfPrvWrd
		GOC	wordrterr
		CSRB.F	A
-		C=C-1	A
		RTNC
		R1=C.F	A
		A=R4
		D1=A
		GOSUB	EdLt
		C=R1.F	A
		GOTO	-
**********************************************************************
* Move cursor 1 word right
**********************************************************************
EdWordRt	GOSUBL	EdEnd?
		GOC	wordrterr
		D0=D0+	2
		GOSUBL	EndOfNxtWrd
		GOC	wordrterr
		CSRB.F	A
		C=C-1	A
-		C=C-1	A
		RTNC
		R1=C.F	A
		A=R4
		D1=A
		GOSUB	EdRt
		C=R1.F	A
		GOTO	-	
wordrterr	GOLONG	BadEdKey

**********************************************************************
* Del all between here and start of (prev) word
**********************************************************************
EdDelWrdLt	GOSUBL	EdStart?
		GOC	wordrterr
		GOSUBL	StartOfPrvWrd
		GOC	wordrterr
		ST=0	sREPEAT
		ST=0	sDISPOK
		D1=(2)	CURPOS
		A=DAT1	A
		A=A-C	A
		DAT1=A	A
*		C=C+1	A		To also DEL char under cursor
		GOSUBL	EdRemoveC
		GOLONG	ToThisPos

**********************************************************************
* Del all between here and end of (next) word
**********************************************************************
EdDelWrdRt	GOSUBL	EdEnd?
		GOC	wordrterr
		GOSUBL	EndOfNxtWrd
		GOC	wordrterr
		ST=0	sREPEAT
		ST=0	sDISPOK
		GOSUBL	EdRemoveC
		GOLONG	ToThisPos

**********************************************************************
* Move to start of text
**********************************************************************
EdFarUp		D1=(2)	STR
		A=DAT1	A
		D0=A
		ST=0	sREPEAT
		GOLONG	ToThisD0
**********************************************************************
* Move to bottom of text
**********************************************************************
EdFarDn		D1=(2)	STREND
		A=DAT1	A
		D0=A
		GOSUBL	LineStart
		GOLONG	ToThisD0
**********************************************************************
* Move to start of row
**********************************************************************
EdFarLt		GOSUB	EdLineStart
		AD0EX
		DAT1=A	A
		GOTO	ToThisX
**********************************************************************
* Move to end of row
**********************************************************************
EdFarRt		GOSUB	EdLineEnd
		AD0EX
		DAT1=A	A
		GOTO	ToThisX
**********************************************************************
* Delete character under cursor
**********************************************************************
EdDel		GOSUB	EdEnd?
		GOC	cantdel	
		ST=1	sLINBAD
		A=DAT0	B
		LCASC	'\n'
		?A#C	B
		GOYES	delnonNL
		ST=0	sDISPOK
delnonNL	
		P=	1
		GOTO	EdRemoveP
cantdel		GOLONG	BadEdKey
**********************************************************************
* Delete previous character
**********************************************************************
EdBS		GOSUB	EdStart?
		GOC	cantbs
		ST=1	sLINBAD
		D0=D0-	2
		A=DAT0	B
		LCASC	'\n'
		?A#C	B
		GOYES	bsnonNL
		ST=0	sDISPOK
bsnonNL		D1=(2)	CURPOS
		AD0EX
		DAT1=A	A
		P=	1
		GOSUB	EdRemoveP
		GOTO	ToThisPos
cantbs		GOLONG	BadEdKey
**********************************************************************
* Insert/overwrite character	C[B]=CHR
**********************************************************************
DoEdChrKey
		GOSUB	TogChr?
		B=A	B
		?ST=1	sOVERWR
		GOYES	OverEdChr
		GOTO	InsEdChr
OverEdChr
		GOSUB	EdEnd?
		GOC	InsEdChr
		A=DAT0	B
		C=B	B
		DAT0=C	B
		LCASC	'\n'
		?C=B	B
		GOYES	overNL
		?A#C	B
		GOYES	overnormal
overNL		ST=0	sDISPOK
		GOTO	EdRt
overnormal
		GOSUBL	DispCurChr
		GOTO	EdRt

* B[B]=chr
InsEdChr
		P=	1
		GOSUB	EdAllocP
		GONC	insnow
		GOLONG	BadEdKey
insnow		ST=1	sLINBAD
		A=B	B
		DAT0=A	B
		LCASC	'\n'
		?A#C	B
		GOYES	insnonNL
		ST=0	sDISPOK
insnonNL
		GOTO	EdRt
**********************************************************************
* Insert/overwrite string key
**********************************************************************
DoEdStrKey
		ST=0	sDISPOK
		?ST=0	sOVERWR
		GOYES	doeds10
		GOSUB	OverEdStr
		GOTO	doeds20
doeds10		GOSUB	InsEdStr
doeds20		GOC	doeds30
		GOTO	ToThisPos
doeds30		GOLONG	BadEdKey
**********************************************************************
OverEdStr
		C=DAT0	S	strlen
		D0=D0+	1
		CD0EX
		B=C	A	->str
		C=R4.F	A
		D1=C
		D1=(2)	CUT
		A=DAT1	A	->cut
		D1=(2)	CURPOS
		C=DAT1	A
		D0=C		->curpos
		D=C	A	->curpos
		C=0	A
		CSLC		strlen
		C=C+C	A	nibbles
		D=D+C	A	curpos'
		CDEX	A	curpos'
		?C>A	A	curpos' > cut?
		RTNYES		Yes - no room
		D1=(2)	STREND	Update strend if needed
		A=DAT1	A
		?C<=A	A
		GOYES	+
		DAT1=C	A	Update strend
+		C=D	A	nibbles
		GOTO	copystrnow
**********************************************************************
InsEdStr
		C=DAT0	S	strlen
		D0=D0+	1
		CD0EX
		B=C	A	->str
		P=C	15
		GOSUB	EdAllocP
		RTNC		no room
		C=0	A
		CSLC
		C=C+C	A	nibbles
copystrnow
		A=B	A
		AD0EX		->str
		D1=A		->curpos
		GOSBVL	=MOVEDOWN
		C=R4.F	A	Now update curpos according to skip index
		D1=C
		D1=(2)	CURPOS
		C=DAT1	A	->curpos
		A=0	A
		A=DAT0	1	skip
		A=A+A	A	skip nibs
		C=C+A	A	curpos'
		DAT1=C	A
		RTNCC
**********************************************************************
* Insert list delimiters nicely
**********************************************************************
EdIndList	GOSUB	Ins&Ind:
		ASC(1)	'{}'
		CON(1)	1
**********************************************************************
* Insert program delimiters nicely
**********************************************************************
EdIndPrg	GOSUB	Ins&Ind:
		ASC(1)	'::;'
		CON(1)	2
**********************************************************************
* Insert array delimiters nicely
**********************************************************************
EdIndArr	GOSUB	Ins&Ind:
		ASC(1)	'[]'
		CON(1)	1
**********************************************************************
* Insert matrix delimiters nicely
**********************************************************************
EdIndMat	GOSUB	Ins&Ind:
		ASC(1)	'MATRIX;'
		CON(1)	6
**********************************************************************
* Insert symbolic delimiters nicely
**********************************************************************
EdIndSym	GOSUB	Ins&Ind:
		ASC(1)	'SYMBOL;'
		CON(1)	6
**********************************************************************
* Insert symbolic delimiters nicely
**********************************************************************
EdIndRpl	GOSUB	Ins&Ind:
		ASC(1)	'\xAB\xBB'
		CON(1)	1

* Insert string nicely
Ins&Ind:	ST=0	sDISPOK
		C=RSTK
		D0=C
		GOSUB	InsEdStr
		GOC	insinderr
		GOSUB	IndNL
		GOC	insinderr
		GOSUB	GetCurPos
		RSTK=C
		GOSUB	IndNL
		C=RSTK
		GOC	insinderr
		D0=C
		GOSUB	ToThisD0
		LCASC	' '
		B=C	B
		GOTO	InsEdChr
insinderr	GOLONG	BadEdKey
**********************************************************************
* Insert newline character
**********************************************************************
EdIndNL		ST=0	sDISPOK
		GOSUB	IndNL
		GOC	edindnlerr
		GOTO	ToThisPos
edindnlerr
		GOLONG	BadEdKey

IndNL		GOSUB	EdLineStart
		D1=(2)	CURPOS
		C=DAT1	A
		AD0EX
		D0=A
		C=C-A	A
		CSRB.F	A
		GOSBVL	=ASLW5
		A=C	A
		B=A	W	Max N & LineStart
		D=0	A
skpwhilp
		D=D+1	A
		B=B-1	A
		GOC	gotwhiN
		A=DAT0	B
		D0=D0+	2
		LC(2)	#1F
		?A=C	B
		GOYES	skpwhilp
		LCASC	' '
		?A<=C	B
		GOYES	skpwhilp
gotwhiN		C=D	A
		GOSUB	EdAlloc	D=C*2
		RTNC
		A=B	W
		GOSBVL	=ASRW5
		AD0EX
		D1=A
		LCASC	'\n'
		DAT1=C	B
		D1=D1+	2
		C=D	A
		C=C-CON	A,2
		GOSBVL	=MOVEDOWN	
		C=R4.F	A
		CD1EX
		D1=(2)	CURPOS
		DAT1=C	A
		RTNCC

**********************************************************************
* Toggle between lower/upper case if so requested	CC: Toggled char
**********************************************************************
TogChr?		A=C	B
		?ST=0	sLOWCS
		RTNYES			No request
		LCASC	'A'
		?A<C	B
		RTNYES			< 'A' - not character
		LCASC	'z'
		?A>C	B		> 'z' - not character
		RTNYES
		LCASC	'Z'
		?A>C	B
		GOYES	+
		ABIT=1	5		Convert to lower case
		RTN
+		LCASC	'a'
		?A<C	B
		RTNYES			'Z' < chr < 'a' - not character
		ABIT=0	5		Convert to upper case
		RTN
**********************************************************************
* At start of text?
* Uses: D1 C[A]
**********************************************************************
EdStart?	GOSUB	GetCurPos	Special entry for cursor position
Start?		C=R4.F	A
		D1=C
		D1=(2)	STR
		C=DAT1	A
		AD0EX
		?A<=C	A
		GOYES	+
+		AD0EX
		RTN
**********************************************************************
* At end of text?
* Uses:	D1 C[A]
**********************************************************************
EdEnd?		GOSUB	GetCurPos
End?		C=R4.F	A
		D1=C
		D1=(2)	STREND
		C=DAT1	A
		AD0EX
		?A>=C	A
		GOYES	+
+		AD0EX
		RTN
**********************************************************************
* Get end of line, CS if end of file
* Uses:	A[W] C[W] D0 D1
**********************************************************************
EdLineEnd	GOSUB	GetCurPos
LineEnd		A=R4.F	A
		AD0EX
		D0=(2)	STREND
		C=DAT0	A	->end of str
		D0=C
		LC(N)	16
		NIBASC	'\n\n\n\n\n\n\n\n'
		DAT0=C	B	Ensure a terminating newline
		D0=A

--		A=DAT0	W	<---------------+
		P=	1			|
		?A=0	P			|
		GOYES	+	--------+	|
-		P=	3	<-------|--+	|
		?A=0	P		|  |	|
		GOYES	+	--------+  |	|
		P=	5		|  |	|
		?A=0	P		|  |	|
		GOYES	+	--------+  |	|
		P=	7		|  |	|
		?A=0	P		|  |	|
		GOYES	+	--------+  |	|
		P=	9		|  |	|
		?A=0	P		|  |	|
		GOYES	+	--------+  |	|
		P=	11		|  |	|
		?A=0	P		|  |	|
		GOYES	+	--------+  |	|
		P=	13		|  |	|
		?A=0	P		|  |	|
		GOYES	+	--------+  |	|
		D0=D0+	16		|  |	|
		P=	15		|  |	|
		?A#0	P		|  |	|
		GOYES	--	--------|-------+
		D0=D0-	16		|  |
+		CD0EX		<-------+  |
		C+P+1			   |
		CD0EX			   |
		D0=D0-	2		   |
		A=DAT0	W		   |
		?A#C	B		   |
		GOYES	-	-----------+
		P=	0

		A=R4.F	A	Now check if we found the dummy to
		AD0EX		indicate end-of-file fith CRY
		D0=(2)	STREND
		C=DAT0	A
		D0=A
		?A=C	A
		RTNYES
		RTNCC

**********************************************************************
* Skip line. CS if no next line
* Uses: A[W] C[W] D0 D1
**********************************************************************
EdLine+		GOSUB	GetCurPos
Line+		GOSUB	LineEnd
		RTNC		Found end
		D0=D0+	2	Skip NL
		RTNCC
**********************************************************************
* Get start of line. CS if start of text
* Uses: B[A] C[A] D0 D1
**********************************************************************
EdLineStart	GOSUB	GetCurPos
LineStart	C=R4.F	A
		CD0EX
		D0=(2)	STR
		A=DAT0	A
		D0=C
		C=C-A	A
		CSRB.F	A
		B=C	A
		LCASC	'\n'
linstrlp	B=B-1	A
		RTNC			CS:Found start
		D0=D0-	2
		A=DAT0	B
		?A#C	B
		GOYES	linstrlp
		D0=D0+	2		Skip NL
		RTNCC			CC:Found chr1
**********************************************************************
* Skip to previous line. CS if no previous line
* Uses: B[A] C[A] D0 D1
**********************************************************************
EdLine-		GOSUB	GetCurPos
Line-		GOSUB	LineStart
		RTNC			CS:Found start
		D0=D0-	2
		GOSUB	linstrlp
		RTNCC			PrevLineStart
**********************************************************************
* Alloc N chars in CURPOS
* Update nonzero ptrs >= CURPOS
* Move block up
**********************************************************************
EdAllocP	C=0	A
		CPEX	0
EdAlloc		C=C+C	A
EdAllocC	D=C	A	Save D[A] = Need in nibbles
		?D=0	A
		GOYES	allocok
		A=R4.F	A
		D1=A
		D1=(2)	CUT
		C=DAT1	A
		D1=(2)	STREND
		A=DAT1	A
		C=C-A	A	Free amount
		?C<D	A
		RTNYES		No memory
		D1=(2)	CURPOS
		A=DAT1	A
		D1=(2)	UPDSTR
		AD1EX
-		AD1EX		<-------+
		C=DAT1	A		|
		?C<A	A		|
		GOYES	+	---+	|
		C=C+D	A	   |	|
		DAT1=C	A	   |	|
+		D1=D1+	5	<--+	|
		AD1EX			|
		LC(2)	UPDEND		|
		?A<C	B		|
		GOYES	-	--------+
		AD1EX
		D1=(2)	STREND	Move up
		C=DAT1	A
		D1=C
		C=C-D	A
		D0=C
		C=C-A	A
		GOSBVL	=MOVEUP
allocok		GOTO	GetCurPos
**********************************************************************
* Delete N chars at CURPOS
* Update nonzero ptrs >= CURPOS
* Scratched locs put to CURPOS
* (DISPOK=0?)
**********************************************************************
EdRemoveP	C=0	A
		CPEX	0
EdRemove	C=C+C	A
EdRemoveC	D=C	A	Scratch
		?D=0	A
		GOYES	removok
		GOSUBL	GetCurPos
		D1=(2)	STREND	Move down
		A=DAT1	A
		D1=C
		C=C+D	A
		D0=C
		C=A-C	A
		GOSBVL	=MOVEDOWN

Update-D	A=R4.F	A
		D1=A
		D1=(2)	CURPOS
		A=DAT1	A
		D1=(2)	UPDSTR
		AD1EX
-		AD1EX		<-------+
		C=DAT1	A		|
		?C<A	A		|
		GOYES	++	-----+	|
		C=C-D	A	     |	|
		?C>=A	A	     |	|
		GOYES	+	---+ |	|
*		ST=0	sDISPOK	   | |	|
		C=A	A	   | |	|
+		DAT1=C	A	<--+ |	|
++		D1=D1+	5	<----+	|
		AD1EX			|
		LC(2)	UPDEND		|
		?A<C	B		|
		GOYES	-	--------+
removok
**********************************************************************
* Get cursor position to D0, data buffer to D1
* Uses: C[A] D0 D1
**********************************************************************
GetCurPos	C=R4.F	A	Return CURPOS
		D1=C
		D1=(2)	CURPOS
		C=DAT1	A
		D0=C
		RTNCC
**********************************************************************
* Get block start & size, CS if no block
**********************************************************************
GetBlk		C=R4.F	A
		D1=C
		D1=(2)	BLKEND
		C=DAT1	A
		D1=(2)	BLK
getsub?		A=DAT1	A
		C=C-A	A
		RTNC
		?C=0	A
		RTNYES
		?A=0	A
		RTNYES
		RTN
**********************************************************************
* Get clip start & size, CS if no clip
**********************************************************************
GetCut		C=R4.F	A
		D1=C
		D1=(2)	MEMEND
		C=DAT1	A
		D1=(2)	CUT
		GOTO	getsub?
**********************************************************************
* Get available memory if clip is ignored
**********************************************************************
GetCutFree	C=R4.F	A
		D1=C
		D1=(2)	STREND
		C=DAT1	A
		D1=(2)	MEMEND
		A=DAT1	A
		C=A-C	A
		RTN
**********************************************************************
* Get available memory
**********************************************************************
GetFree		C=R4.F	A
		D1=C
		D1=(2)	CUT
		C=DAT1	A
		D1=(2)	STREND
		GOTO	getsub
**********************************************************************
* Get total work memory
**********************************************************************
GetWork		C=R4.F	A
		D1=C
		D1=(2)	MEMEND
		GOTO	getstrsub
**********************************************************************
* Get text size
**********************************************************************
GetText		C=R4.F	A
		D1=C
		D1=(2)	STREND
getstrsub	C=DAT1	A
		D1=(2)	STR
getsub		A=DAT1	A
		C=C-A	A
		RTN

**********************************************************************
*		Cursor jump & calculation utilities
**********************************************************************


**********************************************************************
* In:	CURPOS
* Out:	XOFF CURSX WANTX
* Update only what is necessary!
* WANTX always updated
* Clears DISPOK if XOFF changes
**********************************************************************
ToThisX		GOSUBL	EdLineStart
		AD0EX
		R0=A.F	A
		GOTO	findnewX
**********************************************************************

**********************************************************************
* Given new cursor position setup the window parameters properly
* Input:	CURPOS
* Output:	TOPPOS XOFF CURSX CURSY
* Notes:	Updates are made only if absolutely necessary so that
*		simple cursor movement in the current window might
*		be enough
**********************************************************************

* Special entry which takes D0 instead of CURPOS as input

ToThisD0	C=R4.F	A
		D1=C
		D1=(2)	CURPOS
		CD0EX
		DAT1=C	A

ToThisPos	GOSUBL	EdLineStart
		AD0EX
		R0=A.F	A		R0[A] = ->linestart

		D=0	A
* Check whether up/down scrolling is necessary
		D1=(2)	TOPPOS
		C=DAT1	A		Current ->topline
		?C=A	A
		GOYES	topisok	Same as the wanted line - skip scroll
		?C>A	A		topline > wanted line ?
		GOYES	findnewtop	Yes - have to scroll
		D0=C			->topline
-		GOSUB	Line+	<-------+
		D=D+1	A		|	lines++
		CD0EX			|
		D0=C			|
		A=R0.F	A		|	->wantline
		?C>=A	A		|	line >= wantline ?
		GOYES	topisok		|	Yes - wantline is on screen!
		LC(1)	12	9	|
		?D<C	P		|	Still possible to be on screen?
		GOYES	-	--------+	Yes - continue loop
* TOPPOS is invalid, screen has to be scrolled up/down.
* Algorithm:	Skip back 5 rows from wantline so the wanted line will
*		be in the middle of the screen.

findnewtop	ST=0	sDISPOK		Display will have to be updated
		A=R0.F	A
		D0=A			->wantline
		LC(1)	6	5	5 rows to skip
		D=C	A
-		D=D-1	P	<-------+
		GOC	+	----+	|
		GOSUB	Line-	    |	|
		GONC	-	----|---+
+		D1=(2)	TOPPOS	<---+
		AD0EX
		DAT1=A	A		Set new TOPPOS
		D1=(2)	CURSY		New CURSY is of course 5-1 now
		LC(1)	6-1	5-1
		C=C-D	P
		DAT1=C	P
		GOTO	findnewX

* TOPPOS was valid, the wanted line is on the screen. Set new CURSY

topisok		D1=(2)	CURSY
		C=D	A
		DAT1=C	1

* Now TOPPOS and CURSY are valid. Calculate XOFF and CURSX
* R0[A] = ->wantline

findnewX
* 1st count visible X position
		A=R0.F	A
		D0=A			->wantline
		GOSUB	Pos>Xoff	D[A] = XOFF'
		D1=(2)	XOFF
		C=DAT1	A		Old XOFF
		D=D-C	A		XOFF' - XOFF
		GOC	newxoffless	Old XOFF is too big
		LC(5)	32
		?D>C	A
		GOYES	newxoffmore
		D1=(2)	CURSX		Can handle it with cursor X movement!
		C=D	A
		DAT1=C	B
		GOTO	SetWantX
newxoffmore	C=DAT1	A		XOFF
newxoffless	ST=0	sDISPOK		Have to scroll, display won't be ok
		D=D+C	A
		LC(5)	32
		D=D-C	A
		GONC	biggerxoff
		C=C+D	A
		D=0	A
biggerxoff	D1=(2)	CURSX
		DAT1=C	B
		D1=(2)	XOFF
		C=D	A
		DAT1=C	A
**********************************************************************
* Set new WANTX to be the position indicated by XOFF & CURSX
**********************************************************************
SetWantX	C=R4.F	A
		D1=C
		D1=(2)	XOFF
		A=DAT1	A		XOFF
		D1=(2)	CURSX
		C=0	A
		C=DAT1	B		CURSX
		A=A+C	A
		D1=(2)	WANTX
		DAT1=A	A		WANTX = XOFF + CURSX
		RTNCC
**********************************************************************
* Calculate XOFF for cursor position on current line
* Input:	CURPOS
* Output:	D[A] = XOFF
*		D0 = ->curpos (?)
**********************************************************************
POS>XOFF	GOSUBL	EdLineStart
Pos>Xoff	D1=(2)	CURPOS
		C=DAT1	A
		AD0EX
		D0=A
		C=C-A	A			curpos - linestart
		CSRB.F	A
		B=C	A			chars to curpos
		D=0	A
-		LCASC	'\t'	<-------+
		B=B-1	A		|	chars--
		RTNC			|
		D=D+1	A		|	xoff++
		A=DAT0	B		|
		D0=D0+	2		|
		?A#C	B		|
		GOYES	-	--------+
		D=D-1	A		|	Fix back: xoff--
		LC(1)	8		|
		D=D&C	P		|	Go down to even 8
		D=D+CON	A,8		|	And then skip 8 for tab
		GONC	-	--------+
**********************************************************************
SafeWantPos	C=R4.F	A
		D1=C
		D1=(2)	WANTX
		C=DAT1	A
		RSTK=C
		GOSUB	ToThisWant
		GOSUB	ToThisPos
		C=R4.F	A
		D1=C
		D1=(2)	WANTX
		C=RSTK
		DAT1=C	A
		RTN
		
**********************************************************************
* Given new cursor position on line via WANTX calculate proper new
* coordinates.
* Input:	D0	= ->wantline
*		WANTX (XOFF CURSX as old values)
* Output:	CURPOS XOFF'
* Notes:
*	Assumes WANTX>=XOFF+CURSX
**********************************************************************
ToThisWant	GOSUB	SkipToXOFF
		GONC	xofffits
* Wanted XOFF too big, have to scroll left.
* Set Cursor & XOFF to last chr
		ST=0	sDISPOK		Display not ok
		D1=(2)	XOFF
		C=DAT1	A
		C=C-D	A
		DAT1=C	A
		D1=(2)	CURSX
		A=0	B
		DAT1=A	B
		D1=(2)	CURPOS
		AD0EX
		DAT1=A	A
		RTN
* Calculate new XOFF, CURSX and CURPOS
xofffits	D1=(2)	WANTX
		C=DAT1	A
		D1=(2)	XOFF
		A=DAT1	A
		C=C-A	A
		D=D+C	A
		GOSUB	SkipAfterNth
		D1=(2)	CURPOS
		AD0EX
		DAT1=A	A
		D1=(2)	WANTX
		C=DAT1	A
		D1=(2)	XOFF
		A=DAT1	A
		C=C-A	A
		D1=(2)	CURSX
		C=C-D	A
		DAT1=C	B
		A=0	A
		LA(2)	32
		C=C-A	A
		RTNC
		DAT1=A	B
		D1=(2)	XOFF
		A=DAT1	A
		A=A+C	A
		DAT1=A	A
		ST=0	sDISPOK
		RTN
**********************************************************************
* Seek proper place to start displaying characters given the X-scroll offset.
* Optimization of this subroutine is crucial to the speed of display
* when long lines are present. Typically long lines entail data sequences
* containing only hex chars, thus the optimization should be done that
* in mind.
* Input:	D0   = ->line start
*		D[A] = XOFF
* Output:	CS:	XOFF larger than line lenght, no chars left to show
*			D0   = ->last char
*			D[A] = XOFF - last
*		CC:	XOFF fits
*			B[A] = chars until end	B[S] = tab counter
*			1) D[A] = 0		D0 = ->Nth char
*			2) D[A] = unskipped	D0 = ->tabulator
**********************************************************************

* Alternative entry which fetches the XOFF
SkipToXOFF	C=R4.F	A	
		D1=C
		D1=(2)	XOFF
		C=DAT1	A
		D=C	A
* Skip to Nth character position
SkipToNth	C=R4.F	A
		D1=C
		D1=(2)	STREND
		C=DAT1	A
		B=C	A		->strend
		AD0EX			->linestart
		D0=A
		B=B-A	A
		RTNC			Just in case!
		BSRB.F	A		B[A]=chars to end

skipx0loop	B=0	S	<---------+	Init tab counter
* Special entry into the loop		  |
SkipAfterNth	LCASC	'\n'		  |			
-		D=D-1	A	<-------+ |	xoff--
		GOC	skippedx ---+	| |	Got Exact!
		B=B-1	A	    |	| |	chars--
		GOC	skipunfit -+|	| |	No fit!
		A=DAT0	B	   ||	| |
		D0=D0+	2	   ||	| |
		B=B+1	S	   ||	| |	tabctr++
		?A>C	B	   ||	| |
		GOYES	-	---||---+ |
		LC(1)	'\t'	   ||	| |
		?A=C	B	   ||	| |
		GOYES	skipxtab --||-+	| |	Skip tabulator
		LC(1)	'\n'	   || |	| |
		?A#C	B	   || |	| |
		GOYES	-	---||-|-+ |
		D0=D0-	2	   || |	  |	Back to newline
skipunfit	D=D+1	A	<--+| |	  |	XOFF too big, no chars left
		RTNSC		    | |	  |
skippedx	D=0	A	<---+ |	  |	Exact skip!
		RTNCC		      |	  |
* Skip tabulator, adjusting counters accordingly
skipxtab	B=B-1	S	<-----+	  |	Fix back: tabctr--
		D=D+1	A		  |	Fix back: xoff++
		C=B	S		  |	tabctr
		P=C	15		  |	tabctr
		C=0	A		  |
		CPEX	0		  |	tabctr
		C=-C-1	P		  |	-tabctr
		CBIT=0	3		  |	(-tabctr) AND 7
		C=C+1	P		  |	Width taken by tab
		D=D-C	A		  |	Remove width from XOFF
		GONC	skipx0loop  ------+	tab fits, continue
* tab doesnt fit! Return tab + unskipped amount
		D=D+C	A
		D0=D0-	2
		RTNCC

**********************************************************************
*		Cursor Handling Subroutines
**********************************************************************
ClrCurs
		?ST=0	sCURSOR
		RTNYES
		GONC	TogCurs
SetCurs
		?ST=1	sCURSOR
		RTNYES

TogCurs
		?ST=1	sCURSOR
		GOYES	cursoff
		ST=1	sCURSOR
		GONC	curstog
cursoff		ST=0	sCURSOR
curstog		C=R4.F	A
		D1=C
		D1=(2)	CURSY
		C=0	A
		C=DAT1	1
		P=C	0
		CPEX	1	#11*
		C=C+C	A	#22*
		C=C+C	A	#44*
		A=C	A
		C=C+C	A	#88*
		A=A+C	A	#CC*
		D1=(2)	CURSX
		C=0	A
		C=DAT1	B
		A=A+C	A
		D1=(5)	=aADISP
		C=DAT1	A
		D1=C
		C=DAT1	A
		A=A+C	A
		LC(5)	1*34+20		20+2*34
		A=A+C	A
		D1=A
		
		P=	16-6
curstoglp
		A=DAT1	B
		A=-A-1	B
		DAT1=A	1
		D1=D1+	16
		D1=D1+	16
		D1=D1+	2
		P=P+1
		GONC	curstoglp
		RTNCC
**********************************************************************
*		Fast Display Movement Keys
**********************************************************************
ViewDn		GOSUB	ScrollUp
DispLastLine
		A=R4.F	A
		D0=A
		D0=(2)	TOPPOS
		A=DAT0	A
		D0=A
		LC(1)	12-1		9-1
		D=C	P
shxlstlp
		GOSUB	Line+
		GOC	shwlstnox
		D=D-1	P
		GONC	shxlstlp
shwlstnox
		P=	13-1		10-1
		GOTO	DispEdLine
**********************************************************************
ViewUp		GOSUB	ScrollDn
DispFirstLine
		A=R4.F	A
		D0=A
		D0=(2)	TOPPOS
		A=DAT0	A
		D0=A
*		P=	0
		GOTO	DispEdLine
**********************************************************************
ViewRt		GOSUB	ScrollLt
		A=R4.F	A
		D1=A
		D1=(2)	TOPPOS
		A=DAT1	A
		D0=A
		D=0	S
displastlp
		C=R4.F	A
		D1=C
		D1=(2)	XOFF
		C=DAT1	A
		D=C	A
		LC(5)	32
		D=D+C	A
		GOSUB	SkipToNth
		LC(2)	#20
		GONC	displast10
		ST=0	sBLKINV
		RSTK=C
		GOC	displast30	
displast10
		?D#0	A	
		GOYES	displast20
		?B=0	A
		GOYES	displast20
		C=DAT0	B
displast20
		RSTK=C
		GOSUB	BlkInv?
displast30
		C=D	S
		P=C	15
		GOSUB	GetDispRow
		D1=D1+	16
		D1=D1+	16
		C=RSTK
		GOSUB	EdDispChr!	\n as space
		GOSUB	Line+
		D=D+1	S
		P=	15
		LC(1)	13		#A
		P=	0
		?D<C	S
		GOYES	displastlp
		RTN
**********************************************************************
ViewLt		GOSUB	ScrollRt
		A=R4.F	A
		D1=A
		D1=(2)	TOPPOS
		A=DAT1	A
		D0=A
		D=0	S
disp1stlp
		GOSUB	SkipToXOFF
		LC(2)	#20
		GONC	disp1st10
		ST=0	sBLKINV
		RSTK=C
		GOC	disp1st30
disp1st10
		?D#0	A
		GOYES	disp1st20
		?B=0	A
		GOYES	disp1st20
		C=DAT0	B
disp1st20
		RSTK=C
		GOSUB	BlkInv?
disp1st30
		C=D	S
		P=C	15
		GOSUB	GetDispRow
		C=RSTK
		GOSUB	EdDispChr!	\n as space
		GOSUB	Line+
		D=D+1	S
		P=	15
		LC(1)	13		#A
		P=	0
		?D<C	S
		GOYES	disp1stlp
		RTN
**********************************************************************
*		Display Scrolling Subroutines
**********************************************************************
ScrollUp	GOSUB	GetDispRow1
		LC(5)	6*34
		A=A+C	A
		D0=A
		LC(5)	12*6*34		9*6*34
		GOVLNG	=MOVEDOWN
**********************************************************************
ScrollDn
		GOSUB	GetDispRow1
		LC(5)	12*6*34		9*6*34
		A=A+C	A
		D0=A
		LC(5)	6*34
		A=A+C	A
		D1=A
		LC(5)	12*6*34		9*6*34
		GOVLNG	=MOVEUP
**********************************************************************
ScrollLt
		GOSUB	GetDispRow1
		D0=C
		D0=D0+	1
		LC(3)	13*6-1		10*6-1
scrltlp		A=DAT0	W
		DAT1=A	W
		D0=D0+	16
		D1=D1+	16
		A=DAT0	W
		DAT1=A	W
		D0=D0+	16
		D1=D1+	16
		DAT1=C	XS
		D0=D0+	2
		D1=D1+	2
		C=C-1	B
		GONC	scrltlp
		RTN
**********************************************************************
ScrollRt
		GOSUB	GetDispRow1
		LC(5)	13*6*34-1	10*6*34-1
		A=A+C	A
		D1=A
		D0=A
		D0=D0-	1
		LC(3)	13*6-1		10*6-1
scrrtlp		D0=D0-	16
		D1=D1-	16
		A=DAT0	W
		DAT1=A	W
		D0=D0-	16
		D1=D1-	16
		A=DAT0	W
		DAT1=A	W
		D0=D0-	2
		D1=D1-	2
		DAT0=C	XS
		C=C-1	B
		GONC	scrrtlp
		RTN
**********************************************************************
*		General Display Subroutines
**********************************************************************

**********************************************************************
* Clear unused display areas
**********************************************************************
InitDisp	GOSUBL	GetDispRow1
		LC(5)	1*34		2*34
		A=A-C	A
		D1=A
		GOSBVL	=WIPEOUT
		P=	13		10
		GOSUBL	GetDispRow
		LC(5)	1*34	2*34
		GOVLNG	=WIPEOUT
**********************************************************************
* Clear full display area
**********************************************************************
ClrDisp		LC(5)	80*34		64*34
ClrDispC	D1=(5)	=aADISP		Special entry to clear top C[A]
		A=DAT1	A
		D1=A
		A=DAT1	A
		D1=A
		D1=D1+	16
		D1=D1+	4
		GOVLNG	=WIPEOUT
**********************************************************************
GetDispRow1	P=	0
GetDispRow	C=0	A
		C=P	0
		CPEX	1	#11
		A=C	X
		C=C+C	X	#22
		C=C+A	X	#33
		C=C+C	X	#66
		C=C+C	X	#CC
		D1=(5)	=aADISP
		A=DAT1	A
		D1=A
		A=DAT1	A
		A=A+C	A
		LC(5)	1*34+20		20+2*34
		C=C+A	A
		A=C	A
		D1=C
		RTN	
**********************************************************************
DispCurChr
		?ST=0	sDISPOK
		RTNYES
		C=R4.F	A
		D1=C
		D1=(2)	CURPOS
		A=DAT1	A
		D0=A
		D1=(2)	CURSY
		C=DAT1	1
		P=C	0
		GOSUB	GetDispRow
		C=R4.F	A
		CD1EX
		D1=(2)	CURSX
		A=0	A
		A=DAT1	B
		C=C+A	A
		D1=C
		GOSUB	BlkInv?
		C=DAT0	B
		GOSUB	EdDispChr!	\n as spc
		C=R4.F	A
		D1=C
		RTNCC	
**********************************************************************
DispEd		?ST=0	sDISPOK
		GOYES	disped
		?ST=0	sLINBAD
		RTNYES
* Redisplay current line
		GOSUBL	EdLineStart
		D1=(2)	CURSY
		C=DAT1	S
		P=C	15
		GOTO	DispEdLine
* Redisplay entire display
disped		A=R4.F	A
		D1=A
		D1=(2)	TOPPOS
		A=DAT1	A
		D0=A
		D=0	S
dispedlp
		C=D	S
		P=C	15
		GOSUB	DispEdLine
		D=D+1	S
		P=	15
		LC(1)	13		#A
		P=	0
		?D<C	S
		GOYES	dispedlp
		RTN
**********************************************************************
DispEd9		A=R4.F	A
		D1=A
		D1=(2)	TOPPOS
		A=DAT1	A
		D0=A
		D=0	S
disped9lp	C=D	S
		P=C	15
		GOSUB	DispEdLine
		D=D+1	S
		P=	15
		LC(1)	13-1		9
		P=	0
		?D<C	S
		GOYES	disped9lp
		RTN
**********************************************************************
DispEdLine
		GOSUB	GetDispRow
		RSTK=C
		C=R4.F	A
		D1=C
		GOSUB	SkipToXOFF
		A=C	A
		C=RSTK
		D1=C
		C=A	A
		GONC	ExpndNow
* No BLKINV here
		LC(5)	6*34
		GOSBVL	=WIPEOUT
		GOLONG	Line+
ExpndNow
		?D=0	A
		GOYES	expskpok
		C=C-D	A
		D=C	A
		GOSUB	BlkInv?
		C=D	B
		C=C-1	B
		GOSUB	DispSpcs
		D0=D0+	2
expskpok
		LC(5)	#20
		CDEX	A
		D=D-C	A
		A=R4.F	A
		AD1EX
		D1=(2)	XOFF
		C=DAT1	S
		C=-C-1	S
		D1=A
* Expand max D[B],B[A] chars
expandlp
		B=B-1	A
		GOC	explstend
		GOSUB	BlkInv?
		A=DAT0	B
		D0=D0+	2
		LCASC	'\n'
		?C=A	B
		GOYES	expnewline
		LC(1)	#09
		?C=A	B
		GOYES	exptab
		GOSUB	EdDispChrA
		D=D-1	B
		GONC	expandlp
expandok
		GOLONG	Line+
exptab		P=C	15
		C=P	0
		P=	0
		C=C+D	P
		CBIT=0	3
		C=C+1	P
		D=D-C	B
		GOC	exptabend
		C=C-1	B
		GOSUB	DispSpcs
		GOC	expandlp
exptabend
		C=C+D	B
		GOSUB	DispSpcs
		GOLONG	Line+
explstend
		ST=0	sBLKINV
expnewline
		LCASC	' '
		GOSUB	EdDispChr
		ST=0	sBLKINV
		C=D	B
		C=C-1	B
		RTNC
		GOTO	DispSpcs
**********************************************************************
BlkInv?		A=R4.F	A
		AD0EX
		D0=(2)	BLK
		C=DAT0	A
		?C=0	A
		GOYES	noblkinv
		?A<C	A
		GOYES	noblkinv
		D0=(2)	BLKEND
		C=DAT0	A
		?A>=C	A
		GOYES	noblkinv
		AD0EX
		ST=1	sBLKINV
		RTN
noblkinv
		AD0EX
		ST=0	sBLKINV
		RTN	
**********************************************************************
* Write C[B]+1 spaces
* Uses:	A[W] C[X] P D1
**********************************************************************
DispSpcs
		P=	6-1
		C=P	2
		P=C	0
		CSR	B
		A=0	W
		?ST=0	sBLKINV
		GOYES	expspcplp
		A=-A-1	W
expspcplp
		DAT1=A	WP
		D1=D1+	16
		D1=D1+	16
		D1=D1+	2
		C=C-1	XS
		GONC	expspcplp
		CD1EX
		C+P+1
		P=	0
		LA(5)	6*34
		C=C-A	A
		CD1EX
expspcslp
		C=C-1	P
		RTNC
		P=	6-1
		C=P	2
		P=	0
		A=0	A
		?ST=0	sBLKINV
		GOYES	expspcwlp
		A=-A-1	A
expspcwlp
		DAT1=A	W
		D1=D1+	16
		D1=D1+	16
		D1=D1+	2
		C=C-1	XS
		GONC	expspcwlp
		CD1EX
		LA(5)	6*34-16
		C=C-A	A
		CD1EX
		GONC	expspcslp
**********************************************************************

EdDispChr!	LAASC	'\n'
		?A#C	B
		GOYES	EdDispChr
		LCASC	' '
		GONC	EdDispChr
EdDispChrA
		C=A	B
EdDispChr	P=	2
		LCHEX	000
		P=	0

*		C=C+C	X		old code for font data (use R2)
*		A=C	X
*		C=C+A	X
*		C=C+A	X
*		A=R2.F	A
*		C=C+A	A

		C=C+C	A
		A=C	A		2*chr
		A=A+C	A		4*chr
		A=A+C	A		6*chr
		LC(5)	=MINI_FONT
		C=C+A	A

		CD1EX
		A=DAT1	6
		D1=C
		?ST=0	sBLKINV
		GOYES	dspchr10
		P=	6-1
		A=-A-1	WP
		P=	0
dspchr10
		DAT1=A	P
		D1=D1+	16
		D1=D1+	16
		D1=D1+	2
		P=	1
		DAT1=A	P
		D1=D1+	16
		D1=D1+	16
		D1=D1+	2
		P=	2
		DAT1=A	P
		D1=D1+	16
		D1=D1+	16
		D1=D1+	2
		P=	3
		DAT1=A	P
		D1=D1+	16
		D1=D1+	16
		D1=D1+	2
		P=	4
		DAT1=A	P
		D1=D1+	16
		D1=D1+	16
		D1=D1+	2
		P=	5
		DAT1=A	P
		P=	0
		D1=C
		D1=D1+	1
		RTNCC
**********************************************************************
DispRow:Ret
		GOSUBL	GetDispRow
Disp:Ret
		ST=0	sBLKINV
		C=RSTK
		D0=C
dspretlp
		C=DAT0	B
		D0=D0+	2
		?C=0	B
		GOYES	dspretnow
		GOSUB	EdDispChr
		GONC	dspretlp
dspretnow
		CD0EX
		PC=C
**********************************************************************
Disp2Dec6B
		C=B	A
Disp2Dec6
		CSRB.F	A
DispDec6
		A=0	W
		A=C	A
		GOSUB	ToDecRoll
		C=0	A
		CPEX	0
		C=C-CON	A,10
		AD1EX
		A=A+C	A
		AD1EX
		C=-C-1	P
		C=C-CON	B,10
		CSRC
		ST=0	sBLKINV
dspdeclp
		BSLC
		LCASC	'9'
		BCEX	P
		?C<=B	P
		GOYES	dspdec10
		C=C+CON	B,7
dspdec10
		GOSUB	EdDispChr
		C=C-1	S
		GONC	dspdeclp
		RTN
**********************************************************************
* Out:	A[W]=dec A[S]=1st <>0
*	P=skipped zeros
**********************************************************************
ToDecRoll
		GOSBVL	=HXDCW
		SETHEX
		P=	15
		?B=0	W
		RTNYES
rlleadlp
		P=P+1
		?B#0	S
		RTNYES
		BSL	W
		GONC	rlleadlp
**********************************************************************
*		ED Character Catalog
**********************************************************************
EdChrCat	ST=1	sCHRMAIN	Flag catalog called from main loop
* Special entry here for InputChrCat
ChrCat		GOSUBL	EdClrArg	No repeat!
		GOSUB	SwapCurs2	Swap cursors
		GOSUB	InitCC		Init catalog (current character)
		GOSUB	DispCC		Display catalog
		ST=0	sREPEAT		No key repeat yet
CCLOOP		GOSUB	CCSetCurs	Show catalog cursor
		GOSUB	DispCC1		Display catalog info line
		ST=1	sBLINK		Allow blink
		GOSUBL	WaitKey		Wait for key
		GOSUBL	AdjustKey	Adjust for shifts
		GOSUBL	ClrCurs		Clear cursor
		ST=1	sREPEAT		Allow repeat by default
		GOSUB	DoCCKey		Do the key
		GOTO	CCLOOP		And loop
**********************************************************************
* Initialize character catalog
**********************************************************************
InitCC		GOSUBL	EdEnd?		At end of text
		A=0	A
		GOC	inicc1		Yes - init cursor to char 0
		A=DAT0	B		Else read current character
inicc1		D1=(2)	CCCHR		And init CC cursor to position
		DAT1=A	B
		RTN
**********************************************************************
* Set CC cursor on
**********************************************************************
CCSetCurs	C=R4.F	A
		D1=C
		D1=(2)	CCCHR
		A=DAT1	B		A[B] = character
		D1=(2)	CURSX
		LC(2)	#1F
		C=C&A	B
		DAT1=C	B		Cursor X = char & #1F
		D1=(2)	CURSY
		ASR	A
		ASRB.F	P
		DAT1=A	P		Cursor Y = char>>5
		GOLONG	SetCurs
**********************************************************************
* Swap CC and editor cursors
**********************************************************************
SwapCurs2	C=R4.F	A
		D1=C
		D0=C
		D1=(2)	CURSX
		D0=(2)	SAVEX2
		A=DAT1	A		CURSX[B] and CURSY[XS]
		C=DAT0	A
		DAT1=C	X
		DAT0=A	X
		RTN
**********************************************************************
* This is called only once to show all the characters
**********************************************************************
DispCC		LC(5)	80*34		64*34		Offset past info line
		?ST=1	sCHRMAIN
		GOYES	+
		LC(5)	72*34		56*34		When input line is active
+		GOSUBL	ClrDispC
		GOSUBL	GetDispRow1
		B=0	B
-		C=B	B	<-------+
		ST=0	sBLKINV		|
		GOSUBL	EdDispChr	|
		B=B+1	B		|
		RTNC			|	OK
		?B#0	P		|
		GOYES	-	--------+
		C=B	B		|
		?CBIT=1	4		|
		GOYES	-	--------+
		LC(5)	6*34-32		|
		AD1EX			|
		A=A+C	A		|
		AD1EX			|
		GONC	-	--------+
**********************************************************************
* This is called after every key to update catalog display on
* the part of the charater information line.
**********************************************************************
DispCC1		P=	13-1		10-1		Last line by default
		?ST=1	sCHRMAIN
		GOYES	+
		P=P-1			Unless input line is active
+		GOSUBL	GetDispRow

		GOSUBL	Disp:Ret	* Display key info
		CSTRING	'Key:'
		D1=D1+	1
* Now find character from character table
		C=R4.F	A
		D0=C
		D0=(2)	CCCHR
		C=0	A
		C=DAT0	B
		?C=0	B
		GOYES	nonkeyed	* No key for chr00
		B=C	A
--		A=B	A	<----------+
		GOSUBL	GetChrPlane	   |
		D0=C			   |	->plane
		LC(2)	(=ENTERCODE)-1		(=PLUSCODE)-1		   |
-		A=DAT0	B	<-------+  |
		?A=B	B		|  |
		GOYES	+		|  |
		D0=D0+	2		|  |
		C=C-1	B		|  |
		GONC	-	--------+  |
		B=B+1	XS		   |
		LC(3)	#500		   |
		?B<=C	XS		   |
		GOYES	--	-----------+
nonkeyed	GOSUBL	Disp:Ret
		CSTRING	'    '
		GOTO	dispcc1char
* Display the code for the found key. B[XS]=plane C[B]=keycode
+		LA(3)	#A00+(=ENTERCODE)	#900+(=PLUSCODE)
		A=A-C	B		True keycode
		LC(2)	=PLUSCODE	=MINUSCODE	#2C
		?A>C	B
		GOYES	+
		A=A-1	XS
		LC(1)	=MINUSCODE	=TIMESCODE	#27
		?A>C	B
		GOYES	+
		A=A-1	XS
		LC(1)	=TIMESCODE	=DIVCODE	#22
		?A>C	B
		GOYES	+
		A=A-1	XS
		LC(2)	=DIVCODE	=BACKCODE	#1D
		?A>C	B
		GOYES	+
		A=A-1	XS
		LC(1)	=TANCODE	=INVCODE	#18
		?A>C	B
		GOYES	+
		A=A-1	XS
		LC(1)	=BACKCODE	=RIGHTCODE	#12
		?A>C	B
		GOYES	+
		A=A-1	XS
		LC(2)	=RIGHTCODE	#0C
		?A>C	B
		GOYES	+
		A=A-1	XS
		LC(2)	=UPCODE		=RIGHTCODE	#0C
		?A>C	B
		GOYES	+
		A=A-1	XS
		LC(1)	=Sfkey6		#06
		?A>C	B
		GOYES	+
		A=A-1	XS
		C=0	A		#00
+		A=A-C	B		A[XS]=row A[B]=column B[XS]=plane-1
		ASL	B
		ASL	A
		BSR	A
		BSR	A
		A=B	P
		A=A+1	A
		P=	4-1
		GOSUB	DispHexP
		D1=D1-	2
		LCASC	'.'
		GOSUB	EdDispChr
		D1=D1+	1

dispcc1char	D1=D1+	1
		GOSUBL	Disp:Ret	* Display char info
		CSTRING	'Chr:'
		D1=D1+	1		* Display character itself
		C=R4.F	A
		D0=C
		D0=(2)	CCCHR
		C=DAT0	B
		GOSUBL	EdDispChr
		D1=D1+	1		* Display char as hex
		LCASC	'#'
		GOSUBL	EdDispChr
		A=DAT0	B
		P=	2-1
		GOSUB	DispHexP
		D1=D1+	1		* Display char as dec
		A=0	W
		A=DAT0	B
		GOSBVL	=HXDCW
		SETHEX
		P=	3-1
		GOSUB	DispHexP
		D1=D1+	1		* Display char as binary
		LC(3)	#700
		C=DAT0	B
		B=C	X
-		LC(2)	'0'
		B=B+B	B	
		GONC	+
		LC(1)	'1'
+		GOSUBL	EdDispChr
		B=B-1	XS
		GONC	-
		RTN

**********************************************************************
DoCCKey		GOSUBL	DispatchKey:		CC if keys are forward!
CCKeyTab	EDKEY	(UPCODE)+(NS),CCup
		EDKEY	(LEFTCODE)+(NS),CClt
		EDKEY	(DOWNCODE)+(NS),CCdn
		EDKEY	(RIGHTCODE)+(NS),CCrt
		EDKEY	(UPCODE)+(RS),CCfarup
		EDKEY	(LEFTCODE)+(RS),CCfarlt
		EDKEY	(DOWNCODE)+(RS),CCfardn
		EDKEY	(RIGHTCODE)+(RS),CCfarrt
		EDKEY	(ENTERCODE)+(NS),CCecho
		EDKEY	(ONCODE)+(NS),CCexit
*		EDKEY	(ALPHACODE),EdModA	\	Not needed
*		EDKEY	(30)+(NS),AlphaOn		Not needed
*		EDKEY	(30)+(ANS),AlphaOff	/	Not needed
*		EDKEY	(SHIFTCODE),EdModLS	Not needed
		EDKEY	(RSCODE),EdModRS
		EDKEY	0,BadCCKey
**********************************************************************
BadCCKey
		ST=0	sREPEAT
		GOLONG	ErrBeep
**********************************************************************
CCexit		GOSUB	SwapCurs2		Restore editor cursor
		C=RSTK				Was a bug ?
		ST=0	sREPEAT
		ST=0	sDISPOK
		RTN				Return to caller

**********************************************************************
*		Echo CC character to text
**********************************************************************
CCecho
		GOSUB	SwapCurs2
		D0=(2)	CCCHR
		?ST=1	sCHRMAIN
		GOYES	+
		GOSUBL	DoInputChr	* Case 1: Echo in the input line
		GOSUBL	DispInput	*  and continue with ChrCat
		GOTO	SwapCurs2
*		C=RSTK			* Case 2: Echo in the input line
*		GOLONG	DoInputChr	*  and exit from ChrCat

+ 		C=DAT0	B		* Case 3: Echo to text
		ST=0	sDISPOK		*  and continue with ChrCat
		GOSUBL	DoEdChrKey
		GOTO	SwapCurs2
**********************************************************************
*		CC Cursor Movement Keys
**********************************************************************
CCup		LC(2)	#100-#20
		GONC	+	---+
CCdn		LC(2)	#20	   |
		GONC	+	---+
CClt		LC(2)	#100-1	   |
		GONC	+	---+
CCrt		LC(2)	#1	   |
+		D1=(2)	CCCHR	<--+
		A=DAT1	B
		A=A+C	B
		DAT1=A	B
		RTN
**********************************************************************
CCfarup		LC(2)	#1F
		GONC	+	---+
CCfarlt		LC(2)	#E0	   |
+		D1=(2)	CCCHR	<--+
		A=DAT1	B
		A=A&C	B
		GONC	++	--------+
CCfardn		LC(2)	#E0		|
		GONC	+	---+	|
CCfarrt		LC(2)	#1F	   |	|
+		D1=(2)	CCCHR	<--+	|
		A=DAT1	B		|
		A=A!C	B		|
++		DAT1=A	B	<-------+
		ST=0	sREPEAT
		RTN
**********************************************************************
DispHexP	B=A	W
		C=P	15
		A=C	S
		CD1EX
		C+P+1
		CD1EX
		D1=D1-	1
		P=	0
dsphplp		LCASC	'9'
		BCEX	P
		?C<=B	P
		GOYES	dsphp1
		C=C+CON	B,7
dsphp1		GOSUBL	EdDispChr
		D1=D1-	2
		BSR	W
		A=A-1	S
		GONC	dsphplp
		P=C	15
		CD1EX
		C+P+1
		CD1EX
		P=	0
		D1=D1+	1
		RTNCC

**********************************************************************
*		ED Keys Using the Input Line
**********************************************************************
EdInputArg	GOSUB	InputDec:
		CSTRING	'Arg: '
		GOC	Inargok		Cancelled
		GOSUB	EdInputToHex
		GOC	Inarger		Not valid input
		?B=0	W
		GOYES	Inarger		Zero repeat counter
		B=0	A
		?B#0	W
		GOYES	Inarger		Too big repeat counter
		C=R4.F	A
		D1=C
		D1=(2)	EDARG
		DAT1=A	A
Inargok		GOLONG	BackToEdMain	Don't repeat EdInputArg!!
Inarger		GOLONG	BadEdKey
**********************************************************************
EdInputPos	GOSUBL	EdClrArg	Don't repeat inputting!
		GOSUB	InputDec:	
		CSTRING	'Pos: '
		RTNC			Cancelled!
		GOSUB	EdInputToHex
		GOC	Inposer		Invalid numberr
		?A=0	W
		GOYES	Inposer		
		A=0	A
		?A#0	W
		GOYES	Inposer		Too big position
		GOSUBL	GetText
		C=C+A	A		STREND
		B=B-1	A
		A=A+B	A
		A=A+B	A		WANTED
		?A>C	A
		GOYES	Inposer		Over text end - Error
		D0=A
		GOLONG	ToThisD0
Inposer		GOLONG	BadEdKey
**********************************************************************
EdInputRow	GOSUBL	EdClrArg	Don't repeat inputting!
		GOSUB	InputDec:	
		CSTRING	'Row: '
		RTNC			Cancelled
		GOSUB	EdInputToHex
		GOC	Inrower		Invalid number
		?C=0	W
		GOYES	Inrower
		D=C	W
		GOSUBL	GetText
		D0=A
inrwlp		D=D-1	W
		?D=0	W
		GOYES	inrw!
		GOSUBL	Line+
		GONC	inrwlp
Inrower		GOLONG	BadEdKey
inrw!		GOLONG	ToThisD0
**********************************************************************
EdInputChr	GOSUBL	EdClrArg
		GOSUB	InputDec:	
		CSTRING	'Char: '
		RTNC
		GOSUB	EdInputToHex
		GOC	Inchrer
		A=0	W
		A=A+1	XS
		?C>=A	W
		GOYES	Inchrer
		GOLONG	DoEdChrKey
Inchrer		GOLONG	BadEdKey
**********************************************************************
EdInputToHex
		C=R4.F	A
		D1=C
		D1=(2)	INPLEN
		C=DAT1	B
		D=C	B
		D1=(2)	INP$
		B=0	W
		?D=0	B
		RTNYES
		A=0	W
inp>%lp		A=DAT1	B
		D1=D1+	2
		LCASC	'0'
		A=A-C	B
		RTNC
		LC(1)	'9'
		?A>C	P
		RTNYES
		?B#0	S
		RTNYES
		B=B+B	W	*2
		C=B	W
		B=B+B	W	*4
		B=B+B	W	*8
		B=B+C	W	*10
		B=B+A	W	+digit
		D=D-1	B
		?D#0	B
		GOYES	inp>%lp
		A=B	W
		C=A	W
		RTNCC

**********************************************************************
* Input global find/replace, position restored at end
**********************************************************************
EdReplSPos	GOSUBL	EdClrArg	No repeat
		ST=1	sFIND		Flag find mode
		ST=0	sINPDEC		Flag any characters
		GOSUB	Input:	
		CSTRING	'Find: '
		GOC	ReplEnd
		GOSUBL	EdUpdFindNext	Update find position (needed!)
		GOC	ReplEnd
		ST=0	sFIND		Flag not find mode
		ST=0	sINPDEC		Flag any characters
		GOSUB	Input:	
		CSTRING	'Repl: '
		GOC	ReplEnd
		GOSUBL	EdFarUp
		ST=0	sREPL?		Flag no questions asked
		GOSUBL	Replace		
ReplEnd		D1=(2)	SAVEPOS		Restore to start position
		C=DAT1	A
		D0=C
		GOLONG	ToThisD0

**********************************************************************
* Input global find/replace with verification, position restored at end
**********************************************************************
EdRepl?SPos	GOSUBL	EdClrArg	No repeat
		ST=1	sFIND		Flag find mode
		ST=0	sINPDEC		Flag any characters
		GOSUB	Input:	
		CSTRING	'Find: '
		GOC	ReplEnd
		GOSUB	EdUpdFindNext	Update find position (needed!)
		GOC	ReplEnd
		ST=0	sFIND		Flag not find mode
		ST=0	sINPDEC		Flag any characters
		GOSUB	Input:	
		CSTRING	'Repl: '
		GOC	ReplEnd
		GOSUBL	EdFarUp
		ST=1	sREPL?		Flag questions asked
		GOSUBL	Replace		
		GOTO	ReplEnd

**********************************************************************
* Input find/replace, position restored at end
**********************************************************************
EdRepl		GOSUBL	EdClrArg	No repeat
		ST=1	sFIND		Flag find mode
		ST=0	sINPDEC		Flag any characters
		GOSUB	Input:	
		CSTRING	'Find: '
		RTNC			Aborted
		GOSUB	EdUpdFindNext	Update find position (needed!)
		RTNC			No match
		ST=0	sFIND		Flag not find mode
		ST=0	sINPDEC		Flag any characters
		GOSUB	Input:	
		CSTRING	'Repl: '
		RTNC			Aborted
		ST=0	sREPL?		Flag no questions asked
		GOLONG	Replace		
**********************************************************************
* Input find/replace with verification
**********************************************************************
EdRepl?		GOSUBL	EdClrArg	No repeat
		ST=1	sFIND		Flag find mode
		ST=0	sINPDEC		Flag any characters
		GOSUB	Input:	
		CSTRING	'Find: '
		RTNC			Aborted
		GOSUB	EdUpdFindNext	Update find position (needed!)
		RTNC			No match
		ST=0	sFIND		Flag not find mode
		ST=0	sINPDEC		Flag any characters
		GOSUB	Input:	
		CSTRING	'Repl: '
		RTNC			Aborted
		ST=1	sREPL?		Flag questions asked
		GOLONG	Replace		
**********************************************************************
* Input find string
**********************************************************************
EdFind		GOSUBL	EdClrArg	No repeat
		ST=1	sFIND		Flag find mode
		ST=0	sINPDEC		Flag any characters
		GOSUB	Input:
		CSTRING	'Find: '
		RTN
**********************************************************************
* Key press to find next match
**********************************************************************
EdFindNext	ST=0	sDISPOK		Display not ok
		GOSUB	EdUpdFind+	Update forwards
		RTNNC			Match
fnxterr		GOLONG	BadEdKey	No match - error
**********************************************************************
* Key press to find previous match
**********************************************************************
EdFindPrev	ST=0	sDISPOK		Display not ok
		GOSUB	EdUpdFind-	Update backwards
		RTNNC			Match
		GOC	fnxterr		No match - error

**********************************************************************
*		ED Input Subroutines
**********************************************************************
InputDec:	ST=0	sFIND
		ST=1	sINPDEC
Input:		C=RSTK
		D0=C
		GOSUB	DispPrompt
* Set return address
* B[A]=chars in prompt
		CD0EX
		RSTK=C
		GOSUB	InitInput
		?ST=1	sINPDEC
		GOYES	inp11
		GOSUBL	AlphaOn
inp11

InputLoop
		GOSUB	UnScroll9
		GOSUBL	DispEd9
		GOSUBL	SetCurs

		GOSUB	SwapCurs
		GOSUBL	DispInput

		ST=0	sCURSOR
		GOSUBL	SetCurs
		ST=1	sBLINK
		GOSUBL	WaitKey
		GOSUBL	AdjustKey
		GOSUBL	ClrCurs
		GOSUB	SwapCurs
		ST=1	sCURSOR
		GOSUBL	ClrCurs

		ST=1	sREPEAT
		ST=0	sDISPOK
		GOSUB	DoInputKey

		GOTO	InputLoop
**********************************************************************
DispInput
		P=	13-1		10-1
		GOSUBL	GetDispRow
		C=R4.F	A
		D0=C
		D0=(2)	INPOFF
		A=0	A
		A=DAT0	B
		CD1EX
		C=C+A	A
		CD1EX
		
		D0=(2)	INPLEN
		C=DAT0	B
		D0=D0+	2
		D=C	B	Chars
		LC(2)	33	\
		C=C-A	B	Spaces
		B=C	B	/
		ST=0	sBLKINV
dspinplp
		D=D-1	B
		GOC	dspdinp
		B=B-1	B
		C=DAT0	B
		D0=D0+	2
		GOSUBL	EdDispChr
		GONC	dspinplp
dspdinp		C=B	B
		C=C-1	B
		RTNC
		GOLONG	DispSpcs	
**********************************************************************
InitInput	C=R4.F	A	Prompt size
		D1=C
		D1=(2)	INPOFF
		C=B	A
		DAT1=C	B
		D1=(2)	SAVEX	X
		DAT1=C	B
		D1=(2)	SAVEY	Y (fixed)
		LC(1)	13-1	10-1
		DAT1=C	1
		D1=(2)	CURPOS	Pos
		C=DAT1	A
		D1=(2)	SAVEPOS
		DAT1=C	A
		D1=(2)	INPLEN	Len
		C=0	A
		DAT1=C	B
		?ST=0	sFIND
		RTNYES
		D1=(2)	FNDLEN
		DAT1=C	B
		RTN
**********************************************************************
DispPrompt	P=	13-1		10-1
		GOSUBL	GetDispRow
		LC(5)	6*34
		GOSBVL	=WIPEOUT
		LC(5)	6*34
		AD1EX
		A=A-C	A
		AD1EX
		B=0	A	Offset
		ST=0	sBLKINV
dspprlp		C=DAT0	B
		D0=D0+	2
		?C=0	B
		RTNYES
		GOSUBL	EdDispChr
		B=B+1	A
		GONC	dspprlp
**********************************************************************
SwapCurs	C=R4.F	A
		D1=C
		D0=C
		D1=(2)	CURSX
		D0=(2)	SAVEX
		A=DAT1	B
		C=DAT0	B
		DAT1=C	B
		DAT0=A	B
		D1=(2)	CURSY
		D0=(2)	SAVEY
		A=DAT1	1
		C=DAT0	1
		DAT1=C	1
		DAT0=A	1
		D1=(2)	XOFF
		RTN
**********************************************************************
UnScroll9	C=R4.F	A
		D1=C
		D1=(2)	CURSY
		A=DAT1	P
		LC(1)	12-1		9-1
		?A<=C	P
		RTNYES
		DAT1=C	P
		C=R4.F	A
		D1=C
		D1=(2)	TOPPOS
		A=DAT1	A
		D0=A
		GOSUBL	Line+
		AD0EX
		DAT1=A	A
		RTN
**********************************************************************
DoInputKey	GOSUBL	EdStrKey?
		GONC	+
		GOTO	DoInputStr
+		GOSUBL	EdChrKey?
		GONC	+
		GOTO	DoInputChr
+		GOSUBL	DispatchKey:
**********************************************************************
InputKeyTab
		EDKEY	(LEFTCODE)+(NS),InputLt
		EDKEY	(LEFTCODE)+(RS),InputFarLt
		EDKEY	(LEFTCODE)+(ANS),InputLt
		EDKEY	(LEFTCODE)+(ARS),InputFarLt
		EDKEY	(RIGHTCODE)+(NS),InputRt
		EDKEY	(RIGHTCODE)+(RS),InputFarRt
		EDKEY	(RIGHTCODE)+(ANS),InputRt
		EDKEY	(RIGHTCODE)+(ARS),InputFarRt
		EDKEY	(NXTCODE)+(NS),InpUpdFind+
		EDKEY	(DOWNCODE)+(NS),InputWord
		EDKEY	(DOWNCODE)+(ANS),InputWord
		EDKEY	(NXTCODE)+(LS),InpUpdFind-
		EDKEY	(ENTERCODE)+(NS),InputExit
		EDKEY	(ENTERCODE)+(ANS),InputExit
		EDKEY	(ONCODE)+(NS),InputAbort
		EDKEY	(ONCODE)+(ANS),InputAbort
		EDKEY	(TANCODE)+(NS),InputDel
		EDKEY	(BACKCODE)+(NS),InputBS
		EDKEY	(BACKCODE)+(ANS),InputBS
		EDKEY	(NXTCODE)+(RS),DoInputBlk
		EDKEY	(EVALCODE)+(RS),InputChrCat

*		EDKEY	(ALPHACODE),EdModA	\
		EDKEY	(32)+(NS),AlphaOn	  By Dan
		EDKEY	(32)+(ANS),AlphaOff
		EDKEY	(32)+(ALS),TogCase	/
		EDKEY	(LSCODE),EdModLS
		EDKEY	(RSCODE),EdModRS
		EDKEY	(EEXCODE)+(NS),TogBeep
		EDKEY	(EEXCODE)+(LS),TogCase
		EDKEY	(EEXCODE)+(RS),TogOver
		EDKEY	(ONCODE)+(RS),EdOFF

		EDKEY	0,BadInputKey
**********************************************************************
BadInputKey	ST=0	sREPEAT
		GOLONG	ErrBeep
**********************************************************************
* Abort input line
**********************************************************************
InputAbort	D1=(2)	INPLEN		Clear input
		C=0	A
		DAT1=C	B
		C=RSTK			Pop return address
		GOSUBL	AlphaOff	Alpha mode off
		ST=0	sDISPOK		Display not ok
		ST=0	sREPEAT		Repeat not ok
		RTNSC			Input wasn't ok
**********************************************************************
* Exit input
**********************************************************************
InputExit	C=RSTK			Pop return address
		GOSUBL	AlphaOff	Alpha mode off
		ST=0	sDISPOK		Display not ok
		ST=0	sREPEAT		Repeat not ok
		RTNCC			Input was ok

**********************************************************************
* Call Input ChrCat if Find/Replace [i.e. ST(sINPDEC)=ST(sCHRMAIN)=0 ]
**********************************************************************
InputChrCat	?ST=1	sINPDEC
		GOYES	BadInputKey
		GOLONG	ChrCat

**********************************************************************
* Move input cursor left
**********************************************************************
InputLt		D1=(2)	INPOFF
		C=DAT1	B		prompt lenght
		D1=(2)	SAVEX
		A=DAT1	B		cursor pos
		A=A-1	B
		GOC	badinparr	cursor overflow (no prompt?)
		?A<C	B		
		GOYES	badinparr	start of input
		DAT1=A	B
		RTN
badinparr	GOTO	BadInputKey
**********************************************************************
* Move input cursor right
**********************************************************************
InputRt		D1=(2)	INPLEN
		C=DAT1	B		input lenght
		D1=(2)	INPOFF
		A=DAT1	B		prompt lenght
		C=C+A	B		total X
		D1=(2)	SAVEX
		A=DAT1	B		cursor position
		A=A+1	B
		?A>C	B
		GOYES	+		End of input, insert new char
		DAT1=A	B
		RTN
+		?ST=1	sINPDEC
		GOYES	badinparr	Not find/repl
		D1=(2)	INPLEN
		A=0	A
		A=DAT1	B		input lenght
		D1=(2)	CURPOS
		C=DAT1	A
		C=C+A	A
		C=C+A	A		where to get the next char
		D1=(2)	STREND
		A=DAT1	A
		?C>=A	A
		GOYES	badinparr	No more chars in text
		D0=C			->char
		GOTO	DoInputChr	And insert it
**********************************************************************
* Move input cursor to start of input
**********************************************************************
InputFarLt	D1=(2)	INPOFF
		A=DAT1	B
		D1=(2)	SAVEX
		DAT1=A	B
		RTN
**********************************************************************
* Move input cursor to end of input
**********************************************************************
InputFarRt	D1=(2)	INPLEN
		A=DAT1	B
		D1=(2)	INPOFF
		C=DAT1	B
		A=A+C	B
		D1=(2)	SAVEX
		DAT1=A	B
		RTN
**********************************************************************
* Store possible current word in input line
**********************************************************************
InputWord	?ST=0	sINPDEC
		GOYES	+
-		GOTO	BadInputKey	Not when inputting a number
+		GOSUBL	EdThisWord	Find word
		GOC	-		No word under cursor - beep
		B=C	A
		LC(5)	INPMAX		Take max INPMAX characters
		?B>=C	A
		GOYES	+
		C=B	A
+		D1=(2)	INPOFF
		A=DAT1	A
		A=A+C	A
		D1=(2)	SAVEX
		DAT1=A	B		New cursor location
		D1=(2)	INPLEN
		DAT1=C	B
		C=C+C	B
		D1=D1+	2
		AD0EX
		D0=A
		B=A	A
		GOSBVL	=MOVEDOWN	Copy new input line to place
		A=B	A
		D0=A
		GOSUBL	ToThisD0	Change cursor to start of word
		GOTO	InpUpdFind	And update

**********************************************************************
* Delete char under cursor in input line
**********************************************************************
InputDel	A=0	A
		D1=(2)	SAVEX
		A=DAT1	B
		D1=(2)	INPOFF
		C=DAT1	B
		A=A-C	B	True X
		D1=(2)	INPLEN
		C=DAT1	B
		?A>=C	B
		GOYES	Ideler	Nothing left
		C=C-1	B
		DAT1=C	B	Len--
		D1=(2)	INP$
		CD1EX
		C=C+A	A
		C=C+A	A
		D1=C
		D0=C
		D0=D0+	2
		LC(5)	(INPMAX)-1
		C=C-A	A	Chars to move
		C=C+C	A
		GOSBVL	=MOVEDOWN
		GOTO	InpUpdFindNew
Ideler		GOTO	BadInputKey
**********************************************************************
* Delete char before cursor in input line
**********************************************************************
InputBS		C=0	A
		D1=(2)	INPOFF
		C=DAT1	B
		D1=(2)	SAVEX
		A=DAT1	B
		C=A-C	B	True X
		?C=0	B
		GOYES	Ibser
		A=A-1	B
		DAT1=A	B	X--
		D1=(2)	INPLEN
		A=DAT1	B
		A=A-1	B
		DAT1=A	B	Len--
		D1=(2)	INP$
		AD1EX
		A=A+C	A
		A=A+C	A
		D0=A
		D1=A
		D1=D1-	2
		LA(2)	INPMAX
		C=A-C	B
		C=C+C	A
		GOSBVL	=MOVEDOWN
		GOTO	InpUpdFindNew		
Ibser		GOTO	BadInputKey
**********************************************************************
* This should insert possible block into input string
**********************************************************************
DoInputBlk	GOTO	BadInputKey
**********************************************************************
DoInputChr	C=0	A
		C=C+1	A		1 char
		GONC	inp$key
**********************************************************************
DoInputStr	C=0	A
		C=DAT0	1		chars
		D0=D0+	1
* D[A]=CHARS D0=->STR + SKIP
* If CHARS = 1 SKIP=1
inp$key
		D=C	A		chars

		?ST=0	sINPDEC		Check char is decimal
		GOYES	inp$ok
		LC(1)	1
		?C#D	A
		GOYES	inp$bad
		A=DAT0	B	
		LCASC	'0'
		?A<C	B
		GOYES	inp$bad
		LC(1)	'9'
		?A<=C	B
		GOYES	inp$ok
inp$bad		GOTO	BadInputKey
inp$ok
		?ST=1	sOVERWR
		GOYES	inpover$
		GOTO	inpins$

* Overwrite string into input string

inpover$	A=R4.F	A
		D1=A
		D1=(2)	SAVEX
		A=DAT1	B		Cursor X
		D1=(2)	INPOFF	
		C=DAT1	B		Prompt lenght
		A=A-C	B		True X
		LC(2)	INPMAX
		C=C-A	B		Free chars
		?D<=C	B
		GOYES	iov$ok
		GOTO	BadInputKey	No room for the string

iov$ok		D1=(2)	INP$
		CD1EX
		C=C+A	B
		C=C+A	B
		CD1EX			->overwrite position
		C=D	A
		C=C+C	A		nibbles to write
		GOSBVL	=MOVEDOWN	Copy string
		LC(2)	1
		?C=D	B
		GOYES	inpov10		Char-key, skip 1 char only
		C=DAT0	1		Skip according to string key skip index
inpov10		AD1EX
		D0=A
		D1=A
		D1=(2)	SAVEX
		A=DAT1	B		Cursor X
		A=A+C	B		New X
		DAT1=A	B
		D1=(2)	INP$		Update INPLEN if necessary
		CD1EX
		D1=C
		AD0EX
		A=A-C	B
		ASRB.F	B
		D1=(2)	INPLEN
		C=DAT1	B
		?A<C	B
		GOYES	inpovok
		DAT1=A	B
inpovok		GOTO	InpUpdFind

* Insert string into input string

inpins$		A=R4.F	A
		D1=A
		D1=(2)	INPLEN
		A=DAT1	B
		LC(2)	INPMAX
		C=C-A	B	Free
		?D<=C	B
		GOYES	iins$ok
		GOTO	BadInputKey
iins$ok		CD0EX
		B=C	A	->$
		D1=(2)	SAVEX
		A=DAT1	B
		D1=(2)	INPOFF
		C=DAT1	B
		A=A-C	B	True X
		D1=(2)	(INP$)+2*(INPMAX)
		CD1EX
		D1=C
		C=C-D	A
		C=C-D	A
		D0=C
		LC(5)	=INPMAX
		C=C-A	B
		C=C-D	B
		C=C+C	A
		GOSBVL	=MOVEUP	D0=->$INSPOS
		C=B	A
		CD0EX
		D1=C
		C=D	A
		C=C+C	A
		GOSBVL	=MOVEDOWN
		LC(2)	1
		?C=D	B
		GOYES	inpins5
		C=DAT0	1
inpins5		D1=(2)	SAVEX
		A=DAT1	B
		A=A+C	B
		DAT1=A	B
		D1=(2)	INPLEN
		C=DAT1	B
		C=C+D	B
		DAT1=C	B
		GOTO	InpUpdFind
**********************************************************************
*		ED String Matching Code
**********************************************************************
InpToFind	C=R4.F	A
		D0=C
		D1=C
		D0=(2)	INPLEN
		D1=(2)	FNDLEN
		C=0	A
		LC(2)	2*(INPMAX)+2
		GOVLNG	=MOVEDOWN
**********************************************************************
* Update match position since find string changed
**********************************************************************
InpUpdFindNew	?ST=0	sFIND
		RTNYES			Not inputting a find string
		GOSUB	InpToFind	Copy input to find storage
		C=R4.F	A
		D0=C
		D0=(2)	SAVEPOS		Start from the saved original
		C=DAT0	A		cursor position
		D0=C
		GOSUB	UpdFindNext	Update forwards
		RTNNC			Found match
		GOTO	BadInputKey	No match - error
**********************************************************************
* Update match position forwards while in input line
**********************************************************************
InpUpdFind+	?ST=0	sFIND
		RTNYES			Not inputting a find string
		GOSUB	InpToFind	Copy input to find storage
		GOSUB	EdUpdFind+	Update forwards
		RTNNC			Found match
		GOTO	BadInputKey	No match - error
**********************************************************************
* Update match position backwards while in input line
**********************************************************************
InpUpdFind-	?ST=0	sFIND
		RTNYES			Not inputing a find string
		GOSUB	InpToFind	Copy input to find storage
		GOSUB	EdUpdFind-	Update backwards
		RTNNC			Found match
		GOTO	BadInputKey	No match - error
**********************************************************************
* Update match position forwards
**********************************************************************
EdUpdFind+	GOSUBL	GetCurPos	Start from cursor + 1
		D0=D0+	2
		GOTO	UpdFindNext	And update from there
**********************************************************************
* Update match position backwards
**********************************************************************
EdUpdFind-	GOSUBL	GetCurPos	Start from cursor - 1
		D0=D0-	2
		GOTO	UpdFindPrev
**********************************************************************
* Update match position in D0 while in input line
**********************************************************************
InpUpdFind	?ST=0	sFIND
		RTNYES
		GOSUB	InpToFind
		GOSUB	EdUpdFindNext
		RTNNC
		GOTO	BadInputKey
**********************************************************************
* Update editor match position
**********************************************************************
EdUpdFindNext	GOSUBL	GetCurPos

UpdFindNext	ST=0	sFNDCS		Assume not sensitive
		D1=(2)	FNDLEN
		C=DAT1	B
		?C=0	B
		RTNYES			Nothing to seek
		D=C	B		D[B] = length
		D1=(2)	FND$		->find string
* Determine case sensitivity from find string
-		D=D-1	B	<-------+
		GOC	+	---+	|	Tested all, not case sensitive
		A=DAT1	B	   |	|
		D1=D1+	2	   |	|
		LCASC	'a'	   |	|
		?A<C	B	   |	|
		GOYES	-	---|----+
		LCASC	'z'	   |	|
		?A>C	B	   |	|
		GOYES	-	---|----+
		ST=1	sFNDCS	   |	Found lower case ==> case sensitive
+		D1=(2)	FNDLEN	<--+
		A=0	A
		A=DAT1	B		length
		D1=(2)	STREND
		C=DAT1	A
		C=C-A	A
		C=C-A	A		End Addr of seek
		AD0EX
		D0=A
		C=C-A	A
		RTNC			No room for a match!
		CSRB.F	A
		D=C	A		Positions left to test
		D=D+1	A		Find matches at end of text too

* Now dispatch to separate find subroutines for speed
		?ST=1	sFNDCS
		GOYES	FindExact+
		GOTO	FindInExact+
**********************************************************************
* Case dependant search forwards
**********************************************************************
FindExact+

exactlp+	D1=(2)	FND$
		A=DAT1	B
		D=D-1	A
		RTNC			No positions left, no match
-		C=DAT0	B	<-------+
		D0=D0+	2		|
		?A=C	B		|
		GOYES	+	---+	|
		D=D-1	A	   |	|
		GONC	-	---|----+
		RTNSC		   |	No match
* First char matched, try the rest now
+		D1=(2)	FNDLEN	<--+
		A=DAT1	B
		B=A	B		Setup lenght counter
		D1=(2)	(FND$)+2	Second char
		B=B-1	B
-		B=B-1	B	<-------+
		GOC	gotexact+ -+	|	No more chars to compare, match
		A=DAT0	B	   |	|
		D0=D0+	2	   |	|
		C=DAT1	B	   |	|
		D1=D1+	2	   |	|
		?A=C	B	   |	|
		GOYES	-	---|----+	Matched char, try next one
		D1=(2)	FNDLEN	   |	No match, restore search position
		C=0	A	   |
		C=DAT1	B	   |
		C=C-B	B	   |	How many matched
		AD0EX		   |
		A=A-C	A	   |
		A=A-C	A	   |
		D0=A		   |	Start of match

		D0=D0+	2	   |	And skip first char
		GONC	exactlp+   |	And start main loop again
* Found exact match		   |
gotexact+	D1=(2)	FNDLEN	<--+
		C=0	A
		C=DAT1	B
		AD0EX			Skip back to start of match
		A=A-C	A
		A=A-C	A
		D0=A
		GOLONG	ToThisD0	Set cursor to the match position

**********************************************************************
* Case independant search forwards
**********************************************************************
FindInExact+

inexactlp+	D1=(2)	FND$
		A=DAT1	B		1st char to match
		LCASC	'a'
		?A<C	B
		GOYES	+	---+
		LCASC	'z'	   |
		?A>C	B	   |
		GOYES	+	---+
		ABIT=0	5	   |	Convert to upper case
+		B=A	B	<--+	'char1'
--		LCASC	'a'	<---------+
-		D=D-1	A	<-------+ |
		RTNC			| |	No positions left, no match
		A=DAT0	B		| |
		D0=D0+	2		| |
		?A=B	B		| |
		GOYES	+	----+	| |	Matched as is, test the rest
		?A<C	B	    |   | |	See if chars match in upper cs
		GOYES	-	----|---+ |	Not lower case, no match
		LCASC	'z'	    |	  |
		?A>C	B	    |	  |
		GOYES	--	----|-----+	Not lower case, no match
		ABIT=0	5	    |	  |	Convert to lower case
		?A#B	B	    |	  |
		GOYES	--	----|-----+	Still no match, try next pos
* First 'char' matched, compare the rest
+		DSL	W	<---+
		DSL	W
		D1=(2)	FNDLEN
		C=DAT1	B
		D=C	B		Chars to match
		D1=(2)	(FND$)+2	->char2
		D=D-1	B
-		D=D-1	B	<-------+
		GOC	gotinexact+	|
		A=DAT0	B		| Char to match
		D0=D0+	2		|
		LCASC	'a'		| Convert to upper case if possible
		?A<C	B		|
		GOYES	+	---+	|
		LCASC	'z'	   |	|
		?A>C	B	   |	|
		GOYES	+	---+	|
		ABIT=0	5	   |	|
+		B=A	B	<--+	| charN
		A=DAT1	B		| Char to test
		D1=D1+	2		|
		LCASC	'a'		| Convert to upper case if possible
		?A<C	B		|
		GOYES	+	---+	|
		LCASC	'z'	   |	|
		?A>C	B	   |	|
		GOYES	+	---+	|
		ABIT=0	5	   |	|
+		?A=B	B	<--+	|
		GOYES	-	--------+ Match, try next char
* No match, restore old position and start main loop again
		D1=(2)	FNDLEN
		C=0	A
		C=DAT1	B
		C=C-D	B
		AD0EX
		A=A-C	A
		A=A-C	A
		D0=A
		D0=D0+	2
		DSR	W
		DSR	W
		GOTO	inexactlp+
* Found inexact match, restore old position and jump there
gotinexact+	D1=(2)	FNDLEN
		C=0	A
		C=DAT1	B
		AD0EX
		A=A-C	A
		A=A-C	A
		D0=A
		GOLONG	ToThisD0


**********************************************************************
* Update editor match position
**********************************************************************
EdUpdFindPrev	GOSUBL	GetCurPos

UpdFindPrev	ST=0	sFNDCS		Assume not sensitive
		D1=(2)	FNDLEN
		C=DAT1	B
		?C=0	B
		RTNYES			Nothing to seek
		D=C	B		D[B] = length
		D1=(2)	FND$		->find string
* Determine case sensitivity from find string
-		D=D-1	B	<-------+
		GOC	+	---+	|	Tested all, not case sensitive
		A=DAT1	B	   |	|
		D1=D1+	2	   |	|
		LCASC	'a'	   |	|
		?A<C	B	   |	|
		GOYES	-	---|----+
		LCASC	'z'	   |	|
		?A>C	B	   |	|
		GOYES	-	---|----+
		ST=1	sFNDCS	   |	Found lower case ==> case sensitive
+		D1=(2)	FNDLEN	<--+
		A=0	A
		A=DAT1	B		length
		CD0EX
		C=C+A	A
		C=C+A	A		->curstail
		C=C-CON	A,2		Find previous!
		D1=(2)	STREND		Check against end of text
		A=DAT1	A
		?C<=A	A
		GOYES	+
		C=A	A
+		D0=C			start scan from here
		D1=(2)	FNDLEN
		A=0	A
		A=DAT1	B
		A=A-1	A
		C=C-A	A
		C=C-A	A		start pos for 1st char
		D1=(2)	STR
		A=DAT1	A
		C=C-A	A
		RTNC			No positions left!
		CSRB.F	A
		D=C	A		Positions left to test
		D=D+1	A		Find matches at start of text too

* Now dispatch to separate find subroutines for speed
		?ST=1	sFNDCS
		GOYES	FindExact-
		GOTO	FindInExact-
**********************************************************************
* Case dependant search backwards
**********************************************************************
FindExact-
		A=0	A
exactlp-	D1=(2)	FNDLEN
		A=DAT1	B
		B=A	B		length to match
		D1=(2)	FND$
		CD1EX
		C=C+A	A
		C=C+A	A
		CD1EX
		D1=D1-	2		->last char
		A=DAT1	B
		D=D-1	A
		RTNC			No positions left, no match
-		C=DAT0	B	<-------+
		D0=D0-	2		|
		?A=C	B		|
		GOYES	+	---+	|
		D=D-1	A	   |	|
		GONC	-	---|----+
		RTNSC		   |	No match
* Last charmatched, try the rest now
+		D1=D1-	2	<--+	->2nd last char
		B=B-1	B
-		B=B-1	B	<-------+
		GOC	gotexact- -+	|	No more chars to compare, match
		A=DAT0	B	   |	|
		C=DAT1	B	   |	|
		D0=D0-	2	   |	|
		D1=D1-	2	   |	|
		?A=C	B	   |	|
		GOYES	-	---|----+	Matched char, try prev one
		D1=(2)	FNDLEN	   |	No match, restore search position
		C=0	A	   |
		C=DAT1	B	   |
		C=C-B	B	   |	How many matched
		AD0EX		   |
		A=A+C	A	   |
		A=A+C	A	   |
		AD0EX		   |	Start of match
		D0=D0-	2	   |	And skip back over last char
		GONC	exactlp-   |	And start main loop again
* Found exact match		   |
gotexact-	D0=D0+	2	<--+
		GOLONG	ToThisD0	Set cursor to the match position

**********************************************************************
* Case independant search backwards
**********************************************************************

FindInExact-

inexactlp-	D1=(2)	FNDLEN
		A=0	A
		A=DAT1	B
		D1=(2)	FND$
		CD1EX
		C=C+A	A
		C=C+A	A
		CD1EX
		D1=D1-	2		->Last char of FND$
		A=DAT1	B		1st char to match
		LCASC	'a'		Convert it to upper case
		?A<C	B
		GOYES	+	---+
		LCASC	'z'	   |
		?A>C	B	   |
		GOYES	+	---+
		ABIT=0	5	   |
+		B=A	B	<--+	'charN'
-		D=D-1	A	<-------+
		RTNC			|	No positions left, no match
		A=DAT0	B		|
		D0=D0-	2		|
		?A=B	B		|
		GOYES	+	----+	|	Matched as is, test the rest
		LCASC	'a'	    |	|	See if chars match in upper
		?A<C	B	    |	|	case
		GOYES	-	----|---+	Not lower case, no match
		LCASC	'z'	    |	|
		?A>C	B	    |	|
		GOYES	-	----|---+	Not lower case, no match
		ABIT=0	5	    |	|	Convert to lower case
		?A#B	B	    |	|
		GOYES	-	----|---+	Still no match, try prev pos
* Last 'char' matched, compare the rest
+		DSL	W	<---+
		DSL	W
		AD1EX
		D1=A
		D1=(2)	FNDLEN
		C=DAT1	B
		D=C	B		chars to match
		D1=A
		D1=D1-	2		->2nd last char
		D=D-1	B
-		D=D-1	B	<-------+
		GOC	gotinexact-	|
		A=DAT0	B		| Char to match
		D0=D0-	2		|
		LCASC	'a'		| Convert to upper case if possible
		?A<C	B		|
		GOYES	+	---+	|
		LCASC	'z'	   |	|
		?A>C	B	   |	|
		GOYES	+	---+	|
		ABIT=0	5	   |	|
+		B=A	B	<--+	| charN
		A=DAT1	B		| Char to test
		D1=D1-	2		|
		LCASC	'a'		| Convert to upper case if possible
		?A<C	B		|
		GOYES	+	---+	|
		LCASC	'z'	   |	|
		?A>C	B	   |	|
		GOYES	+	---+	|
		ABIT=0	5	   |	|
+		?A=B	B	<--+	|
		GOYES	-	--------+ Match, try prev char
* No match, restore old position and start main loop again
		D1=(2)	FNDLEN
		C=0	A
		C=DAT1	B
		C=C-D	B
		AD0EX
		A=A+C	A
		A=A+C	A
		D0=A
		D0=D0-	2
		DSR	W
		DSR	W
		GOTO	inexactlp-
* Found inexact match, restore old position and jump there
gotinexact-	D0=D0+	2
		GOLONG	ToThisD0


**********************************************************************
* Replace find string with input string
* Input:	CURPOS	- Replace from cursor forwards
*		FND$	- Find string
*		INP$	- Replace string
*		sREPL?	- Verify each replace? (Not implemented)
* Out:		CURPOS'	- Position of last replace
* Notes:
*	ATTN key aborts Replace loop, this because the replace loop
*	can be quite slow for long texts.
**********************************************************************
Replace		ST=0	sDISPOK		Display won't be ok
		GOSUB	EdUpdFindNext	Make sure there is atleast one match
		GONC	ReplaceLoop	There is
		GOTO	replerr		None - error
		
ReplaceLoop	?ST=0	sREPL?
		GOYES	replnow

		GOSUB	ReplaceDisp	First display the match
ReplaceAsk	ST=0	sBLINK
		ST=1	sREPEAT
		GOSUBL	WaitKey
		A=C	A
		LC(2)	Sfkey1		YES
		?A=C	A
		GOYES	replYES
		ST=0	sREPL?
		LC(1)	Sfkey2		ALL
		?A=C	A
		GOYES	replYES
		ST=1	sREPL?
		LC(1)	Sfkey6		NO
		?A=C	A
		GOYES	replNO
		LC(1)	Sfkey5		NONE
		?A=C	A
		GOYES	gorepldone
		LC(2)	ATTNCODE
		?A=C	A
		GOYES	gorepldone
		GOSUBL	ErrBeep
		GOTO	ReplaceAsk
gorepldone	GOTO	repldone

replNO		GOSUBL	GetCurPos
		AD0EX
		D1=A
		D1=D1+	2
		GONC	ReplaceNext
* Replace the match
replYES		GOSUBL	GetCurPos
replnow		GOSBVL	=chk_attn
		GOC	replerr		Abort - ATTN pressed

		C=R4	A
		D1=C
		D1=(2)	FNDLEN
		A=0	A
		A=DAT1	B		lenght of match
		D1=(2)	INPLEN
		C=0	A
		C=DAT1	B		lenght of replace
		?A<C	A		match < replace?
		GOYES	ReplaceLonger
		C=A-C	A		Difference
		GOSUBL	EdRemove	Delete extra chars
		GOTO	+		And overwrite replace string

ReplaceLonger	C=C-A	A		Allocate missing space
		GOSUBL	EdAlloc
		GOC	replerr		No memory - error
* Overwrite replace string to match position
+		D1=(2)	INPLEN
		C=0	A
		C=DAT1	B		lenght to write
		D1=(2)	INP$		->replace string
		AD0EX
		AD1EX			D1 = ->match
		AD0EX			D0 = ->replace
		C=C+C	A		Nibbles
		GOSBVL	=MOVEDOWN	Overwrite
ReplaceNext	C=R4	A
		CD1EX
		D1=(2)	CURPOS
		DAT1=C	A		Set new cursor position after replace
		GOSUBL	EdUpdFindNext	Find next match
		GOC	repldone	Done if none found
		GOTO	ReplaceLoop	And replace again if found one

replerr		GOSUBL	ToThisPos	Make sure display comes out ok
		GOSUBL	InitDisp	Destroy traces of menu
		GOSUBL	SetNoBlk
		GOLONG	BadEdKey	even if memory runs out

repldone	ST=0	sDISPOK
		GOSUBL	ToThisPos	Setup display properly
		GOSUBL	InitDisp	And scratch menu
		GOLONG	SetNoBlk

* Display the match. Note that match may span several lines!
ReplaceDisp	C=R4
		D1=C
		D1=(2)	FNDLEN
		C=0	A
		C=DAT1	B
		AD0EX
		A=A+C	A
		A=A+C	A		->matchend
		D1=(2)	BLKEND		Set block end for highlighting
		DAT1=A	A
		D0=A
		GOSUBL	ToThisD0
		GOSUBL	UnScroll9	Ok, last line must be on screen now
		GOSUBL	GetCurPos
		D1=(2)	FNDLEN
		C=0	A
		C=DAT1	B
		AD0EX
		A=A-C	A
		A=A-C	A		->match
		D1=(2)	BLK		Set block start for highlighting
		DAT1=A	A
		D0=A
		GOSUBL	ToThisD0
		GOSUBL	DispEd9		Display the 9 lines
*		P=	12-1		10-1
		P=	13-1
		GOSUBL	GetDispRow
*		LC(5)	5*34
*		C=A+C	A
		D1=C
		GOSUB	+
*			 YES | ALL |    |    | NONE | NO
*		NIBHEX  0000000000000000000000000000000000
*		NIBHEX  FFFFFDFFFF7FFFFFDFFFF7FFFFFDFFFF70
*		NIBHEX  F513FDF67F7FFFFFDFFFF7B54B8DF61F70
*		NIBHEX  F5DDFD757F7FFFFFDFFFF7355AEDF45F70
*		NIBHEX  FB1BFD747F7FFFFFDFFFF734588DF05F70
*		NIBHEX  FBD7FD757F7FFFFFDFFFF7B459EDF25F70
*		NIBHEX  FB19FD754C7FFFFFDFFFF7B54B8DF61F70
*		NIBHEX  FFFFFDFFFF7FFFFFDFFFF7FFFFFDFFFFF0

*			 YES | ALL | REPLACE? | NONE | NO
		NIBHEX	0000000000000000000000000000000000
		NIBHEX	F513FDF67F70CCD488DD007646CDF91F70
		NIBHEX	F5DDFD757F7045454540107555FDF55F70
		NIBHEX	FB9BFD747F70CCC4C5C8007555EDF55F70
		NIBHEX	FBD7FD757F7045444540007555FDF55F70
		NIBHEX	FB19FD754C704D5C59D9007545CDF51F70
+		C=RSTK
		D0=C
*		LC(5)	34*8
		LC(5)	34*6
		GOVLNG	=MOVEDOWN
**********************************************************************

**********************************************************************
*		ED Counter Variable
**********************************************************************

**********************************************************************
* Initialize ED Counter Variable
* Input:  ddd..d or #hhh..h
**********************************************************************
EdInitCntr	GOSUBL	EdClrArg	Don't repeat input!
		ST=0	sFIND
		ST=0	sINPDEC
		GOSUBL	Input:
		CSTRING	'Counter: '
		RTNC			Aborted
		GOSUB	ParseInput
		GOC	initctrerr	Invalid input - abort
		C=R4.F	A
		D1=C
		D1=(2)	EDCNTR		Save counter
		DAT1=A	8
		CSLC
		D1=(2)	EDCNTRWID	Save counter width with type in hi bit
		?ST=0	sINPDEC
		GOYES	+
		CBIT=1	3
+		DAT1=C	1
		ST=0	sDISPOK
		ST=0	sREPEAT
		RTN
initctrerr	GOLONG	BadEdKey

**********************************************************************
* Insert counter into cursor position and increment it
**********************************************************************
EdOutCntr	C=R4.F	A
		D0=C
		D0=(2)	EDCNTR
		D1=(2)	EDCNTRWID
		C=DAT1	S
		C=C+C	S
		CSRB.F	S		C[S]=cntrwid
		P=C	15
		CD0EX
		C+P+1
		CD0EX
		P=	0
		B=C	S
		D1=(2)	INP$		Output lenght as chars for DoEdStrKey
		C=C+1	S
		DAT1=C	S
		D1=D1+	1
		C=C-1	S
-		LAASC	'0'
		D0=D0-	1
		A=DAT0	1
		LCASC	'9'
		?A<=C	B
		GOYES	+
		A=A+CON	B,7
+		DAT1=A	B
		D1=D1+	2
		C=C-1	S
		GONC	-
		C=B	S		And the skip amount at the end
		C=C+1	S
		DAT1=C	S
		C=R4.F	A		Now insert/overwrite the counter
		D0=C
		D0=(2)	INP$
		GOSUBL	DoEdStrKey
		?ST=0	sREPEAT		If repeat is off then error occurred
		RTNYES
		C=R4.F	A
		D1=(2)	EDCNTRWID
		C=DAT1	S
		C=C+C	S
		GONC	+
		SETDEC
+		CSRB.F	S		C[S]=cntrwid
		D1=(2)	EDCNTR
		A=DAT1	8
		A=A+1	W
		DAT1=A	8
		SETHEX
		RTN
**********************************************************************
* Parse input line as a hex or a decimal number
**********************************************************************
ParseInput	C=R4.F	A
		D1=C
		D1=(2)	INPLEN
		C=DAT1	B
		D=C	B		chars
		D1=(2)	INP$
		B=0	W		No digits yet
		A=DAT1	B		char1
		ST=1	sINPDEC		Assume decimal input
		LCASC	'#'
		?A#C	B
		GOYES	+
		ST=0	sINPDEC
		D1=D1+	2
		D=D-1	B
		RTNC			CS: No digits at all
+		D=D-1	B
		RTNC			CS: No digits at all
		C=D	P
		CSRC			C[S]=digits-1
		LC(2)	8
		?D>=C	B
		RTNYES			CS: Over 8 decimal characters
-		A=DAT1	B
		D1=D1+	2
		LCASC	'0'
		A=A-C	B
		RTNC			CS: Non decimal
		LC(2)	'9'-'0'
		?A<=C	B
		GOYES	+		Is decimal
		?ST=1	sINPDEC
		RTNYES			Wasn't decimal - error
		LC(2)	'A'-'0'
		A=A-C	B
		RTNC			CS: Non hex
		LC(2)	5
		?A>C	B
		RTNYES			CS: Non hex
		A=A+CON	B,10
+		BSL	W
		B=A	P
		D=D-1	B
		GONC	-
		A=B	W		Digits
		RTNCC

**********************************************************************
*		Find matching delimiter
**********************************************************************
EdFindDelim	ST=0	sREPEAT		No repeat!
		ST=0	sDISPOK		Display not ok
		GOSUB	EdThisWord
		GOC	fnddelimerr	No text to test
		A=0	A
		R1=A			token counter = 0
* Choose which scan to start

		GOSUB	WordEndProg?	These branches are too far for GOC
		GONC	+
		GOTO	fndProg
+		GOSUB	WordProg?
		GONC	+
		GOTO	fndEndProg
+		GOSUB	WordEndCode?
		GONC	+
		GOTO	fndCODE
+		GOSUB	WordCode?
		GONC	+
		GOTO	fndENDCODE
+
		GOSUB	WordSemi?	These are close enough
		GOC	fndCOMP
		GOSUB	WordComposite?
		GOC	fndSEMI
		GOSUB	WordRpl?
		GOC	fndASSEMBLE
		GOSUB	WordAssemble?
		GOC	fndRPL
		GOSUB	WordEndDir?
		GOC	fndDIR
		GOSUB	WordDir?
		GOC	fndENDDIR
fnddelimerr	GOLONG	BadEdKey

* Search :: ; or other composite pair

fndCOMP		A=0	A		Use negative counter for
		A=A-1	A		backward searching
-		R1=A	A
fndSEMI		GOSUB	NextPrevWord
		GOC	fnddelimerr
		GOSUB	WordSemi?
		A=R1	A
		GOC	+
		GOSUB	WordComposite?
		GONC	fndSEMI
		A=R1	A
		A=A+1	A
		GONC	-
+		A=A-1	A
		GONC	-
		GOC	founddelim

* Search ASSEMBLE-RPL pair

fndASSEMBLE	A=0	A		Use negative counter for
		A=A-1	A		backward searching
-		R1=A	A
fndRPL		GOSUB	NextPrevWord
		GOC	fnddelimerr
		GOSUB	WordRpl?
		A=R1	A
		GOC	+
		GOSUB	WordAssemble?
		GONC	fndRPL
		A=R1	A
		A=A+1	A
		GONC	-
+		A=A-1	A
		GONC	-
		GOC	founddelim

* Search DIR-ENDDIR pair

fndDIR		A=0	A		Use negative counter for
		A=A-1	A		backward searching
-		R1=A	A
fndENDDIR	GOSUB	NextPrevWord
		GOC	fnddelimerr
		GOSUB	WordEndDir?
		A=R1	A
		GOC	+
		GOSUB	WordDir?
		GONC	fndENDDIR
		A=R1	A
		A=A+1	A
		GONC	-
+		A=A-1	A
		GONC	-
founddelim	GOLONG	ToThisD0
fnddelimerr2	GOTO	fnddelimerr


* Search CODE-ENDCODE pair

fndCODE		A=0	A		Use negative counter for
		A=A-1	A		backward searching
-		R1=A	A
fndENDCODE	GOSUB	NextPrevWord
		GOC	fnddelimerr2
		GOSUB	WordEndCode?
		A=R1	A
		GOC	+
		GOSUB	WordCode?
		GONC	fndENDCODE
		A=R1	A
		A=A+1	A
		GONC	-
+		A=A-1	A
		GONC	-
		GOC	founddelim

* Search << >> pair

fndProg		A=0	A		Use negative counter for
		A=A-1	A		backward searching
-		R1=A	A
fndEndProg	GOSUB	NextPrevWord
		GOC	fnddelimerr2
		GOSUB	WordEndProg?
		A=R1	A
		GOC	+
		GOSUB	WordProg?
		GONC	fndEndProg
		A=R1	A
		A=A+1	A
		GONC	-
+		A=A-1	A
		GONC	-
		GOC	founddelim

* Test if "ASSEMBLE"
WordAssemble?	A=R0
		C=0	A
		LC(1)	8
		?A#C	A
		GOYES	wordnotASSEMBLE
		A=DAT0	W
		LCSTR	'ASSEMBLE'
		?A=C	W
		RTNYES
wordnotASSEMBLE	RTNCC

* Test if "RPL"
WordRpl?	A=R0
		C=0	A
		LC(1)	3
		?A#C	A
		GOYES	wordnotRPL
		A=DAT0	6
		C=A	W
		LCSTR	'RPL'
		?A=C	W
		RTNYES
wordnotRPL	RTNCC

* Test if "DIR"
WordDir?	A=R0
		C=0	A
		LC(1)	3
		?A#C	A
		GOYES	wordnotDIR
		A=DAT0	6
		C=A	W
		LCSTR	'DIR'
		?A=C	W
		RTNYES
wordnotDIR	RTNCC

* Test if "ENDDIR"
WordEndDir?	A=R0
		C=0	A
		LC(1)	6
		?A#C	A
		GOYES	wordnotENDDIR
		A=DAT0	12
		C=A	W
		LCSTR	'ENDDIR'
		?A=C	W
		RTNYES
wordnotENDDIR	RTNCC

* Test if "CODE"
WordCode?	A=R0
		C=0	A
		LC(1)	4
		?A#C	A
		GOYES	wordnotCODE
		A=DAT0	8
		C=A	W
		LCSTR	'CODE'
		?A=C	W
		RTNYES
wordnotCODE	RTNCC

* Test if "ENDCODE"
WordEndCode?	A=R0
		C=0	A
		LC(1)	7
		?A#C	A
		GOYES	wordnotENDCODE
		A=DAT0	14
		C=A	W
		LCSTR	'ENDCODE'
		?A=C	W
		RTNYES
wordnotENDCODE	RTNCC


* Test if "{" "::" "UNIT" "SYMBOL"

WordComposite?	A=R0
		C=0	A
		LC(1)	1
		?A=C	A
		GOYES	maybeDOLIST
		LC(1)	2
		?A=C	A
		GOYES	maybeDOCOL
		LC(1)	4
		?A=C	A
		GOYES	maybeUNIT
		LC(1)	6
		?A=C	A
		GOYES	maybeSYMBOL
		RTNCC
maybeDOLIST	A=DAT0	B
		LCASC	'{'
		?A=C	B
		RTNYES
		RTNCC
maybeDOCOL	A=DAT0	A
		C=A	A
		LCSTR	'::'
		?A=C	A
		RTNYES
		RTNCC
maybeUNIT	A=DAT0	W
		C=A	W
		LCSTR	'UNIT'
		?A=C	W
		RTNYES
		RTNCC
maybeSYMBOL	A=DAT0	W
		C=A	W
		LCSTR	'SYMBOL'
		?A=C	W
		RTNYES
		RTNCC

* Test if ";" or "}"
WordSemi?	LCASC	';'
		GOSUB	wordtest
		RTNC
		LCASC	'}'
		GONC	wordtest

* Test if "<<"
WordProg?	LCASC	'\xAB'
		GOTO	wordtest
* Test if ">>"
WordEndProg?	LCASC	'\xBB'

wordtest	A=R0
		A=A-1	A
		?A#0	A
		GOYES	+
		A=DAT0	B
		?A=C	B
		RTNYES
+		RTNCC

* Get word under cursor, CS if none present
EdThisWord	GOSUBL	GetCurPos
SafeThisWord	GOSUBL	End?
		RTNC
		D1=(2)	STR
		A=DAT1	A
		B=A	A		->str
		D1=(2)	STREND
		C=DAT1	A
		D=C	A		->strend
ThisWord	LCASC	' '
		A=DAT0	B
		?A<=C	B
		RTNYES
-		D0=D0-	2	<-------+	Scan backwards until white char
		A=DAT0	B		|
		?A>C	B		|
		GOYES	-	--------+
		D0=D0+	2	1st black char
		CD0EX		Check against start of str
		?C>=B	A
		GOYES	+	--------+
		C=B	A		|
+		D0=C		<-------+
		RSTK=C		Save start of word
		LCASC	' '
-		A=DAT0	B	<-------+	Scan forward until white
		D0=D0+	2		|
		?A>C	B		|
		GOYES	-	--------+
		D0=D0-	2
		CD0EX		Check against end of text
		?C<=D	A
		GOYES	+	--------+
		C=D	A		|
+		A=C	A	<-------+	->wordtail
		C=RSTK
		D0=C		->word
		C=A-C	A
		CSRB.F	A	chars
		R0=C.F	A
		RTNCC

* Direction dependant next/prev word

NextPrevWord	A=R1	A
		A=A+A	A
		GONC	NextWord	Next if R1[A]>=0
		GOTO	PrevWord	Prev if R1[A]<0


* Get next word, CS if none present
EdNextWord	GOSUBL	GetCurPos
SafeNextWord	GOSUBL	End?
		RTNC
		D1=(2)	STR
		A=DAT1	A
		B=A	A		->str
		D1=(2)	STREND
		C=DAT1	A
		D=C	A		->strend
NextWord	LCASC	' '
-		A=DAT0	B	<-------+	Skip current word
		D0=D0+	2		|
		?A>C	B		|
		GOYES	-	--------+
-		A=DAT0	B	<-------+	Skip white
		D0=D0+	2		|
		?A<=C	B		|
		GOYES	-	--------+
		D0=D0-	2
		CD0EX
		D0=C
		?C>=D	A
		RTNYES			BZZZT! No words left
		RSTK=C
		LCASC	' '
-		A=DAT0	B	<-------+	Skip black
		D0=D0+	2		|
		?A>C	B		|
		GOYES	-	--------+
		D0=D0-	2
		CD0EX
		?C<=D	A
		GOYES	+	--------+	Check against strend
		C=D	A		|
+		A=C	A	<-------+
		C=RSTK
		D0=C			->word
		C=A-C	A
		CSRB.F	A		chars
		R0=C.F	A
		RTNCC

* Get previous word, CS if none present
EdPrevWord	GOSUBL	GetCurPos
SafePrevWord	GOSUBL	Start?
		RTNC
		D1=(2)	STR
		A=DAT1	A
		B=A	A		->str
		D1=(2)	STREND
		C=DAT1	A
		D=C	A		->strend
PrevWord	LCASC	' '
-		A=DAT0	B	<-------+	Skip current word
		D0=D0-	2		|
		?A>C	B		|
		GOYES	-	--------+
-		A=DAT0	B	<-------+	Skip white
		D0=D0-	2		|
		?A<=C	B		|
		GOYES	-	--------+
		D0=D0+	4
		CD0EX			Check against start of text
		D0=C
		?C<=B	A
		RTNYES			BZZZT! No words left
		RSTK=C
		LCASC	' '
-		D0=D0-	2	<-------+
		A=DAT0	B		|
		?A>C	B		|
		GOYES	-	--------+
		D0=D0+	2
		AD0EX			Check against start of text
		?A>=B	A
		GOYES	+	--------+
		A=B	A		|
+		D0=A		<-------+	->word
		C=RSTK
		C=C-A	A
		CSRB.F	A
		R0=C.F	A
		RTNCC

**********************************************************************
* In  : C[A] ->str  D0: CURPOS
* Out : C[A] : # of nib between  CURPOS and start of (prev) word
*       CARRY set if no  prev word

StartOfPrvWrd	B=C	A		->str
		LCASC	' '
-		A=DAT0	B	<-------+	Skip white
		D0=D0-	2		|
		?A<=C	B		|
		GOYES	-	--------+
		D0=D0+	4
		AD0EX			Check against start of text
		D0=A
		?A<=B	A
		RTNYES
-		D0=D0-	2	<-------+
		A=DAT0	B		|
		?A>C	B		|
		GOYES	-	--------+
		D0=D0+	2
		AD0EX			Check against start of text
		?A>=B	A
		GOYES	+	--------+
		A=B	A		|
+		D1=(2)	CURPOS	<-------+
		C=DAT1	A
		C=C-A	A
		RTNCC

**********************************************************************
* IN  : C[A] ->strend  D0: CURPOS
* OUT : C[A] : # of nib between  CURPOS and end of next word
*       CARRY set if no next word

EndOfNxtWrd	B=C	A		->strend
		LCASC	' '
-		A=DAT0	B	<-------+	Skip white
		D0=D0+	2		|
		?A<=C	B		|
		GOYES	-	--------+
		D0=D0-	2
		AD0EX
		D0=A
		?A>=B	A
		RTNYES
-		A=DAT0	B	<-------+	Skip black
		D0=D0+	2		|
		?A>C	B		|
		GOYES	-	--------+
		D0=D0-	2
		AD0EX
		?A<=B	A
		GOYES	+	--------+	Check against strend
		A=B	A		|
+		D1=(2)	CURPOS	<-------+
		C=DAT1	A
		C=A-C	A
		RTNCC

**********************************************************************

f_format	IF  fEDFORMAT

**********************************************************************

**********************************************************************
* Format source code in block or entire text if block not defined
**********************************************************************

**********************************************************************
EdFormat	ST=0	sDISPOK
		ST=0	sREPEAT
		ST=0	sFMTALL		Assume block exists
		GOSUBL	GetBlk		A[A]=->block C[A]=nibbles
		GONC	formatblk
		ST=1	sFMTALL		Flag formatting entire text
		D1=(2)	STR		And mark entire text
		A=DAT1	A
		D1=(2)	BLK
		DAT1=A	A
		D1=(2)	STREND
		C=DAT1	A
		D1=(2)	BLKEND
		DAT1=C	A
		C=C-A	A		Nibbles
* Move everything above block to memory just before clip to
* make sure formatting overflow doesn't trash text
formatblk	C=C+A	A		->blockend
		D1=(2)	STREND
		A=DAT1	A		->strend
		D0=A			->strend
		C=A-C	A		nibbles to move
		D1=(2)	CUT
		A=DAT1	A		->cut
		D1=A			->cut
		GOSBVL	=MOVEUP
		GOSUBL	GetBlk		A[A]=->block
		C=C+A	A		C[A]=->blockend
		GOSUB	FormatArea	D1 = ->endaddress (new blkend)
		C=R4.F	A
		CD1EX
		D0=C			->blkend (new)
		D1=(2)	BLKEND
		A=DAT1	A
		R1=A			->blkend (old)
		A=A-C	A		Saved size (possily negative!)
		R0=A			Saved size
		A=A+C	A		Old blkend
		D1=(2)	STREND
		C=DAT1	A		->strend (old)
		C=C-A	A		Size of text after block
		D1=(2)	CUT
		A=DAT1	A
		A=A-C	A		->saved text
		AD0EX			D0 = ->saved text
		D1=A			D1 = ->blkend (new)
		GOSBVL	=MOVEDOWN
* Now change any pointer into the old block to point to the start
* of the block, any pointer above the block to point to it's new
* location in lower (or higher!) memory
* R1[A] = old blkend	R0[A] = difference
		C=R4.F	A
		D1=C
		D1=(2)	BLK
		A=DAT1	A		->block
		B=A	A
		D1=(2)	CURPOS
		DAT1=A	A		new cursor position
		C=R1.F	A
		D=C	A		->blkend (old)
		D1=(2)	UPDSTR
-		C=DAT1	A
		?C>=D	A
		GOYES	fmtafter	Update after block (STREND if all!)
		?C<=B	A
		GOYES	fmtupdnxt	No need to update below block
		?ST=1	sFMTALL		All text marked?
		GOYES	fmtupdclr	Yes - clear pointer
		C=B	A		Update inside block
		GONC	fmtupdset
fmtupdclr	C=0	A		Clear pointer
		GOC	fmtupdset
fmtafter	A=R0.F	A		Update after block
		C=C-A	A
fmtupdset	DAT1=C	A
fmtupdnxt	D1=D1+	5
		AD1EX
		D1=A
		LC(2)	UPDEND
		?A<C	B
		GOYES	-		Loop until end up updateable ptrs

		D1=(2)	BLKEND
		?ST=0	sFMTALL		Fix block end if block was used
		GOYES	+
		A=0	A
		D1=(2)	BLKEND
		DAT1=A	A
		D1=(2)	BLK
		DAT1=A	A
		GONC	++
+		A=R1.F	A		->blkend (old)
		C=R0.F	A		Saved size
		A=A-C	A
		DAT1=A	A
++		GOLONG	ToThisPos	Update cursor to new CURPOS


**********************************************************************
* Format text between A[A] and C[A], assuming block starts in RPL mode.
* Entry:	A[A] = ->start
*		C[A] = ->end
* Output:	D1   = ->end'	(new end address)
* Notes:
*	Since whitespace is removed the new end address should always be
*	smaller. Due to bugged whiteline handling this may not be the case.
* Uses:	
*	R0[A] = ->end
*	R1[A] = ->current output line start
*	R3[A] = indentlevel for current output line
**********************************************************************
FormatArea	D0=A		->start
		D1=A		->output
		R0=C		->end
		GOTO	FormatRestart

* Handle a starting line
FormatStart	GOSUB	OutThisLine
		GOC	formdone
		LCASC	'\n'
		DAT1=C	B
		D1=D1+	2		
FormatRestart	GOSUB	GetIndent
		R3=A.F	A		whites on current line
FormatRecont	AD1EX
		R1=A.F	A		->output
		AD1EX
		GOSUB	FormatCode?	Change to code format?
		GOC	formatcod	YES
		GOSUB	LineLength	Check if blank line
		GOC	FormatStart	YES - complete restart
		GOSUB	OutThisLine	Wasn't blank, output as usual

* Now keep appending following lines to the above line if possible
AppendLoop	AD0EX			->input
		D0=A
		C=R0.F	A		->textend
		?A<C	A
		GOYES	+
formdone	GOTO	FormatDone	End of text, nothing to do

+		GOSUB	FormatCode?	Change to code formatting?
		GONC	+
		LCSTR	'\n'		Yes - terminate line
		DAT1=C	B
		D1=D1+	2
formatcod	GOTO	FormatCode	And output until back to RPL

* First see if the line to append is blank
+		GOSUB	LineLength	See if blank line
		GOC	FormatBlank	Yep - terminate, output, recont
* Now compare indent levels
		GOSUB	GetIndent
		C=R3.F	A		previous indent
		?A=C	A
		GOYES	FormatEqual
		?A>C	A
		GOYES	FormatMore	Bigger indent level found
* Smaller indent level found, line is done, as is the next one
FormatLess	R3=A.F	A
FormatBlank	LCASC	'\n'
		DAT1=C	B
		D1=D1+	2
		GOSUB	OutThisLine
		GOC	+
		LCASC	'\n'
		DAT1=C	B
		D1=D1+	2
+		GOTO	FormatRecont
* Bigger indent level found, line is done		
FormatMore	R3=A.F	A		indent'
FormatNewLine	LCASC	'\n'
		DAT1=C	B
		D1=D1+	2
		GOTO	FormatRecont
* Equal indent levels, try to append
FormatEqual	CD0EX			Fetch indent for next line
		D=C	A		->line
		D0=C
		GOSUB	FormatLine+	CS if this is the last line
		GOC	FormatBlank	Keep last line separate
		GOSUB	GetIndent		
		GOC	+
		C=D	A
		D0=C			->line
		C=R3.F	A
		?A>C	A		If bigger then don't merge
		GOYES	FormatNewLine
+		C=D	A
		D0=C
		GOSUB	LineLength
		B=C	A		black chars coming up
		AD1EX
		D1=A			->output
		C=R1.F	A		->output start
		A=A-C	A
		ASRB.F	A		output on this line so far
		A=A+B	A		+ the black chars
*		A=A+1	A		+ space as separator
		LC(5)	FMTWIDTH
		?A<=C	A
		GOYES	+
		GOTO	FormatNewLine
* The black chars fit in, append them
+		AD0EX
		C=R3.F	A		indent
		A=A+C	A
		A=A+C	A
		AD0EX
		AD1EX			->output
		D1=A
		C=R1.F	A		->output start
		?A=C	A
		GOYES	+		No need to separate
		LCASC	' '
		DAT1=C	B
		D1=D1+	2
+		C=B	A
		C=C+C	A
		GOSBVL	=MOVEDOWN
		D0=D0+	2		Skip the newline
		GOTO	AppendLoop

**********************************************************************
* Check if have to switch to code formatting
* Only checks if first word on line is ASSEMBLE or CODE (not 2nd word!)
* Input:	D0 = ->line
**********************************************************************
FormatCode?	CD0EX
		RSTK=C		->line
		CD0EX
-		A=DAT0	B	<-------+	Skip white
		D0=D0+	2		|
		LCASC	'\n'		|
		?A=C	B		|
		GOYES	+	---+	|
		LCASC	' '	   |	|
		?A<=C	B	   |	|
		GOYES	-	---|----+
+		D0=D0-	2	<--+

		CD0EX		Check against textend
		A=R0.F	A	->textend
		?C<=A	A
		GOYES	+	---+
		C=A	A	   |
+		D0=C		<--+

		A=DAT0	W
		C=RSTK
		D0=C		->line
		C=A	W
		LCSTR	'CODE'
		?A=C	W
		RTNYES
		LCSTR	'ASSEMBLE'
		?A=C	W
		RTNYES
		RTNCC
**********************************************************************
* Format code.
* Input:	D0 = ->line		R0[A] = ->textend
**********************************************************************
FormatCode	GOSUB	OutThisLine
		GOC	FormatDone
		LCASC	'\n'
		DAT1=C	B
		D1=D1+	2
		GOSUB	GetIndent
		CD0EX
		D0=C
		C=C+A	A
		C=C+A	A
		CD0EX
		A=DAT0	W
		D0=C
		C=A	W
		LCSTR	'RPL'
		?A=C	W
		GOYES	OutOfCode
		LCSTR	'ENDCODE'
		?A#C	W
		GOYES	FormatCode
OutOfCode	GOSUB	OutThisLine
		GOC	FormatDone
		A=0	A
		GOTO	FormatMore
**********************************************************************
* Formatting done.
**********************************************************************
FormatDone	RTN		No work to do anymore, D1 = ->output end
**********************************************************************
* Copy line from D0 to D1, not including the newline character
* Input:	D0 D1	R0[A] = ->textend
* Output:	D0 = ->nextline
*		D1 = ->linetail
*		CS: line was the last one
*		CC: newline was found
* Uses: A[A] B[A] C[A] D0 D1
**********************************************************************
OutThisLine	AD0EX
		D0=A
		C=R0.F	A
		C=C-A	A
		CSRB.F	A
		B=C	A		chars left in text
		LCASC	'\n'
		B=B-1	A
		RTNC			CS: end of text
		A=DAT0	B		If line has just newline then out it
		D0=D0+	2
		?A#C	B
		GOYES	+
		DAT1=A	B
		D1=D1+	2
		AD1EX
		R1=A.F	A
		AD1EX
		RTNCC
outthislp	B=B-1	A
		RTNC			CS: end of text
		A=DAT0	B
		D0=D0+	2
		?A=C	B
		GOYES	outthisnl
+		DAT1=A	B
		D1=D1+	2
		GONC	outthislp
outthisnl	RTNCC
**********************************************************************
* Get indent for current line
* Input:	D0 = ->line	R0[A] = ->textend
* Output:	D0 = ->line
*		A[A] = white chars
*		CS if input is invalid
* Uses:		B[A] C[A]
**********************************************************************
GetIndent	AD0EX
		D0=A
		C=R0.F	A		->textend
		?A>=C	A
		RTNYES
		AD0EX
		B=A	A			->line
		D0=A
-		A=DAT0	B	<-------+
		D0=D0+	2		|
		LCASC	'\n'		|
		?A=C	B		|
		GOYES	+	----+	|
		LCASC	' '	    |	|
		?A<=C	B	    |	|
		GOYES	-	----|---+
+		D0=D0-	2	<---+		->black or ->newline
		AD0EX		
		C=R0.F	A			->textend
		?A<=C	A
		GOYES	+	----+
		A=C	A	    |		Use textend instead
+		A=A-B	A	<---+
		ASRB.F	A			whites
		C=B	A
		D0=C
		RTNCC
**********************************************************************
* Get lenght of line in D0, ignoring leading whitespace and trailing \n
* Input:	D0 = ->line	R0[A] ->textend
* Output:	CS: Empty line
*		CC:	D0 = ->line
*			A[A] = C[A] = chars
* Uses:		A[A] C[A] D[A]
**********************************************************************
LineLength	CD0EX
		RSTK=C				->line
		D0=C
-		A=DAT0	B	<-------+	Skip leading white
		D0=D0+	2		|
		LCASC	'\n'		|
		?A=C	B		|
		GOYES	+	---+	|
		LCASC	' '	   |	|
		?A<=C	B	   |	|
		GOYES	-	---|----+
+		D0=D0-	2	<--+

		CD0EX			Check against textend
		A=R0.F	A		->textend
		?C<=A	A
		GOYES	+	---+
		C=A	A	   |
+		D0=C		<--+

		D=C	A		->black
		LCASC	'\n'
-		A=DAT0	B	<--+	Skip black
		D0=D0+	2	   |
		?A#C	B	   |
		GOYES	-	---+
		D0=D0-	2

		CD0EX			Check against textend
		A=R0.F	A		->textend
		?C<=A	A
		GOYES	+	---+
		C=A	A	   |
+		C=C-D	A	<--+
		CSRB.F	A		black chars
		A=C	A
		C=RSTK
		D0=C			->line
		C=A	A
		?C=0	A		CS if empty line
		RTNYES
		RTNCC
**********************************************************************
* Skip line at D0
* Input:	D0 = ->line	R0[A] = ->textend
* Output:	CS: No next line
*		CC: D0 = ->nextline
* Uses:
**********************************************************************
FormatLine+	LCASC	'\n'
-		A=DAT0	B	<-------+
		D0=D0+	2		|
		?A#C	B		|
		GOYES	-	--------+
		AD0EX
		C=R0.F	A	->textend
		?A<=C	A
		GOYES	+	--------+
		A=C	A		|	Fix end address overflow
+		D0=A		<-------+
		C=C-A	A
		?C=0	A			CS if was at last line
		RTNYES
		RTNCC
**********************************************************************
f_format	ENDIF


**********************************************************************
*		ED Key Wait Subroutines
**********************************************************************

**********************************************************************
* Wait for a keypress.
* Entry:	sREPEAT		- is repeat enabled?
*		sBLINK		- is blink enabled?
*		sDELAY		- should the keypress be delayed?
* Exit:		C[A] = keycode
*
* Han:	The WaitKey code has been modified slighty compared to the
*	orignal Jazz code for the HP48. This mainly has to do with
*	the way SrvcKbdAB works on the HP49 family.

* The original design: after PopKey, there are 3 possible outcomes:
*	(1) a key is pressed, so we return to the main loop
*	(2) we just processed a key, and must check for repeats
*	(3) no keys were pressed, so we enter a timeout loop

* (1) When a key is processed, the time of that key is stored; we use
* it to compare elapsed time during the delay below. The keystate has
* just changed at this point, so there will be no repeated keys.

* (2) Otherwise, we assume the keystate remains the same and check
* for repeated keys upon the completion of the initial delay.
* Each time we go through the delay loop, the current keystate
* (=KSTATEVGER) is compared to the previous keystate. If either the
* ON key was pressed, or all keys released, then we immediately jump
* into the timeout loop (3). What has changed in the ROM, however, is
* how keys are handled. With the new press-hold design, and =SrvcKbdAB
* now only servicing one single key, we have to mask out the modifier
* bits so that combinations such as left-shift + up still work as
* desired during repeats.

* If keys are popped either via PopKey or via RepKey?, then we exit
* WaitKey with the RTI. Before exiting, we set TIMER1 to pre-empt
* interrupt system from handling the keyboard. The delay is somewhere
* between 31.25 to 93.75 ms on the HP48. This seems to have remained
* the same. This allows enough time for all the keys to be processed
* before we reach WaitKey again, without TIMER1 causing an interrupt
* and then having the slow interrupt system process our keyboard.

* NOTE:	In order to have smooth scrolling, not only must we prevent
* 	TIMER1 from causing an interrupt (which would then also
*	process our keys), we must also set =DebounceTiming to 0.
*	It seems enough to set the RAM entry; however, ->KEYTIME
*	also uses one of the new BUSCC opcodes.

* (3) If no keys were pressed, then there is nothing to do but wait
* for a key to be pressed. The Timeoutlp routine enables interrupts
* and traps any changes in the keyboard. If no keys are pressed in
* 5 minutes, we turn the calculator off. Otherwise we pop the key
* and return to the main loop.
**********************************************************************
--		GOVLNG	=AllowIntr  <---+	Got key, done
-		GOTO	TimeoutLp  <----|--+	No
					|  |
WaitKey					|  |
* Interrupts disabled here so that KEYSTATE will be valid for
* key repeats.  Delay loop will update KEYSTATE as needed.
		ST=0	15		|  |
		GOSUB	PopKey		|  |
		GONC	--	--------+  |	Got key
		?ST=0	sREPEAT		   |	Repeat on?
		GOYES	-	-----------+	Yes - delay, repeat

		A=R4	A
		LC(5)	EDSPEED
		A=A+C	A
		D1=A
		A=DAT1	S			Speed flag
		C=0	W
		LC(3)	8192*57/1000-26		Slow repeat = 0.057s
		?A=0	S
		GOYES	+
		LC(3)	8192*15/1000-26		Fast repeat = 0.015s
+		?ST=0	sDELAY
		GOYES	+
		LC(3)	8192*40/100-26		New repeat = 0.40s
+		A=R3	W			LastKeyTime
		A=A+C	W
		R0=A	W			Delay time in R0

		D1=(5)	=DISABLE_KBD
		LC(1)	1
		DAT1=C	1

* Han:	fix carry; HP50G sets carry if ON key was _NOT_ down!!
-		GOSBVL	=BITMAP	 <------+	Keys down in A
		?ABIT=1	0		|	Check bit for ATTN
		GOYES	++              |
		?A=0	W		|	Any keys down?
		GOYES	++		|	No - exit (CS)
		D1=(5)	=KSTATEVGER	|	Get KEYSTATE
		C=DAT1	W		|	(last keyboard save)
		?A=C	W		|	Any change in keyboard?
		GOYES	+	-----------+	No - check delay time
		C=A	P		|  |	Mask annunciators
		GOSBVL	=SrvcKbdAB	|  |
		GOSUB	PopKey		|  |	New key?
		GONC	++		|  |	Yes - exit (CC)
+		GOSBVL	=GetTimChk  <------+	No - check delay time
		A=R0			|
		?C<A	W		|	Delay done?
		GOYES	-	--------+	No - do over

		GOSBVL	=setannun		adjust annunciators
		GOSUB	RepKey?			Check for repeat keys

* Exit delay and repeat check.
* No carry means we got a key (keyboard still disabled).
++		D1=(5)	=DISABLE_KBD
		A=0	P
		DAT1=A	1
		GOC	TimeoutLp		No key!

* We have a key.  The keyboard has been serviced, so set
* timer1 to start keyboard peeks between 31.25 and 93.75 ms.
* This makes for fast, smooth key repeats (like scrolling).
* (Most repeat keys will get back to WaitKey before interrupt!)
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

* Turn interrupts on.  Keyboard has been serviced,
* so no need for RSI in AllowIntr.  RSI may cause
* an interrupt and slow things down!  (Yuk!)
		ST=1	15
		ST=0	14
		RTI				Got key, done

* From this point on it's pretty much the same as GETKEY
TimeoutLp	C=0	W
		LC(6)	=DFLT_TIMEOUT
		R0=C
		GOSBVL	=settimeout	Set timeout
		GOSBVL	=Timer1On
		?ST=0	sBLINK		Blink enabled?
		GOYES	WaitNow		No
		LC(3)	=BLINKMASK		Yes, set blink flag
		GOSBVL	=setflag

ResetT1Cnt	D1=(5)	=T1COUNT	Set cursor count
		LC(1)	8
		DAT1=C	1

WaitNow		GOSBVL	=clrbusy		Not busy anymore
		GOSBVL	=setannun	Update annunciators
		GOSBVL	=AllowIntr

* Run card detect at slow sampling rate (power saver)

		D1=(5)	=CARDCTL
		LC(1)	8
		DAT1=C	1		[ECDT RCDT SMP SWINT]=[1000]
				
		RSI			Avoid ShutDn if Key down
		?ST=1	13		Interrupted?
		GOYES	+  -----+	Yes - Skip ShutDn
		SHUTDN		|	Light Sleep: Keys, Timers Active
				|
+		ST=0	13  <---+
*		GOSBVL	=adjkey		No keys down?  Clear KEYSTATE
		GOSUB	adjkey

		ST=0	15		Interrupts off
		GOSUB	PopKey
		GONC	+			Got key
		GOSBVL	=chk_timeout		Timeout?
		GOC	gosleep
		?ST=0	sBLINK			Blink enabled?
		GOYES	WaitNow			No - skip blink
		D1=(5)	=T1COUNT        Check cursor count
		C=DAT1	S
		?C#0	S		Count = zero?
		GOYES	WaitNow		No - skip blink
		GOSUBL	TogCurs		Blink
		GOTO	ResetT1Cnt	Go reset blink count

gosleep		GOSUB	EdDeepSleep	Nighty night
		ST=0	15
		GOTO	TimeoutLp	Go back and reset timeout

+		RSTK=C			Save key
		LC(3)	=BLINKMASK		Clear blink flag
		GOSBVL	=clrflag
		GOSBVL	=clrtimeout
		GOSBVL	=showbusy	Busy now
		C=RSTK
		GOVLNG	=AllowIntr	Got key, done

**********************************************************************
* adjkey replacement
**********************************************************************
* Han:	Write our own adjkey without RSI to handle press-hold
* keys, which prevents fast typing. Also, the key state is not
* updated immediately when a key is pressed, so KSTATEVGER is
* invalid during the initial delay (and therefore results in
* "double-key" presses). We add in the necessary update here.
adjkey		LC(3)	=allkeys
		D1=(5)	=ORghost
		DAT1=C	X
		OUT=C
		D1=(4)	=DISABLE_KBD
		LC(1)	1
		DAT1=C	1
		D1=(4)	=KSTATEVGER
		A=0	W
		GOSBVL	=CINRTN
		?C=0	X
		GOYES	+
		GOSBVL	=BITMAP
+		DAT1=A	W
		C=0	A
		D1=(4)	=DISABLE_KBD
		DAT1=C	1
		RTN

**********************************************************************
* Initialize timers suitably for ED
**********************************************************************
InitClk		GOSBVL	=DisableIntr
		D1=(5)	=aClkOnNib	No ticking clock
		A=DAT1	A
		D1=A
		A=0	S
		DAT1=A	S	
		GOSBVL	=clrtimeout	Clear timeout
		P=	0		HMM!
		GOVLNG	=AllowIntr
**********************************************************************
* DeepSleep substitute using LoPwrShutDn, which is safer with 1M cards.
**********************************************************************
EdDeepSleep	C=R4.F	A
		D1=C
		D1=(2)	EDMODE		Save ST flags
		C=ST
		DAT1=C	X
		A=R4.F	A
		LC(5)	EDRSTK
		P=	16-4		Save 4 RSTK levels
		A=A+C	A
		D1=A
-		C=RSTK		<-------+
		DAT1=C	A		|
		D1=D1+	5		|
		P=P+1			|
		GONC	-	--------+
		GOSUB	GetptrEvalC
		CON(5)	=DOCOL
		CON(5)	=TurnOff
		CON(5)	=COLA
		CON(5)	=DOCODE
		REL(5)	->EDend

* I don't trust above to keep R2 and R4 intact, thus better pop the needed
* pointers again. Stack: ( $ pos $fstack statbuf )
* Pop fnt into R2[A]
* Pop statbuf into R4[A]

OwnDeepCont	GOSBVL	=SAVPTR
		A=DAT1	A
		LC(5)	#FF+10
		A=A+C	A
		A=0	B
		R4=A.F	A
		D1=D1+	5
		C=DAT1	A
		C=C+CON	A,10		old font; but now $fstack
**		C=C+CON	A,12		minifont offset
		R2=C.F	A
* And restore return stack and status flags
		LC(5)	(EDRSTK)+4*5
		A=A+C	A
		D1=A
		P=	16-4		Restore RSTK levels
-		D1=D1-	5	<-------+
		C=DAT1	A		|
		RSTK=C			|
		P=P+1			|
		GONC	-	--------+
		C=R4.F	A
		D1=C
		D1=(2)	EDMODE
		C=DAT1	X
		ST=C
		RTN

GetptrEvalC	C=RSTK
getptrevalc	A=C	A
		GOSBVL	=GETPTR
		PC=(A)
**********************************************************************
* See any key has been pressed, if so then disable timeout
**********************************************************************
PopKey
		GOSBVL	=chk_attn	ATTN pressed?
		GONC	+		No ATTN key - try keybuffer
		C=0	A		Clear ATTN
		DAT1=C	A
		LC(2)	ONCODE		And return [ATTN]
		GOC	++
+		GOSBVL	=POPKEY
		RTNC			CS: No regular key				
++		ST=1	sDELAY		Must delay next key
		RSTK=C			Save the keycode
		B=C	A
		LC(2)	#3F		Mask out modifiers
		B=B&C	B
		?B=0	B		Modifier key?
		GOYES	+		Yes - skip save

* Save key for repeats.  Keep two keys.
		A=R4.F	A
		LC(3)	REPSTACK
		A=A+C	A
		D0=A
gotkey		A=DAT0	B		Get last key saved
		C=B	A
		DAT0=C	B		Save new key
		D0=D0+	2
		DAT0=A	B		Save old key

+		GOSBVL	=GetTimChk	Save time of keypress in R3
		R3=C			for Delay?
		C=RSTK
		RTNCC			CC: Got key

**********************************************************************
* Handle key repeat after PopKey has failed
* Interrupts disabled on entry!!
**********************************************************************
* Old design:
* Here, KEYSTATE should have valid keyboard keystate.
* Get KEYSTATE, then clear it and use to find what keys
* are down.  Pop keys and use last two saved keys to
* eliminate the latest keys popped (if more than one down).

* New design (Han):
* Since the ROM now allows for press-hold, and hence allows only one
* (possibly modified) key-press, we mask the modifiers (so that
* =SrvcKbdAB will push a modified key into KEYBUFFER) to enable the
* repeat of a modified key.

RepKey?
		D1=(5)	=KSTATEVGER
		A=DAT1	W		get old KEYSTATE
		C=0	W
		C=A	P		Mask annunciators
		DAT1=C	W		Clear KEYSTATE
		GOSBVL	=SrvcKbdAB	get 1 key (with modifiers)
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
		A=R4.F	A
		LC(3)	REPSTACK
		A=A+C	A		Put saved keys at D0
		D0=A			Unused by POPKEY
-		GOSBVL	=POPKEY		Any more keys down?
		GONC	+		Yes

* Valid keycode (minus modifier) in B[B], modifier in D[B]
		C=B	A		Key code (minus modifier)
		C=C!D	B		Add modifier
		ST=0	sDELAY		No delay for this key
		RSTK=C			Save the keycode
		GOTO	gotkey		Got key, go save

* Come here if we have more than one key down.
* One in B[B] (minus modifier) and new one in C[B].
* Mask out modifier and eliminate last key popped.
* This will help multiple key repeats to repeat in
* the correct order.

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
* Move key to B[B] from C[B]
* Get plane to B[XS]
* Remove shifts B[B]
* Reset LS&RS states
**********************************************************************
AdjustKey

* Changes to plane when
* modifier is held down:
*
*	Held
* Old	NS  LS  RS  A
*     +----------------
* NS  |	NS  LS  RS  ANS
* LS  |	        RS  ALS
* RS  |	    LS      ARS
* ANS |	    ALS ARS
* ALS |	        ARS
* ARS |	    ALS


* Old:
*		B=C	A
*		A=0	A
*		A=B	B
*		LC(2)	#3F
*		A=A&C	B
*		?A=0	B
*		RTNYES
*		ABEX	B
*		ASR	B

* New by Dan:
		B=C	A
		A=C	A
		LC(2)	#3F
		B=B&C	B

* Ignore adjust if only LS or RS down
		?B#0	B		Modifier only?
		GOYES	+		No
		B=A	A		KeyCode
		LC(2)	=ALPHACODE
		?B#C	B		Alpha key?
		RTNYES			No

* Only alpha key down.  KeyCode in B,
* clear A, and treat as non-modifier key.
		LC(2)	32
		B=C	A
		A=0	A
+		ASR	B	[xxMMxxxx]

* [xx00xxxx] = NS, [xx10xxxx] = LS, [xx01xxxx] = A, [xx11xxxx] = RS

* Continue old:

*		D0=(5)	=aANNUNCIATORS
*		C=DAT0	A
*		D0=C
		D0=(5)	=ANNUNCIATORS
		C=DAT0	B	[xxxxLRAx]
		CBIT=0	7
		C=0	P
		A=A!C	B	[xxMMLRAx]
		ASRB.F	B
		ASRB.F	B	[MMLRAxxx], 0-3 = {NS LS A RS}
		
* Clear old LS & RS
		C=DAT0	B
		CBIT=0	4
		CBIT=0	5

* Clear old alpha if alpha key down
		?ABIT=0	1	Alpha key?
		GOYES	+	No - skip
		?ABIT=1	0	Shift key?
		GOYES	+	Yes - skip
		CBIT=0	6

+		DAT0=C	B
		GOSUB	PassModTab
*			NLAR
		NIBHEX	1243	NS
		NIBHEX	2253	LS
		NIBHEX	3263	RS
		NIBHEX	0000	LRS!
		NIBHEX	4546	ANS
		NIBHEX	5556	ALS
		NIBHEX	6566	ARS
		NIBHEX	0000	ALRS!
*			NLAR
PassModTab
		C=RSTK
		A=A+C	A
		D0=A
		A=DAT0	XS
		B=A	XS
		RTN


**********************************************************************
*		Default Character and String Tables
**********************************************************************
EdChrKey?
		A=B	XS
		A=A-1	XS
		GOC	notchrky
		GOSUB	GetChrPlane
		A=0	A
		A=B	B
		A=A+A	A
		A=A+C	A
		D0=A
		D0=D0-	2
		C=DAT0	B
		?C#0	B
		RTNYES
notchrky	RTNCC

GetChrPlane	GOSUB	PassPlane1
*			112233445566	Normal Plane
		NIBHEX	000000000000	|       |
		NIBHEX	00000000	|       |
		NIBHEX	000000000000	|       |
		NIBHEX	0000000000      |     |
		NIBHEX	0000000000	|     |
		NIBHEX	00000000F2	|    /|
		NIBHEX	00738393A2	| 789*|
		NIBHEX	00435363D2	| 456-|
		NIBHEX	00132333B2	| 123+|
		NIBHEX	0003E20200	| 0.  |
PassPlane1	C=RSTK
		A=A-1	XS
		RTNC
		GOSUB	PassPlane2
*			112233445566	Left Shift Plane
		NIBHEX	000000000000	|      |
		NIBHEX	00000000	|      |
		NIBHEX	000000000000	|      |
		NIBHEX	0000000000	|     |
		NIBHEX	0000000000	|     |
		NIBHEX	00B898A800	|     | inequalities
		NIBHEX	00000000B5	|    [|
		NIBHEX	0000000082	|    (|
		NIBHEX	00000032B7	|   #{|
		NIBHEX	00F9A37800	| i:p | p=pi, i=infinity
PassPlane2	C=RSTK
		A=A-1	XS
		RTNC
		GOSUB	PassPlane3
*			112233445566	Right Shift Plane
		NIBHEX	000000000000	|      |
		NIBHEX	00000000	|      |
		NIBHEX	000000000000	|      |
		NIBHEX	0000000000	|     |
		NIBHEX	0000000000	|     |
		NIBHEX	00D3C3E300	| =<> |
		NIBHEX	0000000022	|    "|	
		NIBHEX	00000000F5	|    _|
		NIBHEX	00000000BA	|    <| <=<<
		NIBHEX	0000A0C200	| >n, | n=newline
PassPlane3	C=RSTK
		A=A-1	XS
		RTNC
		GOSUB	PassPlane4
*			112233445566	Alpha Shift Plane
		NIBHEX	142434445464	|ABCDEF|
		NIBHEX	74849400	|GHI   |
		NIBHEX	A4B4C4000000	|JKL   |
		NIBHEX	D4E4F40500  	|MNOP |
		NIBHEX	1525354555	|QRSTU|
		NIBHEX	65758595A5	|VWXYZ|
		NIBHEX	00738393A2	| 789*|
		NIBHEX	00435363D2	| 456-|
		NIBHEX	00132333B2	| 123+|
		NIBHEX	0003E20200	| 0.  |
PassPlane4	C=RSTK
		A=A-1	XS
		RTNC
		GOSUB	PassPlane5
*			112233445566	Alpha Left Shift
		NIBHEX	162636465666	|abcdef|
		NIBHEX	76869600	|ghi   |
		NIBHEX	A6B6C6000000	|jkl   |
		NIBHEX	D6E6F60700	|mnop |
		NIBHEX	1727374757	|qrstu|
		NIBHEX	67778797A7	|vwxyz|
		NIBHEX	0000000000	|     |
		NIBHEX	00423A1A00	| $£§ |
		NIBHEX	0052B33200	| %;# |
		NIBHEX	0000007862	|   p&| p=pi

PassPlane5	C=RSTK
		A=A-1	XS
		RTNC
		GOSUB	PassPlane6
*			112233445566	Alpha Right Shift
		NIBHEX	C8FDB9293979	|abDdEr| greek
		NIBHEX	0000C700	|  |   |
		NIBHEX	000000000000	|      |
		NIBHEX	5B6972C900	|ml'p  | greek
		NIBHEX	E538895999	|^sStT | math/greek
		NIBHEX	A9D3C3E3F2	|o=<>/| math/greek
		NIBHEX	0000000022	|    "|
		NIBHEX	000AC508F5	| C\a_| C=160, \=92, a=angle
		NIBHEX	00E712F300	| ~!? |
		NIBHEX	00D8A09004	| >nt@| n=newline, t=tab
PassPlane6	C=RSTK
		RTN

**********************************************************************
EdStrKey?
		A=PC
		LC(5)	(strkeytab)-(*)
		A=A+C	A
		D0=A
strkylp		C=DAT0	4
		D0=D0+	3
		?C=0	X
		GOYES	retnotstr
		?C=B	X
		GOYES	retisstr
		P=C	3
		CD0EX
		C+P+1
		C+P+1
		CD0EX
		GONC	strkylp
retnotstr	P=	0
		RTNCC
retisstr	P=	0
		RTNSC

* KEY(3) CHRS(1) CHRS SKIP(1)

EDSKEY	MACRO
	CON(3)	$1
	ASC(1)	$2
	CON(1)	$3
EDSKEY	ENDM


strkeytab
		EDSKEY	(CHSCODE)+(RS),'==',2
		EDSKEY	(tickCODE)+(NS),\''\,1
		EDSKEY	(MINUSCODE)+(LS),'()',1
		EDSKEY	(MINUSCODE)+(ALS),'()',1
		EDSKEY	(MINUSCODE)+(RS),'ASSEMBLE\n\nRPL',9
		EDSKEY	(TIMESCODE)+(LS),'[]',1
		EDSKEY	(TIMESCODE)+(RS),'""',1
		EDSKEY	(TIMESCODE)+(ARS),'$ ""',3
		EDSKEY	(PLUSCODE)+(LS),'{}',1
		EDSKEY	(PLUSCODE)+(RS),'\xAB\xBB',1
		EDSKEY	(PCODE)+(LS),'::',1
		EDSKEY	(SPCCODE)+(ALS),'CODE\n\nENDCODE\n',5
		EDSKEY	(=0CODE)+(ALS),'!NO CODE\n!RPL\n',14
		EDSKEY	(POWERCODE)+(NS),'GOTO\t',5
		EDSKEY	(POWERCODE)+(LS),'GOLONG\t',7
		EDSKEY	(POWERCODE)+(RS),'GOVLNG\t',7
		EDSKEY	(SQRTCODE)+(NS),'GOSUB\t',6
		EDSKEY	(SQRTCODE)+(LS),'GOSUBL\t',7
		EDSKEY	(SQRTCODE)+(RS),'GOSBVL\t',7
		EDSKEY	(SINCODE)+(NS),'GOYES\t',6
		EDSKEY	(SINCODE)+(LS),'GONC\t',5
		EDSKEY	(SINCODE)+(RS),'GOC\t',4
		EDSKEY	(COSCODE)+(NS),'RTN\n\t',5
		EDSKEY	(COSCODE)+(LS),'RTNNC\n\t',7
		EDSKEY	(COSCODE)+(RS),'RTNC\n\t',6
		CON(3)	0


**********************************************************************
* Memory block swap utility for operating in low memory
* In:	D0=->BLK1 D1=->BLK2 C[A]=NIBS2
* Used:	A[W] C[W] B[A] D[A] D0 D1
**********************************************************************
EdBLKswap	B=C	A
EdBLKswaplp
		?B=0	A
		RTNYES
		AD0EX
		D0=A
		CD1EX
		D1=C
		C=C-A	A	NIBS1
		?C=0	A
		RTNYES
		?B<=C	A
		GOYES	edblkswp1
* NIBS1<NIBS2
		A=C	A
		A=0	P
		?A=0	A
		GOYES	edblkswp1P
		B=B-C	A
		GOSUB	Edblkswap
		GONC	EdBLKswaplp
* NIBS1>=NIBS2
edblkswp1
		A=B	A
		A=0	P
		?A=0	A
		GOYES	edblkswp2P
		C=B	A
		GOSUB	Edblkswap
		CD1EX
		C=C-B	A
		CD1EX
		GONC	EdBLKswaplp
* 0 < NIBS1 < 16
edblkswp1P
		CSRC		C[S]=1-15
		C=DAT0	15
		CD0EX
		CD1EX
		CD0EX
		CBEX	A
		GOSBVL	=MOVEDOWN
		C=B	A
		P=C	15
		P=P-1
		DAT1=C	WP
		P=	0
		RTNCC	
* 0 < NIBS2 < 16
edblkswp2P
		CD1EX
		D0=C
		C=C+B	A
		CD1EX
		CBEX	A
		CSRC
		C=DAT0	15
		CBEX	A
		GOSBVL	=MOVEUP
		C=B	A
		P=C	15
		P=P-1
		DAT0=C	WP
		P=	0
		RTNCC
**********************************************************************
Edblkswap	C=C-1	A
		GOC	Edblkswapped
		P=C	0
		CSR	A
		D=C	A
		D=D-1	A
		GOC	Edblkswapwp
Edblkswaplp
		A=DAT0	W
		C=DAT1	W
		DAT0=C	W
		DAT1=A	W
		D0=D0+	16
		D1=D1+	16
		D=D-1	B
		GONC	Edblkswaplp
		D=D-1	XS
		GONC	Edblkswaplp
		D=D+1	X
		D=D-1	A
		GONC	Edblkswaplp
Edblkswapwp
		A=DAT0	WP
		C=DAT1	WP
		DAT0=C	WP
		DAT1=A	WP
		CD0EX
		C+P+1
		D0=C
		CD1EX
		C+P+1
		D1=C
Edblkswapped	P=	0
		RTNCC
**********************************************************************
* Pop stack arguments and initialize all variables
* Stack:	( $ #pos fnt1 statbuf )
**********************************************************************
InitBuf
* Pop string
		GOSBVL	=D0=DSKTOP
		D0=D0+	15
		A=DAT0	A
		A=A+CON	A,5
		D1=A
		C=DAT1	A		Strlen

		?CBIT=1	0		Error if odd number of nibbles
		GOYES	+
		LC(5)	=SYNTAXERR
		GOTO	getptrevalc
+
		C=C+A	A	Strend
		R0=C		Save it
* Expand string
                GOSBVL  =ROOM
                A=C     A
                ABIT=0  0
		LC(5)	EDMINMEM
		A=A-C	A
		GONC	expok
		GOVLNG	=GPMEMERR
expok		R1=A		Save free
		C=DAT1	A	Fix $LEN
		C=C+A	A
		DAT1=C	A
		C=R0		Fix $LINK
		D1=C
		C=DAT1	A
		C=C+A	A
		DAT1=C	A
		C=A	A
		AD1EX
		GOSBVL	=MOVERSU
* Pop data buffer
		GOSBVL	=D1=DSKTOP
		A=DAT1	A
		LC(5)	#FF+10
		A=A+C	A
		A=0	B
		R4=A.F	A
*		D0=A

* save keytime		
		D0=(5)	=BounceTiming
		C=DAT0	A
		B=C	A
		C=0	A	set to 0 for repeated keys
		DAT0=C	A
		NIBHEX	80BF2	unsupported opcode to set keytime
		LC(5)	EDKEYTIME
		C=C+A	A	A[A] = ->buffer; C[A] = ->keytime
		D0=C
		C=B	A	get saved keytime
		DAT0=C	A
		D0=A
		
* Pop flash pointer stack
		D1=D1+	5
		A=DAT1	A
		A=A+CON	A,10	skip prolog and len
		R2=A.F	A

* Pop position
		D1=D1+	5
		GOSBVL	=POP#
		B=A	A	wanted pos
* Setup pointers
		A=DAT1	A
		A=A+CON	A,10	->$BODY
		D0=(2)	STR
		DAT0=A	A
		D0=(2)	CURPOS
		DAT0=A	A
		D0=(2)	TOPPOS
		DAT0=A	A
		D0=(2)	STREND
		C=R0
		DAT0=C	A
		D0=(2)	CUT
		A=R1
		A=A+C	A
		DAT0=A	A
		D0=(2)	MEMEND
		DAT0=A	A
		?B=0	A
		RTNYES		Didn't want anything

		D0=(2)	CURPOS
		A=DAT0	A
		A=A+B	A
		GOC	+
		A=A+B	A
		GOC	+
		C=R0		strend
		?A<=C	A
		GOYES	++
+		A=C	A	start from strend instead
++		D0=A
		GOLONG	ToThisD0
**********************************************************************
->EDend
  ENDCODE

