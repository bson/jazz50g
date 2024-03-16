**********************************************************************
*		JAZZ - String editor
**********************************************************************
DEFINE EDBUFSIZE #300

* dummy font; internally calls =MINI_FONT
* future use: flash rom stack for tracing FPTRs
DEFINE FSTACK NULLHXS

* Subprogram spanning:
DEFINE Ed#ASS	ZERO
DEFINE Ed#DOB	ONE
DEFINE Ed#STK	TWO
DEFINE Ed#GROB	THREE
DEFINE Ed#EC	FOUR

ASSEMBLE
edASS		EQU 0		Function: Assemble source 
edDOB		EQU 1		Function: Disassemble entry into new ED
edSTK		EQU 2		Function: Visit stack
edGROB		EQU 3		Function: View grob
edEC		EQU 4		Function: Call EC

EDMINMEM	EQU 200		Mimum memory left for SOL

* Flash bank stack for DoEdDob
EDFSTKSIZE	EQU 2+256	256 levels of rom view tracking
RPL

**********************************************************************
* Name:		ED
* Stack:	( $ --> $' )
*		( $ %pos --> $' )
*		( ob --> ob' )
* Description:	General purpose SRPL editor
* Internally used:
*		R0,R1 free
*		R2[A] = ->rom_bank_stack
*		R3    = lastkeytime	(can be used if sREPEAT is set!)
*		R4[A] = ->data
**********************************************************************
ASSEMBLE
	CON(1)	8
RPL
xNAME ED
::
  CK1&Dispatch
  FORTYNINE				( #31 - some trickery in here.. )
  ::
	CK2NOLASTWD
	CHECKME
	COERCE DoEdAt
  ;
  THREE
  ::
	CHECKME
	ZERO DoEdAt
  ;
  ZERO
  ::
	CHECKME
	RESOROMP xDIS EvalNoCK		( $ob )
	ZERO DoEdAt
	BEGIN
	   DUPTYPECSTR?
        WHILE
	   ZEROZEROZERO DoEd_ASS
	REPEAT
  ;
;

**********************************************************************
* Name:		TED
* Stack:	( ob --> ob' )
* Description:	General purpose user-rpl editor
**********************************************************************
ASSEMBLE
	CON(1)	8
RPL
xNAME TED
::
  CK1&Dispatch
  THREE	:: ZERO DoEdAt ;
  ZERO
  ::
    ( Decompile user-rpl object to width 30 )
*    ResetSTKDC
    THIRTY !DcompWidth
    savefmt1
    ERRSET editdecomp$w			
    ERRTRAP ederr
    rstfmt1
    ( Edit it until accepted final result )
    ZERO BEGIN
	DoEdAt
	:: palparse caseTRUE
	   LEN$ #- #1- FALSE
	;
	DUP ?SKIP ERRBEEP
    UNTIL
    EVAL
  ;
;

**********************************************************************
NULLNAME DoEdAt
::
  TOADISP UnScroll TURNMENUOFF CLEARVDISP	( Prepare display )
  FIFTYSIX TestSysFlag 1LAMBIND			( Save beep flag )
  FSTACK [#] EDFSTKSIZE EXPAND			( create stack buffer )
  CODE
		C=DAT1	A
		AD1EX
		CD1EX
		D1=D1+	5+5
		LC(1)	1
		D1=D1+	2
		DAT1=C	1		simulate entry from FPTR 1 0
		AD1EX
		A=DAT0	A
		D0=D0+	5
		PC=(A)	
  ENDCODE
  DoEd
  FIFTYSIX 1GETABND ITE SetSysFlag ClrSysFlag	( Restore beep flag )
;

**********************************************************************
NULLNAME DoEd
::
  NULLHXS EDBUFSIZE EXPAND
  4ROLL FREEINTEMP? ITE >TOPTEMP TOTEMPOB 4UNROLL
  GARBAGE

  ( $ #pos $fstack $buff )
	INCLUDE edit/edcode.s	( ED code )	

* Done if there are no subjobs
  NOTcase 3DROP

* There is a subjob to do:	( $ #pos $fstack data ? .. ? #subcommand )

  Ed#ASS  #=casedrop	DoEd_ASS
  Ed#DOB  #=casedrop	DoEd_DOB
  Ed#STK  #=casedrop	DoEd_STK
  Ed#GROB #=casedrop	DoEd_GROB
  Ed#EC   #=casedrop	DoEd_EC

* Should not reach here!

;


**********************************************************************
* ED exited with [ASS] key
* Assemble source code, if error then restart ED
* Stack:	( $ #pos $fstack data )
**********************************************************************
NULLNAME DoEd_ASS
::
  DROPSWAPDROP SWAP			( --> $fstack $ )
  ERRSET RESOROMP xASS EvalNoCK		( --> $fstack prg / $fstack $ #pos )
  ERRTRAP
  ::
    NOP					( ID for ASS ERRTRAP detection )
    RDROP				( Drop return stack )
    DispStsBound			( Display bound for better looks )
    ERRBEEP				( Beep the error )
    GARBAGE				( GC during the wait for speed )
    CODE				( Wait for a key before restarting )
		GOSBVL	=SAVPTR
-		GOSBVL	=KeyInBuff?
		GOC	+
		GOSBVL	=chk_attn
		GOC	+
		GOSBVL	=clrbusy
		SHUTDN
		GOTO	-
+		GOSBVL	=Flush
		D0=(5)	=KSTATEVGER
		C=0	W
		DAT0=C	W
		GOVLNG	=GETPTRLOOP
    ENDCODE
    ROT
    COLA DoEd				( And restart at error location )
  ;
  ( Assembled fine - finish )
  SWAPDROP				( get rid of $fstack )
;

**********************************************************************
* ED [DOB] key excuted.
* Disasseble entry and start new ED on the result
* Stack:	( $ #pos $fstack data entry #pos' )
**********************************************************************
NULLNAME DoEd_DOB
::
  5UNROLL SWAPDROP ROTDROP		( $ #pos' $fstack entry )

  DEPTH 1LAMBIND			( Save stack depth )
  ERRSET
  ::
    CK&DISPATCH0
    SIX					( ID: RCL DIS ED ASS STO )
    ::
	DUP SAFE@ NcaseTYPEERR ( NOTcase SETTYPEERR )
	RESOROMP xDIS EvalNoCK
	BEGIN
	  DUPTYPEBINT? ?SKIP ZERO	( Start ED with optional #errpos )
	  4PICK DoEd			( get copy of $fstack )
	  DUPTYPECSTR? ITE		( See if still string )
	  ::				( Yes - assemble it )
	    ERRSET
	    :: RESOROMP xASS EvalNoCK ;
	    ERRTRAP
	    :: NOP RSKIP DispStsBound VERYVERYSLOW DROPFALSE ;
	    TRUE
	  ;
          TRUE
        UNTIL
        SWAP SAFESTO NULL$		( Return null clip )
    ;
    SEVEN				( LAM: RCL ED STO )
    ::
	LAM>ID DUP SAFE@ NcaseTYPEERR
	DUPTYPECSTR? NcaseTYPEERR
	ZERO 4PICK DoEd
	SWAP SAFESTO NULL$		( Return null clip )
    ;
    FIFTEEN				( ROMPTR: RCL DIS ED ->CLIP )
    NULLNAME EdDOBROMP
    ::
	ROMPTR@ NcaseTYPEERR
	RESOROMP xDIS EvalNoCK
	ZERO 3PICK DoEd
    ;
    THIRTYONE				( #addr : DOB ED ->CLIP )
    ::
	DUP #40000 #<
	case :: Dob DROPZERO 3PICK DoEd ;
	' Dob
	CODE
		GOSBVL	=SAVPTR
		D1=D1+	5+5		skip Dob, #addr
		C=DAT1	A
		CD1EX			D1 ->$fstack
		D1=D1+	5+5		skip prolog and len
		C=0	A
		C=DAT1	B		get stack size
		D1=D1+	2-1
		AD1EX
		C=C+A	A
		CD1EX			D1 -> rom view prior to DoEdDob
		C=0	A
		C=DAT1	1
		D1=D1+	1
		DAT1=C	1		save it as current rom view
		R0=C			R0[0] = current rom view
		LC(1)	5+3+4
		GOSBVL	=GETTEMP
		LC(5)	=DOFLASHP	create our fptr executor
		DAT0=C	A
		D0=D0+	5
		C=R0
		DAT0=C	X
		D0=D0+	3
		C=0	A
		DAT0=C	4
		D0=D0-	5+3
		AD0EX
		GOSBVL	=GPPushA	push fptr
		A=DAT1	A
		PC=(A)			and execute
	ENDCODE
	DROPZERO 3PICK DoEd
    ;
    THREE				( ENTR># DOB ED ->CLIP )
    ::
	NULLNAME RPEntry?		( handle ROMPTR2 ~<entry> )
	CODE
		GOSBVL	=SAVPTR
		A=DAT1	A
		AD1EX
		D1=D1+	5+5
		A=DAT1	B
		LCASC	'~'
		?A=C	B
		GOYES	+
+		GOVLNG	=GPPushT/FLp
	ENDCODE

	( if "~<entry>" then convert to fptr )
	case
	::
	  Entr>#
	  NULLNAME Entr>Romp
	  CODE
  		GOSBVL	=PopASavptr
		AD1EX
		D1=D1+	5
		A=DAT1	A
  		R1=A
 		LC(5)	5+3+3
		GOSBVL	=GETTEMP
		AD0EX
		R0=A
		AD0EX
		LC(5)	=DOROMP
		DAT0=C	A
		D0=D0+	5		skip prolog
		A=R1
		C=0	A
		C=A	B
		DAT0=C	X		write id number
		ASR	A
		ASR	A
		ASR	A
		D0=D0+	3
		DAT0=A	X		write cmd number
		A=R0	A
		GOVLNG	=GPPushALp
	  ENDCODE
	  EdDOBROMP
	;	

	NULLNAME FPEntry?		( handle FPTR2 ^<entry> )
	CODE
		GOSBVL	=SAVPTR
		A=DAT1	A
		AD1EX
		D1=D1+	5+5
		A=DAT1	B
		LCASC	'^'
		?A=C	B
		GOYES	+
+		GOVLNG	=GPPushT/FLp
	ENDCODE

	( if "^<entry>" then convert to fptr )
	case
	::
	  Entr># Entr>Fptr
	  CODE
		CD1EX
		R1=C			save D1 in R1
		CD1EX
	  	C=DAT1	A
	  	CD1EX
	  	D1=D1+	5
	  	C=0	A
	  	C=DAT1	1
	  	R0=C			R0[A] = flash page
	  	C=R1
	  	D1=C
		D1=D1+	5		D1 -> $flashstk
		C=DAT1	A
		CD1EX
		D1=D1+	5+5		skip prolog and len
		C=0	A
		C=DAT1	B		get stk lvl
		D1=D1+	2
		AD1EX
		C=C+A	A
		CD1EX			D1 -> cur. rom view
		C=R0
		DAT1=C	1
		C=R1
		CD1EX
		GOVLNG	=Loop		
	  ENDCODE
	  Fptr@ DROPZERO 3PICK DoEd
	;

	DUP ERRSET Entr>#
	ERRTRAP SKIP
	:: RDROP SWAPDROP Dob DROPZERO 3PICK DoEd ;
	DUP CAR$ CHR x EQUAL NOTcase SETTYPEERR
	DUPLEN$ TWO SWAP SUB$
	palparse NOTcase SETTYPEERR
	DUPTYPECOL? OVER TYPEROMP? OR NOTcase SETTYPEERR
	DUPTYPEROMP? IT :: ROMPTR@ ?SEMI SETTYPEERR ;
	RESOROMP xDIS EvalNoCK
	ZERO 3PICK DoEd
    ;

* Han:	handle FPTRs here; Fptr@ checks for =DOFLASHP prolog
    ZERO
    ::
    	Fptr@ DROPZERO 3PICK DoEd
    ;
  ;
  ERRTRAP
    ::
	RDROP
	ERRBEEP				( Announce error )
	DEPTH 1GETABND #- NDROP		( Drop extra stuff )
	DROP
	NULLNAME FSTKDROP		( fix fptr stack )
	CODE
		C=DAT1	A
		AD1EX
		CD1EX
		D1=D1+	5+5
		C=DAT1	B
		C=C-1	B
		GONC	+
		C=0	B
+		DAT1=C	B
		AD1EX
		GOVLNG	=Loop
	ENDCODE

	COLA DoEd
    ;

* Restart ED with the given old position and a new clip
* Now:	( $ #pos' $fstack $clip )

  ABND					( Abandon saved stack depth )

  SWAP
  FSTKDROP				( fix fptr stack )
  SWAP

  DUPTYPECSTR? NOTcasedrop DoEd		( Just restart if clip is not $ )
  DUPNULL$? casedrop DoEd		( Just restart if clip is null )

  4UNROLL				( $clip $ #pos' $fstack )
  NULLHXS EDBUFSIZE EXPAND		( $clip $ #pos' $fstack data )
  4ROLL FREEINTEMP? ITE >TOPTEMP TOTEMPOB 4UNROLL
  GARBAGE 5ROLL				( $ #pos $fstack $data $clip )

  CODE
		A=PC			Fix interpreter pointer into DoEd
		LC(5)	(->EDend)-(*)
		A=A+C	A
		D0=A
		GOSBVL	=PopASavptr
		C=A	A
		RSTK=C			Save $dis
		CLRST
		GOSUBL	InitDisp
		GOSUBL	InitBuf		Init variables, memory etc
* Now move the disassembly into the clip (if it fits)
		C=RSTK
		D0=C			->$dis
		D0=D0+	5
		C=DAT0	A
		C=C-CON	A,5		nibbles needed
		D=C	A
		D0=D0+	5		->$dis
		GOSUBL	GetFree		C[A] = free memory A[A]=->strend
		?D>=C	A
		GOYES	dobnomem	No memory for the clip!
		D1=(2)	MEMEND
		C=DAT1	A
		C=C-D	A		->cut
		D1=(2)	CUT
		DAT1=C	A
		D1=C
		C=D	A
		GOSBVL	=MOVEDOWN
		GOLONG	EdDobEntry	Re-entry
dobnomem
		GOSUBL	ErrBeep		Beep
		GOLONG	EdDobEntry
 ENDCODE
;

**********************************************************************
* ED [STK] key was pressed
* Start SOL, exit back to ED when CONT key is pressed
* Stack:	( $ #pos $fstack data #pos' )
**********************************************************************
NULLNAME DoEd_STK
::
  4UNROLL ROT 2DROP			( $ #pos' $fstack )
  ( Save internal variables due to ED )
  DEPTH UStackDepth #- ZERO CACHE

  ::
    SuspendOK? NOTcase ERRBEEP	( check whether it is OK to start SOL )

    ( Start SOL replacement )
    ERRSET
    ::
      SAVESTACK			( Save user stack regardless of mode )
      BEGIN
	AtUserStack		( Validate user stack )
	SysMenuCheck		( Menu maintenance )
	SysDisplay		( System Display )
	GetKeyOb		( Wait for a key )
	ERRSET DoKeyOb		( Execute the key )
	ERRTRAP
	::
	  NOP			( Validate for ASS error messages )
	  LastRomWord@ PTR>ROMPTR ' xASS EQUAL case
	  NULLNAME EdStkAssTrap
	  ::
	    DUPTYPEBINT? ITE
	      ::
	        UNCOERCE
	        1LAMBIND FixStk&Menu 1GETABND
		AtUserStack
	      ;
	      FixStk&Menu
	    LastRomWord@ ERROR@
	    SysErrFixUI ERRBEEP
	    TOADISP UnScroll
	    CODE
		A=DAT1	A
		CD1EX
		AD1EX
		D1=D1+	5
		A=DAT1	A
		CD1EX
		LC(5)	#3E000		Jazz ROM ID
		C=A	B
		?A=C	A
		GOYES	+
+		GOVLNG	=PushT/FLoop
	    ENDCODE

	    ( Jazz error -> already handled; otherwise display error )
	    ITE 2DROP :: MakeErrMesg DISPROW1 DISPROW2 ;
	    SetDA1Temp
	  ;
	  
	  FixStk&Menu
	  ERROR@ ZERO #=casedrop SysErrFixUI
	  Err#Cont #=casedrop
	  ::
	    HALTTempEnv?
	    ( :: ' LAM 'halt @ NOTcaseFALSE DROPTRUE ; )
	    caseERRJMP
	    SysErrFixUI RSKIP TRUE
	  ;
	  Err#Kill #=casedrop ( DoCont/Kill )
	    ( This is a replacement for DoCont/Kill )
	    NULLNAME DoCont/Kill
	    :: HALTTempEnv? caseERRJMP CkSysError ;
	  #CAlarmErr #=case ProcessAlarm
	
	  NULLNAME DoEdErrJmp
	  ::
	    LastRomWord@ ERROR@	
	    SysErrFixUI ERRBEEP
	    TOADISP UnScroll
	    MakeErrMesg DISPROW1 DISPROW2
	    SetDA1Temp
	  ;
	;
	FALSE
      UNTIL
      UNDO_TOP? IT ABND		( Dump the saved stack )
    ;
    ERRTRAP ERRJMP
  ;
  ( Restart )
  ZERO DUMP ABND DROP TOADISP TURNMENUOFF COLA DoEd
;
**********************************************************************
* ED [VIEW] key was pressed for a grob
* View grob with VV
* Stack:	( $ #pos $fstack data grob #pos' )
**********************************************************************
NULLNAME DoEd_GROB
::				( $ #pos $fstack data grob #pos' )
  5UNROLL SWAP 4ROLL 2DROP	( $ #pos' $fstack grob )
  ABUFF TOTEMPOB DUP TOTEMPOB
  ViewGrob! 3DROP
  COLA DoEd
;

**********************************************************************
* ED [EC] key was pressed
* Start catalog, insert returned objects into the edit string
* Stack:	( $ #pos $fstack data word submode #pos' )
**********************************************************************
NULLNAME DoEd_EC
::				( $ #pos $fstack data word submode #pos' )
  6UNROLL 5ROLLDROP		( $ #pos' $fstack data word submode )
  DUP1LAMBIND ONE #AND		( save alpha mode in 1LAM )
  6UNROLL 6UNROLL DROP		( word submode $ #pos' $fstack )
  DEPTH #1-

  { NULLLAM NULLLAM NULLLAM NULLLAM } BIND	( word submode )
*   $       #pos'   $fstack #depth
  ERRSET
     #0=ITE
	:: DUPNULL$? ITE [#] EDSCANEC [#] EDGREPEC DoEC ONE ;
	INCLUDE edit/ed_fill.s
  ERRTRAP
  ::
     ERRBEEP RDROP 1GETLAM DEPTH #- #2+ NDROP
     4GETLAM 3GETLAM 2GETLAM ABND ABND
     TOADISP TURNMENUOFF COLA DoEd
  ;
  4GETLAM 3GETLAM 2GETLAM DEPTH 1GETABND
  ( $ #pos' $fstack #depth #depthsave )

* Merge the returned objects for insertion into ED
  2DUP#> ITE
	::
	  #- NULL$SWAP ZERO_DO (DO)
		6ROLL		( <more> ErrCode ¤ $ #pos' $fstack <entryob> )
		DUPTYPETAG? IT
		:: 'EvalNoCK: xOBJ> SWAPDROP ;
		DUPTYPEHSTR? IT HXS>$
		DUPTYPECSTR? ?SKIP DROPNULL$
		CHR_Newline >H$ !insert$
	  LOOP
	  TWO MINUSONE SUB$	( strip first newline )
	;
	:: 2DROP NULL$ ;	( new stack is <= )

  5UNROLL
  ( $insert ErrCode $ #pos' $fstack )

* Restart ED with an insert

  NULLHXS EDBUFSIZE EXPAND	( $insert ErrCode $ #pos' $fstack Buf )
  4ROLL >TOPTEMP 4UNROLL
  GARBAGE 6ROLL 6ROLL		( $ #pos' $fstack Buf $insert ErrCode )
  1GETABND #100 #AND #+		( Add #100 to ErrCode if Alpha on )
  CODE
		A=PC			Fix interpreter pointer into DoEd
		LC(5)	(->EDend)-(*)
		A=A+C	A
		D0=A
		GOSBVL	=POP#
		C=A	A
		RSTK=C			Save ErrCode:use 2 stk lvl,should be ok
		GOSBVL	=PopASavptr
		C=A	A
		C=C+CON	A,5
		RSTK=C			Save $ec
		CLRST
		GOSUBL	InitDisp
		GOSUBL	InitBuf		Init variables, memory etc
		C=RSTK
		D0=C
		C=DAT0	A
		C=C-CON	A,5		ec$==NULL ?	
		?C#0	A	
		GOYES	EdCatTryRepl
		GOSUBL	EdThisWord	yes-> goto end of word
		AD0EX
		GOC	+		and return in ED
		C=C+C	A
		A=A+C	A		
+		GOTO	EdCatToA		 

EdCatTryRepl	CD0EX			
		RSTK=C
		GOSUBL	EdThisWord
		GOC	++		if no current word, insert
		D=C	A		else replace current word
		LCASC	'='
		A=DAT0	B		 (left '=' if at beginning of word)
		?A#C	B
		GOYES	+
		D=D-1	A
+		C=D	A
		GOSUBL	EdRemove 
	
* Insert $ec if it fits
++		B=0	A					**TAB**
*		D1=(5)	aUserFlags				**TAB**
*		C=DAT1	A					**TAB**	
*		D1=C						**TAB**
		D1=(5)	=UserFlags
		C=DAT1	A					**TAB**
		?CBIT=0	7-1	if usrFlag 7 not set don't take	**TAB**
		GOYES	+		care of Tab		**TAB**
		LCASC	'\t'	if char before current pos is TAB **TAB**
		D0=D0-	2					**TAB**
		A=DAT0	B					**TAB**
		?A#C	B					**TAB**
		GOYES	+					**TAB**
		LCASC	'='		then we will insert '='	**TAB**
		B=C	A					**TAB**
+		C=RSTK
		RSTK=C
		D0=C
		C=DAT0	A
		C=C-CON	A,5
		CSRB.F	A		C[A] = #chars in insert
		?B=0	B					**TAB**
		GOYES	+					**TAB**
		C=C+1	A		one more char for '='	**TAB**
+		GOSUBL	EdAlloc		Try to allocate
		GOC	EdCaterr	No luck - no insert
		D1=C			->curpos
		?B=0	B					**TAB**
		GOYES	+					**TAB**
		C=B	A		Do insert '='		**TAB**
		DAT1=C	B					**TAB**
		D1=D1+	2					**TAB**
		
+		C=RSTK			Ok, insert ec$ ...
		D0=C
		C=DAT0	A
		C=C-CON	A,5
		D0=D0+	5
		GOSBVL	=MOVEDOWN
				
		AD1EX			and go to end of insert
EdCatToA	D0=A
		GOSUBL	ToThisD0

		GOSBVL	=getBPOFF
		C=RSTK
		?C#0	P		if ErrCode=#0, 2 beeps
		GOYES	+
		GOSUBL  ErrBeep
		D=0	A
		D=D-1	A
-		D=D-1	X
		GONC	-	
+		C=C-1	P		if ErrCode=#2, 1 beep
		?C=0	P
		GOYES	EdCatDobEntry	else no beep
--		GOSUBL  ErrBeep
EdCatDobEntry	
		GOSUBL	AlphaOff		Restore alpha mode
		?C=0	XS
		GOYES	+
		GOSUBL	AlphaOn
+		GOLONG	EdDobEntry
EdCaterr	C=RSTK
		GOSBVL	=getBPOFF
		GOTO	--
  ENDCODE
;


