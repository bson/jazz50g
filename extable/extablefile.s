RPL ( Ensure RPLCOMP and the syntax highlighter are in RPL mode )
( extablefile.s, part of the extablefile.s project, created by Cyrille de brebisson on 17/09/99 )

* Compilation process.
* In order to create a new extable, you must first create a table
* and store it in a file called table.hp. You can use the tablegenp
* program and the latest suprom49.a to do it.
* Then, just compile this project and you net a new table!

INCLUDE extable.H
(
  This librarie contains and allows access to the external entry table.
  The table has this structure:

  10 nibbles: strobj prolog and size
  5 nibbles: nb of entry in the table
  5 nibbles: offset to the data part of the table
  128*5 nibbles: offset to the list of entry of crc n
                (where n is the number of this entry in the 64 entry table]
  n*5 nibbles: offsets to the value of the entry n (sorted by address]
  128*
    n*5 nibbles offset to the entries of same crc. sorted by name lenght then by name
    00000
  data part
  n*
  5 nibbles: entry value
  2 nibbles: entry size in chr
  m*2 nibbles: entry text
  7 nibbles: 0000000 [end of list]
)

****************************************************
* This entry does nothing, it's just here to prvide
* an access to the internal asm functions.
****************************************************
ASSEMBLE
        CON(1)        8                * Tell parser 'Non algebraic'
RPL
xNAME nop
CODEM
RPL

DC _MaxLabSize    40

DC _SCREEN        822B2

DC _ExpValueStkStart 0+_SCREEN
DC _ExpOpStkStart 80+_ExpValueStkStart
DC _TempAreaStart 0+_ExpOpStkStart
DC _TempAreaEnd   5+(_TempAreaStart)
DC _TempAreaSize  5+(_TempAreaEnd)
DC _TempArea      5+(_TempAreaSize)
DC PORT2EOS 80540
DC _SwitchAdr 0+(PORT2EOS)
DC _GetAdrJmp 7+_SwitchAdr
DC _GetNameJmp 7+7+_SwitchAdr
DC _FindFirstJmp 7+7+7+_SwitchAdr
DC _FindNextJmp 7+7+7+7+_SwitchAdr
DC _FindFirstNearJmp 7+7+7+7+7+_SwitchAdr
DC _FindNextNearJmp 7+7+7+7+7+7+_SwitchAdr
DC ROMPTAB 8611D

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this function initialize the table datas
% this function should be call before any call
% to the database.
% you can use this 7 lines of code to call the InitTable function
%
% D1=(5)ROMPTAB C=DAT1.X D=C.X D1+3 LC 102    % read to look in the lib table for lib 102
% { D-1.X RTNC A=DAT1.X D1+16 ?C#A.X UP }     % look for it
% D1-8 C=DAT1.A D=C.A D1-5 C=DAT1.A D1=C      % D: access routine, C: @header
% ?D=0.A { C=D.A GOSUB .pcisc }               % switch if needed
% D1+13 A=DAT1.A ?A=0.A RTY                   % go to link table
% CD1EX A+C.A A+10.A D1=A C=DAT1.A C+A.A C+20.A % jump to the InitTableCode
% *.pcisc PC=C
%
% after initializing the database, you can use
%
% P=0 GOSBVL _SwitchAdr  % uncover the table
% GOSBVL _xxxJmp         % call the function you want
% Do your stuff          % do your stuff :-)
% P=1 GOSBVL _SwitchAdr  % switch back on the current view.

% Add in offsets for Jazz compatibility
*_TableOffsets
GOTO _InitTable
$(5)"(_table)-(*)"+#10		% offset to number of entries

% Input: D: access function
% uses D0, Aa, Ca, RSTK1
% return non carry
*_InitTable
C=D.A D0=(5)_SwitchAdr+#2 DAT0=C.A D0-2
LC D8 DAT0=C.B ?D#0.A { LC 1002 DAT0=C.4 } D0+7
LC D8 DAT0=C.B D0+2
A=PC LC(5)"(_GetAdr)-(*)" A+C.A DAT0=A.A D0+5
LC D8 DAT0=C.B D0+2
A=PC LC(5)"(_GetName)-(*)" A+C.A DAT0=A.A D0+5
LC D8 DAT0=C.B D0+2
A=PC LC(5)"(_FindFirst)-(*)" A+C.A DAT0=A.A D0+5
LC D8 DAT0=C.B D0+2
A=PC LC(5)"(_FindNext)-(*)" A+C.A DAT0=A.A D0+5
LC D8 DAT0=C.B D0+2
A=PC LC(5)"(_FindFirstNear)-(*)" A+C.A DAT0=A.A D0+5
LC D8 DAT0=C.B D0+2
A=PC LC(5)"(_FindNextNear)-(*)" A+C.A DAT0=A.A
RTNCC

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% purpose: get the address corresponding to a name
% Input: TempArea: label name, Da: label size
% output: carry if error
%         non carry if cuxess. result in Ca
% uses RSTK2, Aw, Ba, Cw, Da, D0, D1
*_GetAdr
D1=(5)_TempArea
B=0.A C=D.B C-1.B RTNC		% name too short; exit
{ A=DAT1.B B+A.B D1+2 C-1.B UPNC }	% compute hash
LC 0007F C&B.A			% hash mask; 0 <= hash <= 128-1
A=PC *_l1 A+C.A C+C.A C+C.A A+C.A
LC(5)_table-_l1+#20 A+C.A D1=A	% D1 -> offset to hash table
C=DAT1.A A+C.A D1=A B=A.A	% Ba = D1; D1 -> start of hash table
D0=(5)_TempArea-#2
C=0.A C=DAT0.4 C=D.B D=C.A	% Da = [firstchar][length]
{
  A=DAT1.A ?A=0.A RTY		% reached end of hash table; exit
  A+B.A D0=A			% D0 -> length byte of current entry
  D1+5 B+5.A			% Ba = D1 -> next offset
  C=0.A C=DAT0.4
  ?C<D.B UP			% test length
  ?C>D.B RTY
  ?C<D.A UP ?C>D.A RTY		% test first char
  D1=(5)_TempArea D0+2 A=C.B	% match; test rest of entry name
  GOSBVL CompareACbBytes EXITNC	% match found, exit loop
  A=B.A D1=A UP			% no match
}
C=0.A C=D.B D=C.A CD0EX C-D.A C-D.A CD0EX D0-7 C=DAT0.A RTNCC

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Purpose:	get the name corresponding to an address
% Input:	Ca = test address
% Output:	Ca preserved!!!
%		carry if error
%         	no carry if found; D1 -> entry size byte
% Uses:		RSTK1, Aa, Ba, Ca, Da, D1
% Note:		modified by Han Duong; in case of entries with
%		same addresses, the entry that appears first in
%		the addr table is always selected; this routine
%		reduces RSTK usage by 1 and preserves Ca regardless
%		of success/failure
*_GetName
D=C.A B=0.A			% Da = addr to find; Ba = START
A=PC *_113 LC(5)_table-_113+#10	% get number of entries and
A+C.A D1=A A=DAT1.A A-1.A	% Aa = MAXN-1
ABEX.A				% set Aa = START; Ba = END
{
  AD1EX				% D1 = START
  A=PC *_111 LC(5)_table-_111+#20+(#128*#5)	% skip hashes
  A+C.A				% Aa -> start of addr offsets
  CD1EX D1=C C=C+B.A CSRB.A	% Ca = MID
  A+C.A C+C.A C+C.A A+C.A	% Aa -> middle of addr offsets
  AD1EX C=DAT1.A AD1EX A+C.A	% Aa -> addr of middle entry; D1 = START
  AD1EX C=DAT1.A		% Ca = addr of middle entry; Aa = START
  
  ?A=B.A EXIT			% START = END; see if we have match
  ?D<=C.A -> .adjend		% our addr is smaller than middle entry
  A+B.A ASRB.A A+1.A UPNC	% START = MID+1 = (START+END)/2 + 1
  *.adjend
  B+A.A BSRB.A UPNC		% END = MID = (START+END)/2
}
D1+5 CDEX.A ?C#D.A RTY RTN	% D1 -> entry length; CC if match

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% purpose: initiate a find by start of name search and find the first entry
% Input: D1 point on the text to find, Ba: nb chr in text to find
% output: everything is initialized
%         carry if no entry found
%         no carry and D0 point on the size of a name meeting the description
% uses RSTK2, Aw, Ba, Cw, D0
*_FindFirst
A=PC *.labelhere LC(5)_table-.labelhere+#15 A+C.A D0=A C=DAT0.A A+C.A D0=A

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% purpose: find the next entry meeting the description
% Input: D1 point on the text to find, Ba: nb chr in text to find, D0 point after the last found entry
% output: everything is initialized
%         carry if no entry found
%         no carry and D0 point on the size of a name meeting the description
% uses RSTK2, Aw, Ba, Cw, D0
*_FindNext
D0+5 ?B=0.A                                        % skip the last found entry, test for nul string
{                                                  % we are facing a  non null search string
  C=0.A D1-2 C=DAT1.4 D1+2 A=0.A                   % Cb2=1st chr of the name
  {
    A=DAT0.4 ?A=0.B RTY C=A.B                      % A: entry size. and 1st chr. End of list?
    ?A<B.B -> .skip                                % if the number of chr of this entry if < than the string we are looking at, not worth looking...
    ?A>C.A RTY                                     % if the current entry 1st chr is > than the match string, finish
    ?A#C.A -> .skip                                % if the current entry 1st chr is < than the match string, skip it
    D0+2 A=B.B C=B.B GOSBVL CompareACbBytes EXITNC % compare. if they are equal, it's finish
    C=0.A C=DAT1.4 D1+2 C=DAT0.B                   % reload 1st chr in Cb2 and continue
    *.skip A=0.A A=C.B A+A.A CD0EX C+A.A CD0EX D0+7 UPNC % skip the entry
  }
  A=B.A A+A.A CD0EX C-A.A CD0EX CD1EX C-A.A CD1EX D0-2 RTNCC % go back at the begining of the texts
}
A=DAT0.B ?A=0.B RTY RTN

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% purpose: initiate a find by start of name search and find the first entry
% Input: Cw contain the string to find (Cs contains the number of nibbles to compare -1 (P))
% output: everything is initialized
%         carry if no entry found
%         no carry and D0 point on the size of a name meeting the description
% uses RSTK2, Aw, Bw, Cw, D0
*_FindFirstNear
B=C.W A=PC *.labelhere2 LC(5)_table-.labelhere2+#15 A+C.A D0=A C=DAT0.A A+C.A D0=A

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% purpose: find the next entry meeting the description
% Input: Bw contain the string to find, D0 point after the last found entry
% output: everything is initialized
%         carry if no entry found
%         no carry and D0 point on the size of a name meeting the description
% uses RSTK2, Aw, Bw, Cw, D0
*_FindNextNear
D0+5                                               % skip the last found entry
{
  C=0.A C=DAT0.B ?C=0.B RTY                        % C: entry size. End of list?
  C=B.S P=C.15                                     % get size to compare on in P
  C+C.A C=-C.A C+P+1 SKC                           % ensure the entry is at least as big as the seach string
  {
    C=-C.A CSRB.A                                  % get number of chr to look test (nb chr entry - nb chr to compare)
    CD0EX RSTK=C CD0EX D0+2                        % save entry start and point on the text
    {
      A=DAT0.WP ?A=B.WP EXIT3                      % found it?
      D0+2 C-1.B UPNC                              % one less compare to do
    }
    C=RSTK D0=C                                    % restore D0 point on entry
  }
  P=0 C=0.A C=DAT0.B AD0EX A+C.A A+C.A AD0EX D0+7 UPNC % skip the entry
}
P=0 C=RSTK D0=C RTNCC                              % Found it! go back at the begining of the texts

ENDCODE

****************************************************
* Get the value of an entry from it's address
* Input:
*   1: "Name"
* Output:
*   1: # value h / error
****************************************************
ASSEMBLE
        CON(1)        8                * Tell parser 'Non algebraic'
RPL
xNAME GETADR
::
  CK1&Dispatch
  str :: getadr case #>HXS # 10201 DO#EXIT ;
;

****************************************************
* Get the name of an entry from it's address
* Input:
*   1: # value h
* Output:
*   1: "NAME" / error
****************************************************
ASSEMBLE
        CON(1)        8                * Tell parser 'Non algebraic'
RPL
xNAME GETNAME
::
  CK1&Dispatch
  hxs :: HXS># getname ?SEMI # 10201 DO#EXIT ;
;

****************************************************
* Get a list of entry starting with this chars
* Input:
*   1: "StartChars"
* Output:
*   1: { "NAMES" }
****************************************************
ASSEMBLE
        CON(1)        8                * Tell parser 'Non algebraic'
RPL
xNAME GETNAMES
::
  CK1&Dispatch
  str getnames
;

****************************************************
* Get a list of entry starting with this chars
* Input:
*   1: "StartChars"
* Output:
*   1: { "NAMES" }
****************************************************
ASSEMBLE
        CON(1)        8                * Tell parser 'Non algebraic'
RPL
xNAME GETNEAR
::
  CK1&Dispatch
  str :: ONE SEVEN SUB$ getnear ;
;

****************************************************
* Get the value of an entry from it's address
* Input:
*   1: "Name"
* Output if entry exists:
*   2: #value
*   1: true
* Output if entry does not exists:
*   1: false
****************************************************
NULLNAME getadr
CODEM
  A=DAT1.A D1+5 D+1.A SAVE                    % pop the string
  D0=A D0+5 C=DAT0.A C-5.A                    % Ca: string size
  B=0.A B=C.B ?B=C.A { LOAD LC 10202 GOVLNG ErrjmpC } % test if the string is > 128 ch
  D0+5 D1=(5)_TempArea GOSBVL MOVEDOWN        % copy the string in temparea
  D1=(5)ROMPTAB+#3 LC 102                     % ready to look in the lib table for lib 102
  { A=DAT1.X D1+16 ?C#A.X UP }                % look for it
  D1-8 C=DAT1.A D=C.A D1-5 C=DAT1.A D1=C      % D: access routine, C: @header
  ?D=0.A { C=D.A GOSUB .pcIsC }               % switch if needed
  D1+13 A=DAT1.A                              % go to link table
  CD1EX A+C.A A+10.A D1=A C=DAT1.A C+A.A C+20.A GOSUB .pcIsC % jump to the InitTableCode
  C=B.A D=C.A DSRB.A GOSBVL _GetAdrJmp        % look for the entry
  SKNC { P=1 GOSBVL _SwitchAdr LOAD GOVLNG PushFLoop } % if error, restore view, push false and bye.
  R0=C.W P=1 GOSBVL _SwitchAdr LOAD A=C.A GOVLNG Push#TLoop % else, restore, push the SB and true and bye.
  *.pcIsC PC=C
ENDCODE

****************************************************
* Get a list of entry starting with this chars
* Input:
*   1: "StartChars"
* Output:
*   1: { "NAMES" }
****************************************************
NULLNAME getnames
:: ERRSET getnames2 ERRTRAP :: GARBAGE getnames2 ; ;

NULLNAME getnames2
CODEM
  SAVE
  GOSBVL MAKERAM$ C=D.A RSTK=C CD0EX R1=C.A   % get some ram! RSTK=free memory R1: string
  D1=(5)ROMPTAB+#3 LC 102                     % ready to look in the lib table for lib 102
  { A=DAT1.X D1+16 ?C#A.X UP }                % look for it
  D1-8 C=DAT1.A D=C.A D1-5 C=DAT1.A D1=C      % D: access routine, C: @header
  ?D=0.A { C=D.A GOSUB .pcIsC3 }              % switch if needed
  D1+13 A=DAT1.A                              % go to link table
  CD1EX A+C.A A+10.A D1=A C=DAT1.A C+A.A C+20.A GOSUB .pcIsC3 % jump to the InitTableCode
  C=RSTK D=C.A                                % Da: memory
  GOSBVL D1=DSKTOP C=DAT1.A D1=C              % D1 point on the string
  D1+5 C=DAT1.A C-5.A CSRB.A B=C.A D1+5       % D1: string text, Ba: nb chr in string
  GOSBVL _FindFirstJmp SKC                    % init the stuff,
  {
    AD1EX AR1EX.A AD1EX                       % D1 point on the output
    D-10.A GOC .mem                           % get some mem for the string prolog
    LC(5)DOCSTR DAT1=C.A D1+5                 % write string prolog
    C=0.A C=DAT0.B C+C.A D-C.A GOC .mem       % get mem and for the data
    C+5.A DAT1=C.A C-5.A D1+5                 % write string length
    D0+2 GOSBVL MOVEDOWN                      % copy the text
    AD1EX AR1EX.W AD1EX                       % restore D1
    GOSBVL _FindNextJmp UPNC                  % and continue the search
  }
  P=1 GOSBVL _SwitchAdr                       % swith on base port
  C=R1.A D0=C GOSBVL Shrink$List LOAD A=R0.A DAT1=A.A RPL % shrink the list, and push
  *.mem LOAD GOVLNG DOMEMERR                  % memory error
  *.pcIsC3 PC=C
ENDCODE

****************************************************
* Get the name of an entry from it's address
* Input:
*   1: #value
* Output if entry exists:
*   2: "NAME"
*   1: true
* Output if entry does not exists:
*   1: false
****************************************************
NULLNAME getname
CODEM
  GOSBVL POP# R0=A.W SAVE                     % pop the SB
  D1=(5)ROMPTAB+#3 LC 102                     % ready to look in the lib table for lib 102
  { A=DAT1.X D1+16 ?C#A.X UP }                % look for it
  D1-8 C=DAT1.A D=C.A D1-5 C=DAT1.A D1=C      % D: access routine, C: @header
  ?D=0.A { C=D.A GOSUB .pcIsC2 }              % switch if needed
  D1+13 A=DAT1.A                              % go to link table
  CD1EX A+C.A A+10.A D1=A C=DAT1.A C+A.A C+20.A GOSUB .pcIsC2 % jump to the InitTableCode
  C=R0.W GOSBVL _GetNameJmp                   % look for the entry
  SKNC { P=1 GOSBVL _SwitchAdr LOAD GOVLNG PushFLoop } % if error, restore view, push false and bye.
  CD1EX D0=C C=0.A C=DAT0.B C+1.B C+C.A D1=(5)_TempArea GOSBVL MOVEDOWN % copy the entry in temp area
  P=1 GOSBVL _SwitchAdr                       % swith on base port
  D0=(5)_TempArea C=0.A C=DAT0.B C+C.A GOSBVL MAKE$N % get a string
  CD0EX CD1EX D0=(5)_TempArea C=0.A C=DAT0.B C+C.A D0+2 GOSBVL MOVEDOWN % copy the entry in the string
  LOAD A=R0.A D1-5 D-1.A DAT1=A.A GOSBVL PushTLoop % push the string and a true
  *.pcIsC2 PC=C
ENDCODE

****************************************************
* Get a list of entry containing this chars
* Input:
*   1: "Chars"
* Output:
*   1: { "NAMES" }
****************************************************
NULLNAME getnear
:: ERRSET getnear2 ERRTRAP :: GARBAGE getnear2 ; ;

NULLNAME getnear2
CODEM *asmgetnear
  SAVE
  GOSBVL MAKERAM$ C=D.A RSTK=C CD0EX R1=C.A   % get some ram! RSTK=free memory R1: string
  D1=(5)ROMPTAB+#3 LC 102                     % ready to look in the lib table for lib 102
  { A=DAT1.X D1+16 ?C#A.X UP }                % look for it
  D1-8 C=DAT1.A D=C.A D1-5 C=DAT1.A D1=C      % D: access routine, C: @header
  ?D=0.A { C=D.A GOSUB .pcIsC3 }              % switch if needed
  D1+13 A=DAT1.A                              % go to link table
  CD1EX A+C.A A+10.A D1=A C=DAT1.A C+A.A C+20.A GOSUB .pcIsC3 % jump to the InitTableCode
  C=RSTK D=C.A                                % Da: memory
  GOSBVL D1=DSKTOP C=DAT1.A D1=C              % D1 point on the string
  D1+5 C=DAT1.A C-6.A P=C.0 D1+5 C=DAT1.WP C=P.15 P=0 % Cw: text and P in Cs
  GOSBVL _FindFirstNearJmp SKC                % init the stuff,
  {
    AD1EX AR1EX.A AD1EX                       % D1 point on the output
    D-10.A GOC .mem                           % get some mem for the string prolog
    LC(5)DOCSTR DAT1=C.A D1+5                 % write string prolog
    C=0.A C=DAT0.B C+C.A D-C.A GOC .mem       % get mem and for the data
    C+5.A DAT1=C.A C-5.A D1+5                 % write string length
    D0+2 GOSBVL MOVEDOWN                      % copy the text
    AD1EX AR1EX.W AD1EX                       % restore D1
    GOSBVL _FindNextNearJmp UPNC              % and continue the search
  }
  P=1 GOSBVL _SwitchAdr                       % swith on base port
  C=R1.A D0=C GOSBVL Shrink$List LOAD A=R0.A DAT1=A.A RPL % shrink the list, and push
  *.mem LOAD GOVLNG DOMEMERR                  % memory error
  *.pcIsC3 PC=C
ENDCODE

****************************************************
* This is an include of the table itself
****************************************************
ASSEMBLE
_table
        INCLOB hptab49.hp
RPL

NULLNAME CONFIG
:: # 102 TOSRRP # 100 TOSRRP ;
