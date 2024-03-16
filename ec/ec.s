**********************************************************************
*		JAZZ - Entries browser
**********************************************************************
* Following 2 names must be the same as in rtab.s
*DEFINE ECRPL	LAM ~rtb
*DEFINE ECDIS	LAM ~dtb

* Han:	no longer using ~rtb and ~dtb
* DEFINE ECRPL	NULLLAM
* DEFINE ECDIS	NULLLAM

DEFINE ECNTB	LAM ~ntb
	
ASSEMBLE
	CON(1)	8
RPL
xNAME EC

::
 CK0
 CHECKME			( Check Jazz is not covered )
 NULL$				( Default Search String )
 ZERO				( Default Flags )
 FIFTYSIX TestSysFlag 1LAMBIND	( Save beep flag )
 NULLNAME DoEC			( Entry point for ED ECcat & sEC )
 ::
  '
	INCLUDE	ec/eccode.s	( EC code object )

* The names in the BIND are provided only for the convenience of DIS
* This prevents DIS from trying to get the tables from covered port again.

*DEFINE @eccode	7GETLAM
*DEFINE @ecrtab	6GETLAM
*DEFINE @ecdtab	5GETLAM

DEFINE @eccode	5GETLAM
DEFINE @ecntab	4GETLAM
DEFINE @ecbuf	3GETLAM
DEFINE @ecstat	2GETLAM
DEFINE !ecstat	2PUTLAM
DEFINE @ecmod#	1GETLAM
DEFINE !ecmod#	1PUTLAM


  FINDTAB DROP GetTabCfg

  ' ECNTB @LAM ITE UNROT2DROP	( Restore NTAB from lam, if not create it )
  :: ERRSET			( Create NTAB, if no memory push #0 )
	CODE
		GOSBVL	=POP2#
		R3=A			R3[A] -> number of entries
		R4=C			R4[A] = config address
		GOSBVL	=SAVPTR
		GOSUB	ntabcfg		configure entry library
+		C=R3
		CD0EX
		A=DAT0	A		A[A] = num of entries
		GOSUB	ntabucfg	unconfig (in case of memerr)
+		A=A+A	A
		C=A	A
		GOSBVL	=MAKE$N
		AD0EX
		GOSUB	ntabcfg
		AD0EX
	
		A=R3
		D1=A
		C=DAT1	A
		B=C	A
		D1=D1+	5
		C=DAT1	A
		C=C+A	A
		D1=C
		D1=D1+	5		D1 -> first entry addr

		A=0	A
MKlenlp		B=B-1	A
		GOC	ENlenlp
		D1=D1+	5
		A=DAT1	B
		DAT0=A	B
		D0=D0+	2
		CD1EX
		A=A+1	A
		C=C+A	A
		C=C+A	A
		CD1EX
		GONC	MKlenlp
	
ENlenlp		GOSUB	ntabucfg
		GOVLNG	=GPPushR0Lp

ntabucfg	P=	1
ntabcfg		C=R4
		?C#0	A
		GOYES	+
		P=	0
		RTN
+		PC=C

		
	ENDCODE
	  ERRTRAP ZERO
  ; 

  NULLHXS 50 EXPAND			( 2 + 2*MAXENTRLEN = 50 )

*  7ROLL				( Get Search String )
  5ROLL

* Copy search string HXS (21-55)
  CODE
		GOSBVL	=PopASavptr
		D0=A
		D0=D0+	5	D0= ->string + 5
		C=DAT0	A		
		C=C-CON	A,5
		CSRB.F	A	C=length of string
		A=C	A
		R0=C
		C=0	A
		LC(2)	MAXENTRLEN
		A=A-C	A
		GONC	+	Cut to first 24 chars
		C=R0
+		A=DAT1	A	A= -> BUFHEX
		D1=A
		D1=D1+	10	D1= start of search str in BUF
		DAT1=C	B	store length
		D1=D1+	2
		D0=D0+	5	d0 = ->STRING + 10 ( 1st char)
		B=C	A
-		B=B-1	A	Loop on n chars
		GOC 	++	  -> END LOOP
		A=DAT0	B
		LC(2)	'a'	Convert to uppercase ...
		?A<C	B
		GOYES	+
		LC(2)	'z'
		?A>C	B
		GOYES	+
		ABIT=0	5		
+		DAT1=A	B	and store this char
		D0=D0+	2
		D1=D1+	2
		GONC	-
++		GOSBVL	=GETPTRLOOP
ENDCODE
*  6ROLL		( Get default flags #STAT )
  4ROLL

  ZERO

  ( COD     NTAB  $search #STAT   #N )
  { NULLLAM ECNTB NULLLAM NULLLAM NULLLAM } BIND

  BEGIN

	FLUSH

*	@ecrtab @ecdtab
*	always refresh tables since they can move when flash ports
*	are updated
	FINDTAB GetTabCfg
	@ecntab @ecbuf @ecstat @ecmod#

*	A bit more beautiful than straight RECLAIMDISP
	TOADISP UnScroll TURNMENUOFF CLEARVDISP

	@eccode EVAL
	FLUSH
	ITE
	::
	   !ecmod# !ecstat
	   ZERO #=casedrop		( Mode: View code at addr )
	   ::
	     DUP
	     NULLNAME ECView
	     CODE
		GOSBVL	=POP#
		AD0EX
		C=DAT0	A
		D0=A
		LA(5)	=DOGROB
		?A=C	A
		GOYES	+
		GOVLNG	=DOFALSE
+		GOSBVL	=POP#
		D1=D1-	5
		D=D-1	A
		DAT1=A	A
		GOVLNG	=DOTRUE
	     ENDCODE

* Han:	1) ED -> DoEd_EC -> view -> DoEd_STK may leave sysobs on stack
*	May need to implement virtual stack
*	2) calling xDOB, xED, or xVV instead of their non-UsrRPL names
*	will alter the user stack depth
*	TODO: use virtual stack in DoEd_STK ?

	     ?SKIP
	     ::
	       DUP #>Entr

	       FPEntry? casedrop :: Entr>Fptr FPTR@ DROP ;

	       RPEntry? casedrop
	         ::
		   Entr>Romp ROMPTR@ case xDIS
		   "Library Object Not Found" TOTEMPOB
	         ;

	       DROP #>HXS xDOB DROP
	     ;
	     DUPTYPECSTR? ITE xED xVV DROPFALSE
	   ;
	
	   ONE #=casedrop		( Mode: View code at @addr )
	   ::
	     CODE
	     	GOSBVL	=PopASavptr
	     	D0=A
	     	D0=D0+	5
	     	A=DAT0	A
	     	D0=A
	     	A=DAT0	A
	     	GOVLNG	=PUSH#ALOOP
	     ENDCODE
	     DUP ECView ?SKIP :: #>HXS xDOB DROP ;
	     DUPTYPECSTR? ITE xED xVV DROPFALSE
	   ;
	   
           DROPTRUE
        ;
        TRUE

  UNTIL
  ABND
 ;			( end of DoEd )

  FIFTYSIX 1GETABND ITE SetSysFlag ClrSysFlag	( Restore beep flag )

;
**********************************************************************

