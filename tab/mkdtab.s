**********************************************************************
*		JAZZ - DIS.TAB creation
**********************************************************************

**********************************************************************
* Name:		->DTB
* Interface:	( --> )
* Description:	Create DIS.TAB from RPL.TAB and store it to a variable.
* 1) Count the number of entries in RPL.TAB
* 2) Create list of offsets from start of RPL.TAB to address fields.
* 3) Sort the offsets according to the addresses they point to
* Note: Currently insertion sort is used in combination with binary search
*	--> For my 2500 entries it takes ~ 45 seconds to create DIS.TAB
* Sort:	Insertion sort with binary search to find insertion point
*	--> Inner loop passed ~ N*lg(N) times (log2)
*	    Example: For my 2571 entries 28093 passes are done
*	Originally I uses bubble sort: ~ N^2/2 passes, *very slow*
**********************************************************************
ASSEMBLE
	CON(1)	8
RPL
xNAME \8DDTB
::
  CK0
  CHECKME	( Error if lib is hidden )
  GetRplTab DUPNULL$? case :: [#] XerrNoRPLtab DO#EXIT ;
  "Creating DIS.TAB\nPlease wait\1F" DISPSTATUS2
CODE
		GOSBVL	=PopASavptr	* A[A] = ->tab
		R1=A			* R1[A] = ->tab
		GOSUB	MKgetnum	* R2[A] = N
		GOSUB	MKmalloc	* R0[A] = ->dtab  D0 = ->dtab body
		GOSUB	MKsinit
		GOSUB	MKgetadrs	* Get offsets into dtab
		GOSUB	MKsort		* Sort offsets
		GOVLNG	=GPPushR0Lp
****************************************
* Initialize DIS.TAB
* Entry:	D0=->tab	R0[A]=->$tab	R2[A]=N
* Exit:		D0=->entrs
****************************************
MKsinit		D0=D0-	5
		A=DAT0	A
		CD0EX
		A=A+C	A
		D0=A
		D0=D0-	5
		A=0	A
		DAT0=A	A		00000 terminator
		D0=C
		D0=D0+	5
		LC(4)	DTABMAGIC
		DAT0=C	4
		D0=D0+	4
		A=R2
		DAT0=A	A
		D0=D0+	5
		RTN
	
****************************************
* Calculate number of entries
* Entry:	R1[A] = ->tab
* Exit:		R2[A] = N
****************************************
MKgetnum	A=R1			* A[A] = ->tab
		A=A+CON	A,5
		D0=A
		C=DAT0	A
		C=C+A	A
		D=C	A		* D[A] = ->tabend
		LC(5)	#1E9
		C=C+A	A
		D0=C			* D0 = ->1st entry

		B=0	A		* N=0

		A=0	A
MKnumlp		?C>=D	A
		GOYES	MKgotn
		B=B+1	A		* N++
		C=C+CON	A,5		* Skip addr
		D0=C
		A=DAT0	1
		C=C+A	A		* Skip name
		C=C+A	A
		C=C+1	A		* Skip name lenght
		GONC	MKnumlp
MKgotn		C=B	A
		R2=C			* R2[A] = N
		RTN
****************************************
* Allocate room for DIS.TAB
* Entry:	R2[A] = N
* Exit:		R0[A] = ->dtab  D0=->dtab body
****************************************
MKmalloc	C=R2			* C[A] = N
		C=C+1	A		* Also room for N
		A=C	A
		C=C+C	A
		C=C+C	A
		C=C+A	A
		C=C+CON	A,4+5		* Room for magic constant + "00000"
		GOVLNG	=MAKE$N
****************************************
* Fill dtab fill offsets into RPL.TAB
* Entry:	D0 = ->dtab body	
*		R1[A] = ->tab
*		R2[A] = N
****************************************
MKgetadrs	C=R1
		D=C	A	* D[A] = ->tab
		LA(5)	#1E9+5
		A=A+C	A
		D1=A		* D1 = ->1st entry
		A=R2
		B=A	A	* B[A] = N
		A=0	A
MKadrlp		B=B-1	A
		RTNC		* Done
		CD1EX
		D1=C		* D1 = ->entry
		C=C-D	A	* C[A] = offset
		DAT0=C	A	* Write offset
		D0=D0+	5
		D1=D1+	5	* Skip addr
		A=DAT1	1
		CD1EX
		C=C+A	A	* Skip name
		C=C+A	A
		C=C+1	A	* Skip namelen
		CD1EX
		GONC	MKadrlp
****************************************
* Sort offsets in dtab according to addresses
* Entry:	R0[A] = ->dtab
*		R1[A] = ->tab
*		R2[A] = N
* Algorithm assuming a 0 - N-1 array:
* I = 1			(1st element already 'sorted')
* REPEAT
*   A = ADDR (A)
*   J = LOC (A)
*   Move up elements J-I
*   OFFS(J) = OFFS(I)
*   I=I+1
* UNTIL I=N
****************************************

MKsend		A=R0.F	A	* Fix ->dtab offsets back to ->dtab
		LC(5)	19
		A=A-C	A
		R0=A.F	A
		RTN

MKsort		A=R0.F	A	* Change ->dtab to ->dtab offsets
		LC(5)	19	* so we'll get a smaller inner loop
		A=A+C	A
		R0=A.F	A	* Fixed back upon exit in MKsend
		A=0	A
		R4=A.F	A	* R4[A] = I

MKinslp		A=R4.F	A	* I++
		A=A+1	A
		R4=A.F	A
		C=R2.F	A	* N
		?A>=C	A	* ( > test superfluous )
		GOYES	MKsend	* I=N ==> done

* Find address stored to Ith location

		C=R0.F	A	* ->offsets
		C=C+A	A
		A=A+A	A
		A=A+A	A
		C=C+A	A
		D1=C		* D1 = ->offset
		A=DAT1	A	* A[A] = offset
		C=R1.F	A	* ->tab
		C=C+A	A
		D0=C
		C=DAT0	A
		D=C	A	* D[A] = ADDR

* Find location of a larger element in the already sorted part of the table

		A=R4.F	A	* I
		B=A	A	* B[A]=END index
		A=0	A	* A[A]=START index
MKfndlp		C=A	A
		C=C+B	A
		CSRB.F	A	* C[A]=MID index
		D0=A		* D0 = START
		A=R0.F	A	* A[A]=->offsets
		A=A+C	A
		C=C+C	A
		C=C+C	A
		A=A+C	A	* A[A]=->offset
		AD0EX		* A[A]=START
		C=DAT0	A	* C[A]=offset
		D0=A		* D0=START
		A=R1.F	A	* A[A]=->tab
		A=A+C	A	* A[A]=->entry
		AD0EX		* A[A]=START D0=->entry
		C=DAT0	A	* C[A]=addr
		?A=B	A	* If START=END
		GOYES	MKfend	* Then we found the location
		?C>D	A
		GOYES	MKfup	* addr > ADDR, move downwards
		A=A+B	A	* addr <= ADDR, move upwards
		ASRB.F	A
		A=A+1	A
		GONC	MKfndlp
MKfup		B=B+A	A	* move downwards
		BSRB.F	A
		GONC	MKfndlp

* Found location where addr >= ADDR
* (no smaller elements can be found since ADDR is included in the search)

MKfend		?C<=D	A	* addr <= ADDR?  ( < test superfluous)
		GOYES	MKnoins	* Yes - no insert to do

* Now:	D1   = I location in table (TOP)
*	A[A] = J (BOTTOM)

		C=R0.F	A
		C=C+A	A
		A=A+A	A
		A=A+A	A
		A=A+C	A	* A[A] = J location in table (BOTTOM)
		C=DAT1	A
		B=C	A	* B[A] = offset
		CD1EX		* C[A] = TOP
		D0=C		* D0 = TOP
		D1=C		* D1 = TOP
		D1=D1+	5	* For MOVEUP call
		C=C-A	A	* Bloc size
		GOSBVL	=MOVEUP
		C=B	A
		DAT0=C	A	* Store offset to it's correct position
MKnoins		GOTO	MKinslp

ENDCODE
  ' ID DIS.TAB Sys!
;
**********************************************************************

