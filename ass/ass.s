**********************************************************************
*		Jazz Assembler
**********************************************************************

**********************************************************************
*		Main Program
**********************************************************************
ASSEMBLE
	CON(1)	#8
RPL
xNAME ASS
::
  CK1
  CHECKME		( Error if lib is hidden )
  :: STRIPTAGS DUPTYPECSTR? ?SEMI
     SETTYPEERR
  ;

* If debugging with MLDL here is needed:
* RECLAIMDISP TURNMENUOFF
* Else SetupAssOps will put user options to wrong location

*  GetRplTab			( --> $src $tab )

* Now fetch the config address of entries library
  GetTabCfg			( $src #cfg )
  FindTabs SWAPDROP		( $src #cfg #tab )

  MakeAssStat$			( --> $src #cfg #tab $status )
  SetupAssOps			( Fetch user options into $status )

  NULL$TEMP			( $src #cfg #tab $status $buffer )
  5ROLL				( #cfg #tab $status $buffer $src )
  GARBAGE			( To simplify things )
  Assemble
  DROP 4UNROLL 3DROP		( --> $buffer )

;
**********************************************************************
*		Subroutines
**********************************************************************

**********************************************************************
* Input: ( $tab $status $buffer $src )
* Output: ( $tab $status $buffer $src )
**********************************************************************
NULLNAME Assemble

ASSEMBLE
		CON(5)	=DOCODE
		REL(5)	->AssEnd
		GOLONG	AssembleStart
		INCLUDE	ass/assdisp.a
		INCLUDE ass/assdisplay.a	formerly display.s
		INCLUDE ass/error.a
		INCLUDE	ass/assemble.a		AssembleStart is here
		INCLUDE ass/assrpl.a
GoL_Error	GOLONG	Error			ass/error.a too far
GoL_SHRINKOB$	GOLONG	SHRINKOB$		misc/memory.s too far
GoL_SHRINK$	GOLONG	SHRINK$			misc/memory.s too far
		INCLUDE ass/parse.a
		INCLUDE	ass/save.a
		INCLUDE ass/asscode.a
		INCLUDE	ass/symbols.a
->AssEnd
RPL

**********************************************************************
* Make assembler status buffer to bottom of tempob area.
* Makes it big enough to use even page method.
* The address of the buffer will not change unless:
*	1) ROMPTAB changes
*	2) One of the display grob sizes is changed
* Neither of above can happen while the assembler loop is running
**********************************************************************
( --> $status )
NULLNAME MakeAssStat$

CODE
		GOSBVL	=SAVPTR
		LC(5)	(ASSBUFSIZE)+256
*		GOSUBL	MAKEBOT$N		now in ROM 2.15
		GOSBVL	=MAKEBOT$N
		GOVLNG	=GPPushR0Lp
ENDCODE

**********************************************************************
* Fetch user options into status buffer.
* Interface: ( $status --> $status' )
* Note: TestFlag uses ST0 which is ok since ST0 is not an option
*	but a temporary flag.
**********************************************************************

( $status --> $status' )

NULLNAME SetupAssOps
CODE
		GOSBVL	=SAVPTR
		A=DAT1	A
		A=A+CON	A,10
		A=0	B
		LC(5)	#100
		A=A+C	A
		D1=A

		D1=(2)	O_ST_SAVE
		C=DAT1	X
		ST=C		* Just in case there already were some flags..

		LC(2)	1
		GOSUB	UserFlag?
		ST=0	qREPORT
		GONC	+
		ST=1	qREPORT
+		C=ST
		DAT1=C	X
		GOVLNG	=GETPTRLOOP

UserFlag?	ST=1	0
Flag?		A=0	A
		A=C	B
		GOSBVL	=TestFlag
		C=C&A	XS
		?C#0	XS
		RTNYES
		RTN

SysFlag?	ST=0	0
		GOTO	Flag?
ENDCODE
**********************************************************************
