**********************************************************************
*		JAZZ - Main SSTK Subroutines
**********************************************************************
DEFINE	exstk	LAM ~stk		( Exit flag )
DEFINE	@exstk	LAM ~stk
DEFINE	!exstk	' LAM ~stk STOLAM

DEFINE	notxtbk		LAM ~tbk
DEFINE	notxtbkflag	BINT79
DEFINE	notxtbk?	BINT79 TestSysFlag
DEFINE	sysdis		LAM ~sys
DEFINE	sysdisflag	BINT85
DEFINE	sysdis?		BINT85 TestSysFlag

ASSEMBLE
=KeyObLam	EQU	#27660
*=CtlAlarm?	EQU	#25976
RPL

**********************************************************************
* Name:		xSSTK
* Interface:	( ? --> ? )
* Description:
*		SOL Replacement
**********************************************************************
ASSEMBLE
	CON(1)	8
RPL
xNAME SSTK
::
  CK0NOLASTWD

  CHECKME			( Error if covered )

* If SDB is running, then just exit. This will prevent accidentally
* running SSTK and killing SDB. Check before SSTK flag; make sure to
* KEEP THIS ORDER (i.e. SdbBrk check before exstk check)

  ' SdbBrk @LAM caseDROP

  ( If SSTK already exists then exit it by setting exstk flag )
  ' exstk @LAM casedrop :: TRUE !exstk ;

  ( Setup SSTK variables )
  UNDO_TOP? IT ABND		( abandon possible saved stack )

  TEN GETLAMPAIR ITE_DROP	( check how we're called )
  ::
    UNROT2DROP
    EQ: KeyObLam
    NOT?SEMI
    1GETABND
    KeyOb!
    UNDO_TOP? IT ABND
    KeyOb@ ' KeyObLam
    ONE DOBIND
  ;

  notxtbk? sysdis? FALSE	( Setup SSTK variables )
  { notxtbk sysdis exstk } BIND
*  CacheStack			( Save stack if necessary )
  UNDO_ON? IT SAVESTACK

  NULLNAME SSTKLOOP		( Entry point to sstk )
  ::
  BEGIN
	notxtbkflag SetSysFlag	( Textbook mode off )
	sysdisflag SetSysFlag	( SysRPL mode on )
	AtUserStack		( Signal valid user stack )
	SysMenuCheck		( Do menu maintenance )
        NULLNAME SysDisplay!	( Do system display )
        ::
	  ?DispCommandLine	( Display edit line )
	  ?DispStatus		( Display status area )
*	  ?DispStack1		( Alternate stack display )
	  ?DispStack		( Display stack area )
	  ?DispMenu		( Display menu area )
	  ClrDAsOK		( Reset display flags )
	;
	GetKeyOb		( Wait for a key, return key object )

	ERRSET DoKeyOb		( Evaluate key object )
	ERRTRAP 		( Clean up possible error )
	NULLNAME SSTKErrTrap
	::
	  NOP			( validate ASS error trap )
	  LastRomWord@ PTR>ROMPTR
	  ' xASS EQUAL case EdStkAssTrap

*	  ( uncomment to compile only SDB )
*	  ::
*	    DUPTYPEBINT? ITE
*	      ::
*	        UNCOERCE
*	        1LAMBIND FixStk&Menu 1GETABND
*		AtUserStack
*	      ;
*	      FixStk&Menu
*	    LastRomWord@ ERROR@ SysErrFixUI ERRBEEP
*	    TOADISP UnScroll
*	    CODE
*		A=DAT1	A
*		CD1EX
*		AD1EX
*		D1=D1+	5
*		A=DAT1	A
*		CD1EX
*		LC(5)	#3E000		Jazz ROM ID
*		C=A	B
*		?A=C	A
*		GOYES	+
*+		GOVLNG	=PushT/FLoop
*	    ENDCODE
*
*	    ( Jazz error -> already handled; otherwise display error )
*	    ITE 2DROP :: MakeErrMesg DISPROW1 DISPROW2 ;
*	    SetDA1Temp
*	  ;
	  
	  FixStk&Menu
	  ERROR@ ZERO #=casedrop SysErrFixUI
	  Err#Cont #=casedrop ( DoCont/Kill )
	    :: HALTTempEnv? caseERRJMP CkSysError ;
	  Err#Kill #=casedrop ( DoCont/Kill )
	    :: HALTTempEnv? caseERRJMP CkSysError ;
	  #CAlarmErr #=case ProcessAlarm

*	  ( alternate alarm processing; check equate at top )
*	  ::
*	    CtlAlarm?
*	    case SysErrFixUI
*	    CtlAlarm@ SysErrFixUI
*	    ERRSET
*	      :: DUP RCLALARM% THREE NTHCOMPDROP EVAL ;
*	    ERRTRAP
*	      SSTKErrTrap
*	  ;


* Han:	comment the DoEdErrJump line and uncomment the seco directly
*	below to compile SDB without Jazz
	  DoEdErrJmp
*	  ::
*	    LastRomWord@ ERROR@	
*	    SysErrFixUI ERRBEEP
*	    TOADISP UnScroll
*	    MakeErrMesg DISPROW1 DISPROW2
*	    SetDA1Temp
*	  ;

	;

	@exstk			( Exit condition )
  UNTIL
  ;

  notxtbkflag notxtbk ITE SetSysFlag ClrSysFlag
  sysdisflag sysdis ITE SetSysFlag ClrSysFlag
  
  ( Abandon until sstk lams destroyed )
  BEGIN
    ' exstk @LAM DUP IT :: SWAPDROP ABND ;
    NOT
  UNTIL

  ( exit similarly to EQSTK or JAVA )
  ( otherwise we might crash other SOLs )

  TEN GETLAMPAIR		( get 1st local env with name )
  casedrop CacheStack		( none found; save stack )
  UNROT2DROP			( otherwise check vs KeyObLam )
  EQ: KeyObLam
  NOTcase CacheStack
  1GETABND KeyOb!		( do as in ROM exiting editline )
  CacheStack
  KeyOb@ ' KeyObLam ONE DOBIND
;

**********************************************************************
* ?DispStack replacement ( incomplete )
**********************************************************************
*	INCLUDE stk/dispstack.s


**********************************************************************
* Name:		StkDis1		renamed to JazzStkDis1
* Interface:	( ob --> $ )
* Description:
*	Disassembles object for single-line stack display
**********************************************************************
NULLNAME JazzStkDis1
::
  FindTabs			( --> ob dtab tab )
  
* An additional entry point for the benefit of Java v3.0

  NULLNAME JavaDis1
  ::
     MEM 1000 #< IT GARBAGE	( TOTEMPBOT? is too slow.. )
     3PICK SetStkDis1Ops	( --> ob dtab tab flag )
     NOTcase
     :: 3DROP "Invalid Object" TOTEMPOB ;
     NULL$TEMP			( --> ob dtab tab $labels )
     NULL$TEMP Diss		( --> ob dtab tab $labels $diss )
     5UNROLL 4DROP		( --> $diss )
  ;
;
**********************************************************************

**********************************************************************
*		JAZZ HOOKS FOR EXTERNAL LIBRARIES
**********************************************************************

**********************************************************************
* Name:		JazzHook
* Interface:	( --> { hooks } )
* Description:
*		Hidden xlib for external programs to use Jazz subroutines.
**********************************************************************
NULLNAME JazzHook
tNAME JazzHook JAZZHOOK		( Provide stable hooking mechanism )
::
  CODE
	?C<=B	A		PC <= RPL return stack? (see DOCODE end)
	GOYES	+
+	GOVLNG	=PushT/FLoop	TRUE if Jazz is covered
  ENDCODE
  case NULL{}			( NULL{} if Jazz is covered )

  {
*	GetRplTab		( --> RPL.TAB )		( * Java * )
*	GetDisTab		( --> DIS.TAB )		( * Java * )
	FindTabs
	GetTabCfg
	JazzStkDis1		( ob --> $ )		( * Java * )
	JavaDis1		( ob dtab tab --> $ )	( * Java * )
  }
;

* Sample on how to call the hook:
*	( --> false | {hooks} true )
*	::
*	  "JAZZHOOK" palparse DROP	( try parsing the name )
*	  DUPTYPEROMP? NOTcsdrpfls	( fail if romp not found )
*	  EVAL DUPNULLCOMP? casedrpfls	( fail if Jazz is covered )
*	  TRUE
*	;
*
*	If true is returned then just pick the items you need from
*	the returned list.
*
*	Programmers please feel free to suggest additions to the list.
