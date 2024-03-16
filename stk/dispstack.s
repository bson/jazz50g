**********************************************************************
* Defines/Equates used by ?DispStack!
**********************************************************************
DEFINE	CopyDisp1	FLASHPTR 002 93
DEFINE	CopyDisp2	FLASHPTR 002 94
DEFINE	Fptr4Eval	FLASHPTR 002 0

ASSEMBLE
=GET_THE_TYPE	EQU	#12F29
=?UpdateStk	EQU	#2A28C
=NoRollDA2?	EQU	#2EEAD
*=#NoRoomForSt	EQU	#33635

* These entries are located in flash page 2; see =?DispStack
* It must be called via ' <entry> FLASHPTR 002 0
=CopyToBuff	EQU	#6A7F8
=DcmpSpcFill	EQU	#6AC3E
RPL

**********************************************************************
* ?DispStack replacement
**********************************************************************
NULLNAME ?DispStack!
::
*  ?UpdateStk			( enough time to update? if not, skip )
  KEYINBUFFER? NOT
  DA2aLess1OK? ORcase
  ::
    TOADISP
    DA2aLess1OK?		( Roll enough to validate display? )
    ClrNewEditL			( Clear DA2aLess1OK? flag )
    case			( Then maybe roll stack up )
    ::
      SetDA2aValid		( Signal stack display valid )
      NoRollDA2?		( No roll requested? )
      case ClrNoRollDA2		( Then just clear the roll flag )

      StackLineHeight
      BINT72
      OVER#- THIRTYFOUR #*	( #slh #hdr_off )
      GetFontCmdHeight
      ROT OVER#- THIRTYFOUR #*	( #hdr_off #gfch #rows )
      SWAP THIRTYFOUR #*	( #hdr_off #rows #cmd_rows )

      CODE
		GOSBVL	=POP#
		R0=A			R0[A] = #cmd_rows
		GOSBVL	=POP2#
		R1=C			R1[A] = #rows; A[A] = #hdr_off
		GOSBVL	=SAVPTR
		D1=(5)	=ADISP
		C=DAT1	A
		A=A+C	A
		LC(5)	5+5+5+5
		A=A+C	A
		D1=A			write position
		C=R0
		A=A+C	A
		D0=A			read position
		C=R1			num of rows to copy
		GOSBVL	=MOVEDOWN
		GOVLNG	=GETPTRLOOP
      ENDCODE
    ;

    ( roll not enough; must redisplay stack )
    ClrNoRollDA2
    TOADISP ONE

    ERRSET
    ::
      StackLineHeight
      CommandLineHeight
      CODE
		AD1EX
		D1=(5)	=SysNib1
		C=DAT1	A
		D1=A
		?CBIT=1	2		is there an editline?
		GOYES	+
		LC(5)	=ZERO
		DAT1=C	A
+		GOVLNG	=Loop
      ENDCODE
      2DUP #=case 3DROP

      ( #lvl #stk_h #ed_h )
      DUP4UNROLL #-				( #ed_h #lvl #rows )
      SCANFONT

      BEGIN
	DUP BINT95 TestSysFlag
	
	( #ed_h #lvl #rows #rows T/F )
	ITE NULL$ :: 3PICK #:>$ ;
	
	( #ed_h #lvl #rows #rows "#:>" )
	4PICK #6+ DEPTH				( #lvl > #depth ? )		
	#>ITE 'NOP :: 4PICK #5+ PICK ;
	
	( #ed_h #lvl #rows #rows "#:>" ob )
	BINT64 SysITE ONE ZERO			( left/right )
		
	( #ed_h #lvl #rows #rows "#:>" ob #1/0  )		
	::
	  OVER 'NOP EQ
	  case :: 2DROP NULL$ ' CopyToBuff Fptr4Eval ;
	
	  SWAPDUP

	  ( #ed_h #lvl #rows #rows "#:>" #1/0 ob ob )
	  RCLSYSF2 1LAMBIND
	  BINT85 SetSysFlag
		  ERRSET Decomp1Line 		( StkDis1 )
		  ERRTRAP :: NULL$SWAP GET_THE_TYPE ;
	  1GETABND STOSYSF2
	
	  ROT

          ( #ed_h #lvl #rows #rows "#:>" ob $ob #1/0 )
	  ' DcmpSpcFill	Fptr4Eval
	  ' CopyToBuff Fptr4Eval
	;

	UNROTDUP 6ROLL SWAP 5ROLL
	ITE CopyDisp1 CopyDisp2
	4UNROLL #- SWAP#1+SWAP
	DUP#0=
      UNTIL
      3DROP
    ;
    ERRTRAP
    ::
      FixStk&Menu
      ERRBEEP
      $ "Error In Stack"
      ONE TRUE DISP_LINE
    ;

    SetDA2aValid
  ;

  SetDA2aBad
;
