**********************************************************************
* Name:	MFED
* Author:	Han Duong
* Notes:	Uses internal font editor for editing; clips all
*		fonts to 6x4; menu keys disabled
**********************************************************************
xNAME MFED
::
  CK1&Dispatch
  # DF
  ::
    TOTEMPOB
    ROMPTR 0DD 00F			( xFONT6 )
    
    ( convert minifont into system font using FONT6 )
    CODE
		GOSUB	InitFont
--		P=	16-6		6 rows of pixels to copy
		A=0	W
		DAT0=A	W		delete FONT6 data
-		A=DAT1	1		copy 1 row of data
		DAT0=A	1
		D0=D0+	2		system font data = 2 nibs per row
		D1=D1+	1		MINIFONT data = 1 nib per row
		P=P+1
		GONC	-
		D0=D0+	4		system font data = 8 rows;
		C=C-1	B
		GONC	--
		GOVLNG	=GPPushTLoop

InitFont
		GOSBVL	=SAVPTR
		A=DAT1	A
		C=0	A
		LC(2)	5+5+4+2+2*8+2	prolog, len, height, name
		A=A+C	A
		D0=A			D0 -> FONT6 body
		D1=D1+	5
		A=DAT1	A
		LC(2)	5+5+2		prolog, len, font #
		A=A+C	A
		D1=A                    D1 -> MINIFONT body
		LC(2)	256-1		all characters
		RTN
    ENDCODE
    
    ' :: DropBadKey DROPFALSE ;		( menu handler )

    EditFont NOT ?SEMI
    
    ( now convert back to minifont )
    CODE
    		GOSUB	InitFont
--		P=	16-6
-		A=DAT0	1
		DAT1=A	1
		D0=D0+	2
		D1=D1+	1
		P=P+1
		GONC	-
		D0=D0+	4
		C=C-1	B
		GONC	--
		GOVLNG	=GETPTRLOOP
    ENDCODE

    DROP				( get rid of FONT6' )
  ;
;
