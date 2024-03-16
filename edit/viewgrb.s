**********************************************************************
*		JAZZ - Grob viewer
**********************************************************************
( grob --> grob )
NULLNAME ViewGrob
::
	DOLCD> DUP TOTEMPOB
	RECLAIMDISP TURNMENUOFF
	( g1 abu1 abu2 )

  NULLNAME ViewGrob!
CODE
XPOS	EQU 0
YPOS	EQU 5
XSIZE	EQU 10
YSIZE	EQU 15
GVSPD	EQU 20

* Han:	add delay since small grobs move too fast on HP50G;
*	in future, set initial delay flag depending on size of grob
GVTIME	EQU 25
sGVFAST	EQU 5

		GOSBVL	=SAVPTR
		ST=0	sGVFAST
		GOSBVL	=DisableIntr
		GOSUB	InitGvv
		GOSUB	GvvSaveTime
GvvMain		GOSUB	DispGvv
		GOSUB	GvvDelay
		GOSUB	JKbd_OR
		GOC	+
		SHUTDN			Sleep
+		GOSUB	GvvSaveTime
		C=R4	A
		D0=C
		LC(2)	=PLUSCODE
		GOSUB	GvvKey?
		GONC	+
		ST=1	sGVFAST
+		LC(2)	=MINUSCODE
		GOSUB	GvvKey?
		GONC	+
		ST=0	sGVFAST
+		LC(2)	=UPCODE
		GOSUB	GvvKey?
		GONC	gvk10
		GOSUB	GvvUp
gvk10		LC(2)	=DOWNCODE
		GOSUB	GvvKey?
		GONC	gvk20
		GOSUB	GvvDn
gvk20		LC(2)	=LEFTCODE
		GOSUB	GvvKey?
		GONC	gvk30
		GOSUB	GvvLt
gvk30		LC(2)	=RIGHTCODE
		GOSUB	GvvKey?
		GONC	gvk40
		GOSUB	GvvRt
gvk40		LC(2)	=PCODE
		GOSUB	GvvKey?
		GONC	gvk50
		GOSUB	InitGrobPos
gvk50
		LC(2)	=Sfkey1
		GOSUB	GvvKey?
		GONC	gvk60
		GOSUB	GvvSpd1
gvk60		LC(2)	=Sfkey2
		GOSUB	GvvKey?
		GONC	gvk61
		GOSUB	GvvSpd2
gvk61		LC(2)	=Sfkey3
		GOSUB	GvvKey?
		GONC	gvk62
		GOSUB	GvvSpd3
gvk62		LC(2)	=Sfkey4
		GOSUB	GvvKey?
		GONC	gvk63
		GOSUB	GvvSpd4
gvk63		LC(2)	=Sfkey5
		GOSUB	GvvKey?
		GONC	gvk64
		GOSUB	GvvSpd5
gvk64		LC(2)	=Sfkey6
		GOSUB	GvvKey?
		GONC	gvk65
		GOSUB	GvvSpd6
gvk65
		LC(2)	=ENTERCODE
		GOSUB	GvvKey?
		GOC	GvvExit
		GOSBVL	=AINRTN
		?ABIT=1	15
		GOYES	GvvExit
		GOTO	GvvMain
**********************************************************************
GvvExit		GOSUB	JKbd_OR
		GOC	GvvExit
		GOSBVL	=AllowIntr
		GOSBVL	=Flush
		GOVLNG	=GETPTRLOOP
**********************************************************************
GvvSaveTime	C=R4	A
		D0=C
		D0=(2)	GVTIME
		D1=(5)	=TIMER2
		C=DAT1	A
		DAT0=C	A
		RTN
**********************************************************************
GvvDelay	?ST=1	sGVFAST
		RTNYES
		C=R4	A
		D0=C
		D0=(2)	GVTIME
		A=DAT0	A
		LC(5)	8192*8/100	.08 seconds
		A=A-C	A
		D0=(5)	=TIMER2
-		C=DAT0	A
		?C>A	A
		GOYES	-
		RTN
**********************************************************************
GvvUp		D0=(2)	GVSPD
		C=DAT0	A
		D0=(2)	YPOS
		A=DAT0	A
		A=A-C	A
		DAT0=A	A
		RTN
GvvDn		D0=(2)	GVSPD
		C=DAT0	A
		D0=(2)	YPOS
		A=DAT0	A
		A=A+C	A
		DAT0=A	A
		RTN
GvvLt		D0=(2)	GVSPD
		C=DAT0	A
		D0=(2)	XPOS
		A=DAT0	A
		A=A-C	A
		DAT0=A	A
		RTN
GvvRt		D0=(2)	GVSPD
		C=DAT0	A
		D0=(2)	XPOS
		A=DAT0	A
		A=A+C	A
		DAT0=A	A
		RTN
GvvSpd6		P=P+1
GvvSpd5		P=P+1
GvvSpd4		P=P+1
GvvSpd3		P=P+1
GvvSpd2		P=P+1
GvvSpd1		P=P+1
		D0=(2)	GVSPD
		C=0	A
		CPEX	0
		DAT0=C	A
		RTN
**********************************************************************
GvvKey?		GOVLNG	=ThisKeyDnCb?_
*		A=C	B
*		GOLONG	JThisKeyDown?
**********************************************************************
InitGvv		D0=(5)	(=IRAM@)-4
		C=DAT0	A
		LC(4)	#100
		R4=C	A
		D0=C			->buffer
* Init viewer speed
		D0=(2)	GVSPD
		A=0	A
		A=A+1	A
		DAT0=A	A
* Init grob related data
		GOSBVL	=D1=DSKTOP
		D1=D1+	10		->grob to view
		A=DAT1	A
		D1=A
		D1=D1+	10
		C=DAT1	A
		D0=(2)	YSIZE		Store grob ysize
		DAT0=C	A
		D1=D1+	5
		A=DAT1	A
		D0=(2)	XSIZE
		DAT0=A	A		Store grob xsize
* Init XPOS & YPOS so that grob is centered

InitGrobPos	D0=(2)	XSIZE
		A=DAT0	A
		ASRB.F	A		xsize/2
		LC(5)	131/2		131/2 - xsize/2
		C=C-A	A
		D0=(2)	XPOS
		DAT0=C	A
		D0=(2)	YSIZE
		A=DAT0	A
		ASRB.F	A		ysize/2
		LC(5)	80/2		80/2
		C=C-A	A		80/2 - ysize/2
		D0=(2)	YPOS
		DAT0=C	A
		RTNCC
**********************************************************************
DispGvv		C=R4	A
		D0=C
		D0=(2)	XPOS
		C=DAT0	A
		R0=C	A	x
		D0=(2)	YPOS
		C=DAT0	A
		R1=C	A	y
* Put abu2 into abu1
		GOSBVL	=D1=DSKTOP
		A=DAT1	A
		D0=A
		D1=D1+	5
		A=DAT1	A
		D1=A
		B=A	A	abu1
		D0=D0+	5
		D1=D1+	5
		C=DAT0	A
		GOSBVL	=MOVEDOWN
* Put grob into abu1
		GOSBVL	=D1=DSKTOP
		D1=D1+	10
		A=DAT1	A
		D0=A
		C=B	A	abu1
		D1=C
		RSTK=C
		C=R4	A
		RSTK=C
		GOSUB	grob!!
		C=RSTK
		R4=C	A
		C=RSTK
		D0=C
* Put abu1 into display
		D1=(5)	=aADISP
		A=DAT1	A
		D1=A
		A=DAT1	A
		D1=A
		B=A	A	->ADISP
		D0=D0+	5
		D1=D1+	5
		C=DAT0	A
		GOVLNG	=MOVEDOWN
**********************************************************************
* grob! replacement
* Input:
*	D0 = ->INGROB
*	D1 = ->OUTGROB
*	R0[A] = x	(signed)
*	R1[A] = y	(signed)
**********************************************************************
sSTARTROW	EQU 0
sCLIPROW	EQU 1

grob!!		D1=D1+	5
		C=DAT1	A
		C=C-CON	A,16
		RTNC
		D1=D1+	5
		C=DAT1	A	h2
		?C=0	A
		RTNYES
		D1=D1+	5
		A=DAT1	A	w2
		?A=0	A
		RTNYES
		D1=D1+	5
		R2=A.F	A
		R3=C.F	A
* R0[A] = x
* R1[A] = x
* R2[A] = w2
* R3[A] = h2
		D0=D0+	5
		C=DAT0	A
		C=C-CON	A,16
		RTNC
		D0=D0+	5
		C=DAT0	A	h1
		?C=0	A
		RTNYES
		D0=D0+	5
		A=DAT0	A	w1
		?A=0	A
		RTNYES
		D0=D0+	5
		B=A	A
		D=C	A
* R0[A] = x
* R1[A] = y
* R2[A] = w2
* R3[A] = h2
* B[A] = w1
* D[A] = h1
* D0 = çbase1
* D1 = çbase2

** Now handle y coordinate
		
		C=R1.F	A	y
		CSR	A
		?CBIT=0	15
		GOYES	gposy	y >= 0
* y < 0
		C=R1.F	A
		C=-C	A	ABS(y)
		?D<=C	A	h1<=y?
		RTNYES		done
		D=D-C	A	rows
		A=B	A	w1
		GOSBVL	=w->W	W1
		R1=A.F	A	W1
* Clip away top of g1
gny+lp		SB=0
		CSRB.F	A
		?SB=0
		GOYES	gnyno+
		CD0EX
		C=C+A	A
		CD0EX
gnyno+		A=A+A	A
		?C#0	A
		GOYES	gny+lp
* Check if bottom needs clipping
		C=R3.F	A	h3
		?D<=C	A	rows<=h2?
		GOYES	gclipy+
		D=C	A	rows=h2
gclipy+
		GOTO	gyclipok

* R0[A] = x
* R1[A] = y
* R2[A] = w2
* R3[A] = h2
* B[A] = w1
* D[A] = h1
* D0 = çbase1
* D1 = çbase2
* y >= 0
gposy		A=R3.F	A	h2
		C=R1.F	A	y
		?C>=A	A
		RTNYES
* update çbase2
		A=R2.F	A	w2
		GOSBVL	=w->W	W2
g2clplp		SB=0
		CSRB.F	A
		?SB=0
		GOYES	g2clpno
		CD1EX
		C=C+A	A
		CD1EX
g2clpno		A=A+A	A
		?C#0	A
		GOYES	g2clplp
* now clip bottom of g1 if needed
		C=R3.F	A	h2
		A=R1.F	A	y
		C=C-A	A	h2-y
		?D<=C	A
		GOYES	g2no+cl
		D=C	A	rows=h2-y
g2no+cl		A=B	A	w1
		GOSBVL	=w->W	W1
		R1=A.F	A	W1
		
* R0[A] = x
* R1[A] = W1
* R2[A] = w2
* R3[A] = h2	(free)
* B[A] = w1
* D[A] = rows
* D0 = ->base1
* D1 = ->base2
gyclipok	

* Now clip in x direction
		C=D	A
		C=C-1	A
		R4=C.F	A	rows
		A=R2.F	A	w2
		GOSBVL	=w->W
		R3=A.F	A	W2
* R0[A] = x
* R1[A] = W1
* R2[A] = w2
* R3[A] = W2
* R4[A] = rows
* B[A] = w1
* D0 = çbase1
* D1 = çbase2

		C=R0.F	A	x
		CSR	A
		?CBIT=1	15
		GOYES	gnegx
		GOTO	gposx
* x < 0
gnegx		ST=1	sCLIPROW
		C=R0.F	A
		C=-C	A	ABS(x)
		R0=C.F	A
		?C>=B	A	x>=w1
		RTNYES		Done
* Update ->base1
		CSRB.F	A
		CSRB.F	A
		AD0EX
		A=A+C	A
		AD0EX
* R0[A] = x
* R1[A] = W1
* R2[A] = w2
* R3[A] = W2
* R4[A] = rows
* B[A] = w1
* D0 = çbase1
* D1 = çbase2
* Count pixels & gskip1
		C=R0.F	A	x
		C=C-B	A	x-w1
		C=-C	A	w1-x
		A=R2.F	A	w2
		?C<=A	A
		GOYES	gp1ok
		C=A	A	pix=w2
gp1ok		B=C	A	pix
		BSRB.F	A
		BSRB.F	A	pix/4
		A=R1.F	A	W1
		A=A-B	A
		R1=A.F	A	gskip1
		A=R3.F	A	W2
		A=A-B	A
		R3=A.F	A	gskip2

* R0[A] = x		ok
* R1[A] = gskip1	ok
* R2[A] = w2		ok
* R3[A] = gskip2	ok
* R4[A] = rows		ok
* C[A] = pix		ok
* D0 = ->base1		ok
* D1 = ->base2		ok

		CR0EX.F	A	pix
* Shift = x[0 1 2 3] ç [0 3 2 1]
		C=-C	P
		CBIT=0	3
		CBIT=0	2
		P=C	0
		C=P	15
		P=	0
		?C=0	S
		GOYES	gg49
		A=R1.F	A
		A=A-1	A
		R1=A.F	A
gg49
* Mask2 = f(bits MOD 4)
		C=R0.F	P	pix
		CBIT=0	2
		CBIT=0	3
		P=C	0	bits
		LCHEX	FEC8
		P=C	3
		C=0	B	Mask1=0
		CPEX	1
		D=C	B
		GOTO	Grob!Row	

* x >= 0
gposx		ST=0	sCLIPROW
		C=R0.F	A	x
		A=R2.F	A	w2
		?C>=A	A	x>=w2?
		RTNYES		Done
* Update ->base2
		CSRB.F	A
		CSRB.F	A
		AD1EX
		A=A+C	A
		AD1EX
* R0[A] = x
* R1[A] = W1
* R2[A] = w2
* R3[A] = W2
* R4[A] = rows
* B[A] = w1
* D0 = ->base1
* D1 = ->base2

* BitsRow = MIN(w1,w2-x)
		A=R2.F	A	w2
		C=R0.F	A	x
		D=C	A	x
		A=A-C	A	w2-x
		?A<B	A
		GOYES	gg48
		A=B	A	w1
gg48		R0=A.F	A	BitsRow
		C=0	A
		LC(1)	3
		C=C&D	P	x MOD 4
		D=C	P
		A=A+C	A	Bits+x4
		ASRB.F	A
		ASRB.F	A	nibs
		C=R1.F	A	W1
		C=C-A	A
		R1=C.F	A	gskip1
		C=R3.F	A	W2
		C=C-A	A
		R3=C.F	A	gskip2

		C=D	P	x MOD 4
		CSRC		C[S]=b
* Compute Mask2
		C=R0.F	P	bits
		C=C+D	P
		CBIT=0	3
		CBIT=0	2
		P=C	0
		LCHEX	FEC8
		P=C	3
		C=P	1
		D=C	B
* Compute Mask1	
		P=C	15
		LCHEX	0137
		P=C	3
		C=P	0
		P=	0
		D=C	P	Mask1
* Need to add code if w1<4

**********************************************************************
* Here:
* C[S]	= b		BitOffset
* D[X]	= xxy		Mask2, Mask1
* D0	= ->g1		Source grob
* D1	= ->g2		Target grob
* R0[A]	= BitsRow	Pix to write
* R1[A]	= gskip1
* R2[A]	= BitsLeft	Pix left
* R3[A]	= gskip2
* R4[A]	= rows		Row counter
**********************************************************************
Grob!Row
		A=R0.F	A	BitsRow
		ST=1	sSTARTROW
		?ST=0	sCLIPROW
		GOYES	g!5

Grob!14		ST=0	sSTARTROW		<---------------+
g!5		R2=A.F	A	BitsLeft			|
		C=0	A					|
		LC(1)	4					|
		?A<C	A					|
		GOYES	Grob!LastNib				|
		B=A	A					|
		BSRB.F	A					|
		BSRB.F	A	BitsLeft/4			|
		LC(1)	14					|
		?B<C	A					|
		GOYES	g!10					|
		B=C	A	14				^
g!10		A=DAT0	W					|
		GOSUB	Grob!Shift				|
* Calculate bits						|
		C=B	P	NibsToWrite			|
		P=C	0	1-14				|
		P=P-1		0-13				|
		B=B+B	B					|
		B=B+B	B	BitsToWrite			|
		?ST=0	sSTARTROW				|
		GOYES	g!20		>---------------+	|
		CPEX	15				|	|
		C=P	0	b			|	|
		CPEX	15				|	^
		B=B-C	B	BitsToWrite-b		v	|
		C=DAT1	1	C[4-1] always 0 here	|	|
		C=C&D	B	@g2&Mask1		|	|
		A=A!C	B				|	|
		?C=0	S				|	|
		GOYES	g!20		>-------+	|	|
		D0=D0-	1			|	|	|
g!20		DAT1=A	WP		<------<+-------+	|
		CD1EX						|
		C+P+1						|
		D1=C						|
		CD0EX						|
		C+P+1						|
		D0=C						|
		P=	0					|
		A=R2.F	A		BitsLeft--		|
		A=A-B	A					|
		GOTO	Grob!14		>-----------------------+

Grob!LastNib	?A=0	A
		GOYES	Grob!RowOk
		A=DAT0	B
		GOSUB	Grob!Shift
		B=A	P
		C=D	B
		CSR	B	Mask2
		A=DAT1	B
		A=A&C	P
		C=-C-1	P
		B=B&C	P
		A=A!B	P
		DAT1=A	P
Grob!RowOk	A=R4.F	A
		A=A-1	A	RowCount--
		RTNC		Done
		R4=A.F	A
		C=R1.F	A	gskip1
		AD0EX
		A=A+C	A
		AD0EX
		C=R3.F	A	gskip2
		AD1EX
		A=A+C	A
		AD1EX
		?C=0	S
		GOYES	+
		D0=D0+	1
+		GOTO	Grob!Row
**********************************************************************
Grob!Shift	?C=0	S
		RTNYES
		P=C	15	b
		?ST=1	sSTARTROW
		GOYES	+
-		ASRB
		P=P+1
		?P#	4
		GOYES	-
		P=	0
		RTNCC
+
-		A=A+A	W
		P=P-1
		?P#	0
		GOYES	-
		RTNCC
**********************************************************************
ENDCODE
  2DROP
;
**********************************************************************
