**********************************************************************
*		JAZZ - SRPL Debugger
**********************************************************************
DEFINE	SdbHalt		LAM 'halt	( Annunciator lam )

* Next 3 names must be the same as in SSTK
DEFINE	SdbExitFlag	LAM ~stk	( Exit flag for SSTK )

* Next names must be the same as in rtab.s
* Han:	we no longer need RPL.TAB and DIS.TAB
*DEFINE	SdbRTab		LAM ~rtb	( RPL.TAB )
*DEFINE	SdbDTab		LAM ~dtb	( DIS.TAB )

DEFINE	SdbTBMode	LAM ~tbkm	( textbook mode )
DEFINE	SdbDisMode	LAM ~sysm	( SysRPL mode )
DEFINE	Sdbnotxtbk?	BINT79 TestSysFlag
DEFINE	Sdbsysdis?	BINT85 TestSysFlag

DEFINE	SdbMode		LAM ~dbg	( Current mode )
DEFINE	SdbTop?		LAM ~dtop?	( Top exists? )
DEFINE	SdbTop		LAM ~dtop	( Top )
DEFINE	SdbIn?		LAM ~din?	( Never into secondaries? )
DEFINE	SdbCur		LAM ~dcur	( Current command )
DEFINE	SdbBrk		LAM ~dbrk	( Break command )

DEFINE	ModNone		ZERO
DEFINE	ModStkDisp	ONE		( Stack display )
DEFINE	ModRstkDisp	TWO		( Return stack display )
DEFINE	ModLamDisp	THREE		( Lam display )
DEFINE	ModLoopDisp	FOUR		( Loop display )
DEFINE	ModContinue	FIVE		( CONT command )
DEFINE	ModExec		SIX		( Exec stk1 )
DEFINE	ModSkip		SEVEN		( Skip next )
DEFINE	ModSemi		EIGHT		( Do SEMI )
DEFINE	ModGiveLam	NINE		( Dump topmost env )
DEFINE	ModGiveLoop	TEN		( Dump topmost loop )

* Next ones must be highest and be in this order
DEFINE	ModSst		TWENTY		( ->SST )
DEFINE	ModIn		TWENTYONE	( ->IN )
DEFINE	ModSstSemi	TWENTYTWO	( ->SST until SEMI )
DEFINE	ModDb		TWENTYTHREE	( Debug ml )
* Continuous mode debuggers last
DEFINE	ModSlowSst	TWENTYFIVE	( SST-> Slow )
DEFINE	ModSlowIn	TWENTYSIX	( IN-> Slow )
DEFINE	ModFastSst	TWENTYSEVEN	( SST-> Fast )
DEFINE	ModFastIn	TWENTYEIGHT	( IN-> Fast )

* Keycodes
DEFINE	kcUpArrow	TEN
DEFINE	kcLeftArrow	FOURTEEN
DEFINE	kcDownArrow	FIFTEEN
DEFINE	kcRightArrow	SIXTEEN

* Choose decompiler; make sure to address flags -79 and -85 if using
* built-in decompiler
*DEFINE	StkDis1		JazzStkDis1
DEFINE	StkDis1		Decomp1Line
**********************************************************************
* Name:		xSDB
* Interface:	( :: --> ? )
*		( id --> ? )
*		( lam --> ? )
*		( romp --> ? )
* Description:
*	If SDB is not running then initialize debugger and display menu
*	Else just display menu
**********************************************************************
ASSEMBLE
	CON(1)	8
RPL
xNAME SDB
::
  CHECKME			( Error if covered )
  ' SdbMode @			( SDB already running? )
  NOTcase SdbStart		( Nope - initialize )
  DROP				( Drop Sdbmode )
  ' SdbMenu InitMenu		( Init SDB menu )
;
**********************************************************************
* Name:		xSHALT
* Interface:	( --> )
* Description:
*	Provide HALT command for SDB debugger
**********************************************************************
ASSEMBLE
	CON(1)	8
RPL
xNAME SHALT
:: CK0NOLASTWD
   ' SdbMode @LAM NOTcase NOHALTERR
   DROP "HALT" FlashMsg
   COLA RUIHALT
;
**********************************************************************
* Name:		xSKILL
* Interface:	( --> )
* Description:
*	Provide KILL command for SDB debugger which resets stack flags
**********************************************************************
ASSEMBLE
	CON(1)	8
RPL
xNAME SKILL
::
  CK0
  NULLNAME SdbRstFlags
  ::
    ' SdbTBMode @LAM NOT?SEMI
    BINT79 SWAP ITE SetSysFlag ClrSysFlag
    BINT85 SdbDisMode ITE SetSysFlag ClrSysFlag
  ;
  xKILL
;
**********************************************************************
*		SDB Initialization romps
**********************************************************************
ASSEMBLE
	CON(6)	=~xSDB		Attribute error within to xSDB
RPL
NULLNAME SdbStart
::
  CK1&Dispatch
  EIGHT		SdbSeco
  SIX		SdbName
  SEVEN		SdbName
  FIFTEEN	SdbRomp
  FIVE		::		( GX list processing shit )
		  INNERCOMP #1=?SKIP SETTYPEERR
                  RESOROMP SdbStart EvalNoCK
		;
;

NULLNAME SdbName
::
  SAFE@ NOTcase SETNONEXTERR
  CK&DISPATCH1
  EIGHT		SdbSeco
  FIFTEEN	SdbRomp
;

NULLNAME SdbRomp
::
  ROMPTR@ NOTcase SETROMPERR
  CK&DISPATCH0
  EIGHT SdbSeco
;

NULLNAME SdbSeco
::
  UNDO_ON?		( --> x )
  FALSE			( --> x exit? )
  Sdbnotxtbk?		( --> x exit? txtm )
  Sdbsysdis?		( --> x exit? txtm sysm )
  ModNone		( --> x exit? txtm sysm #mode )
  FalseFalse		( --> x exit? txtm sysm #mode top? top )
  TrueTrue		( --> x exit? txtm sysm #mode top? top in? cur )
  ' xKILL		( --> x exit? txtm sysm #mode top? top in? cur brk )
  {
    SdbHalt
    SdbExitFlag
    SdbTBMode SdbDisMode
    SdbMode
    SdbTop? SdbTop
    SdbIn?
    SdbCur
    SdbBrk
  }
  BIND
* Set protection counts to maximum for the lams & possible loops
* on current level. This validates the plain ERRTRAP used in the exit.
* Note: Do not use value #FFFFF, any subsequent ERRSET
*	will increase that to zero and the following ERRTRAP
*	will purge the lams!!!!!!
  CODE
		AD0EX			A[A] = I
*		D0=(5)	=aTEMPENV
		D0=(5)	=TEMPENV
		GOSUB	sdberrinc
*		D0=(5)	=aDOLPENV
		D0=(5)	=DOLPENV
		GOSUB	sdberrinc
		D0=A			Restore I to D0
		GOVLNG	=Loop

sdberrinc
*		C=DAT0	A		->ramvar
*		D0=C
		C=DAT0	A		->var
		D0=C
		C=DAT0	A		C[A] = count or first link
		?C=0	A
		RTNYES			No environments
		D0=D0+	5		D0 -> first protection word
		LC(5)	#80000		Nice value in the middle..
		DAT0=C	A
		RTN
  ENDCODE

  ( Insert program that abandons lams if xCONT was executed )
  ' ::
      ERRTRAP
      ::
        ( If this is reached then some error really happened - not CONT )
        'R EVAL			( Abandon SDB lams )
        RECLAIMDISP ERRJMP	( And error with valid display! )
*         ERROR@ Err#Kill #=case :: RECLAIMDISP ERRJMP ;
*         ERROR@ Err#Cont #<>case ERRJMP
      ;

      ( Here we had a Finish *OR* a CONT )
      ::
	SdbRstFlags		( Restore stack display flags )

	BEGIN			( Abandon SDB lams )
	  ' SdbBrk @LAM
	WHILE
	  :: DROP ABND ;
	REPEAT
      ;
      ( And then just let it run down )
    ;
  >R

  ( Insert stopmark + safety duplicates )
  ' SSTmark >R RDUP RDUP RDUP
  ( Insert program to debug )
  >R
  ( Init menu & start outer loop )
  ' SdbMenu InitMenu RUI
(;)
**********************************************************************
*		SDB UI restart program
**********************************************************************
NULLNAME RUI
::
  RDROP					( Drop calling program )

  ( If we stepped then show current stream on line 2 )
  SdbMode ModSst #<			( for all ->SST keys )
  SdbMode ModSlowIn #>			( Except fast modes )
  OR ?SKIP
  ::
    SdbTop? case
    ::
      ' SdbTop @LAM DROP		( --> topob )
      StkDis1				( --> $tobob )
      "COLA: " SWAP&$
      DISPROW2* SetDA1Temp
    ;
    RSWAP SSTend? NOTcase
    :: RSWAP ;				( no display for ending )
    R@ RSWAP				( -> stream )
    StkDis1 FOUR LAST$ SPACE$ !insert$
    DISPROW2* SetDA1Temp
  ;

  ( Now continue as usual )
  KEYINBUFFER? ITE
    TRUE				( Not continuous if key down )
    :: SdbMode ModSlowSst #< ;		( Not continuous evaluation? )
  case
  NULLNAME RUIHALT			( Restart outer UI )
  ::
	ONE ZERO_DO RDROP		( Create dummy loop env )
	UNDO_ON? { SdbHalt } BIND	( Store undo mode + establish ann )
	' SdbTBMode 1LAMBIND		( Dummy lam env )
	UNDO_ON? IT SAVESTACK
	' haltrtn-5 >R			( Set start marker )
	' restartol-5 >R		( Protect from leaving SSTK )
	ERRSET SSTKLOOP			( Start SSTK )
	( This is really reached only due to error! )
	ERRTRAP NOP
	ERROR@ Err#Cont #<>case ERRJMP
	( Got CONTINUEERR, handle it )
	ModContinue SdbDoMode
  ;
  ( Continuous evaluation is on, check for breakpoint command )
  ' SdbBrk @LAM DROP
  ' SdbCur @LAM DROP
  EQUALcase
  :: "Breakpoint" DISPROW2 ModNone ' SdbMode STOLAM COLA RUIHALT ;

  ( If not fast-mo then display stack )
  SdbMode ModFastSst #< IT ( DispStack! ) ?DispStack

  ( SdbThisMode needs duplicate in rstk )
  RDUP SdbMode COLA SdbThisMode
;
**********************************************************************
*		SDB command menu
**********************************************************************
NULLNAME SdbMenu
::
 NoExitAction
 {
  {	"\8DSST"
	{
	  :: TakeOver SdbCheckMe ModSst SdbDoMode ;
	  DoBadKey
	  :: TakeOver SdbCheckMe ModSstSemi SdbDoMode ;
	}
  }
  {	"\8DIN"
	:: TakeOver SdbCheckMe ModIn SdbDoMode ;
  }
  {	"SNXT"
	:: TakeOver SdbCheckMe
           SdbMode ModStkDisp #=ITE ModRstkDisp ModStkDisp
	   SdbDoMode
	;
  }
  {	"SST\8D"
	{
	  :: TakeOver SdbCheckMe
	     SdbMode ModSlowSst #=ITE ModFastSst ModSlowSst
	     SdbDoMode
	  ;
	  DoBadKey
	  :: TakeOver SdbCheckMe ModFastSst SdbDoMode ;
	}

  }
  {	"IN\8D"
	{
	  :: TakeOver SdbCheckMe
	     SdbMode ModSlowIn #=ITE ModFastIn ModSlowIn
	     SdbDoMode
	  ;
	  DoBadKey
	  :: TakeOver SdbCheckMe ModFastIn SdbDoMode ;
	}
  }
  {	"DB"
	:: TakeOver SdbCheckMe ModDb SdbDoMode ;
  }
*  xKILL
  xSKILL
  {	"SKIP"
	{
	  :: TakeOver SdbCheckMe ModSkip SdbDoMode ;
	  DoBadKey
	  :: TakeOver SdbCheckMe ModSemi SdbDoMode ;
	}
  }
  {	"SEXEC"
	:: TakeOver SdbCheckMe CK1NOLASTWD ModExec SdbDoMode ;
  }
  {	"SBRK"
	{
	  :: TakeOver SdbCheckMe
	     CK1NOLASTWD
	     DUP ' SdbBrk STOLAM
	     StkDis1 "Breakpoint set to:\n " SWAP&$ showsst
	  ;
	  DoBadKey
	  :: TakeOver SdbCheckMe
	     ' xKILL ' SdbBrk STOLAM
	     "Breakpoint cleared" showsst
	  ;
	}
  }
  {	"LOOPS"
	{
	  :: TakeOver SdbCheckMe ModLoopDisp SdbDoMode ;
	  DoBadKey
	  :: TakeOver SdbCheckMe ModGiveLoop SdbDoMode ;
	}
  }
  {	"LAMS"
	{
	  :: TakeOver SdbCheckMe ModLamDisp SdbDoMode ;
	  DoBadKey
	  :: TakeOver SdbCheckMe ModGiveLam SdbDoMode ;
	}
  }
  {	:: TakeOver "IN?" ' SdbIn? @LAM ?SKIP TRUE Std/BoxLabel ;
	:: TakeOver SdbCheckMe
	   SdbIn? NOT ' SdbIn? STOLAM
	;
  }
 }
;
**********************************************************************
*		SDB Runtime check utility
**********************************************************************
NULLNAME SdbCheckMe
::
  ' SdbMode @ caseDROP
  RDROP
  "SDB Not Running!" FlashMsg
;

**********************************************************************
*		SDB Command Execution
**********************************************************************

**********************************************************************
* Name:		SdbDoMode
* Interface:	( #mode --> )
* Notes:	Removes trash from rstk and loopenv, then executes
*		command indicated by mode
**********************************************************************
NULLNAME SdbDoMode
::
  DUP ' SdbMode STOLAM		( Set new mode )

  ( Abandon all until dummy lamda environment )
  BEGIN	1GETLAM ' SdbTBMode EQUALNOT WHILE ABND REPEAT
  ( And abandon the dummy )
  ABND

  ( Restore UNDO flag to same condition as when starting Sdb )
  UNDOsetABND

  ( Destroy dummy loop environment )
  RDUP EXITLOOP

  ( Drop return stack levels until debugged stream is found )
  SSTfind		( Also does RDUP )

  ( And execute command )
  COLA  ( SdbThisMode )
(;)
**********************************************************************
* Name:		SdbThisMode
* Interface:	( #mode --> ? )
* Notes:	Current stream must be in rstk and be duplicated
**********************************************************************
NULLNAME SdbThisMode
::
  ( First the debug commands )
  DUP ModSst #< NOTcase
  ::
	SdbTop? case					( Get possible top )
	::
	  ' SdbTop @LAM DROP
	  FALSE ' SdbTop? STOLAM
	  FALSE ' SdbTop? STOLAM
	  COLA SdbEval
	;
	SSTend? NOTcasedrop SdbFinish			( Done )
	( Now handle modes needing arguments )
	ticR case SdbEval

	RDROP						( Drop duplicate )
	SSTend? NOTcasedrop SdbFinish			( Check if done )
	";" showsst
	DROP RUI
  ;
  ( Now the extra modes )
  RDROP						( Drop duplicate )
  ModStkDisp	#=casedrop SdbD0Disp		( Stream display )
  ModRstkDisp	#=casedrop SdbRstkDisp		( Return stack display )
  ModLamDisp	#=casedrop SdbLamDisp		( Lam display )
  ModLoopDisp	#=casedrop SdbLoopDisp		( Loop display )
  ModExec	#=casedrop SdbExec		( Execute command )
  ModContinue	#=casedrop NOP			( Continue )
  ModSkip	#=casedrop SdbSkip		( Skip next )
  ModSemi	#=casedrop SdbSemi		( Drop rest of stream )
  ModGiveLoop	#=casedrop			( Dump loop env 1 )
		:: ZERO GetLoopEnv ?SKIP DoBadKey RUI ;
  ModGiveLam	#=casedrop			( Dump lam env 1 )
		:: ZERO GetLamEnv! ?SKIP DoBadKey RUI ;


  DROP RUI					( Shouldn't happen )
(;)
**********************************************************************
* Name:		SdbFinish
* Interface:	( --> )
* Description:
*		SDB reached end of debugged object.
*		Abandon SDB variables and drop through to lower UI.
**********************************************************************
NULLNAME SdbFinish
::
* Do not use ABND here or it might trash 1LAM when SDB is typed
  RDROP						( Drop duplicate )
  "Finished" DISPSTATUS2
  ClrDAsOK
;
**********************************************************************
* Name:		SdbEval
* Interface:	( #mode ob --> )
* Description:
*		Debug object according to mode
**********************************************************************
NULLNAME SdbEval
::
  SWAPOVER ' SdbCur STOLAM
  ModFastSst	#=casedrop SdbSstOb
  ModSlowSst	#=casedrop SdbSstOb
  ModSst	#=casedrop SdbSstOb
  ModFastIn	#=casedrop SdbInOb
  ModSlowIn	#=casedrop SdbInOb
  ModIn		#=casedrop SdbInOb
  ModSstSemi	#=casedrop SdbSstSemi
  ModDb		#=casedrop SdbDbCode	( Debug code with DB )
  DROP RUI				( Shouldn't happen )
(;)
**********************************************************************


**********************************************************************
* Name:		SdbRstkDisp
* Interface:	( --> )
* Description:
*		Displays SDB return stack or current stream
*		if no return stack exists
**********************************************************************

NULLNAME SdbRstkDisp
::
  ( If no rstk exists then display current stream )
  SSTend? NOTcase SdbD0Disp

  ( Calculate depth of current program )
  CODE
	GOSBVL	=SAVPTR
	C=B	A
	D0=C
	B=0	A
	LC(5)	=SSTmark5		Marker to look for
	GOVLNG	=findsst
  ENDCODE

  ( Eight rows is max )
  #1- EIGHT #MIN
  ( Blank necessary areas )
  FOUR OVER#> ITE
	BlankDA1
	BlankDA12
  ONE_DO (DO)
	INDEX@ RPICK R>			( Fetch stream )
	StkDis1				( Decompile )
	FOUR LAST$			( Drops "::" formed by R> )
	INDEX@ #1- #:>$ SWAP&$		( Add RSTK level )
	INDEX@ DISPN			( Display )
  LOOP
  SetDA12Temp				( Freeze )
  RUI
(;)

* Pick nth return stack level to top return stack level
* ( #n --> )
* Note: No need for GC checks, code always guarantees 5 nibbles
NULLNAME RPICK
CODE
	GOSBVL	=POP#
	C=A	A
	A=A+A	A
	A=A+A	A
	A=A+C	A		5*level
	C=B	A		->rstk
	C=C-A	A		->rstk - 5*level
	CD0EX			C[A] = "D0"
	D0=D0-	5
	A=DAT0	A		->stream
	D0=C			D0 = "D0"
	C=B	A
	CD0EX
	DAT0=A	A		Add new rstk level
	D0=D0+	5
	CD0EX
	B=C	A
	GOVLNG	=Loop
ENDCODE
**********************************************************************
* Name:		SdbD0Disp
* Interface:	( --> )
* Description:
*		Display current stream or if a COLA has been executed
*		display only the colad object
**********************************************************************
NULLNAME SdbD0Disp
::
  SdbTop? case
  ::
    ' SdbTop @LAM DROP		( --> topob )
    StkDis1			( --> $topob )
    "COLAd object:\n" SWAP&$ showsst RUI
  ;

  SSTend? NOTcase SdbFinish		( Finish if nothing to display )
  R@ StkDis1 FOUR LAST$ showsst RUI	( Drops "::" formed by R> first )
(;)
**********************************************************************
* Name:		SdbLamDisp
* Interface:	( --> )
* Description:
*		Enables browsing through lambda environments
**********************************************************************
DEFINE @sstlam_row	4GETLAM
DEFINE !sstlam_row	4PUTLAM
DEFINE @sstlam_env	3GETLAM
DEFINE !sstlam_env	3PUTLAM
DEFINE @sstlam_exit	2GETLAM
DEFINE !sstlam_exit	2PUTLAM
DEFINE @sstlam_time?	1GETLAM

NULLNAME SdbLamDisp
::

  ZERO GetLamEnv!		( env TRUE | FALSE )
  NOTcase :: "No lamda variables" FlashMsg RUI ;

  ZERO ONE FALSE DispTime?
  ' NULLLAM FOUR NDUPN DOBIND
  ClrDA1IsStat			( Clock display off )
  TOADISP TURNMENUOFF		( Use 8 lines to display )
  DOCLLCD
  BEGIN
	( Display lamda environment )
	"Lam env.   : " @sstlam_env #>$ !append$ DISPROW1
	DUP#2+PICK #>$ "Prot. level: " !insert$ DISPROW2
	@sstlam_row #1+	THREE SdbDispLam
	@sstlam_row #2+	FIVE SdbDispLam
	@sstlam_row #3+	SEVEN SdbDispLam

	WaitForKey DROP		( --> #key )
	::
	  kcUpArrow #=casedrop
	  :: @sstlam_row #0=case DoBadKey	( Already top )
	     @sstlam_row #1- !sstlam_row
	  ;
	  kcDownArrow #=casedrop
	  :: DUP @sstlam_row #1+ #2*		( #lams*2 #lam*2 )
	     2DUP#> NOTcase2drop DoBadKey
	     #2/ !sstlam_row DROP
	  ;
	  kcLeftArrow #=casedrop
	  :: @sstlam_env #1=case DoBadKey
	     NDROP DROP
	     @sstlam_env #1- DUP !sstlam_env GetLamEnv! DROP
	     ZERO !sstlam_row
	  ;
	  kcRightArrow #=casedrop
	  :: NDROP DROP
	     @sstlam_env #1+ DUP !sstlam_env GetLamEnv!
	     case :: ZERO !sstlam_row ;
	     @sstlam_env #1- DUP !sstlam_env GetLamEnv! DROP
	     DoBadKey
	  ;
	  DROPTRUE !sstlam_exit
	;

	@sstlam_exit
  UNTIL
  NDROP DROP				( drop last env )
  TURNMENUON				( menu back on )
  1GETABND IT SetDA1IsStat		( restore ticking clock )
  RUI
(;)



( #prot Meta #lam #disprow --> )
NULLNAME SdbDispLam
::
* Display lam name
  3PICK	3PICK #2* #1-		( #lam #disprow #lams*2 #lam*2-1 )
  2DUP#> NOTcase2drop
  :: SWAPDROP NULL$ OVER DISPN NULL$ SWAP#1+ DISPN ;
  #- #4+ PICK StkDis1		( #lam #disprow $lamname )
  "Name " 4PICK #>$ !append$ ": " !append$ !insert$
  OVER DISPN			( #lam #disprow )
* Display lam contents
  3PICK 3PICK #2*		( #lam #disprow #lams*2 #lam*2 )
  2DUP#< case2drop
  :: SWAPDROP NULL$ SWAP#1+ DISPN ;
  #- #4+ PICK StkDis1		( #lam #disprow $lamob )
  "Obj: " 4ROLLDROP ( #>$ !append$ ":  " !append$ ) !insert$
  SWAP#1+ DISPN
;


* GetLamEnv which is limited to lams on top of SDB
NULLNAME GetLamEnv!
CODE
		GOSBVL	=POP#
		GOSBVL	=SAVPTR
		D0=(5)	=aTEMPENV
		C=DAT0	A
		D0=C
		C=DAT0	A
		D0=C			->lamenv1
		B=A	A		level
		C=0	W
		LCSTR	'\5~dbrk'
		D=C	W		
* Skip level envs, fail if find SDB lam1 = SdbBrk = LAM ~dbrk
sst_lamenv!+	A=DAT0	A		Offset to next environment
		?A=0	A
		GOYES	sst_nolam	No such environment
		D0=D0+	10
		C=DAT0	A
		D0=D0-	10
		D1=C			->lamname1
		D1=D1+	5		->lamname1 lenght
		C=0	W		
		C=DAT1	12
		?C=D	W		Found SDB lam?
		GOYES	sst_nolam	Yes - fail
		B=B-1	A
		GOC	sst_thislam!	Found wanted env
		CD0EX			Skip env
		C=C+A	A
		CD0EX
		GONC	sst_lamenv!+	Loop
ENDCODE

* Dump one lam environment
* ( #level --> #prot lam1 ob1 ... lamn obn #m TRUE
* ( #level --> FALSE )
* ZERO means topmost environment

* TEMPENV Structure:
*		REL(5)	NextLamEnv
*		CON(5)	#protection
*		CON(5)	=lam1name
*		CON(5)	=lam1ob
*		CON(5)	=lam2name
*		...
*		CON(5)	0

NULLNAME GetLamEnv
CODE
		GOSBVL	=POP#
		GOSBVL	=SAVPTR
		D0=(5)	=aTEMPENV
		C=DAT0	A
		D0=C
		C=DAT0	A
		D0=C			->lamenv1
* Skip level envs
sst_lamenv+	C=DAT0	A		Offset to next environment
		?C=0	A
		GOYES	sst_nolam	No such environment!
		A=A-1	A
		GOC	sst_thislam	This env
		AD0EX
		A=A+C	A
		AD0EX
		GONC	sst_lamenv+	Loop until reached level
sst_nolam	GOVLNG	=GPPushFLoop

sst_thislam!	C=A	A		Offset
sst_thislam	R1=C			Save offset
		D0=D0+	5		->#protection
		A=DAT0	A
		R0=A			#protection
		AD0EX
		R2=A			Save ->#protection
		GOSBVL	=PUSH#		Push #protection
		GOSBVL	=SAVPTR
		A=R2
		D0=A			->#protection
		C=R1			Offset
		C=C-CON	A,10		Done offset & protection
sst_lam+	D0=D0+	5
		C=C-CON	A,5
		GOC	sst_lamok	Done
		RSTK=C			Save counter
		A=DAT0	A		->lam contents
		CD0EX
		RSTK=C			Save ->lam'
		GOSBVL	=GPPushA	Push it
		GOSBVL	=SAVPTR
		C=RSTK
		D0=C			->lam'
		C=RSTK			Counter
		GONC	sst_lam+	Loop
* Now push number of lams
sst_lamok	C=R1			Offset
		C=C-CON	A,10		-10
		GOSBVL	=DIV5		/5
		R0=C
		GOSBVL	=PUSH#		Push #lams
		GOVLNG	=DOTRUE
ENDCODE

**********************************************************************
* Name:		SdbLoopDisp
* Interface:	( --> )
* Description:
*		Enables browsing through loop environments
**********************************************************************

DEFINE @sstlp_env	3GETLAM
DEFINE !sstlp_env	3PUTLAM
DEFINE @sstlp_exit	2GETLAM
DEFINE !sstlp_exit	2PUTLAM
DEFINE @sstlp_time?	1GETLAM

NULLNAME SdbLoopDisp
::

  ZERO GetLoopEnv		( env TRUE | FALSE )
  NOTcase :: "No loop variables" FlashMsg RUI ;
  3DROP				( drop env )

  ZERO FALSE DispTime?
  ' NULLLAM THREE NDUPN DOBIND
  ClrDA1IsStat			( Clock display off )
  TOADISP TURNMENUOFF		( Use 8 lines to display )
  DOCLLCD
*  1234567890123456789012
  " #  Prot: Index: Stop:" DISPROW1
  BEGIN
  ( Display loop environments )
	NINE TWO DO					( Extra loop! )
		@sstlp_env INDEX@ #+-1 GetLoopEnv
		ITE
		::						( #p #i #s )
		  NULL$ @sstlp_env INDEX@ #+ #2- #>$ TWO Pad$	( #p #i #s $ )
		  4ROLL #>$ SEVEN Pad$				( #i #s $ )
		  ROT #>$ FIFTEEN Pad$				( #s $ )
		  SWAP #>$ TWENTYONE Pad$			( $ )
		;
		  NULL$
		INDEX@ DISPN
	LOOP

	WaitForKey DROP		( --> #key )
	::
	  kcUpArrow #=casedrop
	  :: @sstlp_env #0=case DoBadKey	( Already top )
	     @sstlp_env #1- !sstlp_env
	  ;
	  kcDownArrow #=casedrop
	  :: @sstlp_env SEVEN #+ GetLoopEnv
	     NOTcase DoBadKey
	     3DROP @sstlp_env #1+ !sstlp_env
	  ;
	  DROPTRUE !sstlp_exit
	;

	@sstlp_exit
  UNTIL
  TURNMENUON				( menu back on )
  1GETABND IT SetDA1IsStat		( restore ticking clock )
  RUI
(;)


* Append strings so that the resulting string lenght will be
* the given (#col) minimum but so that there is atleast one space between
* the appended strings.
* ( $1 $2 #col --> $ )
NULLNAME Pad$
::
  UNROT DUPLEN$ 3PICK LEN$ #+ 4ROLLSWAP	( $1 $2 #col #len1+2 )
  2DUP#> NOTcase
  :: 2DROP SWAP APPEND_SPACE !insert$ ;
  #-
*  1234567890123456789012
  "                      "
  ONE ROT SUB$ !insert$ !append$
;

NULLNAME GetLoopEnv
* ( #level --> #prot1 #index1 #stop1 TRUE )
* ( #level --> FALSE )
* ZERO means topmost env

* DOLPENV structure:
*	CON(5)	#environments
*	CON(5)	#protection1
*	CON(5)	#index1
*	CON(5)	#stop1
*	[..]

CODE
		GOSBVL	=POP#
		GOSBVL	=SAVPTR
*		D0=(5)	=aDOLPENV
*		C=DAT0	A
*		D0=C
		D0=(5)	=DOLPENV
		C=DAT0	A
		D0=C			->loopenv1
		C=DAT0	A		#environments
		?A<C	A		
		GOYES	+
		GOVLNG	=GPPushFLoop	No such env
+		C=A	A		#level
		ASL	A		#level*16
		A=A-C	A		#level*15
		CD0EX
		C=C+A	A
		D0=C
		D0=D0+	5		->prot
		A=DAT0	A
		R0=A			#prot
		D0=D0+	5
		A=DAT0	A
		R1=A			#index
		D0=D0+	5
		A=DAT0	A
		R2=A			#stop
		GOSBVL	=PUSH2#		Push #prot & #index
		GOSBVL	=SAVPTR
		A=R2
		R0=A			#stop
		GOVLNG	=Push#TLoop	Push #stop & TRUE
ENDCODE
**********************************************************************
* Name:		SdbSkip
* Interface:	( --> )
* Description:
*		Skip next object in SDB stream
**********************************************************************
NULLNAME SdbSkip
::
  "Skip  : " 'R StkDis1 !append$ DISPROW1
  "Stream: " R@ StkDis1 FOUR LAST$ !append$ DISPROW2
  SetDA1Temp
  RUI
(;)
**********************************************************************
* Name:		SdbSemi
* Interface:	( --> )
* Description:
*		Skip all obs in this stream, eg do a SEMI
**********************************************************************
NULLNAME SdbSemi
::
  R>
  SSTend? NOTcasedrop SdbFinish		( Finish if passed all )
  "Skip  : " SWAP StkDis1 FOUR LAST$ !append$ DISPROW1
  "Stream: " R@ StkDis1 FOUR LAST$ !append$ DISPROW2
  SetDA1Temp
  RUI
(;)
**********************************************************************
* Name:		SdbExec
* Interface:	( ob --> ? )
* Description:
*		Evaluate stk1 by adding xSHALT to the end of the object
**********************************************************************
NULLNAME SdbExec
::
  "Executing.." DISPROW1
  DUP StkDis1 DISPROW2

  ( Top must be added to the stream )
  SdbTop? IT
  ::
    ' SdbTop @LAM DROP		( --> topob )
    RSWAP R> INNERCOMP		( --> topob stream )
    #1+ ::N >R RSWAP		( Put new stream back in )
    FALSE ' SdbTop? STOLAM
    FALSE ' SdbTop STOLAM
  ;
  DUPTYPECOL? ITE		( Make debugger program )
	INNERCOMP
	ONE
  ' COLA ' xSHALT ROT #2+
  ::N COLA_EVAL
;
**********************************************************************
* Name:		SdbInOb
* Interface:	( ob --> )
* Description:
*		Debug object, go in if allowed
**********************************************************************
NULLNAME SdbInOb
::
  CK&DISPATCH0
  SIX		SdbInId
  SEVEN		SdbInId
  EIGHT		:: DUP SdbIn? NOTcasedrop SdbSstOb COLA SdbInThis ;
  FIFTEEN
  :: DUP ' xSHALT EQUALcase SdbSstOb
     DUPROMPTR@ NOTcase SdbSstOb
     COLA SdbInThis
  ;
  ZERO		SdbSstOb
;

NULLNAME SdbInId
::
  DUPSAFE@ NOTcase SdbSstOb	( No contents, exec ID as is )
  COLA SdbInThis
;

NULLNAME SdbInThis
::
  DUPTYPECOL? NOTcase
  :: SWAPDROP COLA SdbSstOb ;	( Drop 'name' & exec as normal )
  RSWAP RDROP			( Drop duplicate )
  SWAP StkDis1			( --> $name )
  "Into: " SWAP&$ showsst	( Display name )
  >R RUI			( Insert into stream & cont )
(;)
**********************************************************************
* Name:		SdbDbCode
* Interface:	( ob --> )
* Description:
*		Debug code object with DB
**********************************************************************
NULLNAME SdbDbCode
::
* Check if code object or PCO
* If using DB on a ROMPTR which is a code object, then debug it.
  DUPTYPEROMP? IT :: ROMPTR@ NOTcase SETROMPERR ;
  CODE
	C=DAT1	A
	CD1EX
	A=DAT1	A			prolog
	CD1EX
	C=C+CON	A,5
	?A=C	A
	GOYES	++
	LC(5)	=DOCODE
	?A=C	A
	GOYES	+
+	GOVLNG	=PushT/FLoop
++	GOSBVL	=PopASavptr
	P=	4
	GOSBVL	=PUSHhxs		Transfer PCO address as hxs
	GOVLNG	=PushTLoop
  ENDCODE
  NOTcasedrop
  :: RDROP DoBadKey RUI ;		( Not code object )
  RSWAP RDROP				( Drop original stream )
  xDB RUI				( Debug & cont )
(;)
**********************************************************************
* Name:		SdbSstSemi
* Interface:	( ob --> )
* Description:
*		Debug rest of stream at once
**********************************************************************
NULLNAME SdbSstSemi
::
  DROP RDROP R>			( Use the original stream )
  ( DUP StkDis1 FOUR LAST$ showsst )
  COLA ( SdbSstOb )
(;)
**********************************************************************
* Name:		SdbSstOb
* Interface:	( ob --> )
* Description:
*		Debug object, then restart UI
**********************************************************************
NULLNAME SdbSstOb
:: (;)

  RSWAP RDROP			( Drop duplicate )
  DUP StkDis1 showsst		( --> ob ob )

  DUP ' xSHALT EQUALcase :: DROP RUI ;

* If word is a DupAndThen word, do DUP and push next ob for debugging

  CODE
	C=DAT1	A		->ob
	CD0EX
	RSTK=C			"D0"
	A=DAT0	A
	LC(5)	=DupAndThen
	?A=C	A
	GOYES	+		It's a DupAndThen
	C=RSTK
	D0=C
	GOVLNG	=DOFALSE
+	D0=D0+	5		->nextob
	C=RSTK
	CD0EX
	DAT1=C	A		Overwrite ->ob with ->nextob
	GOVLNG	=DOTRUE
  ENDCODE
  IT OVERSWAP

* Now dispatch special words

CODE
		A=PC
		LC(5)	(SstTable)-(*)
		C=C+A	A
		A=DAT1	A		->ob
		CD1EX
		RSTK=C			"D1"
* Establish new D0 and try if it is correct
ssttrynew	C=DAT1	A
		AD1EX
		C=C+A	A
		AD1EX
		D0=C			-> new D0
		D1=D1+	5
		C=DAT1	A
		?C=0	A
		GOYES	sstmatch	End of tables - do "match"
ssttrythis	C=DAT1	A
		D1=D1+	5
		?C=0	A
		GOYES	ssttrynew	End of table - try new table
		?A#C	A
		GOYES	ssttrythis	Loop until 0 or match
sstmatch	C=RSTK
		D1=C
		GOVLNG	=Loop

** Collection of words that can be emulated with a common dispatchee

** Han:	The dispatch code requires that each table is non-empty;
**	otherwise the wrong dispatchee will be used due to the
**	"trick" used by the final table. The table is also very
**	incomplete. ROM 2.15 has SysRPL entries that are neither
**	prolog'd nor PCOs, which means some entries have several
**	addresses to check, one which is stable, and the other which
**	could change after a ROM update.

SstTable

* tick words needing next
	REL(5)	sst_tick1
	CON(5)	='
	CON(5)	=top&Cr
	CON(5)	=WithHidden
	CON(5)	=Unitversion
*	CON(5)	=dosepob		need to find in ROM 2.15
	CON(5)  =DoDelim		=DoDelim points to #1BC99
	CON(5)	#1BC99
	CON(5)  =DoDelims		=DoDelims points to #1BCC1
	CON(5)	#1BCC1
	CON(5)  =DoLevel1:
	CON(5)  =Roll&Do:
	CON(5)  =SYMALG->
*	CON(5)	='RRDstdsolve		Hmm, this appears later too..
	CON(5)	=PassiveEval
	CON(5)	='Rswapop
	CON(5)	=resolwith
*	CON(5)  =XEQMUPDN		Han: compare xMATCHUP with HP48 code
	CON(5)	=DUP'			*DETLEF* added the following ones
	CON(5)	=SWAP'
	CON(5)	=OVER'
	CON(5)	=xSILENT'
	CON(5)	=DROP'
	CON(5)	=STO'
	CON(5)	=TRUE'
	CON(5)	=ONEFALSE'
	CON(5)	=FALSE'
	CON(5)	=#1+'
	CON(5)	=sstSILENT'
	CON(5)	=x'
*	CON(5)	=xALG->
*	CON(5)	=xRPN->
* Han:	added the next few	
	CON(5)	=DoHere:		#11111 type
	CON(5)	=InitTrack:
	CON(5)	=RunRPN:
	CON(5)	=Rcl&Do:
	CON(5)  0

* tick words needing next 2

	REL(5)	sst_tick2		Where's Echo2Macros?
	CON(5)  ='R'Rpsh2&rev
	CON(5)	=LinSerRHS
	CON(5)	=LinSetRHStrg
	CON(5)	=LinSetRHSitg
	CON(5)	=adjustRwhich
	CON(5)	=adjustLwhich
* Han:	added the next few
	CON(5)	=Box/StdLbl:
* Han:	for whoever wondered about Echo2Macros, it was handled by
*	by the default handler far below in the HP48 series but must
*	now be added here due to it being a #11111 type entry
	CON(5)	=Echo2Macros
	CON(5)  0

* tick words needing next 3

	REL(5)	sst_tick3
	CON(5)  =Echo3Macros
	CON(5)	=CnLn?RHS
	CON(5)	=LnCn?RHS
	CON(5)  0

* tick words needing next 4

	REL(5)	sst_tick4
	CON(5)  =Echo4Macros
	CON(5)	=CnLnSetRHS
	CON(5)  0

* tick words needing rest of stream

	REL(5)	sst_tickall
	CON(5)	=cknumdsptch1
*	CON(5)	=MDISPATCH2A		Han:	SX - removed
	CON(5)	=G_MDISPA2A
*	CON(5)	=MDISPATCH1+		Han:	SX - removed
	CON(5)	=G_MDISPA1+
*	CON(5)	=MDISPATCH2+		Han:	SX - removed
	CON(5)	=G_MDISPA2+
	CON(5)	=Do1st/1st+:
	CON(5)	=Do1st/2nd+:
	CON(5)  =symdispatch1		need to find in ROM 2.15
	CON(5)	=applyinv1		need to find in ROM 2.15
*	CON(5)	=cknumdsptch2	* seems to work without
	CON(5)  =nssymdsptch
	CON(5)  =snsymdsptch
	CON(5)  =sssymdsptch
	CON(5)  =sscknum2
	CON(5)  =sncknum2
	CON(5)  =nscknum2
	CON(5)  =cknum2
*	CON(5)	='RRDstdsolve		needs 1 or 2 from stream?!
*	CON(5)	=G_'RRDstdsol		need to find in ROM 2.15
*	CON(5)	=shiftmerge		need to find in ROM 2.15
*	CON(5)	=caseout		need to find in ROM 2.15
	CON(5)  0

* 'R words needing 1 from prev

	REL(5)	sst_'r1
	CON(5)  ='R
	CON(5)  =ifeclause
	CON(5)  0

* case words needing next from stream

	REL(5)	sst_case1
	CON(5)	=AEQ1stcase
	CON(5)	=AEQopscase
	CON(5)	=REQcase
	CON(5)	=REQcasedrop
	CON(5)	=?CaseKeyDef
	CON(5)	=?CaseRomptr@
	CON(5)	0

* End of table - use a little trick to simplify the inner loop..

	REL(5)	sst_dotab2	Dispatch special words instead
	CON(5)	0
+
ENDCODE
**********************************************************************
ASSEMBLE		* Words needing next 1
sst_tick1
RPL
	'R TWO sst_rprot
**********************************************************************
ASSEMBLE		* Words needing next 2
sst_tick2
RPL
	'R'R THREE sst_rprot
**********************************************************************
ASSEMBLE		* Words needing next 3
sst_tick3
RPL
	'R'R 'R FOUR sst_rprot
**********************************************************************
ASSEMBLE		* Words needing next 4
sst_tick4
RPL
	'R'R 'R'R FIVE sst_rprot
**********************************************************************
ASSEMBLE		* Words needing all
sst_tickall
RPL
	:: RSWAP ERRSET COLA_EVAL ;
	ERRTRAP sst_dtrap RUI
**********************************************************************
ASSEMBLE		* Words needing prev 1
sst_'r1
RPL
	RSWAP EVAL RSWAP RUI
**********************************************************************
ASSEMBLE		* case words needing next
sst_case1
RPL
(::)
	'R
	' :: 'R RDROP sst_raddtop ;
	' RSKIP
	' RUI
	FIVE ::N >R
;
**********************************************************************

**********************************************************************
* Now try the special ones with nothing in common
**********************************************************************
ASSEMBLE
sst_dotab2
RPL

CODE
	A=DAT1	A		->ob
-	C=DAT0	A		->testob
	D0=D0+	5
	?C=0	A
	GOYES	sstdo0
	?A=C	A
	GOYES	sstdo1
	C=DAT0	A
	AD0EX
	A=A+C	A
	AD0EX
	GONC	-		Loop until match or end of table
sstdo1	D1=D1+	5		Drop object with specific dispatchee
	D=D+1	A
	D0=D0+	5		Skip offset
sstdo0	GOVLNG	=Loop		Evaluate dispatchee / default code
ENDCODE

* Help macro for dispatching

*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*!!!!!!!!!!! MUST NOT USE ++ LABELS UNTIL DISPATCH TABLE ENDS !!!!!!!!
*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
ASSEMBLE
SSTMAC	MACRO
++	CON(5)	$1
	REL(5)	++
SSTMAC	ENDM
RPL

* Dispatch table for special words

**********************************************************************
ASSEMBLE
	SSTMAC	=ticR
RPL
	RSWAP ticR DUP IT RSWAP RUI
**********************************************************************
ASSEMBLE
	SSTMAC	=RDUP
RPL
	RSWAP RDUP THREE RROLL RUI
**********************************************************************
ASSEMBLE
	SSTMAC	=RSWAP
RPL
	THREE RROLL RSWAP RUI
**********************************************************************
ASSEMBLE
	SSTMAC	='RRDROP
RPL
	RSWAP 'RRDROP RUI
**********************************************************************
ASSEMBLE
	SSTMAC	='R'R
RPL
	RSWAP 'R'R RSWAP RUI
**********************************************************************
ASSEMBLE
	SSTMAC	=RROLL
RPL
	#1+ RROLL RSWAP RUI
**********************************************************************
ASSEMBLE
	SSTMAC	=>R
RPL
	>R RSWAP RUI
**********************************************************************
ASSEMBLE
	SSTMAC	=R>
RPL
	RSWAP R> RUI
**********************************************************************
ASSEMBLE
	SSTMAC	=OBJ>R			Han:	new in HP50G?
RPL
	OBJ>R RSWAP RUI
**********************************************************************
ASSEMBLE
	SSTMAC	=R>OBJ			Han:	new in HP50G?
RPL
	RSWAP R>OBJ RUI
**********************************************************************

ASSEMBLE
	SSTMAC	=R@
RPL
	RSWAP R@ RSWAP RUI
**********************************************************************
ASSEMBLE
	SSTMAC	=RPITE
RPL
	NULLNAME sst_rpite
	:: RDROP ROT NOT?SWAPDROP sst_raddtop ;
**********************************************************************
ASSEMBLE
	SSTMAC	=COLARPITE
RPL
	RDROP sst_rpite
**********************************************************************
ASSEMBLE
	SSTMAC	=RPIT
RPL
	SWAP case sst_addtop DROP RUI
**********************************************************************
ASSEMBLE
	SSTMAC	=EVAL
RPL
	sst_raddtop
**********************************************************************
ASSEMBLE
	SSTMAC	=COLA_EVAL
RPL
	RDROP sst_raddtop
**********************************************************************
ASSEMBLE
	SSTMAC	='REVAL
RPL
	RSWAP 'R RSWAP sst_raddtop
**********************************************************************
* Han:	does this exist in ROM 2.15?
*ASSEMBLE
*	SSTMAC	=FREECOVEVAL
*RPL
*	?Cov#> sst_raddtop
**********************************************************************
ASSEMBLE
	SSTMAC	=::NEVAL
RPL
	sst_reval: ::NEVAL
**********************************************************************
ASSEMBLE
	SSTMAC	=2GETEVAL
RPL
	sst_reval: 2GETEVAL
**********************************************************************
ASSEMBLE
	SSTMAC	=1GETCOLAEVAL	HP48GX: #5CDA7
RPL
	1GETLAM RDROP sst_raddtop
**********************************************************************
*ASSEMBLE
*	SSTMAC	=1GETEVAL
*RPL
*	sst_reval: 1GETEVAL
**********************************************************************
ASSEMBLE
	SSTMAC	=COMPEVAL
RPL
	>R RUI
**********************************************************************
ASSEMBLE
	SSTMAC	=2@REVAL
RPL
	THREE RROLL
	RDUP 'RRDROP
	THREE RROLL THREE RROLL
	sst_raddtop
**********************************************************************
ASSEMBLE
	SSTMAC	=3@REVAL
RPL
	FOUR RROLL
	RDUP 'RRDROP
	FOUR RROLL FOUR RROLL FOUR RROLL
	sst_raddtop
**********************************************************************
ASSEMBLE
	SSTMAC	=GOTO
RPL
	CODE
sst_goto	C=B	A
		CD0EX
		RSTK=C
		D0=D0-	5
		C=DAT0	A
		CD0EX
		A=DAT0	A
		D0=C
		DAT0=A	A
		C=RSTK
		CD0EX
		GOVLNG	=Loop
	ENDCODE
	RUI
**********************************************************************
ASSEMBLE
	SSTMAC	=?GOTO
RPL
	CODE
sst_?goto	GOSBVL	=popflag
		GOC	sst_goto
sst_nogoto	C=B	A
		CD0EX
		D0=D0-	5
		A=DAT0	A
		A=A+CON	A,5
		DAT0=A	A
		CD0EX
		GOVLNG	=Loop
	ENDCODE
	RUI
**********************************************************************
ASSEMBLE
	SSTMAC	=NOT?GOTO
RPL
	CODE
		GOSBVL	=popflag
		GOC	sst_nogoto
		GOTO	sst_goto
	ENDCODE
**********************************************************************
* Han:	need to find in ROM 2.15
*ASSEMBLE
*	SSTMAC	=GOT0P?GOTO
*RPL
*	ZEROSWAP GOTPACKET?
*	CODE
*		GOTO	sst_?goto
*	ENDCODE
*	RUI
**********************************************************************
ASSEMBLE
	SSTMAC	='RSAVEWORD
RPL
	CODE
sst_rsavew	AD0EX
		C=B	A
		D0=C
		D0=D0-	10
*		C=DAT0	A
*		C=C-CON	A,10
*		D0=(5)	=LASTROMWDOB
*		DAT0=C	A
*		D0=A
		GOSUB	sdbsavewd
		A=DAT0	A
		D0=D0+	5
		PC=(A)
	ENDCODE
	RUI
**********************************************************************
* =CK0ATTNABORT points to #38B03
ASSEMBLE
	SSTMAC	=CK0ATTNABORT
RPL
	CODE
		GOTO	sst_rsavew
	ENDCODE
	CK0NOLASTWD ?ATTNQUIT RUI
**********************************************************************
ASSEMBLE
	SSTMAC	=R4?DROP	HP48GX: #180D8		
RPL
	IT DROP 2RDROP 2RDROP RUI
**********************************************************************
ASSEMBLE
	SSTMAC	=R4?2DROP	HP48GX: #17EBB
RPL
	IT 2DROP 2RDROP 2RDROP RUI
**********************************************************************
* Han:	need to find in ROM 2.15
*ASSEMBLE
*	SSTMAC	='R:RSKPEVAL	HP48GX: #217A9
*RPL
*	'RRDROP 'R RSKIP sst_raddtop
**********************************************************************
ASSEMBLE
	SSTMAC	=maybeder
RPL
	'xDEREQ case :: RDRDTRUE RUI ;
	RSWAP RDROP RDUP RUI
**********************************************************************
ASSEMBLE
	SSTMAC	=CK1&Dispatch
RPL
	CODE
		GOSUB	SdbSaveWord
		GOSBVL	=CK1nolastwd
		GOTO	sst_dspt1
* =SAVEWORD replacement
SdbSaveWord	A=B	A
		AD0EX			A[A] = "D0"
		D0=D0-	5
sdbsavewd	C=DAT0	A		->stream1
		C=C-CON	A,10		->stream1 ob start address
*		GOVLNG	#18C83		Store C[A], set D0 = A[A]
		D0=(5)	=LASTROMWDOB
		DAT0=C	A
		D0=A
		RTNCC
	ENDCODE
	ERRTRAP skipcola
	sst_rcola sst_ntrap
**********************************************************************
ASSEMBLE
	SSTMAC	=CK2&Dispatch
RPL
	CODE
		GOSUB	SdbSaveWord
		GOSBVL	=CK2nolastwd
		GOTO	sst_dspt1
	ENDCODE
	ERRTRAP skipcola
	sst_rcola sst_ntrap
**********************************************************************
ASSEMBLE
	SSTMAC	=CK3&Dispatch
RPL
	CODE
		GOSUB	SdbSaveWord
		GOSBVL	=CK3nolastwd
		GOTO	sst_dspt1
	ENDCODE
	ERRTRAP skipcola
	sst_rcola sst_ntrap
**********************************************************************
ASSEMBLE
	SSTMAC	=CK4&Dispatch
RPL
	CODE
		GOSUB	SdbSaveWord
		GOSBVL	=CK4nolastwd
		GOTO	sst_dspt1
	ENDCODE
	ERRTRAP skipcola
	sst_rcola sst_ntrap
**********************************************************************
ASSEMBLE
	SSTMAC	=CK5&Dispatch
RPL
	CODE
		GOSUB	SdbSaveWord
		GOSBVL	=CK5nolastwd
		GOTO	sst_dspt1
	ENDCODE
	ERRTRAP skipcola
	sst_rcola sst_ntrap
**********************************************************************
ASSEMBLE
	SSTMAC	=EvalNoCK
RPL
	CODE
sst_evalnock	C=DAT1	A		->ob
		CD0EX
		RSTK=C			"D0"
		D0=D0+	5		->cmd1
		A=DAT0	A		cmd1
		LC(5)	=CK1&Dispatch
		?A<C	A
		GOYES	sst_evalnotck
		LC(5)	=CK5&Dispatch
		?A>C	A
		GOYES	sst_evalnotck
		D1=D1+	5		Drop ob
		D0=D0+	5		1st command CK<n>&Dispatch, skip it
		C=B	A		Push address to return stack
		CD0EX
		DAT0=C	A		->cmd2
		D0=D0+	5
		C=RSTK			"D0"
		CD0EX
		B=C	A
		GOTO	sst_dspt1	Now do CK&DISPATCH1 on return stack
sst_evalnotck	C=RSTK			"D0"
		CD0EX
		GOSBVL	=SKIPOB		Handle in srpl 5 obs further
		GOSBVL	=SKIPOB
		GOSBVL	=SKIPOB
		GOSBVL	=SKIPOB
		GOSBVL	=SKIPOB
		GOVLNG	=Loop
	ENDCODE
	ERRTRAP 2skipcola
	COLA sst_cola
	sst_ntrap
	>R RSKIP RUI
**********************************************************************
* ='EvalNoCK: points to #21130
ASSEMBLE
	SSTMAC	='EvalNoCK:
RPL
	'R
	CODE
		GOTO	sst_evalnock
	ENDCODE
	ERRTRAP 2skipcola
	COLA sst_cola
	sst_ntrap
	>R RSKIP RUI
**********************************************************************
* Han:	need to find in ROM 2.15
*ASSEMBLE
*	SSTMAC	=backtoit
*RPL
*	RSKIP 'RRDROP
*	CODE
*		GOTO	sst_evalnotck
*	ENDCODE
*	ERRTRAP 2skipcola
*	COLA sst_cola
*	sst_dtrap
*	ERRTRAP NOP
*	>R RSKIP RUI
**********************************************************************
* Han:	need to find in ROM 2.15
*ASSEMBLE
*	SSTMAC	=collapsechs
*RPL
*	#1-UNROT
*	CODE
*		GOTO	sst_evalnock
*	ENDCODE
*	ERRTRAP 2skipcola
*** EvalNoCK object now in return stack, SWAP must be done after it
*	COLA :: ' collapsechsdo >R RSWAP sst_rcola ;
*	sst_dtrap
*	ERRTRAP NOP
*	' collapsechsdo >R >R RSKIP RUI
**********************************************************************
* Dispatch equates
ASSEMBLE
sOKSTRIPTAGS	EQU 2		OK to remove tags
sXTABLE		EQU 3		dispatch table selection
sOK2NDPASS	EQU 4		OK to try again w/o tags
RPL

ASSEMBLE
	SSTMAC	=CK&DISPATCH0
RPL
	CODE
		ST=0	sOK2NDPASS
		GOSUB	sstprepdsp	Save "D0" to 2nd pass
		GOTO	sst_dspt0	Dispatch
	ENDCODE
	ERRTRAP skipcola
	sst_rcola sst_ntrap
**********************************************************************
ASSEMBLE
	SSTMAC	=CK&DISPATCH2
RPL
	CODE
		GOTO	sst_dspt1
	ENDCODE
	ERRTRAP skipcola
	sst_rcola sst_ntrap

**********************************************************************
* Han:	Before, we essentially CK&DISPATCH1 in HP48GX ROM R; however,
*	on the HP50G ROM 2.15, the code is slightly different.
*
*	The main difference is that ROM 2.15 allows integers in place
*	of reals. When the required argument is a real number, and the
*	provided argument is an integer, the integer is converted to
*	a real number.
**********************************************************************
ASSEMBLE
	SSTMAC	=CK&DISPATCH1
RPL

	INCLUDE	sdb/ckdispatch.s

	ERRTRAP skipcola
	sst_rcola sst_ntrap
**********************************************************************
ASSEMBLE
++	CON(5)	0		End of special words
RPL
**********************************************************************

**********************************************************************
**********************************************************************
*		Default debugger
**********************************************************************
**********************************************************************
* Now try to do programs with 'R or 'R'R or 'RRDROP
* The ones in above tables are special cases

  DUPTYPECOL? IT
  ::
	DUP CARCOMP
	DUPEQ: TakeOver
	IT :: DROPDUP TWO NTHELCOMP ?SEMI RDROP ;	( Take second instead )
	REQcasedrop 'R		:: RDROP 'R TWO sst_rprot ;
	REQcasedrop 'R'R	:: RDROP 'R'R THREE sst_rprot ;
	REQcasedrop 'RRDROP	:: RDROP 'RRDROP TWO sst_rprot ;
	DROP
  ;

* Now the main debugger examiner for ordinary words

* Add error trap
* No ERRSET must be used, thus sst_ntrap is used to do extra clearing
* There is no way to guess how ERRSET would affect before the command
* and whether ERRTRAP would decrement the correct env protection
* Thus NO ERRSET ... ERRTRAP sst_ntrap!!!

* ' :: ERRTRAP sst_ntrap ; >R	( Establish trap )
*
* ( Add 4 protections )
* ' :: sst_exam ;
* EIGHT NDUPN FOUR SWAP#1+ ::N DUP >R
* TOTEMPOB sst_decr DUP >R
* TOTEMPOB sst_decr DUP >R
* TOTEMPOB sst_decr DUP >R
* TOTEMPOB sst_decr >R
* COLA_EVAL

  ::
    ::
      ::
        ::
          ::
            EVAL
            :: sst_exam ; :: sst_exam ; :: sst_exam ; :: sst_exam ;
            :: sst_exam ; :: sst_exam ; :: sst_exam ; :: sst_exam ;
            ZERO
          ;
          :: sst_exam ; :: sst_exam ; :: sst_exam ; :: sst_exam ;
          :: sst_exam ; :: sst_exam ; :: sst_exam ; :: sst_exam ;
          ONE
        ;
        :: sst_exam ; :: sst_exam ; :: sst_exam ; :: sst_exam ;
        :: sst_exam ; :: sst_exam ; :: sst_exam ; :: sst_exam ;
        TWO
      ;
      :: sst_exam ; :: sst_exam ; :: sst_exam ; :: sst_exam ;
      :: sst_exam ; :: sst_exam ; :: sst_exam ; :: sst_exam ;
      THREE
    ;
    :: sst_exam ; :: sst_exam ; :: sst_exam ; :: sst_exam ;
    :: sst_exam ; :: sst_exam ; :: sst_exam ; :: sst_exam ;
    FOUR
  ;
  ERRTRAP sst_ntrap

* Decrement protection level bint in secondary
*NULLNAME sst_decr
*CODE
*	A=DAT1	A		->program
*	LC(5)	21*8+5		Offset to bint ( 5+11+5 = 21 )
*	A=A+C	A
*	AD1EX
*	C=DAT1	A		bint address
*	C=C-CON	A,10		previous bint
*	DAT1=C	A		set new bint
*	D1=A
*	LOOP
*ENDCODE
**********************************************************************
NULLNAME sst_exam
::
  FALSE sst_status?
  case sst_addtop RUI
(;)
**********************************************************************
NULLNAME sst_rprot
::
  RDROP ::N
  ERRSET EVAL
  ERRTRAP sst_dtrap
  RUI
(;)
**********************************************************************
NULLNAME sst_reval:
::
  'RRDROP >R 'REVAL RSKIP sst_raddtop
;
**********************************************************************
NULLNAME sst_rcola
:: RDROP COLA (;)
**********************************************************************
NULLNAME sst_cola
:: 'R COLA (;)
**********************************************************************
NULLNAME sst_raddtop
:: RDROP COLA (;)
**********************************************************************
NULLNAME sst_addtop
::
  ' SdbTop STOLAM
  TRUE ' SdbTop? STOLAM
  RUI
(;)
**********************************************************************
NULLNAME sst_ntrap
::
  CODE
	GOTO	+
  ENDCODE
  RUI
(;)
**********************************************************************
NULLNAME sst_dtrap
::
  FALSE ' SdbTop? STOLAM
  CODE
	GOSBVL	=FIXENV
+	A=B	A
	AD0EX
	R0=A
--	D0=D0-	5
	A=DAT0	A
	D=D+1	A
	?A=0	A
	GOYES	sstwarm		Warmstart!
	LC(5)	=SSTmark5
	?A=C	A
	GOYES	+
	AD1EX
	C=DAT1	A
	D1=A
	LA(5)	=ERRTRAP
	?A=C	A
	GOYES	++
	GONC	--
+	AD0EX
	B=A	A
	D0=A
	LC(5)	=ERRTRAP
	GOVLNG	#4EE4		Han:	same entry in ROM 2.15
++	A=DAT0	A
	A=A+CON	A,5
	DAT0=A	A
	D0=D0+	5
	A=R0
	AD0EX
	B=A	A
	GOVLNG	=Loop
sstwarm	P=	13
	GOVLNG	=PWLseq
  ENDCODE
  RUI
(;)

**********************************************************************
*		SDB stream examiner
**********************************************************************

* Scans status of test stream and updates true stream to match
* --> topob TRUE	; if COLA or similar happened
* --> FALSE		; otherwise

NULLNAME	sst_status?

* R0
* R1

CODE
		GOSBVL	=SAVPTR
		C=0	W
		R0=C
		R1=C
		C=B	A
		D0=C
		D0=D0-	5
		C=DAT0	A	->rpl1
		D1=C		->rpl1
		D0=D0-	5	->rstk2
		A=DAT0	A	->rpl2
		D0=D0+	5	->rstk1
		A=A-C	A	->rpl2 - ->rpl1
		A=A-CON	A,5	- 5 for SEMI
		R4=A		R4[A] = rpldiff (for cola checking)
		D1=D1+	5	Skip SEMI
		B=0	A	stream index = 0
		GOTO	sst_rscan1

sst_rscan	D0=D0-	5	previous ->rstk
		C=DAT0	A
		D1=C		previous ->rpl
		C=DAT1	A
		LA(5)	=ERRTRAP
		?A=C	A
		GOYES	sst_scanend
sst_rscan1	GOSUB	sst_calcloc	A[A]=bint	D[A]=skpilevel
		C=A	A
		BCEX	A
		P=C	0		stream index
		BCEX	A
		GOSUB	sst_shift	Shift bint upwards
		R0=C.F	P		Store bint
		C=D	A		skiplevel
		GOSUB	sst_shift	Shift level
		R1=C.F	P		Store level
		P=	0
		B=B+1	A		stream++
		GONC	sst_rscan	Loop until errtrap found

* Shift C[0] to C[P]
sst_shift	P=P-1
		GOC	+
		CSLC
		GOTO	sst_shift
+		BCEX	A
		P=C	0
		BCEX	A
		RTN
* Found ERRTRAP, now modify stream below it as indicated by
* the indexes in R0 (bint) and R1 (skiplevel)

sst_scanend
		C=B	 A
		R2=C			streams
		C=R0
		A=0	A
		A=C	P
		R3=A			current stream bint
-		D0=D0-	5		Drop that many rstk levels..
		A=A-1	A
		GONC	-
		
		C=R1			Now emulate skipping on
		C=C-1	B		the topmost stream
		R1=C
		GOSUB	sst_doskp

		A=R4			Now check if found a cola word
		?A#0	A
		GOYES	sst_eneed1		* Next-Current<>5
* No COLA nor ITE, P=1 is meaningless
		P=	2
		GOSUB	sst_diff
		GONC	sst_examr2		* Do RDROPs & RSKIPs
* Do RDUP/IDUP ( Works without knowing )
		C=DAT0	A
		D0=D0+	5
		DAT0=C	A
		GOTO	sst_doexit
* Have to save 1st object to be later added to top
sst_eneed1	A=DAT0	A
		AD1EX		* D1 = @D0
		C=DAT1	A	* C = @@D0
		CD0EX		* D0 = @@D0, C = D0
		A=DAT0	A	* A = @@@D0
		D0=(5)	=PRLG
		CD0EX		* D0 = D0, C = @@@D0
		?A#C	A
		GOYES	+	* Store the pointee
		CD1EX		* Store pointer to the prolog
		GONC	++
+		C=DAT1	A
++		R4=C

* R4 now has a valid pointer to next object

* ITE or COLA ?, ITE if level is same
		P=	1
		GOSUB	sst_diff
		GONC	sst_curprev
* We've got ITE now ( with true, false means just skip )
		C=DAT0	A
		CD0EX
		RSTK=C
		GOSBVL	=SKIPOB
		GOSBVL	=SKIPOB
		C=RSTK
		CD0EX
		DAT0=C	A
		GOTO	sst_examr2
sst_curprev	D0=D0-	5
		C=C-1	A
		A=A-1	A
		GONC	sst_curprev
		R3=C			* Corrected 'currect' level
		P=	1		* Corrected 'current' ob
		GOSUB	sst_doskp
		GOTO	sst_doexit
* Now do possible rdrops & rskips for prev level
sst_examr2	D=0	A
		D=D+1	A
		GONC	+
sst_examR1	D=0	A
+		D=D+1	A

		C=D	A
		P=C	0
		GOSUB	sst_diff
sst_dordrp	A=A-1	A
		GOC	sst_dorskp
		C=DAT0	A
		D0=D0-	5
		DAT0=C	A
		GONC	sst_dordrp

sst_dorskp	D0=D0-	5
		C=D	A
		P=C	0
		GOSUB	sst_doskp
		D0=D0+	5

sst_doexit	D0=D0+	5
		AD0EX
		GOSBVL	=GETPTR
		B=A	A
		D=D+CON A,3

		A=R4
		?A=0	A
		GOYES	sst_finexit
		DAT1=A	A
		GOVLNG	=DOTRUE
sst_finexit	GOVLNG	=Loop

sst_diff	C=R0
		GOSUB	sst_nthtoa
		C=R3
		A=A-C	A
		A=A-1	A
		RTN

sst_nthtoa	A=0	W
		A=C	P
-		P=P-1
		GOC	+
		ASRC
		GOTO	-
+		P=	0
		RTN

sst_doskp	C=DAT0	A
		CD0EX
		D1=C
		C=R1
		GOSUB	sst_nthtoa
		B=A	A
-		B=B-1	A
		GOC	+
		GOSBVL	=SKIPOB
		GOTO	-
+		CD1EX
		CD0EX
		DAT0=C	A
		RTN

sst_calcloc	LC(5)	8	Assume skipped none
		D=C	A	
		LC(5)	=DOCOL
-		A=DAT1	A	Scan until found bint
		?A#C	A
		GOYES	+
		D1=D1+	10	Skip  DOCOL  [ROMPTR]  SEMI
		D1=D1+	11	Skip [DOCOL]  ROMPTR  [SEMI]
		D=D-1	A
		GONC	-
+		AD1EX		D1 = ->bint
		D1=D1+	5
		A=DAT1	A	A[A] = bint
		RTN		D[A] = skiplevel
ENDCODE
**********************************************************************

