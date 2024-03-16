**********************************************************************
*		JAZZ Message Table
**********************************************************************

ASSEMBLE
=xxMESSAGE

* Help macro:

msgnum	= 0			* Current message number

MSGMAC	MACRO	$msg,$label	* Message creation macro
	REL(5)	+
	NIBASC	\$1\
+
msgnum	= (msgnum)+1
$2	EQU msgnum
X$2	EQU (ROMID#)*256+(msgnum)
MSGMAC	ENDM

* Array of string:

	CON(5)	=DOARRY
	REL(5)	->MsgTabEnd
	CON(5)	=DOCSTR		* String table
	CON(5)	1		* 1 dimension
	CON(5)	totmsg		* Number of messages

	MSGMAC	Lib Not Fixed,errNonFixed		[1]
*	MSGMAC	RPL.TAB Missing,errNoRPLtab		[2]
	MSGMAC	extable Missing,errNoRPLtab		[2]
	MSGMAC	Invalid DBpar,errDBpar			[3]

* Assembler error display:
* 1234567890123456789012lllll/ddddd
* Where:
*	12345... 	= error message
*	lllll		= line	(decimal)
*	ddddd		= location in chars (decimal)
* line display ignores leading zeros so usually there is only lll or less

*		 12345678901234567890123
	MSGMAC	No Program,errNoPrgm			[4]
	MSGMAC	Undefined Result,errUndefRes		[5]
	MSGMAC	Invalid Token,errInvTok			[6]
	MSGMAC	More Tokens Expected,errMoreToks	[7]
	MSGMAC	Need Hex Field,errNeedHex		[8]
	MSGMAC	Missplaced ; or },errWrongSemi		[9]
*		 12345678901234567890123
	MSGMAC	Invalid #,errInv#			[10]
	MSGMAC	Too Big #,errBig#			[11]
	MSGMAC	Invalid PTR,errInvPTR			[12]
	MSGMAC	Too Big PTR,errBigPTR			[13]
	MSGMAC	Invalid LibID,errInvLibID		[14]
	MSGMAC	ROMPTR LibID > FFF,errBigLibID		[15]
	MSGMAC	Invalid RomWd,errInvRomWd		[16]
	MSGMAC	ROMPTR RomWd > FFF,errBigRomWd		[17]
	MSGMAC	ACPTR is a G Object,errAcptr		[18]
	MSGMAC	Invalid APda,errAPda			[19]
*		 12345678901234567890123
	MSGMAC	Invalid APaa,errAPaa			[20]
	MSGMAC	Invalid C%%,errInvC%%			[21]
	MSGMAC	Invalid C%,errInvC%			[22]
	MSGMAC	Invalid %%,errInv%%			[23]
	MSGMAC	Invalid %,errInv%			[24]
	MSGMAC	EXT1 is a S Object,errExt1		[25]
	MSGMAC	Invalid NIBB Length,errNibbLen		[26]
	MSGMAC	Length Too Big,errBigLen		[27]
	MSGMAC	Zero Length,errZeroLen			[28]
	MSGMAC	Expecting Hex Size,errWantHexSize	[29]
*		 12345678901234567890123
	MSGMAC	Body Len Not Hex,errHexSize		[30]
	MSGMAC	Body Len Too Big,errBigBody		[31]
	MSGMAC	Missing Body,errMissBody		[32]
	MSGMAC	Body Too Short,errShortBody		[33]
	MSGMAC	Invalid Body,errInvBody			[34]
	MSGMAC	Body Too Long,errLongBody		[35]
	MSGMAC	Missing TagOb,errMissTagOb		[36]
	MSGMAC	Invalid ID/LAM Body,errIdBody		[37]
	MSGMAC	Too Long ID/LAM,errLongId		[38]
	MSGMAC	Missing String,errMissString		[39]
*		 12345678901234567890123
	MSGMAC	Invalid String,errInvString		[40]
	MSGMAC	Invalid CHR,errInvChr			[41]
	MSGMAC	Can't INCLOB,errInclob			[42]
	MSGMAC	Can't INCLUDE,errInclude		[43]
	MSGMAC	INCLUDE Depth Overflow,errFlowInclude	[44]
	MSGMAC	INCLUDE Ob Not String,errNoIncl$	[45]
	MSGMAC	DEFINE Depth Overflow,errFlowDef	[46]
	MSGMAC	Too Long Label,errLongLabel		[47]
	MSGMAC	DEFINE String Missing,errDefine$	[48]
	MSGMAC	Not Implemented,errImplement		[49]
*		 12345678901234567890123

* Don't change order of following 5:
	MSGMAC	Label Reserved,errReserved		[50]
	MSGMAC	Label Already External,errExternal	[51]
	MSGMAC	Duplicate Label,errDuplicate		[52]
	MSGMAC	Label Already Defined,errDefined	[53]
	MSGMAC	Undefined Label,errUndefined		[54]

	MSGMAC	Macro Already Exists,errMacrod		[55]
	MSGMAC	Cannot Redefine Value,errRedefVal	[56]
	MSGMAC	Value Changed,errValueChange		[57]

	MSGMAC	Empty Label,errEmpLab			[55]
	MSGMAC	Invalid Use of Symbol,errInvUse		[56]
	MSGMAC	Relative Value,errRelValue		[57]
	MSGMAC	Unresolved Expression,errExpr		[58]
	MSGMAC	Invalid Mnemonic,errMnemonic		[59]
*		 12345678901234567890123
	MSGMAC	GOYES Expected,errWantGoyes		[60]
	MSGMAC	GOYES Without Test,errDontGo		[61]
	MSGMAC	Branch Too Long,errLongBranch		[62]
	MSGMAC	Label Expected,errWantLabel		[63]
	MSGMAC	<ENDCODE Not Expected>,errDontEndcode	[64]
	MSGMAC	Argument Field Expected,errWantArg	[65]
	MSGMAC	Argument 1-16 Expected,errWant1-16	[66]
	MSGMAC	Argument 0-15 Expected,errWant0-15	[67]
	MSGMAC	Argument 1-256 Expected,errWant1-256	[68]
	MSGMAC	Invalid Decimal Number,errInvDec	[69]
*		 12345678901234567890123
	MSGMAC	Invalid Hex Number,errInvHex		[70]
	MSGMAC	Invalid Expression,errInvExpr		[71]
	MSGMAC	Field Selector Expected,errWantfs	[72]
	MSGMAC	Invalid Field Selector,errInvfs		[73]
	MSGMAC	Invalid Reg Combination,errInvRegs	[74]
	MSGMAC	Invalid Scratch Reg,errInvScratch	[75]
	MSGMAC	Invalid (N) Field,errInvN		[76]
	MSGMAC	<ENDCODE Expected>,errWantEndcode	[77]
	MSGMAC	Too Long Hex Field,errLongHex		[78]
	MSGMAC	Invalid Operator,errInvOp		[79]
*		 12345678901234567890123
	MSGMAC	Too Many ('s,errManyLefts		[80]
	MSGMAC	Too Many )'s,errManyRights		[81]
	MSGMAC	Expr Buffer Overflow,errFlowExpr	[82]
	MSGMAC	Division By Zero,errZeroDiv		[83]
	MSGMAC	Too Big Exponent,errBigExp		[84]
	MSGMAC	Too Long Asc Field,errLongAsc		[85]
	MSGMAC	Invalid Asc Field,errInvAsc		[86]
	MSGMAC	Too Long Offset,errLongRel		[87]
	MSGMAC	Invalid Binary Number,errInvBin		[88]
*		 12345678901234567890123
	MSGMAC	Embedding Not Allowed,errBadMakerom	[89]
	MSGMAC	Not in MAKEROM Mode,errLibMode		[90]
	MSGMAC	Invalid ROMID,errInvRomid		[91]
	MSGMAC	Invalid Title,errInvTitle		[92]
	MSGMAC	Duplicate ROMID,errDupRomid		[93]
	MSGMAC	Duplicate TITLE,errDupTitle		[94]
	MSGMAC	Too Long Title,errLongTitle		[95]
	MSGMAC	Duplicate Config,errDupConfig		[96]
	MSGMAC	Duplicate Message Table,errDupMesg	[97]
	MSGMAC	Used Before Declaration,errDeclaration	[98]
	MSGMAC	Duplicate Name,errDupName		[99]
*		 12345678901234567890123
	MSGMAC	Label Already Romptr,errOldRomp		[100]
	MSGMAC	Too Long Name,errLongName		[101]
	MSGMAC	Invalid Hash Assignment,errInvHash	[102]
	MSGMAC	Too Many Labels,errManyLabels		[103]
	MSGMAC	MACRO Missing,errMissMacro		[104]
	MSGMAC	ENDM Missing,errMissEndm		[105]
	MSGMAC	Empty Macro,errEmptyMac			[106]
	MSGMAC	IF Stack Overflow,errManyIfs		[107]
	MSGMAC	Unmatched ELSE,errExtraElse		[108]
	MSGMAC	Unmatched ENDIF,errExtraEndif		[109]
	MSGMAC	Missing ENDIF,errMissEndif		[110]
*		 12345678901234567890123
	MSGMAC	Invalid FPTR ID,errInvFPTRID		[111]
	MSGMAC	FPTR ID > FFF,errBigFPTRID		[112]
	MSGMAC	Invalid FPTR CMD,errInvFPTRCMD		[113]
	MSGMAC	FPTR CMD > FFFF,errBigFPTRCMD		[114]
	MSGMAC	Undefined FPTR Name,errUndefFPTR	[115]
	MSGMAC	Undefined ROMPTR Name,errUndefRPTR	[116]
	MSGMAC	Invalid ZINT,errInvZint			[117]
totmsg	= msgnum		* Total message count
->MsgTabEnd
RPL
**********************************************************************
