**********************************************************************
*		JAZZ - String/Grob viewer
**********************************************************************
ASSEMBLE
	CON(1)	8
RPL
xNAME VV
::
  CK1&Dispatch
  THREE
  INCLUDE edit/viewstr.s
  TWELVE
  INCLUDE edit/viewgrb.s
  ZERO
  ::
     DUP
     %1 "AGROB" palparse NcaseTYPEERR
     DUPTYPEROMP? NcaseTYPEERR
     ROMPTR@ NcaseTYPEERR
     CLEARVDISP
     EvalNoCK ViewGrob DROP
  ;
;
**********************************************************************
