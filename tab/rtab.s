**********************************************************************
*		JAZZ - Main RPL.TAB Subroutines
**********************************************************************

DEFINE RPLROMP	ROMPTR 3E1 0
DEFINE DISROMP	ROMPTR 3E1 1
* Change sdb.s and ec.s accordingly if changing the following
DEFINE RPLLAM	LAM ~rtb
DEFINE DISLAM	LAM ~dtb

**********************************************************************
* Name:		xRTAB
* Interface:	( --> $tab )
* Description:	Finds and returns RPL.TAB from the system
**********************************************************************
ASSEMBLE
	CON(1)	8
RPL
xNAME RTAB
:: CK0 GetRplTab ;

**********************************************************************
* Name:		GetRplTab
* Interface:	( --> $tab | NULL$ )
* Description:	Finds and returns RPL.TAB from the system
**********************************************************************
NULLNAME GetRplTab
::
* SEVEN TestUserFlag case NULL$
  ' RPLLAM @LAM ?SEMI
  ' RPLROMP ROMPTR@ ITE
	TRUE
	:: ' ID RPL.TAB RclID ;
  NOTcase NULL$
  DUPTYPECSTR? NOTcasedrop NULL$
  CODE
	C=DAT1	A
	CD0EX
	D0=D0+	10
	A=0	A
	A=DAT0	4
	CD0EX
	LC(5)	TABMAGIC
	?A=C	A
	GOYES	grt100
grt100	GOVLNG	=PushT/FLoop
  ENDCODE
  NOTcasedrop NULL$
;
**********************************************************************
* Name:		xDTAB
* Interface:	( --> $dtab )
* Description:	Finds and returns DIS.TAB from the system
**********************************************************************
ASSEMBLE
	CON(1)	8
RPL
xNAME DTAB
:: CK0 GetDisTab ;

**********************************************************************
* Name:		GetDisTab
* Interface:	( --> $dtab | NULL$ )
* Description:	Finds and returns DIS.TAB from the system
**********************************************************************
NULLNAME GetDisTab
::
* SEVEN TestUserFlag case NULL$
  ' DISLAM @LAM ?SEMI
  ' DISROMP ROMPTR@ ITE
	TRUE
	:: ' ID DIS.TAB RclID ;
  NOTcase NULL$
  DUPTYPECSTR? NOTcasedrop NULL$
  CODE
	C=DAT1	A
	CD0EX
	D0=D0+	10
	A=0	A
	A=DAT0	4
	CD0EX
	LC(5)	DTABMAGIC
	?A=C	A
	GOYES	gdt100
gdt100	GOVLNG	=PushT/FLoop
  ENDCODE
  NOTcasedrop NULL$
;
**********************************************************************
* Name:		RclID
* Interface:	( id --> ob TRUE / FALSE )
* Description:	Find id from system. (Ram cards / userob area )
*		The found object is evaluated and is expected to return
*		1 object to the stack.
* Notes:	Due to the low speed of this routine the execution time
*		for disassembling small objects can consist mostly of this
*		routine being executed for DIS.TAB and RPL.TAB.
* HP50G Notes:	Implement full search later; right now assume available
**********************************************************************
NULLNAME RclID
::
*  DUP ERRSET :: MINUSONE SG_ITE ROMPTR 0F0 067 ROMPTR 0F0 091 TRUE ;
*  ERRTRAP FALSE
*  ?SKIP
  ::
     DUP ( SG_ITE COMPILEID ) G_COMPILEID ?SEMI
     2DROP FALSE RDROP
  ;
  DEPTH 1LAMBIND EVAL
  DEPTH 1GETABND #<>case SETTYPEERR	( Invalid program )
  SWAPDROP TRUE
;

