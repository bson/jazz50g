**********************************************************************
* Name:		xEA
* Interface:	( $ --> hxs )
*		( hxs --> $ )
*		( ob --> hxs )
**********************************************************************
ASSEMBLE
	CON(1)	8
RPL
xNAME EA
::
  CK1&Dispatch
  THREE :: Entr># #>HXS ;
  ELEVEN :: HXS># #>Entr ;
  ZERO
  ::
    CODE
	GOSBVL	=PopASavptr
	GOVLNG	=PUSH#ALOOP
    ENDCODE
    #>HXS
  ;
;

( # --> $ )
NULLNAME #>Entr
::
  FINDTAB 2DROP ( ensure extable library exists )
  ExtGetName
  NOTcase SETNONEXTERR
;

( $ --> # )
NULLNAME Entr>#
::
  FINDTAB 2DROP	( ensure extable library exists )
  ExtGetAdr
  NOTcase SETNONEXTERR
;


**********************************************************************
* Name:		FINDTAB
* Interface:	( -> #rtab #dtab )
* Description:	returns the address of rtab and dtab if library
*		exists anywhere in memory (RAM/ERAM/FLASH); otherwise
*		errors out if entries table library is missing
* Notes:	For use with EC and ED
**********************************************************************
NULLNAME FINDTAB
CODE
		GOSBVL	=SAVPTR
		GOSUB	FindTab
		GOC	+
		GOSUB	ftGetTabDis
		GOSBVL	=Push2#Loop

+		LC(5)	XerrNoRPLtab	#3E002
		GOVLNG	=GPErrjmpC

FindTab		C=0	A
		LC(3)	=ENTRY_LIB	entry table library id
**********************************************************************
* Name:		FindLibC
* Entry:	C[A] = lib id
* Exit:		CC: lib found		or	CS: lib not found
*		C[A] ->libaccess
*		A[A] ->libnum
* Uses:		A[A] B[A] C[A] D0 CRY
**********************************************************************
FindLibC	B=C	A
		D0=(5)	=ROMPTAB
		A=DAT0	X
		D0=D0+	3
-		A=A-1	X
		RTNC
		C=DAT0	X
		D0=D0+	16
		?C#B	X
		GOYES	-
		D0=D0-	16-3
		A=DAT0	A		A[A] ->libnum
		D0=D0+	5
		C=DAT0	A		C[A] ->libaccess
		RTNCC

**********************************************************************
ftGetTabDis	D=C	A
		?C=0	A
		GOYES	+
		GOSUB	ftPC=C		configure rom view
+		D0=A			D0 ->libnum
		D0=D0+	3+5+5		skip id, hash offset, msg offset
		C=DAT0	A
		AD0EX
		A=A+C	A		A[A] ->link
		AD0EX
		D0=D0+	5+5		skip link prolog, len
		C=DAT0	A		get offset to first xlib
		AD0EX

*** extable
		C=C+A	A
		CD0EX			D0 -> nop
		D0=D0+	5+5		skip CODE prolog, len
		D0=D0+	10+4		skip "LOOP", GOTO
		C=DAT0	A		C[A] = offset to table
		AD0EX
		A=A+C	A
		D0=A
		R0=A			save ->rpltab (entry count)
		LC(5)	128*5+10
		A=A+C	A
		R1=A			save ->distab
		C=D	A
		?C=0	A
		RTNYES
		P=	1		restore rom view
ftPC=C		PC=C

**********************************************************************
* Set up rtab, dtab, and cfg hooks for DEBUG
**********************************************************************
ftDbHook	GOSUB	FindTab		get ->cfg into C[A]
		GOC	+
		D0=(5)	(DBADDRGX)-15	
		DAT0=C	A		save ->cfg
		GOSUB	ftGetTabDis
		D0=(5)	(DBADDRGX)-5
		C=R0
		DAT0=C	A		save ->rtab
		D0=D0-	5		(gDTAB)-(gRTAB)
		C=R1
		DAT0=C	A		save ->dtab
		RTN

+		C=0	W
		P=	14
		D0=(5)	(DBADDRGX)-15
		DAT0=C	WP
		P=	0
		RTN		
ENDCODE

**********************************************************************
* Name:		FindTabs
* Interface:	( -> #dtab #rtab )
* Description:	returns the address of dtab and rtab if entry library
*		exists anywhere in memory (RAM/ERAM/FLASH);
*		if entries library doesn't exist, returns ZERO ZERO
**********************************************************************
NULLNAME FindTabs
::
  CODE
  		GOSBVL	=SAVPTR
		GOSUB	FindTab
		GONC	+
		GOVLNG	=PushFLoop
+		GOSUB	ftGetTabDis
		GOSBVL	=PUSH2#
		GOVLNG	=PushTLoop
  ENDCODE
  ITE SWAP ZEROZERO
;

**********************************************************************
* Name:		GetTabCfg
* Interface	( -> #libcfg )
* Description:	Get the config address of entries table
**********************************************************************
NULLNAME GetTabCfg
CODE
		GOSBVL	=SAVPTR
		GOSUB	FindTab
  		GONC	+
  		C=0	A
+		A=C	A
		GOSBVL	=PUSH#ALOOP
ENDCODE
