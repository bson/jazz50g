**********************************************************************
*		JAZZ - Main x Subroutines
**********************************************************************

* =IRAMBUFF : #800F5, we need to align to #80100 as is declared
* by the routine InitDisOps (see dis.s); use IRAMBUFF+11

**********************************************************************
* Name:		SX?
* Interface:	( --> flag )
**********************************************************************
*NULLNAME SG_ITE
*::
*NULLNAME SX?
*CODE
*	CD0EX
*	D0=(5)	=IRAM@
*	A=DAT0	S
*	CD0EX
*	A=A+A	S
*	GOVLNG	=PushF/TLoop
*ENDCODE
*  2'RCOLARPITE
*;
**********************************************************************
* Error if code itself is in tempob area
**********************************************************************
NULLNAME CHECKME
CODE
	AD0EX
*	D0=(5)	=aUSEROB
*	C=DAT0	A
*	D0=C
	D0=(5)	=USEROB

	C=DAT0	A
	AD0EX
	A=PC
	?A<C	A		* PC < USEROB ?
	GOYES	ERRME		* Yes - thus code is in tempob
	LOOP
ERRME	LC(5)	XerrNonFixed
	A=C	A
	GOVLNG	=Errjmp
ENDCODE
**********************************************************************
* Name:		TOTEMPBOT?
* Interface:	( ob --> ob' )
* Description:
* If object is in tempob area move it to bottom to fix it's location.
* Use direct memory block swap!
**********************************************************************
NULLNAME TOTEMPBOT?
CODE
		GOSBVL	=SAVPTR
		A=DAT1	A		* A[A] = ->ob
		GOSUB	GetBOT
		?A<C	A
		GOYES	GPLP
		GOSUB	GetTOP
		?A<C	A
		GOYES	isintemp
GPLP		GOVLNG	=GETPTRLOOP

*GetBOT		D0=(5)	=aTEMPOB
*		GOTO	gettop10
*GetTOP		D0=(5)	=aTEMPTOP
*gettop10	C=DAT0	A
*		D0=C
*		C=DAT0	A
*		RTN
GetBOT		D0=(5)	=TEMPOB
		GOTO	gettop10
GetTOP		D0=(5)	=aTEMPTOP
		C=DAT0	A
		D0=C
gettop10	C=DAT0	A
		RTN

* Ob is in tempob, move it to bottom
* If ROOM is too small then just execute GC and ob will be fixed

isintemp	B=A	A		* B[A] = ->ob
		C=C-CON	A,5
		D1=C

* Move down in tempob until ob is above temp ptr

tempdnlp	A=DAT1	A
		C=C-A	A		* C[A] = ->temp list
		D1=C
		?B<C	A		* Ob not in this temp area?
		GOYES	tempdnlp
		D1=D1+	5		* Skip link field (not marker!)
		B=A	A		* B[A] = oblen+6

* Move to tempbot using direct on-location block swap

		GOSUB	GetBOT
		D0=C
		D0=D0+	5		* Skip zero link
		C=B	A
* Now:
*	D0=->block1	(bottom of tempob area)
*	D1=->block2	(tail of link)
*	C[A]=nibbles2	(hole size)

		GOSUB	BLKSWAP+	* Swap & update PTRs
		GOTO	GPLP

**********************************************************************
* Swap contiguous memory blocks in place.
* Entry:	D0= ->block1	(lower)
*		D1= ->block2	(higher)
*		C[A]= size of block2
* Alters:	A[W] C[W] B[A] D[A]
* Stack:	1 (BLKswap)
* Algorithm:
*
* If block2 is smaller than (or equal to) block1 then
*	swap block2 and start of block1
*	recalculate nibbles1, return block2 pointer back and restart
*		x                  y
*	Start:	1234567890123456789ABCDEF
*	End:	ABCDEF7890123456789123456
*		      x            y
* Else
*	swap block1 and start of block2
*	recalculate nibbles2 and restart
*		x     y
*	Start:	ABCDEF1234567890123456789
*	End:	123456ABCDEF7890123456789
*		      x      y
* Final result:
*		x                  y
*	Start:	1234567890123456789ABCDEF
*	Final:	ABCDEF1234567890123456789
*		                         x
* 
* Performance can be poor if one of the blocks is small.
* Setting compiler flag fUSEIRAM enables special code when either
* block is smaller than #100 nibbles. IRAMBUFF is then used as a buffer
* for the smaller block to do a buffered block swap.
*
**********************************************************************

* PTRADJUST2:
* Entry:	A[A]= ->block1	B[A]= ->block1tail	C[A]= offs1
* 		R0[A]= ->block2	R1[A]= ->block2tail	D0= offs2
* Exit:
*	All same as entry except C[A] moved to D[A]
* Uses:
*	D1 C[15-14]
* Applied:
* Entry:	A[A]= ->block1	B[A]= ->block2		C[A]= nibbles2
*		R0[A]= ->block2	R1[A]= ->block2tail	D0= -nibbles1
		
BLKSWAP+	?C=0	A
		RTNYES
		AD1EX
		B=A	A		B[A] = ->block2
		R0=A			R0[A] = ->block2
		RSTK=C
		C=C+A	A
		R1=C			R1[A] = ->block2tail
		AD0EX			A[A] = ->block1
		C=R0
		C=C-A	A
		C=-C	A
		D0=C			D0 = -nibbles1
		C=RSTK			C[A] = nibbles2
		GOSBVL	=PTRADJUST2
* Restore entry conditions for BLKSWAP
		D0=A			D0 = ->block1
		A=B	A
		D1=A			D1 = ->block2
		C=D	A		C[A] = nibbles2

BLKSWAP		B=C	A		B[A] = nibbles2 during loop
BLKswaplp	?B=0	A		* Done if nibbles2 = 0
		RTNYES
		AD0EX
		D0=A
		CD1EX
		D1=C
		C=C-A	A		C[A] = nibbles1
		?C=0	A		* Done if nibbles1 = 0
		RTNYES
		?C>=B	A		* nibbles1 >= nibbles2 ?
		GOYES	BLKup&back	* Swap block & D1 comes back
		A=C	A
		A=0	B
		?A=0	A
		GOYES	BLKiram1	* Use IRAM if nibbles1 < #100
		B=B-C	A		* Block 2 becomes smaller
		GOSUB	BLKswap		* swap blocks of size nibbles1
		GONC	BLKswaplp
BLKup&back
		A=B	A
		A=0	B
		?A=0	A
		GOYES	BLKiram2	* Use IRAM if nibbles2 < #100
		C=B	A		* nibbles2
		GOSUB	BLKswap
		CD1EX			* D1 back to where it was
		C=C-B	A
		CD1EX
		GONC	BLKswaplp

* nibbles1 < #100. block1 to IRAM, block2 down, block1 to end
BLKiram1	R0=C			R0[A] = nibbles1
		CD0EX
		R1=C			R1[A] = ->block1
		D0=C
*		GOSUB	GETIRAM
*		D1=C
		D1=(5)	=IRAMBUFF+11
		C=R0
		GOSBVL	=MOVEDOWN	Buffered block1, D0 = ->block2
		A=R1
		D1=A			D1 = ->block1
		C=B	A		C[A] = nibbles2
		GOSBVL	=MOVEDOWN	D1 = ->block2tail'
*		GOSUB	GETIRAM
*		D0=C
		D0=(5)	=IRAMBUFF+11
		C=R0			C[A] = nibbles1
		GOVLNG	=MOVEDOWN
		
* nibbles2 < #100. block2 to IRAM, block1 up, block2 to bottom
BLKiram2	R0=C			R0[A] = nibbles1
		CD1EX
		R1=C			R1[A] = ->block2
		D0=C			D0 = ->block2
*		GOSUB	GETIRAM
*		D1=C
		D1=(5)	=IRAMBUFF+11
		C=B	A		C[A] = nibbles2
		GOSBVL	=MOVEDOWN	D0 = ->block2tail
		C=R1
		CD0EX			D0 = ->block2
		D1=C			D1 = ->block2tail = ->block1tail'
		C=R0
		GOSBVL	=MOVEUP		D0 = ->block1
*		GOSUB	GETIRAM
		LC(5)	=IRAMBUFF+11
		CD0EX			D0 = ->buffer
		D1=C			D1 = ->block1
		C=B	A		C[A] = nibbles2
		GOVLNG	=MOVEDOWN

* Han:	no longer needed for Bigapple
* GETIRAM	LC(5)	=IRAM@
*		CD0EX
*		C=DAT0	S
*		CD0EX
*		LC(5)	=IRAMBUFF
*		C=C+C	S
*		RTNNC
*		LC(5)	=G_IRAMBUFF
*		RTN

**********************************************************************
* Swap equal size blocks
* Entry:	D0= ->blk1	D1= ->blk2	C[A]= nibbles
* Exit:		D0= ->blk1 tail	D1= ->blk2 tail	CC
* Alters:	A[W] C[W] D[A] P CRY
**********************************************************************
BLKswap		C=C-1	A
		GOC	BLKupdone	* Nothing to swap
		P=C	0		* P=nibs
		CSR	A		* C[A]=words
		D=C	A
		D=D-1	A
		GOC	BLKupwrd	* Swap the last <= 16 nibbles

BLKuplp		A=DAT0	W		* Modified MOVEDOWN code
		C=DAT1	W
		DAT0=C	W
		DAT1=A	W
		D0=D0+	16
		D1=D1+	16
		D=D-1	B
		GONC	BLKuplp
		D=D-1	XS
		GONC	BLKuplp
		D=D+1	X
		D=D-1	A
		GONC	BLKuplp

BLKupwrd	A=DAT0	WP
		C=DAT1	WP
		DAT0=C	WP
		DAT1=A	WP
		CD0EX
		C+P+1
		D0=C
		CD1EX
		C+P+1
		D1=C
BLKupdone	P=	0
		RTNCC
ENDCODE


ASSEMBLE

**********************************************************************
* Extract object from a string by removing the string prologs etc.
* Input:
*	R0.A = ->$ (embedded ob)
*	R4.A = ->obend (inside $, the expected end address )
* Exit:
*	CC: R0.A = ->ob		( Might equal ->$, might not )
*	CS: P=0 empty object
*	CS: P=1 undefined result
**********************************************************************

SHRINKOB$	P=	0		* Make sure P=0
		A=R0			* A.A = ->$
		C=R4			* C.A = ->obend
		C=C-A	A
		C=C-CON	A,10		* Minus prlg & len fields
		?C=0	A
		RTNYES			* Empty object
		C=C-CON	A,5
		GOC	ShrUndef	* obsize < 5
		?C#0	A
		GOYES	ShrNotPtr	* obsize <> 5, check for object

* Object is a pointer, return the pointee address

		D0=A
		D0=D0+	10
		A=DAT0	A
		R0=A.F	A
		RTNCC

ShrUndef	P=	1		* Flag undefined result
		RTNSC

* Try to extract a valid object from the string

ShrNotPtr	C=R0			* C.A = ->$
		D0=C
		D0=D0+	5		* D0 = ->$len
		A=DAT0	A		* A.A = $len
		C=C+A	A
		C=C+CON	A,5		* C.A = ->$end
		B=C	A		* B.A = ->$end
		D0=D0+	5

* First check if $ contains a prologed object

		A=DAT0	A
		D1=A
		A=DAT1	A
		LC(5)	=PRLG
		?A#C	A
		GOYES	ShrUndef

* Now check if the object is skippable

		GOSUBL	SafeSkipOb	* D0 = ->obend
		GOC	ShrUndef	* Skip failed..

* Now check if skipped ob matches the expected obend

		CD0EX			* C.A = ->obend
		A=R4			* A.A = ->obend (expected)
		?A#C	A
		GOYES	ShrUndef	* No match - error

* Now shrink the string to object

		D=C	A		* D.A = ->obend
		A=B	A		* A.A = ->$end
		A=A-C	A		* A.A = extra nibs
		GOC	ShrUndef	* Just in case..
		C=0	A
		LC(1)	10		* Nibs to remove from the start
		A=A+C	A		* A.A = total nibs to remove
		R1=A.F	A		* R1.A = extra + 10
		A=R0			* A.A = ->$
		D1=A			* D1 = ->$
		A=A+C	A		* A.A = ->ob
		D0=A			* D0 = ->ob
		C=D	A		* C.A = ->obend
		C=C-A	A		* C.A = obsize
		ST=0	15		* protect from ON keys
		GOSBVL	=MOVEDOWN
		A=B	A		* A.A = ->$end
		C=R1			* C.A = extra+10
		GOSBVL	=MOVERSD	* Remove extra at end
		A=B	A		* A.A = ->obend (new)
		D0=A			* D0 = ->obend (new)
		A=DAT0	A		* A.A = offset (old)
		C=R1			* C.A = extra+10
		A=A-C	A		* A.A = offset (new)
		DAT0=A	A
		GOSBVL	=AllowIntr	* Enable ON keys again
		RTNCC

**********************************************************************
* Shrink string. Replacement for built-in Shrink$ that assumes the
* string is topmost in tempob area.
* Input:
*	R0[A] = ->$
*	D0 = ->$end (new)
**********************************************************************

SHRINK$		C=R0			* C[A] = ->$
		C=C+CON	A,5
		D1=C			* D1 = ->$len
		A=DAT1	A
		A=A+C	A		* A[A] = ->$end (old)
		A=A+CON	A,5		* Skip offset
		B=A	A		* A[A] = ->$end+5 (old)
		AD0EX			* A[A] = ->$end (new)
		D0=A
		C=A-C	A		* C[A] = $len (new)
		DAT1=C	A		* Set new $len
		C=R0			* C[A] = ->$
		A=A-C	A		* A[A] = size($) (new)
		A=A+CON	A,6		* Add 5 for offset + 1 for GC_nib
		DAT0=A	A		* Set new offset
		D0=D0+	5		* D0 = ->nextob (new)
		CD0EX			* C[A] = ->nextob (new)
		C=C-B	A		* C[A] = nexton (new) - $end (old)
		?C=0	A		* Fast exit if no movement
		RTNYES
		C=-C	A		* C[A] = nibs to move down
		A=B	A
		GOVLNG	=MOVERSD	* Move down

**********************************************************************
* Make a string of size C.A to bottom of tempob area.
* The address of the buffer will not change unless:
*	1) ROMPTAB changes
*	2) One of the display grob sizes id changed
*	3) This routine is called again
*
* Input:
*	C.A = nibbles
* Output:
*	R0 = ->String
*	GPMEMERR if insufficient memory
* Uses:
*	regs + R0.A + R1.A
* Notes:
*	Might be better to add ON key protection
*	Han:	Now exists as supported entry in ROM 2.15
**********************************************************************
*MAKEBOT$N	C=C+CON	A,10		* Need room for prolog & len too
*		GOSUB	GETBOTTEMP	* Allocate
*					* D0=->obend D1=->ob R0=->ob R1=nibbles
*		LC(5)	=DOCSTR		* Set String prolog
*		DAT1=C	A
*		D1=D1+	5		* Set String len
*		C=R1			* Set String len
*		C=C-CON	A,5
*		DAT1=C	A
*		D1=D1+	5		* Clear string body
*		C=C-CON	A,5
*		R1=C			* Output body size in nibbles
*		GOVLNG	=WIPEOUT

**********************************************************************
* Allocate memory from bottom of the tempob area.
* Input:
*	C.A = nibbles
* Output:
*	R0 = ->ob
*	R1 = nibbles
*	D0 = ->obend
*	D1 = ->ob
*	GPMEMERR if insufficient memory
* Notes:	Han: Now exists as supported entry in ROM 2.15
**********************************************************************
*GETBOTTEMP
*		R1=C.F	A		* R1.A = nibbles
*
**		D0=(5)	=aTEMPOB
**		A=DAT0	A
**		D0=A
*		D0=(5)	=TEMPOB
*
*		A=DAT0	A
*		A=A+CON	A,6
*		R0=A.F	A		* R0.A = ->tempbot + 6
*
*MkBotObLp	ST=0	10
*		C=R1
*		C=C+CON	A,6		* Move rstk up
*		GOSBVL	=MOVERSU
*		GONC	MkBotObOK
*		GOSBVL	=Garbage?Err
*		A=R0
*		GONC	MkBotObLp
*
*MkBotObOK	A=R0
*		D1=A			* D1 = ->ob
*		C=R1
*		A=A+C	A
*		D0=A			* D0 = ->obend
*		C=C+CON	A,6		* Set backward offset
*		DAT0=C	A
*		RTNCC

**********************************************************************
* Maximize string obeying MINMEM requirement.
* Input:
*	A.A = ->String
* Output:
*	R4.A = free space at the end of the expanded string
*	A.A = ->strend (new)
*	C.A = B.A  ->strend (old)
* GPMEMERR if MINMEM requirement is not satisfied even after GC
* Notes:
*	Might be better to add ON key protection
**********************************************************************

MAXIM$		B=A	A		* B.A = ->$
		GOSBVL	=ROOM		* C.A = room
		LA(5)	(MINMEM)+1
		C=C-A	A
		GONC	MaximNow

* GC may modify the string address so push it to stack and pop
* it after GC.

		A=B	A		* A.A = ->$
		GOSBVL	=GPPushA	* Push $
* Han:	avoiding this unsupported entry
*		GOSBVL	=SPGarbageGP
		GOSBVL	=SAVPTR
		GOSBVL	=GARBAGECOL
		GOSBVL	=GETPTR		
		GOSBVL	=PopASavptr
		B=A	A		* B.A = ->$
		GOSBVL	=ROOM
		LA(5)	(MINMEM)+1
		C=C-A	A
		GONC	MaximNow
		GOVLNG	=GPMEMERR

MaximNow	C=C+1	A
		R4=C.F	A		* R4.A = free
		BCEX	A		* B.A = free C.A = ->$
		D0=C			* D0 = ->$
		D0=D0+	5		* D0 = ->$len
		A=DAT0	A		* A.A = $len (old)
		C=C+A	A
		C=C+CON	A,5		* C.A = ->$end (old)
		A=A+B	A		* A.A = $len (new)
		DAT0=A	A
		D0=C			* D0 = ->$end (old)
		A=DAT0	A		* A.A = rel (old)
		A=A+B	A		* A.A = rel (new)
		DAT0=A	A		* 

		C=B	A		* C.A = free
		AD0EX			* A.A = ->$end (old)
		GOSBVL	=MOVERSU	* B.A = ->$end (old)
		A=R4			* A.A = free
		C=B	A		* C.A = ->$end (old)
		A=A+C	A		* A.A = ->$end (new)
		RTNCC

**********************************************************************
* Check if Rom-Word in libraries 002/700
* Entry:	D0 = ->ptr
* Exit:		CC - yes
*		CS - nope
* Uses:		A[A] B[A] C[A] D[A]
* Stack:	1
**********************************************************************
RomRomWord?	CD0EX
		D=C	A	->ptr
*		D0=(5)	(=IRAM@)-4
*		A=DAT0	A
		D0=C
*		LA(4)	0
		LA(5)	=RAMSTART	A[A]=RAM base
		C=DAT0	A	->ob
		?C>=A	A
		RTNYES		Not in RAM -> not Rom-Word
		D0=C		->ob
		D0=D0-	6
		A=DAT0	X	libnum
		D0=D0+	6
		LC(3)	#002
		?A=C	X
		GOYES	rrw10	Library 002?
		LC(3)	#700
		?A=C	X
		GOYES	rrw10
rrw00		C=D	A	Restore ->ptr & fail
		D0=C
		RTNSC		Fail
* Possible 002/700 Rom-Word, check link table
rrw10		B=A	X
		GOSUB	FromPart
		GOC	rrw00	No such lib - fail (No 002??)
* Now check if rompnum gives object
		D0=D0+	13	->link table pointer
		A=DAT0	A
		?A=0	A
		GOYES	rrw00	No link table!
		CD0EX
		A=A+C	A
		D0=A		->link table
		GOSUB	HexTable?
		GOC	rrw00	No visible table - fail
		C=D	A
		CD0EX
		A=DAT0	A	->ob
		D0=A
		D0=D0-	3	->rompnum
		A=0	A
		A=DAT0	X	rompnum
		D0=C
		A=A+1	A
		C=A	A
		A=C	A
		A=A+A	A
		A=A+A	A
		A=A+C	A	5*rompnum+5
		D0=D0+	5
		C=DAT0	A	link table lenght + 5
		?A>=C	A
		GOYES	rrw00	Outside link table! Fail!
		CD0EX
		A=A+C	A
		D0=A		->link table entry
		A=DAT0	A
		?A=0	A
		GOYES	rrw00	No such romp! Fail!
		CD0EX
		A=A+C	A	->ROM-WORD
		C=D	A
		D0=C		->ptr
		C=DAT0	A	->ob
		?A#C	A
		RTNYES		Not same object - no match
		RTNCC		Is Rom-Word

**********************************************************************
* Search name for ROMPTR
* Entry:	A[X]=lib	P = 0
*		C[X]=romp
* Exit:		CC - match	D0 = ->name	P = 0
*		CS - no match
*		C[5-9] = bank routine
* Uses:		A[A] B[A] C[W] D[A] D0
* Stack:	1
* Notes:	Now switches ROMBank2 if need be; only used by the
*		disassembler (see dcadr.a)
*
*		P register MUST BE 0!!! (configures to address #40000)
*
*		Make sure to reset ROMBank2 after calling! If address
*		is zero, then no switching was done.		-- Han
**********************************************************************
GetRompName	
		D=C	X	romp
		B=A	X	lib
*		GOSUB	FromPart	D0=->libnum if lib exists (uncovered)
*		RTNC			No match

* Han:	set C[5-9] = 0 in case we have an nonexisting lib
		C=0	W

* Han:	check even covered ports, too; configure if necessary and
*	save config routine at C[5-9]
		D0=(5)	=ROMPTAB	G_ROMPTAB = ROMPTAB = #8611D
		C=DAT0	X		libs
		D0=D0+	3
-		C=C-1	X
		RTNC			No match
		A=DAT0	X
		D0=D0+	16		GX!
		?A#B	X
		GOYES	-
		D0=D0-	16-3
		A=DAT0	A		->libnum
		D0=D0+	5
		C=DAT0	A		->access
		B=C	A
		GOSBVL	=CSLW5		keep a copy of the acc routine
		C=B	A
		?C=0	A
		GOYES	+
		GOSUB	GRN_PC=C
+		C=A	A

* Next is common for SX/GX, on SX the ACPTR tests are just meaningless
grn80		D0=C			->libnum
		D0=D0+	3
		A=DAT0	A		offset to hashtable
		?A=0	A		
		RTNYES			No hashes - no match
		CD0EX
		A=A+C	A
		D0=A			->hashtable
* Try to find a hex table
		GOSUB	HexTable?
		RTNC			No visible hash table, no match
* Now D0 = ->hash table (hstr)
grn110		D0=D0+	5
		C=DAT0	A		size+5
		B=C	A
		AD0EX
		B=B+A	A		->hashend
		LC(5)	16*5+5
		A=A+C	A
		D0=A			->names field
		C=DAT0	A
		A=A+C	A		->end of names field
		C=0	A
		C=D	X		romp
		A=A+C	A
		C=C+C	A
		C=C+C	A
		A=A+C	A		->romplink
		?A>=B	A
		RTNYES			No name if link is beyond ->hashend
		D0=A
		C=DAT0	A
		?C=0	A
		RTNYES			No name if no link
		A=A-C	A
		D0=A			->NAME
		RTNCC			Return match!

GRN_PC=C	PC=C
****************************************
* Follow D0 to a hex string, CC if found
****************************************
HexTable?	A=DAT0	A
		LC(5)	=DOHSTR
		?A=C	A
		GOYES	ishtb

* Han:	probably not needed any more given the new bankswitching
*	scheme on the ARM series; should check ROM before altering
		LC(5)	=DOACPTR
		?A#C	A
		RTNYES			Invalid table!
		D0=D0+	10
		A=DAT0	A
		?A#0	A
		RTNYES			Covered!
		D0=D0-	5
		A=DAT0	A
		D0=A
		GONC	HexTable?
ishtb		RTNCC

**********************************************************************
* Fetch library
* Entry:	B[X] = ->libnum
* Exit:		CC -	C[A]=D0 = ->libnum
*		CS - no such lib
* Uses:		A[A] C[A] D0
**********************************************************************
FromPart

* Han:	SX code no longer needed

* Setup SX/GX flag
*		D0=(5)	=IRAM@
*		C=DAT0	1
*		?CBIT=1	3
*		GOYES	grn50
* Find library from SX ROMPTAB
*		D0=(5)	=ROMPTAB
*		C=DAT0	X
*		D0=D0+	3
*grn20		C=C-1	X
*		RTNC			No match
*		A=DAT0	X
*		D0=D0+	8
*		?A#B	X
*		GOYES	grn20
*		D0=D0-	5
*		C=DAT0	A
*		D0=C
*		RTNCC			Match


* Find library from GX ROMPTAB
grn50		D0=(5)	=ROMPTAB	G_ROMPTAB = ROMPTAB = #8611D
		C=DAT0	X		libs
		D0=D0+	3
grn60		C=C-1	X
		RTNC			No match
		A=DAT0	X
		D0=D0+	16		GX!
		?A#B	X
		GOYES	grn60
		D0=D0-	16-3
		C=DAT0	A		->libnum
		D0=D0+	5
		A=DAT0	A		->access
		?A#0	A
		RTNYES			hidden - can't match
		D0=C
		RTNCC			Match!

**********************************************************************
* Set carry if on G/GX (used in assrpl.a)
* RSTK: 2
**********************************************************************
*SafeOnGX?	RSTK=C
*		CD0EX
*		RSTK=C
*		D0=(5)	=IRAM@
*		C=DAT0	1
*		?CBIT=1	3
*		GOYES	SafeIsGX
*SafeIsGX	C=RSTK
*		D0=C
*		C=RSTK
*		RTN
**********************************************************************
* Set carry if on G/GX. Uses C.A (used in assrpl.a)
* RSTK:1
**********************************************************************
*OnGX?		CD0EX
*		RSTK=C
*		D0=(5)	=IRAM@
*		C=DAT0	1
*		?CBIT=1	3
*		GOYES	IsGX
*IsGX		C=RSTK
*		D0=C
*		RTN

**********************************************************************
* Recall the variable whose name is in D0, name lenght in B[A]
* Sets carry if failed search
* Else clear carry and return address of var in A[A]
* Currently scans only CONTEXT.
* RSTK:2
**********************************************************************
RclTok		C=0	A
		LC(2)	#7F		Name too long?
		?C<=B	A
		RTNYES			Yep - ignore search

		GOSUBL	SaveRegs	Save registers

		B=B+1	A		use idlen value in search

		AD0EX
		R0=A			R0 = ->token

*		D0=(5)	=aCONTEXT
*		C=DAT0	A
*		D0=C
		D0=(5)	=CONTEXT

		C=DAT0	A

rcltokloop	R1=C			R1 = curdir
		GOSUB	RclTokHere
		GONC	rcltokok	Found variable, it's in D0
		A=R1			->rrp
*		D0=(5)	=aUSEROB
*		C=DAT0	A
*		D0=C
		D0=(5)	=USEROB

		C=DAT0	A		->home
		?A=C	A
		GOYES	rcltokfail	Already at home - fail
		D0=A			->rrp
		GOSBVL	=TRAVERSE-	Skip name of rrp
-		D0=D0-	5
		C=DAT0	A		Skip to start of rrp
		AD0EX
		A=A-C	A
		AD0EX
		?C#0	A
		GOYES	-
		D0=D0-	5+3
		A=DAT0	A		Tricky test - think about it..
		LC(5)	=DORRP
		?A=C	A
		GOYES	+		Not home yet
*		D0=(5)	=aUSEROB
*		A=DAT0	A
*		D0=A
		D0=(5)	=USEROB

		A=DAT0	A
		D0=A
+		CD0EX
		GOTO	rcltokloop

rcltokfail	GOSUBL	RestoreRegs
		RTNSC			SC: found no var

rcltokok	AD0EX			A.A = ->variable
		GOSUBL	RestoreRegs
		RTNCC			CC: found var

**********************************************************************
* Recall token in rrp at R1[A]
* RSTK:1
**********************************************************************

RclTokHere	A=R1	A		->rrp
		GOSUB	FindLoPtr
		A=DAT0	A
		A=-A	A
-		?A=0	A		End of rrp?
		RTNYES			Yes - return CS
		CD0EX			Follow offset
		C=C-A	A
		D0=C			D0 = ->varname
		R2=C			R2[A] = ->varname
		GOSUB	ThisVar?
		GONC	+
		C=R2
		D0=C			D0 = ->varname
		D0=D0-	5		To previous offset
		A=DAT0	A
		GONC	-
+		D0=D0+	2		Skip 2nd idlen, always nonzero
		RTNCC			CC: match

* A[A] = ->rrp	--> D0 = ->lastramword offset

FindLoPtr
*		D0=(5)	=aUSEROB
*		C=DAT0	A
*		D0=C
		D0=(5)	=USEROB

		C=DAT0	A		->home
		D0=A
		D0=D0+	5		Skip DORRP
		?A#C	A		rrp <> home?
		GOYES	+
		C=DAT0	A		C[A] = libs in home
-		C=C-1	X		libs--
		GOC	+
		D0=D0+	13
		GONC	-
+		D0=D0+	3		D0 = ->lastramword offset
		RTN

**********************************************************************
* Check if varname at D0 matches token and toklen
* CC: match, return D0 that has skipped idlen and id
* CS: no match
* RSTK:0
**********************************************************************
ThisVar?	C=DAT0	B		* Compare namelen to toklen
		?C#B	B
		RTNYES
		D0=D0+	2		* Skip namelen field
		A=R0
		D1=A			* D1 = ->token
		C=0	XS
		C=C+C	X
		P=C	0
		CSR	X
		D=C	B
IdCmpLoop	D=D-1	B
		GOC	IdCmpLast
		A=DAT0	W		
		C=DAT1	W
		D0=D0+	16
		D1=D1+	16
		?A=C	W
		GOYES	IdCmpLoop
IdCmpFail	P=	0
		RTNSC			* Fail comparison
IdCmpLast	P=P-1
		GOC	IdCmpOk
		A=DAT0	WP
		C=DAT1	WP
		?A#C	WP
		GOYES	IdCmpFail
		CD0EX
		C+P+1
		D0=C
IdCmpOk		P=	0
		RTNCC
**********************************************************************
RPL

