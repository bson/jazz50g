**********************************************************************
*		External Definitions
**********************************************************************

* display

* assmain.s
EXTERNAL	xASS
EXTERNAL	Assemble
EXTERNAL	MakeAssStat$
EXTERNAL	SetupAssOps

* dismain.s
EXTERNAL	xDIS
EXTERNAL	xDISXY
EXTERNAL	xDOB
EXTERNAL	Dob
EXTERNAL	xDISN

EXTERNAL	Diss
EXTERNAL	SetDissOps
EXTERNAL	SetDisXYOps
EXTERNAL	SetDisnOps
EXTERNAL	SetStkDis1Ops

EXTERNAL	ScanLabels	( $status --> $status $labels )
EXTERNAL	ScanLabsXY	( $status --> $status $labels )
EXTERNAL	AddLabsRPL	( $labels #x #y --> $labels' )
EXTERNAL	AddLabsXY	( $labels #x #y --> $labels' )

EXTERNAL	FindObEnd	( #x --> #x #y TRUE / #x FALSE )
EXTERNAL	SkipMLN

* db.s
EXTERNAL	xDB
EXTERNAL	DBHOOK
EXTERNAL	DBHook

* sdb.s
EXTERNAL	xSDB
EXTERNAL	xSHALT
EXTERNAL	xSKILL
EXTERNAL	SdbRstFlags
EXTERNAL	SdbStart
EXTERNAL	SdbName
EXTERNAL	SdbRomp
EXTERNAL	SdbSeco
EXTERNAL	RUI
EXTERNAL	RUIHALT
EXTERNAL	SdbMenu
EXTERNAL	SdbCheckMe
EXTERNAL	SdbDoMode
EXTERNAL	SdbThisMode
EXTERNAL	SdbFinish
EXTERNAL	SdbEval
EXTERNAL	SdbRstkDisp
EXTERNAL	RPICK
EXTERNAL	SdbD0Disp
EXTERNAL	SdbLamDisp
EXTERNAL	SdbDispLam
EXTERNAL	GetLamEnv!
EXTERNAL	GetLamEnv
EXTERNAL	SdbLoopDisp
EXTERNAL	Pad$
EXTERNAL	GetLoopEnv
EXTERNAL	SdbExec
EXTERNAL	SdbSkip
EXTERNAL	SdbDbCode
EXTERNAL	SdbSemi
EXTERNAL	SdbInOb
EXTERNAL	SdbInId
EXTERNAL	SdbInThis

EXTERNAL	SdbSstSemi
EXTERNAL	SdbSstOb
EXTERNAL	sst_rpite
*EXTERNAL	sst_decr
EXTERNAL	sst_exam
EXTERNAL	sst_rprot
EXTERNAL	sst_reval:
EXTERNAL	sst_rcola
EXTERNAL	sst_cola
EXTERNAL	sst_raddtop
EXTERNAL	sst_addtop
EXTERNAL	sst_ntrap
EXTERNAL	sst_dtrap
EXTERNAL	sst_status?

* ea.s
EXTERNAL	xEA
EXTERNAL	#>Entr
EXTERNAL	Entr>#
EXTERNAL	FINDTAB
EXTERNAL	FindTabs
EXTERNAL	GetTabCfg

* rtab.s	no longer supported
*EXTERNAL	xRTAB
*EXTERNAL	xDTAB
*EXTERNAL	GetRplTab
*EXTERNAL	GetDisTab
*EXTERNAL	RclID

* mkrtab.s	no longer supported
*EXTERNAL	xRTB\8D
*EXTERNAL	x\8DRTB

* mkdtab.s	no longer supported
*EXTERNAL	x\8DDTB

* memory.s
*EXTERNAL	SG_ITE
*EXTERNAL	SX?
EXTERNAL	CHECKME
EXTERNAL	TOTEMPBOT?

* ec.s
EXTERNAL	xEC
EXTERNAL	DoEC
EXTERNAL	ECView

* ed.s
EXTERNAL	xED
EXTERNAL	xTED
EXTERNAL	DoEdAt
EXTERNAL	DoEd
EXTERNAL	DoEd_ASS
EXTERNAL	DoEd_DOB
EXTERNAL	EdDOBROMP
EXTERNAL	RPEntry?
EXTERNAL	Entr>Romp
EXTERNAL	FPEntry?
EXTERNAL	FSTKDROP
EXTERNAL	DoEd_STK
EXTERNAL	EdStkAssTrap
EXTERNAL	DoCont/Kill
EXTERNAL	DoEdErrJmp
EXTERNAL	DoEd_GROB
EXTERNAL	DoEd_EC


* view.s
EXTERNAL	xVV
EXTERNAL	ViewGrob
EXTERNAL	ViewGrob!

* stk.s
EXTERNAL	xSSTK
EXTERNAL	SSTKLOOP
EXTERNAL	SysDisplay!
EXTERNAL	?DispStack!
EXTERNAL	SSTKErrTrap
EXTERNAL	JazzStkDis1
EXTERNAL	JavaDis1

* istk.s
EXTERNAL	IStk
EXTERNAL	IStkDisp
EXTERNAL	?DispIStk
EXTERNAL	IStkKeys
EXTERNAL	IStkUp&Rep
EXTERNAL	IStkDn&Rep
EXTERNAL	IStkPgUp
EXTERNAL	IStkPgDn
EXTERNAL	IStkFarUp
EXTERNAL	IStkFarDn
EXTERNAL	IStkMenu
EXTERNAL	IStkDoN:
EXTERNAL	IStkMenuEd
EXTERNAL	IStkView
EXTERNAL	IStkIView
EXTERNAL	IStkEdit
EXTERNAL	IStkVisit
EXTERNAL	IStkDrop
EXTERNAL	?AdjSel/Exit!
EXTERNAL	?AdjSelPos!
EXTERNAL	ShowSel!
EXTERNAL	UnShowSel!
EXTERNAL	>SelPict!

* mfed.s
EXTERNAL	xMFED

* utils.s
EXTERNAL	PEEK
EXTERNAL	FPTR@
EXTERNAL	Fptr@
EXTERNAL	Entr>Fptr
EXTERNAL	Ent11111@

* jazz.s itself
EXTERNAL	JazzHook
*EXTERNAL	xJAZZ
