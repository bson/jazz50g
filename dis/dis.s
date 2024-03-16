**********************************************************************
*		JAZZ - Main Disassembler Subroutines
**********************************************************************
**********************************************************************
*		Jazz Disassembler Commands
**********************************************************************

**********************************************************************
* Name:		xDIS
* Interface:	( ob --> $ )
* Description:
*	Disassembles object
* Notes:
*	Disassembler cannot run from TEMPOB area
*	A temporary ob is moved to bottom of tempob area to keep it fixed
*	A copy of the ob is kept on stack so GC will not destroy it
**********************************************************************
ASSEMBLE
	CON(1)	8
RPL
xNAME DIS
::
  CK1
  CHECKME		( Error if lib is hidden )
  TOTEMPBOT?		( If ob in tempob move it to bottom )
*  GetDisTab		( --> ob dtab )
*  GetRplTab		( --> ob dtab tab )
  FindTabs
  3PICK SetDissOps	( --> ob dtab tab flag )
  NOTcase :: 3DROP "Invalid Object" TOTEMPOB ;
  ScanLabels 		( --> ob dtab tab $labels )
  NULL$TEMP Diss	( --> ob dtab tab $labels $diss )
  5UNROLL 4DROP		( --> $diss )
;

**********************************************************************
* Name:		xDISXY
* Interface:	( hxs_x hxs_y --> $ )
* Description:	Disassembles range X-Y using PCO/RPL detection
**********************************************************************
ASSEMBLE
	CON(1)	8
RPL
xNAME DISXY
::
  CK2&Dispatch
  # BB ( 2HXS )
  ::
    CHECKME				( Error if lib is hidden )
    HXS># SWAP HXS># SWAP		( --> #x #y )
*    2DUP#> caseSIZEERR			( Error if x >= y )
*    2DUP#= caseSIZEERR
    2DUP#< NcaseSIZEERR
*    GetDisTab				( --> #x #y dtab )
*    GetRplTab				( --> #x #y dtab tab )
    FindTabs
    2SWAP 2DUP SetDisXYOps		( --> dtab tab #x #y )
    NULL$TEMP UNROT ScanLabsXY 		( --> dtab tab $labels )
    NULL$TEMP Diss			( --> dtab tab $labels $diss )
    4UNROLL 3DROP			( --> $diss )
  ;
;
**********************************************************************
* Name:		xDOB
* Interface:	( hxs_x --> $ hxs_y )
* Description:	Disassembles range X-Y using PCO/RPL detection
*		End address is guessed
*		Also handles non-PCO/non-RPL entries
**********************************************************************
ASSEMBLE
	CON(1)	8
RPL
xNAME DOB
::
  CK1&Dispatch
  ELEVEN	:: HXS># Dob ;
  THREE		:: Entr># Dob ;
  THIRTYONE
    NULLNAME Dob
    ::
      CHECKME

      Ent11111@				( convert entry if need be )
      
      FindObEnd NOTcase SETSIZEERR	( --> #x #y )

      DUP #>HXS UNROT			( --> hxs_y #x #y )
*      GetDisTab				( --> y #x #y dtab  )
*      GetRplTab				( --> y #x #y dtab tab )
      FindTabs
      2SWAP 2DUP SetDisXYOps		( --> y dtab tab #x #y )
      NULL$TEMP UNROT ScanLabsXY	( --> y dtab tab $labs )
      NULL$TEMP Diss			( --> y dtab tab $labs $diss )
      5UNROLL 3DROP			( --> $diss y )
    ;
  ZERO
  ::
    CODE
	GOSBVL	=PopASavptr
	GOVLNG	=PUSH#ALOOP
    ENDCODE
    Dob
  ;
;
**********************************************************************
* Name:		xDISN
* Interface:	( hxs_x %n --> $ )
* Description:
*	Disassembles N ml instructions
**********************************************************************
ASSEMBLE
	CON(1)	8
RPL
xNAME DISN
::
  CK2&Dispatch
  # B1 ( HXSREAL )
  ::
    CHECKME				( Error if lib is hidden )
    COERCE DUP%0= caseSIZEERR
    SWAP HXS># SWAP			( --> #x #n )
    OVERSWAP SkipMLN			( --> #x #y )
*    GetDisTab				( --> #x #y dtab )
*    GetRplTab				( --> #x #y dtab tab )
    FindTabs
    2SWAP SetDisnOps			( --> dtab tab #x #y )
    NULL$TEMP UNROT FALSE AddLabsXY	( --> dtab tab $labels  )
    NULL$TEMP Diss			( --> dtab tab $labels $diss )
    4UNROLL 3DROP			( --> $diss )
  ;
;

**********************************************************************
*		DISASSEMBLER SUBROUTINES
**********************************************************************

	INCLUDE dis/scanlabs.s
	INCLUDE dis/skipml.s

**********************************************************************
* Disassembler code
* (     dtab tab $status $buffer
*   --> dtab tab $status $diss   )
**********************************************************************
NULLNAME Diss
CODE
	INCLUDE	dis/disass.a		* Main loops
	INCLUDE	dis/dcadr.a		* RPL disassembler
	INCLUDE	dis/disutils.a		* Utilities
	INCLUDE	dis/dcchr.a		* character disassembler
	INCLUDE	dis/dcreal.a		* % & %% disassembler
	INCLUDE	dis/disinstr.a		* CODE disassembler
	INCLUDE	dis/itype.a		* Determine ml instr type
	INCLUDE dis/disnewops.a		* new opcodes
ENDCODE
**********************************************************************
* Setup status buffer for DISS command
* ( ob --> flag )
* flag is FALSE if object is prologed but corrupt
**********************************************************************
NULLNAME SetDissOps
CODE
		GOSBVL	=SAVPTR
		A=DAT1	A		* A[A] = ->ob
		R0=A.F	A		* R0[A] = ->ob

		GOSUB	InitDisOps
setdisob	A=R0.F	A
		D0=A
		GOSUBL	PC=PRLG?
		GONC	setdispco
		GOSUBL	SafeSkipOb
		GOC	setdisfail
		ST=1	sDISOB
		ST=1	sDISRPL
		C=ST
		DAT1=C	X
		D1=(2)	dCURADDR
		A=R0.F	A
		DAT1=A	A
		D1=(2)	dENDADDR
		AD0EX
		DAT1=A	A
		GOVLNG	=GPOverWrTLp
setdisfail	GOVLNG	=GPOverWrFLp	* Corrupt object		

setdispco	ST=0	sDISRPL
		ST=1	sSPECIAL
		C=ST
		DAT1=C	X
		D1=(2)	dDISMODE
		LC(2)	typDISPCO
		DAT1=C	B
		D1=(2)	dCURADDR
		A=R0.F	A		->pco
		DAT1=A	A
		D1=(2)	dENDADDR
		A=A+CON	A,5
		DAT1=A	A
		GOVLNG	=GPOverWrTLp
**********************************************************************
* Name:		InitDisOps
* Desc:		Initialize status buffer, setup user flags
* Entry:	-
* Exit:		D1 = ->dMODES	ST[X] = user options
**********************************************************************
InitDisOps	D1=(5)	=IRAMBUFF+11	* Clear status
		LC(5)	DISBUFSIZE
		GOSBVL	=WIPEOUT

		D1=(5)	=IRAMBUFF+11	* Setup user options
		CLRST			No flags yet
		D1=(2)	dMODES
*		D0=(5)	=aUserFlags
*		C=DAT0	A
*		D0=C
		D0=(5)	=UserFlags

		C=DAT0	A		C[A] = user flags 1-20

		ST=1	sGUESS		Default: guess on
		?CBIT=0	2-1
		GOYES	+
		ST=0	sGUESS

+		ST=1	sCODEOK		Default: code on
		?CBIT=0	4-1
		GOYES	+
		ST=0	sCODEOK

+		ST=1	sTABU		Default: Tabulator on
		?CBIT=0	5-1
		GOYES	+
		ST=0	sTABU

+		ST=0	sLBPACK		Default: Label pack off
		?CBIT=0	6-1
		GOYES	+
		ST=1	sLBPACK

+		C=ST
		DAT1=C	X
		RTNCC

*D1=IRAMBUF	RSTK=C
*		D1=(5)	(=IRAM@)-4
*		C=DAT1	A
*		D1=C
*		D1=(4)	#100
*		C=RSTK
*		RTN
ENDCODE
**********************************************************************
* Setup status buffer for DISXY command
* ( #x #y --> )
**********************************************************************
NULLNAME SetDisXYOps
CODE
		GOSBVL	=POP2#		* A[A]=start C[A]=end
		R3=A.F	A		* R3[A]=start
		R4=C.F	A		* R4[A]=end
		GOSBVL	=SAVPTR

		GOSUB	InitDisOps
		ST=1	sSPECIAL
		ST=1	sCODEOK
		D1=(2)	dDISMODE
		LC(2)	typDISXY
		DAT1=C	B

		D1=(2)	dGLOBEND
		A=R4.F	A
		DAT1=A	A
		D1=(2)	dENDADDR
		DAT1=A	A
		D1=(2)	dCURADDR
		A=R3.F	A
		DAT1=A	A

*		D0=(5)	(=IRAM@)-4	* Load RAM base to C[A]
*		C=DAT0	A
*		LCHEX	0000		* D0 altered later, so we're ok
		LC(5)	=RAMSTART
		?A>=C	A
		GOYES	+
		ST=0	sGUESS		Disable guess in ROM
+
		D0=A			* ->start
*		ST=0	sDISOB		* Assume not object
*		ST=0	sDISRPL		* Insiginicant until ob is found
		GOSUBL	PC=RPL?		* Start in rpl?
		GONC	setdisxyml
		ST=1	sDISRPL		* Start in rpl mode
		ST=1	sDISOB		* and a valid object
		A=R4.F	A		global end address
		?A<=C	A
		GOYES	setdisxyml
		D1=(2)	dENDADDR
		DAT1=C	A		* Set end of rpl object
setdisxyml	D1=(2)	dMODES
		C=ST
		DAT1=C	X
		GOVLNG	=GETPTRLOOP
ENDCODE
**********************************************************************
* Setup status buffer for DISN command
* ( #x #y -->  #x #y )
**********************************************************************
NULLNAME SetDisnOps
CODE
		GOSBVL	=SAVPTR
		GOSBVL	=POP2#		* A[A]=start C[A]=end
		R3=A.F	A		* R3[A]=start
		R4=C.F	A		* R4[A]=end

		GOSUB	InitDisOps	* Set mode flags
*		ST=0	sDISOB
		ST=1	sSPECIAL
		ST=1	sCODEOK
		C=ST
		DAT1=C	X
		D1=(2)	dDISMODE
		LC(2)	typDISN
		DAT1=C	B

		D1=(2)	dGLOBEND	* Set global end address
		C=R4.F	A
		DAT1=C	A
		D1=(2)	dENDADDR	* Set end address
		DAT1=C	A
		D1=(2)	dCURADDR	* Set start address
		C=R3.F	A
		DAT1=C	A

		GOVLNG	=GETPTRLOOP
ENDCODE
**********************************************************************
* Setup status buffer for disassembling 1 stack level
* ( ob --> flag )
* flag is FALSE if object is prologed but corrupt
**********************************************************************
NULLNAME SetStkDis1Ops
CODE
		GOSBVL	=SAVPTR
		A=DAT1	A
		R0=A.F	A		R0[A] = ->ob

		GOSUB	InitDisOps	* Set mode flags
		ST=1	sDISSTK
		ST=0	sCODEOK

*		D0=(5)	(=IRAM@)-4	* D0 altered later, so we're ok
*		C=DAT0	A
*		LCHEX	0000		C[A] = RAM base address
		LC(5)	=RAMSTART
		A=R0.F	A		->ob
		?A<C	A
		GOYES	setstkdispco	* ROM address, dis as PCO
		GOTO	setdisob
setstkdispco	GOTO	setdispco
ENDCODE
**********************************************************************
