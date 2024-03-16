**********************************************************************
*		JAZZ - String viewer
**********************************************************************
::
	TOADISP TURNMENUOFF
*	FNT1
* R0	->font
* R1	->top
* R2	->topline
* R3	->row1
* R4	xoff	key_time
	CODE
sVVFAST	EQU 5
sVVDISP	EQU 6

*		GOSBVL	=PopASavptr
		GOSBVL	=SAVPTR
*		LC(5)	=MINI_FONT	->font
*		R0=C
		C=0	A
		R4=C			xoff
		
		A=DAT1	A
		LC(1)	10
		A=A+C	A
		R1=A			->top
		R2=A			->topline
		GOSBVL	=D0->Row1
		LC(5)	1*34
		A=A+C	A
		R3=A			->row1
		ST=0	sVVFAST
		ST=1	sVVDISP
		GOSBVL	=DisableIntr
		GOSUB	VVDispClear
		GOSUB	VVSaveTim
VVMain		?ST=0	sVVDISP
		GOYES	+
		GOSUB	VVDispScreen
+		GOSUB	VVDelay
		GOSUB	JKbd_OR
		GOC	+
		SHUTDN
+		ST=1	sVVDISP
		GOSUB	VVSaveTim
		LC(2)	=PLUSCODE
		GOSUB	VVKeyDn?
		GONC	+
		ST=1	sVVFAST
+		LC(2)	=MINUSCODE
		GOSUB	VVKeyDn?
		GONC	+
		ST=0	sVVFAST
+		LC(2)	=UPCODE
		GOSUB	VVKeyDn?
		GONC	+
		GOTO	VVDoUp
+		LC(2)	=DOWNCODE
		GOSUB	VVKeyDn?
		GONC	+
		GOTO	VVDoDn
+		LC(2)	=APPSCODE
		GOSUB	VVKeyDn?
		GONC	+
		GOTO	VVDoTop
+		LC(2)	=TOOLCODE
		GOSUB	VVKeyDn?
		GONC	+
		GOTO	VVDoBot
+		LC(2)	=MODECODE
		GOSUB	VVKeyDn?
		GONC	+
		GOTO	VVDoPgUp
+		LC(2)	=STOCODE
		GOSUB	VVKeyDn?
		GONC	+
		GOTO	VVDoPgDn
+		LC(2)	=LEFTCODE
		GOSUB	VVKeyDn?
		GONC	+
		GOTO	VVDoLt
+		LC(2)	=RIGHTCODE
		GOSUB	VVKeyDn?
		GONC	+
		GOTO	VVDoRt
+		LC(2)	=VARCODE
		GOSUB	VVKeyDn?
		GONC	+
		GOTO	VVDoPgLt
+		LC(2)	=NXTCODE
		GOSUB	VVKeyDn?
		GONC	+
		GOTO	VVDoPgRt
+		LC(2)	=ENTERCODE
		GOSUB	VVKeyDn?
		GOC	VVExit
		GOSBVL	=AINRTN
		?ABIT=1	15
		GOYES	VVExit
VVMainOk	ST=0	sVVDISP
		GOTO	VVMain
VVExit		GOSUBL	JKbd_OR
		GOC	VVExit
		GOSBVL	=AllowIntr
		GOVLNG	=GETPTRLOOP
**********************************************************************
*		Kbd_OR emulation
**********************************************************************
JKbd_OR
JAnyKeyDown?
		P=	0
		C=0	A
		LC(3)	#1FF
JSetOR&Down?
		D1=(5)	=ORghost
		DAT1=C	X
		OUT=C
		GOSBVL	=CINRTN
		?C#0	A
		RTNYES
		RTN

**********************************************************************
VVKeyDn?	GOVLNG	=ThisKeyDnCb?_		unsupported but stable
*		A=C	B
*		GOLONG	JThisKeyDown?
**********************************************************************
VVSaveTim	D1=(5)	=TIMER2
		A=DAT1	A
		GOSBVL	=ASLW5
		A=R4.F	A
		R4=A			R4[A] = key_time
		RTN
**********************************************************************
VVDelay		?ST=1	sVVFAST
		RTNYES
		A=R4
		GOSBVL	=ASRW5		key_time
		LC(5)	8192*8/100	.08 seconds
		A=A-C	A
		D1=(5)	=TIMER2
-		C=DAT1	A
		?C>A	A
*		?C#A	A		Christophe G.	Doesn't seem to work in EMU48
		GOYES	-
		RTN
**********************************************************************
VVDoLt		A=R4.F	B
		A=A-1	B
		GOC	VVbadcrs
VVnewcrs	R4=A.F	B
		GOTO	VVMain
**********************************************************************
VVDoRt		A=R4.F	B
		A=A+1	B
		GONC	VVnewcrs
VVbadcrs	GOTO	VVMainOk
**********************************************************************
VVDoPgLt	A=R4.F	B
		?A=0	B
		GOYES	VVbadcrs
		LC(2)	33
		A=A-C	B
		GONC	VVnewcrs
		A=0	B
		GOC	VVnewcrs
**********************************************************************
VVDoPgRt	A=R4.F	A
		LC(2)	33
		A=A+C	B
		GONC	VVnewcrs
		LA(2)	256-33
		GOC	VVnewcrs
**********************************************************************
VVDoUp		A=R1.F	A		->top
		C=R2.F	A		->topline
		?A=C	A
		GOYES	+
		A=R3.F	A		->row1
		LC(5)	12*6*34
		A=A+C	A
		D0=A
		LC(5)	6*34
		A=A+C	A
		D1=A
		LC(5)	12*6*34
		GOSBVL	=MOVEUP
		A=R2.F	A		->topline
		D0=A
		D0=D0-	2
		GOSUB	VVPrevLine
		AD0EX
		R2=A.F	A
		AD0EX
		C=0	A
		GOSUB	VVDispLine
+		GOTO	VVMainOk
**********************************************************************
VVDoDn		A=R2.F	A		->topline
		D0=A
		GOSUB	VVNextLine
		CD0EX
		RSTK=C
		CD0EX
		LC(1)	12-1
		D=C	P
-		GOSUB	VVNextLine
		D=D-1	P
		GONC	-
		GOSUB	VVEnd?
		C=RSTK
		GOC	+
		R2=C.F	A		->topline'
		CD0EX
		RSTK=C
		A=R3.F	A		->row1
		D1=A
		LC(5)	6*34
		A=A+C	A
		D0=A
		LC(5)	12*6*34
		GOSBVL	=MOVEDOWN
		C=RSTK
		D0=C
		LC(1)	13-1
		GOSUB	VVDispLine
+		GOTO	VVMainOk
**********************************************************************
VVDoTop		C=R1.F	A		->top
		R2=C.F	A		->topline'
		GOTO	VVMain
**********************************************************************
VVDoBot		A=R1.F	A		->top
		A=A-CON	A,5
		D0=A
		C=DAT0	A		$len
		A=A+C	A		->end
		R2=A.F	A		->topline'
**********************************************************************
VVDoPgUp	A=R2.F	A		->topline
		D0=A
		LC(1)	13-1
		D=C	P
-		D0=D0-	2
		GOSUB	VVPrevLine
		D=D-1	P
		GONC	-
		AD0EX
		R2=A.F	A		->topline'
		GOTO	VVMain
**********************************************************************
VVDoPgDn	A=R2.F	A		->topline
		D0=A
		LC(1)	13-1
		D=C	P
-		GOSUB	VVNextLine
		D=D-1	P
		GONC	-
		CD0EX
		RSTK=C
		CD0EX
		LC(1)	12
		D=C	P
-		GOSUB	VVNextLine
		D=D-1	P
		GONC	-
		GOSUB	VVEnd?
		C=RSTK
		GOC	+
		R2=C.F	A		->topline'
		GOTO	VVMain
+		GOTO	VVDoBot
**********************************************************************
VVDispClear	GOSBVL	=D0->Row1
		D1=A
		LC(5)	80*34
		GOVLNG	=WIPEOUT
**********************************************************************
VVDispScreen	A=R2.F	A		->topline
		D0=A
		D=0	A		row
-		C=D	XS
		CSR	X
		CSR	X
		GOSUB	VVDispLine
		D=D+1	XS
		LC(3)	#D00
		?D<C	XS
		GOYES	-
		RTN
**********************************************************************
VVDispLine	P=C	0
		C=0	A
		C=P	0
		CPEX	1
		A=C	X
		C=C+C	X
		C=C+A	X
		C=C+C	X
		C=C+C	X		#CC * Y
		A=R3.F	A
		C=C+A	A
		RSTK=C			->row
		D1=C
		LC(5)	6*34
		GOSBVL	=WIPEOUT
		C=RSTK
		D1=C
		GOSUB	VVEnd?
		RTNC
		B=C	A
		C=R4.F	B		xoff
		D=C	B
		C=0	S		taboff
--		D=D-1	B
		GOC	gotxtoff
		AD0EX
		D0=A
		?A>=B	A
		RTNYES
		A=DAT0	B
		D0=D0+	2
		LCASC	'\n'
		?A=C	B
		RTNYES
		C=C+1	S		taboff
		LCASC	'\t'
		?A#C	B
		GOYES	--
		CPEX	15
		C=0	B
		CPEX	0
		C=-C	P
		CBIT=0	3
		D=D-C	B
		GONC	--
		D=-D	B
		LC(5)	32
		DCEX	B
		D=D-C	B
		AD1EX
		A=A+C	A
		AD1EX
		GONC	VVDisploop
gotxtoff	LC(2)	32
		D=C	B
VVDisploop	AD0EX
		D0=A
		?A>=B	A
		RTNYES
		A=0	A
		A=DAT0	B
		D0=D0+	2
		LCASC	'\n'
		?A=C	B
		RTNYES
		LC(1)	'\t'
		?A=C	B
		GOYES	VVDisptab
		GOSUB	VVDispChr
		D=D-1	B
		GONC	VVDisploop
VVDispdone	GOTO	VVNextLine
VVDisptab	C=0	A
		C=R4.F	P
		C=-C-1	P
		C=C+D	P
		CBIT=0	3
		C=C+1	P
		D=D-C	B
		GOC	VVDispdone
		AD1EX
		A=A+C	A
		AD1EX
		GONC	VVDisploop
**********************************************************************
VVDispChr	A=A+A	X
		C=A	X
		A=A+C	X
		A=A+C	X
*		C=R0.F	A		->font
		LC(5)	=MINI_FONT
		C=C+A	A
		CD0EX
		A=DAT0	6
		CD0EX
*		P=	1-1
		DAT1=A	P
		D1=D1+	16
		D1=D1+	16
		D1=D1+	2
		P=	2-1
		DAT1=A	P
		D1=D1+	16
		D1=D1+	16
		D1=D1+	2
		P=	3-1
		DAT1=A	P
		D1=D1+	16
		D1=D1+	16
		D1=D1+	2
		P=	4-1
		DAT1=A	P
		D1=D1+	16
		D1=D1+	16
		D1=D1+	2
		P=	5-1
		DAT1=A	P
		D1=D1+	16
		D1=D1+	16
		D1=D1+	2
		P=	6-1
		DAT1=A	P
		P=	0
		AD1EX
		LC(5)	5*34-1
		A=A-C	A
		D1=A
		RTNCC
**********************************************************************
VVEnd?		A=R1.F	A		->top
		AD0EX
		D0=D0-	5
		C=DAT0	A
		AD0EX
		C=C+A	A		->end
		AD0EX
		D0=A
		?A>=C	A
		RTNYES
		RTN
**********************************************************************
VVNextLine	GOSUB	VVEnd?
		RTNC
		C=C-A	A
		CSRB.F	A
		B=C	A
		LCASC	'\n'
-		A=DAT0	B
		D0=D0+	2
		?A=C	B
		RTNYES
		B=B-1	A
		GONC	-
		RTN
**********************************************************************
VVPrevLine	C=R1.F	A		->top
		B=C	A
-		D0=D0-	2
		AD0EX
		?A<B	A
		GOYES	+
		AD0EX
		A=DAT0	B
		LCASC	'\n'
		?A#C	B
		GOYES	-
		D0=D0+	2
		RTNCC
+		A=B	A
		D0=A
		RTNSC
	ENDCODE
;
**********************************************************************
