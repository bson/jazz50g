ASSEMBLE
	LISTM
RPL
**********************************************************************
* Modulname:	JAZZ
* Author:	Mika Heiskanen
* Address:	JMT 7 C 355, 02150 ESPOO, FINLAND
* Email:	mph@fyslab.hut.fi
*
* Author:	Han Duong (ROM 2.15 port and new features)
* Address:	Jacksonville University
*		2800 University Blvd N
*		Jacksonville, FL 32211
* Email:	hduong_NOSPAM_@ju.edu (remove _NOSPAM_)
**********************************************************************

**********************************************************************
*		Compile Flags
**********************************************************************
ASSEMBLE
fDBGSERVER	EQU 1
* 		enable/disable IO support
*		SETFLAG	fDBGSERVER
		CLRFLAG	fDBGSERVER
		
fEDFORMAT	EQU 2
*		enable/disable formatting in ED (buggy)
*		SETFLAG fEDFORMAT
		CLRFLAG fEDFORMAT
RPL

**********************************************************************
*		Config & Message table
**********************************************************************

xROMID	3E0	( 992 )

ASSEMBLE
ROMID#	EQU #3E0
=xxCONFIG
RPL

:: [#] ROMID# TOSRRP ;

	INCLUDE msgtab.s
	INCLUDE external.h

**********************************************************************
*		Global Definitions
**********************************************************************
*	Jazz Entry	Supported Entry
DEFINE OVER#2+UNROLL	OVER#2+UNROL
DEFINE Sys!		SysSTO
DEFINE ExtGetAdr	ROMPTR 102 5
DEFINE ExtGetNames	ROMPTR 102 6
DEFINE ExtGetName	ROMPTR 102 8

ASSEMBLE
	INCLUDE	gentries.a	* Unsupported entries
	INCLUDE	gmacros.a	* Global macros
	INCLUDE	dis/disdefs.a	* DISS definitions
	INCLUDE	ass/assdefs.a	* ASS definitions
	INCLUDE dbg/dbdefs.a	* MDB definitions
RPL
**********************************************************************
*		JAZZ Subroutines
**********************************************************************

	INCLUDE	ass/ass.s		( Assembler )
*	INCLUDE	ass/noass.s		( uncomment to remove xASS )
	INCLUDE	misc/memory.s		( Memory subroutines )
ASSEMBLE
	INCLUDE	misc/safeskip.a		( SafeSkipOb )
RPL
	INCLUDE	dis/dis.s		( Disassembler )
	INCLUDE	dbg/db.s		( ML Debugger )
	INCLUDE	sdb/sdb.s		( SysRPL Debugger )
	INCLUDE	ec/ec.s			( Entries Catalog )
	INCLUDE	edit/ed.s		( ED )
	INCLUDE	edit/view.s		( VV )
	INCLUDE tab/ea.s		( EA command )	
	INCLUDE misc/fptr.s		( Peek and FPTR-> )
	INCLUDE stk/stk.s		( SSTK )
	INCLUDE misc/mfed.s		( MINIFONT editor )
		
* Han:	no longer used; keeping source files, though
*	INCLUDE	tab/rtab.s		( RTAB & DTAB )
*	INCLUDE	tab/mkrtab.s		( RTAB-> and ->RTAB )
*	INCLUDE	tab/mkdtab.s		( ->DTAB )

* Han:	alternate keyboard handler to handle 3 simultaneous keys
*ASSEMBLE
*	INCLUDE kbd/srvckbdab.a		( need further bugtesting )
*	INCLUDE kbd/keycodedown.a
*	INCLUDE kbd/anykeydown.a
*RPL

