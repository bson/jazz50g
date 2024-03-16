**********************************************************************
* Name:		DBHOOK
* Interface:	( -> )
* Description:	Hidden command to manually set up DB hooks and
*		set up DBpar
**********************************************************************
NULLNAME DBHOOK
tNAME DBHOOK DBHOOK
::
  CK0

  NULLNAME DBHook
  ::
* Setup DB hooks
    CODE
		GOSBVL	=SAVPTR
		D0=(5)	DBADDRGX
		LCHEX	D8
		DAT0=C	B
		D0=D0+	2
		A=PC
		LC(5)	(GxDbg)-(*)
		A=A+C	A
		DAT0=A	A

		A=PC			now set up rtab, dtab, cfg
		LC(5)	(ftDbHook)-(*)
		C=C+A	A
		GOSUB	+
		GOVLNG	=GETPTRLOOP

+		PC=C
    ENDCODE

* Validate existing DBpar
ASSEMBLE
DBPARSIZE	EQU (DBBUFSIZE)+8+5
RPL
    ' ID DBpar Sys@ ITE
    ::
      CODE
		C=DAT1	A
		CD0EX
		D0=D0+	5
		A=DAT0	A
		CD0EX
		R1=C
		LC(5)	DBPARSIZE
		?A<C	A
		GOYES	+	PAR smaller than it should be, corrupt
		C=R1
		CD0EX
		D0=D0+	5
		A=DAT0	8
		D0=C
		LC(8)	(0)-(DBMAGIC)
		P=	7
		C=-C-1	WP
		?A#C	WP
		GOYES	+	Invalid magic - corrupt
+		P=	0
		GOVLNG	=OverWrT/FLp
      ENDCODE
      NOT?SEMI [#] XerrDBpar DO#EXIT
    ;
* Create new DBpar
    ::
ASSEMBLE
		CON(5)	=DOEXT0
		REL(5)	+
		CON(8)	(0)-(DBMAGIC)
+
RPL
      [#] DBBUFSIZE EXPAND
      CODE
		C=DAT1	A
		CD1EX
		D1=D1+	10
		A=DAT1	8
		A=-A-1	W
		DAT1=A	8
		D1=C
		GOVLNG	=Loop
      ENDCODE		
      ' ID DBpar Sys!
    ;
  ;

;

**********************************************************************
* Name:		xDB
* Interface:	( ob --> )
* Description:	Debug machine language
**********************************************************************
ASSEMBLE
	CON(1)	#8
RPL
xNAME DB
::
  CK1
  CHECKME

* Set up DBpar and hooks
  DBHook

* Check argument
  DUPTYPEIDNT? IT :: @ ?SEMI 0LastRomWrd! SETNONEXTERR ;
  DUPTYPEROMP? IT :: ROMPTR@ ?SEMI 0LastRomWrd! SETROMPERR ;
  DUPTYPECSTR? IT :: Entr># #>HXS ;

  ::
	CK&DISPATCH1
	THIRTYONE	DUPTWO
	#7F		ONE
	ELEVEN
	:: HXS>#
	   CODE
		GOSBVL	=POP#
		R0=A
		GOSBVL	=SAVPTR
		D0=A
		A=DAT0	A
		GOVLNG	=Push2#aLoop
	   ENDCODE
	   TWO
	;
	ZERO	:: ITE THREE FOUR ;
  ;

  THIRTYTHREE UserITE TWO ZERO

ASSEMBLE
f_dbgs		IF fDBGSERVER
RPL
  THIRTYTWO UserITE
  :: #1+ CLOSEUART DOOPENIO ( NULLPAINT NULLPAINT ) ;
ASSEMBLE
f_dbgs		ENDIF
RPL
  :: ( FNT1 FNT2 ) TOADISP TURNMENUOFF ;

*  ROT GetRplTab GetDisTab

  ( args #mode #flags )

  ( COLA is needed so that stream appears to be unmodified )
  COLA

ASSEMBLE
*  CODE
	CON(5)	=DOCODE
	REL(5)	->end_debug
	
	INCLUDE	dbg/dbentry.a
	INCLUDE	dbg/dbhooks.a
	INCLUDE	dbg/dbkeywait.a
	INCLUDE	dbg/dbmain.a
	INCLUDE	dbg/dbarg.a
	INCLUDE	dbg/dbdis.a
	INCLUDE	dbg/cycles.a
	INCLUDE	dbg/dbview.a
	INCLUDE	dbg/dbdisp.a
	INCLUDE	dbg/dbmsg.a
	INCLUDE	dbg/dbstep.a
	INCLUDE dbg/dbreg.a

f_dbg0	IF fDBGSERVER

	INCLUDE	dbg/dbserver.a
	INCLUDE	dbg/dbread.a
	INCLUDE	dbg/dbwrite.a

f_dbg0	ENDIF
	
->end_debug	
*  ENDCODE
RPL

;
**********************************************************************
