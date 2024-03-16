Saturn Assembler                                       Thu Aug 12 19:50:24 2010
V3.0.9 (04/15/2007)                                      extablefile.a  Page    1

    1               * File  extablefile.s   1
    2               * RPL
    3               * Ensure RPLCOMP and the syntax highlighter are in RPL mode
    4               * File  extablefile.s   2
    5               * extablefile.s, part of the extablefile.s project, created by Cyrille de brebisson on 17/09/99
    6               * File  extablefile.s   3
    7
    8               * Compilation process.
    9               * In order to create a new extable, you must first create a table
   10               * and store it in a file called table.hp. You can use the tablegenp
   11               * program and the latest suprom49.a to do it.
   12               * Then, just compile this project and you net a new table!
   13               * File  extablefile.s   9
   14
   15               * File  extablefile.s   10
   16               *|| Reading from C:\Documents and Settings\Han\Desktop\jazz\july08\extable\extable.H
   17
   18               =RomId  EQU     #102
   19               * ROMID set to 102
   20
   21
   22               *|| Resuming file extablefile.s at line 10
   23               * File  extablefile.s   12
   24               * This librarie contains and allows access to the external entry table.
   25               * File  extablefile.s   13
   26               * The table has this structure:
   27               * File  extablefile.s   14
   28
   29               * File  extablefile.s   15
   30               * 10 nibbles: strobj prolog and size
   31               * File  extablefile.s   16
   32               * 5 nibbles: nb of entry in the table
   33               * File  extablefile.s   17
   34               * 5 nibbles: offset to the data part of the table
   35               * File  extablefile.s   18
   36               * 128*5 nibbles: offset to the list of entry of crc n
   37               * File  extablefile.s   19
   38               * (where n is the number of this entry in the 64 entry table]
   39               * File  extablefile.s   20
   40               * n*5 nibbles: offsets to the value of the entry n (sorted by address]
   41               * File  extablefile.s   21
   42               * 128*
   43               * File  extablefile.s   22
   44               * n*5 nibbles offset to the entries of same crc. sorted by name lenght then by name
   45               * File  extablefile.s   23
   46               * 00000
   47               * File  extablefile.s   24
   48               * data part
   49               * File  extablefile.s   25
   50               * n*
   51               * File  extablefile.s   26
   52               * 5 nibbles: entry value
   53               * File  extablefile.s   27
   54               * 2 nibbles: entry size in chr
   55               * File  extablefile.s   28
   56               * m*2 nibbles: entry text
   57               * File  extablefile.s   29
   58               * 7 nibbles: 0000000 [end of list]
   59               * File  extablefile.s   30
   60               *
   61               * File  extablefile.s   31
   62
   63               ****************************************************
   64               * This entry does nothing, it's just here to prvide
   65               * an access to the internal asm functions.
   66               ****************************************************
   67               * File  extablefile.s   36
   68               * ASSEMBLE
   69               * File  extablefile.s   37
   70 00000 8               CON(1)        8                * Tell parser 'Non algebraic'
   71               * File  extablefile.s   38
   72               * RPL
   73               * File  extablefile.s   39
   74 00001 000000          CON(6)  =~xnop
   75 00007         =xnop
   76               * File  extablefile.s   40
   77 00007 00000           CON(5)  =DOCODE
   78 0000C 55300           REL(5)  LBL000
   79               * File  extablefile.s   41
   80 00011 142             A=DAT0  A
   81 00014 164             D0=D0+  5
   82 00017 808C            PC=(A)
   83               * File  extablefile.s   42
   84
   85               * File  extablefile.s   43
   86               _MaxLabSize     EQU     #40
   87               * File  extablefile.s   44
   88
   89               * File  extablefile.s   45
   90               _SCREEN EQU     #822B2
   91               * File  extablefile.s   46
   92
   93               * File  extablefile.s   47
   94               _ExpValueStkStart       EQU     #0+_SCREEN
   95               * File  extablefile.s   48
   96               _ExpOpStkStart  EQU     #80+_ExpValueStkStart
   97               * File  extablefile.s   49
   98               _TempAreaStart  EQU     #0+_ExpOpStkStart
   99               * File  extablefile.s   50
  100               _TempAreaEnd    EQU     #5+(_TempAreaStart)
  101               * File  extablefile.s   51
  102               _TempAreaSize   EQU     #5+(_TempAreaEnd)
  103               * File  extablefile.s   52
  104               _TempArea       EQU     #5+(_TempAreaSize)
  105               * File  extablefile.s   53
  106               =PORT2EOS       EQU     #80540
  107               * File  extablefile.s   54
  108               _SwitchAdr      EQU     #0+(PORT2EOS)
  109               * File  extablefile.s   55
  110               _GetAdrJmp      EQU     #7+_SwitchAdr
  111               * File  extablefile.s   56
  112               _GetNameJmp     EQU     #7+7+_SwitchAdr
  113               * File  extablefile.s   57
  114               _FindFirstJmp   EQU     #7+7+7+_SwitchAdr
  115               * File  extablefile.s   58
  116               _FindNextJmp    EQU     #7+7+7+7+_SwitchAdr
  117               * File  extablefile.s   59
  118               _FindFirstNearJmp       EQU     #7+7+7+7+7+_SwitchAdr
  119               * File  extablefile.s   60
  120               _FindNextNearJmp        EQU     #7+7+7+7+7+7+_SwitchAdr
  121               * File  extablefile.s   61
  122               =ROMPTAB        EQU     #8611D
  123               * File  extablefile.s   62
  124
  125               * File  extablefile.s   63
  126               * File  extablefile.s   64
  127               * File  extablefile.s   65
  128               * File  extablefile.s   66
  129               * File  extablefile.s   67
  130               * File  extablefile.s   68
  131               * File  extablefile.s   69
  132               * File  extablefile.s   70
  133               * File  extablefile.s   71
  134               * File  extablefile.s   72
  135               * File  extablefile.s   73
  136               * File  extablefile.s   74
  137               * File  extablefile.s   75
  138               * File  extablefile.s   76
  139               * File  extablefile.s   77
  140               * File  extablefile.s   78
  141               * File  extablefile.s   79
  142               * File  extablefile.s   80
  143               * File  extablefile.s   81
  144               * File  extablefile.s   82
  145               * File  extablefile.s   83
  146
  147               * File  extablefile.s   84
  148               * File  extablefile.s   85
  149 0001B         _TableOffsets
  150               * File  extablefile.s   86
  151 0001B 6800            GOTO    _InitTable
  152               * File  extablefile.s   87
  153 0001F B7900           CON(5)  ((_table)-(*))+10
  154               * File  extablefile.s   88
  155
  156               * File  extablefile.s   89
  157               * File  extablefile.s   90
  158               * File  extablefile.s   91
  159               * File  extablefile.s   92
  160 00024         _InitTable
  161               * File  extablefile.s   93
  162 00024 DB              C=D     A
  163 00026 1B24508         D0=(5)  (_SwitchAdr)+2
  164 0002D 144             DAT0=C  A
  165 00030 181             D0-     2
  166               * File  extablefile.s   94
  167 00033 318D            LCHEX   D8
  168 00037 14C             DAT0=C  B
  169 0003A 8AF             ?D#0    A
  170 0003D C0              SKIPYES{
  171 0003F 332001          LCHEX   1002
  172 00045 15C3            DAT0=C  4
  173                       }
  174 00049 166             D0+     7
  175               * File  extablefile.s   95
  176 0004C 318D            LCHEX   D8
  177 00050 14C             DAT0=C  B
  178 00053 161             D0+     2
  179               * File  extablefile.s   96
  180 00056 81B4            A=PC
  181 0005A 34F9000         LC(5)   ((_GetAdr)-(*))
  182 00061 CA              A=A+C   A
  183 00063 140             DAT0=A  A
  184 00066 164             D0+     5
  185               * File  extablefile.s   97
  186 00069 318D            LCHEX   D8
  187 0006D 14C             DAT0=C  B
  188 00070 161             D0+     2
  189               * File  extablefile.s   98
  190 00073 81B4            A=PC
  191 00077 34B4100         LC(5)   ((_GetName)-(*))
  192 0007E CA              A=A+C   A
  193 00080 140             DAT0=A  A
  194 00083 164             D0+     5
  195               * File  extablefile.s   99
  196 00086 318D            LCHEX   D8
  197 0008A 14C             DAT0=C  B
  198 0008D 161             D0+     2
  199               * File  extablefile.s   100
  200 00090 81B4            A=PC
  201 00094 34BA100         LC(5)   ((_FindFirst)-(*))
  202 0009B CA              A=A+C   A
  203 0009D 140             DAT0=A  A
  204 000A0 164             D0+     5
  205               * File  extablefile.s   101
  206 000A3 318D            LCHEX   D8
  207 000A7 14C             DAT0=C  B
  208 000AA 161             D0+     2
  209               * File  extablefile.s   102
  210 000AD 81B4            A=PC
  211 000B1 346A100         LC(5)   ((_FindNext)-(*))
  212 000B8 CA              A=A+C   A
  213 000BA 140             DAT0=A  A
  214 000BD 164             D0+     5
  215               * File  extablefile.s   103
  216 000C0 318D            LCHEX   D8
  217 000C4 14C             DAT0=C  B
  218 000C7 161             D0+     2
  219               * File  extablefile.s   104
  220 000CA 81B4            A=PC
  221 000CE 3411200         LC(5)   ((_FindFirstNear)-(*))
  222 000D5 CA              A=A+C   A
  223 000D7 140             DAT0=A  A
  224 000DA 164             D0+     5
  225               * File  extablefile.s   105
  226 000DD 318D            LCHEX   D8
  227 000E1 14C             DAT0=C  B
  228 000E4 161             D0+     2
  229               * File  extablefile.s   106
  230 000E7 81B4            A=PC
  231 000EB 34F0200         LC(5)   ((_FindNextNear)-(*))
  232 000F2 CA              A=A+C   A
  233 000F4 140             DAT0=A  A
  234               * File  extablefile.s   107
  235 000F7 03              RTNCC
  236               * File  extablefile.s   108
  237
  238               * File  extablefile.s   109
  239               * File  extablefile.s   110
  240               * File  extablefile.s   111
  241               * File  extablefile.s   112
  242               * File  extablefile.s   113
  243               * File  extablefile.s   114
  244               * File  extablefile.s   115
  245 000F9         _GetAdr
  246               * File  extablefile.s   116
  247 000F9 1F14328         D1=(5)  (_TempArea)
  248               * File  extablefile.s   117
  249 00100 D1              B=0     A
  250 00102 AEB             C=D     B
  251 00105 A6E             C=C-    1       B
  252 00108 400             RTNC
  253               * File  extablefile.s   118
  254                       {
  255 0010B 14B             A=DAT1  B
  256 0010E A68             B=B+A   B
  257 00111 171             D1+     2
  258 00114 A6E             C=C-    1       B
  259 00117 53F             UPNC
  260               * File  extablefile.s   119
  261                       }
  262 0011A 34F7000         LCHEX   0007F
  263 00121 0EF5            C=C&B   A
  264               * File  extablefile.s   120
  265 00125 81B4            A=PC
  266 00129         _l1
  267 00129 CA              A=A+C   A
  268 0012B C6              C=C+C   A
  269 0012D C6              C=C+C   A
  270 0012F CA              A=A+C   A
  271               * File  extablefile.s   121
  272 00131 34B7800         LC(5)   (_table)-(_l1)+20
  273 00138 CA              A=A+C   A
  274 0013A 131             D1=A
  275               * File  extablefile.s   122
  276 0013D 147             C=DAT1  A
  277 00140 CA              A=A+C   A
  278 00142 131             D1=A
  279 00145 D8              B=A     A
  280               * File  extablefile.s   123
  281 00147 1BF3328         D0=(5)  (_TempArea)-2
  282               * File  extablefile.s   124
  283 0014E D2              C=0     A
  284 00150 15E3            C=DAT0  4
  285 00154 AEB             C=D     B
  286 00157 D7              D=C     A
  287               * File  extablefile.s   125
  288                       {
  289               * File  extablefile.s   126
  290 00159 143             A=DAT1  A
  291 0015C 8A8             ?A=0    A
  292 0015F 00              RTNYES
  293               * File  extablefile.s   127
  294 00161 C0              A=A+B   A
  295 00163 130             D0=A
  296               * File  extablefile.s   128
  297 00166 174             D1+     5
  298 00169 818F14          B=B+    5       A
  299               * File  extablefile.s   129
  300 0016F D2              C=0     A
  301 00171 15E3            C=DAT0  4
  302               * File  extablefile.s   130
  303 00175 9E3             ?C<D    B
  304 00178 1E              UP
  305               * File  extablefile.s   131
  306 0017A 9E7             ?C>D    B
  307 0017D 00              RTNYES
  308               * File  extablefile.s   132
  309 0017F 8B3             ?C<D    A
  310 00182 7D              UP
  311 00184 8B7             ?C>D    A
  312 00187 00              RTNYES
  313               * File  extablefile.s   133
  314 00189 1F14328         D1=(5)  (_TempArea)
  315 00190 161             D0+     2
  316 00193 AEA             A=C     B
  317               * File  extablefile.s   134
  318 00196 8F00000         GOSBVL  =CompareACbBytes
  319 0019D 5B0             EXITNC
  320               * File  extablefile.s   135
  321 001A0 D4              A=B     A
  322 001A2 131             D1=A
  323 001A5 63BF            UP
  324               * File  extablefile.s   136
  325               * File  extablefile.s   137
  326                       }
  327 001A9 D2              C=0     A
  328 001AB AEB             C=D     B
  329 001AE D7              D=C     A
  330 001B0 136             CD0EX
  331 001B3 EB              C=C-D   A
  332 001B5 EB              C=C-D   A
  333 001B7 136             CD0EX
  334 001BA 186             D0-     7
  335 001BD 146             C=DAT0  A
  336 001C0 03              RTNCC
  337               * File  extablefile.s   138
  338
  339               * File  extablefile.s   139
  340               * File  extablefile.s   140
  341               * File  extablefile.s   141
  342               * File  extablefile.s   142
  343               * File  extablefile.s   143
  344               * File  extablefile.s   144
  345               * File  extablefile.s   145
  346               * File  extablefile.s   146
  347               * File  extablefile.s   147
  348               * File  extablefile.s   148
  349               * File  extablefile.s   149
  350               * File  extablefile.s   150
  351               * File  extablefile.s   151
  352 001C2         _GetName
  353               * File  extablefile.s   152
  354 001C2 D7              D=C     A
  355 001C4 D1              B=0     A
  356               * File  extablefile.s   153
  357 001C6 81B4            A=PC
  358 001CA         _113
  359 001CA 340D700         LC(5)   (_table)-(_113)+10
  360               * File  extablefile.s   154
  361 001D1 CA              A=A+C   A
  362 001D3 131             D1=A
  363 001D6 143             A=DAT1  A
  364 001D9 CC              A=A-    1       A
  365               * File  extablefile.s   155
  366 001DB DC              ABEX    A
  367               * File  extablefile.s   156
  368                       {
  369               * File  extablefile.s   157
  370 001DD 133             AD1EX
  371               * File  extablefile.s   158
  372 001E0 81B4            A=PC
  373 001E4         _111
  374 001E4 3404A00         LC(5)   ((_table)-(_111)+20+(128)*5)
  375               * File  extablefile.s   159
  376 001EB CA              A=A+C   A
  377               * File  extablefile.s   160
  378 001ED 137             CD1EX
  379 001F0 135             D1=C
  380 001F3 C9              C=C+B   A
  381 001F5 819F2           CSRB.f  A
  382               * File  extablefile.s   161
  383 001FA CA              A=A+C   A
  384 001FC C6              C=C+C   A
  385 001FE C6              C=C+C   A
  386 00200 CA              A=A+C   A
  387               * File  extablefile.s   162
  388 00202 133             AD1EX
  389 00205 147             C=DAT1  A
  390 00208 133             AD1EX
  391 0020B CA              A=A+C   A
  392               * File  extablefile.s   163
  393 0020D 133             AD1EX
  394 00210 147             C=DAT1  A
  395               * File  extablefile.s   164
  396
  397               * File  extablefile.s   165
  398 00213 8A0             ?A=B    A
  399 00216 D1              EXIT
  400               * File  extablefile.s   166
  401 00218 8BF             ?D<=C   A
  402 0021B E0              GOYES   .adjend
  403               * File  extablefile.s   167
  404 0021D C0              A=A+B   A
  405 0021F 819F0           ASRB.f  A
  406 00224 E4              A=A+    1       A
  407 00226 56B             UPNC
  408               * File  extablefile.s   168
  409 00229         .adjend
  410               * File  extablefile.s   169
  411 00229 C8              B=B+A   A
  412 0022B 819F1           BSRB.f  A
  413 00230 5CA             UPNC
  414               * File  extablefile.s   170
  415               * File  extablefile.s   171
  416                       }
  417 00233 174             D1+     5
  418 00236 DF              CDEX    A
  419 00238 8A7             ?C#D    A
  420 0023B 00              RTNYES
  421 0023D 01              RTN
  422               * File  extablefile.s   172
  423
  424               * File  extablefile.s   173
  425               * File  extablefile.s   174
  426               * File  extablefile.s   175
  427               * File  extablefile.s   176
  428               * File  extablefile.s   177
  429               * File  extablefile.s   178
  430               * File  extablefile.s   179
  431               * File  extablefile.s   180
  432 0023F         _FindFirst
  433               * File  extablefile.s   181
  434 0023F 81B4            A=PC
  435 00243         .labelhere
  436 00243 34C5700         LC(5)   (_table)-(.labelhere)+15
  437 0024A CA              A=A+C   A
  438 0024C 130             D0=A
  439 0024F 146             C=DAT0  A
  440 00252 CA              A=A+C   A
  441 00254 130             D0=A
  442               * File  extablefile.s   182
  443
  444               * File  extablefile.s   183
  445               * File  extablefile.s   184
  446               * File  extablefile.s   185
  447               * File  extablefile.s   186
  448               * File  extablefile.s   187
  449               * File  extablefile.s   188
  450               * File  extablefile.s   189
  451               * File  extablefile.s   190
  452 00257         _FindNext
  453               * File  extablefile.s   191
  454 00257 164             D0+     5
  455               * File  extablefile.s   192
  456 0025A 8A9             ?B=0    A
  457 0025D 87              SKIPYES{
  458               * File  extablefile.s   193
  459 0025F D2              C=0     A
  460 00261 1C1             D1-     2
  461 00264 15F3            C=DAT1  4
  462 00268 171             D1+     2
  463 0026B D0              A=0     A
  464               * File  extablefile.s   194
  465                       {
  466               * File  extablefile.s   195
  467 0026D 15A3            A=DAT0  4
  468 00271 968             ?A=0    B
  469 00274 00              RTNYES
  470 00276 AE6             C=A     B
  471               * File  extablefile.s   196
  472 00279 9E4             ?A<B    B
  473 0027C B2              GOYES   .skip
  474               * File  extablefile.s   197
  475 0027E 8B6             ?A>C    A
  476 00281 00              RTNYES
  477               * File  extablefile.s   198
  478 00283 8A6             ?A#C    A
  479 00286 12              GOYES   .skip
  480               * File  extablefile.s   199
  481 00288 161             D0+     2
  482 0028B AE4             A=B     B
  483 0028E AE9             C=B     B
  484 00291 8F00000         GOSBVL  =CompareACbBytes
  485 00298 532             EXITNC
  486               * File  extablefile.s   200
  487 0029B D2              C=0     A
  488 0029D 15F3            C=DAT1  4
  489 002A1 171             D1+     2
  490 002A4 14E             C=DAT0  B
  491               * File  extablefile.s   201
  492 002A7         .skip
  493 002A7 D0              A=0     A
  494 002A9 AEA             A=C     B
  495 002AC C4              A=A+A   A
  496 002AE 136             CD0EX
  497 002B1 C2              C=C+A   A
  498 002B3 136             CD0EX
  499 002B6 166             D0+     7
  500 002B9 53B             UPNC
  501               * File  extablefile.s   202
  502               * File  extablefile.s   203
  503                       }
  504 002BC D4              A=B     A
  505 002BE C4              A=A+A   A
  506 002C0 136             CD0EX
  507 002C3 E2              C=C-A   A
  508 002C5 136             CD0EX
  509 002C8 137             CD1EX
  510 002CB E2              C=C-A   A
  511 002CD 137             CD1EX
  512 002D0 181             D0-     2
  513 002D3 03              RTNCC
  514               * File  extablefile.s   204
  515               * File  extablefile.s   205
  516                       }
  517 002D5 14A             A=DAT0  B
  518 002D8 968             ?A=0    B
  519 002DB 00              RTNYES
  520 002DD 01              RTN
  521               * File  extablefile.s   206
  522
  523               * File  extablefile.s   207
  524               * File  extablefile.s   208
  525               * File  extablefile.s   209
  526               * File  extablefile.s   210
  527               * File  extablefile.s   211
  528               * File  extablefile.s   212
  529               * File  extablefile.s   213
  530               * File  extablefile.s   214
  531 002DF         _FindFirstNear
  532               * File  extablefile.s   215
  533 002DF AF5             B=C     W
  534 002E2 81B4            A=PC
  535 002E6         .labelhere2
  536 002E6 349B600         LC(5)   (_table)-(.labelhere2)+15
  537 002ED CA              A=A+C   A
  538 002EF 130             D0=A
  539 002F2 146             C=DAT0  A
  540 002F5 CA              A=A+C   A
  541 002F7 130             D0=A
  542               * File  extablefile.s   216
  543
  544               * File  extablefile.s   217
  545               * File  extablefile.s   218
  546               * File  extablefile.s   219
  547               * File  extablefile.s   220
  548               * File  extablefile.s   221
  549               * File  extablefile.s   222
  550               * File  extablefile.s   223
  551               * File  extablefile.s   224
  552 002FA         _FindNextNear
  553               * File  extablefile.s   225
  554 002FA 164             D0+     5
  555               * File  extablefile.s   226
  556                       {
  557               * File  extablefile.s   227
  558 002FD D2              C=0     A
  559 002FF 14E             C=DAT0  B
  560 00302 96A             ?C=0    B
  561 00305 00              RTNYES
  562               * File  extablefile.s   228
  563 00307 AC9             C=B     S
  564 0030A 80DF            P=C     15
  565               * File  extablefile.s   229
  566 0030E C6              C=C+C   A
  567 00310 FA              C=-C    A
  568 00312 809             C+P+1
  569               * File  extablefile.s   230
  570 00315 4B2             SKIPC{
  571               * File  extablefile.s   231
  572 00318 FA              C=-C    A
  573 0031A 819F2           CSRB.f  A
  574               * File  extablefile.s   232
  575 0031F 136             CD0EX
  576 00322 06              RSTK=C
  577 00324 136             CD0EX
  578 00327 161             D0+     2
  579               * File  extablefile.s   233
  580                       {
  581               * File  extablefile.s   234
  582 0032A 1521            A=DAT0  WP
  583 0032E 910             ?A=B    WP
  584 00331 72              EXIT3
  585               * File  extablefile.s   235
  586 00333 161             D0+     2
  587 00336 A6E             C=C-    1       B
  588 00339 50F             UPNC
  589               * File  extablefile.s   236
  590               * File  extablefile.s   237
  591                       }
  592 0033C 07              C=RSTK
  593 0033E 134             D0=C
  594               * File  extablefile.s   238
  595               * File  extablefile.s   239
  596                       }
  597 00341 20              P=      0
  598 00343 D2              C=0     A
  599 00345 14E             C=DAT0  B
  600 00348 132             AD0EX
  601 0034B CA              A=A+C   A
  602 0034D CA              A=A+C   A
  603 0034F 132             AD0EX
  604 00352 166             D0+     7
  605 00355 57A             UPNC
  606               * File  extablefile.s   240
  607               * File  extablefile.s   241
  608                       }
  609 00358 20              P=      0
  610 0035A 07              C=RSTK
  611 0035C 134             D0=C
  612 0035F 03              RTNCC
  613               * File  extablefile.s   242
  614
  615               * File  extablefile.s   243
  616 00361         LBL000
  617               * File  extablefile.s   244
  618
  619               ****************************************************
  620               * Get the value of an entry from it's address
  621               * Input:
  622               *   1: "Name"
  623               * Output:
  624               *   1: # value h / error
  625               ****************************************************
  626               * File  extablefile.s   252
  627               * ASSEMBLE
  628               * File  extablefile.s   253
  629 00361 8               CON(1)        8                * Tell parser 'Non algebraic'
  630               * File  extablefile.s   254
  631               * RPL
  632               * File  extablefile.s   255
  633 00362 000000          CON(6)  =~xGETADR
  634 00368         =xGETADR
  635               * File  extablefile.s   256
  636 00368 00000           CON(5)  =DOCOL
  637               * File  extablefile.s   257
  638 0036D 00000           CON(5)  =CK1&Dispatch
  639               * File  extablefile.s   258
  640 00372 00000           CON(5)  =str
  641 00377 00000           CON(5)  =DOCOL
  642 0037C 00000           CON(5)  =DOROMP
  643 00381 000000          CON(6)  =~getadr
  644 00387 00000           CON(5)  =case
  645 0038C 00000           CON(5)  =#>HXS
  646 00391 00000           CON(5)  =DOBINT
  647 00396 10201           CON(5)  #10201
  648 0039B 00000           CON(5)  =DO#EXIT
  649 003A0 00000           CON(5)  =SEMI
  650               * File  extablefile.s   259
  651 003A5 00000           CON(5)  =SEMI
  652               * File  extablefile.s   260
  653
  654               ****************************************************
  655               * Get the name of an entry from it's address
  656               * Input:
  657               *   1: # value h
  658               * Output:
  659               *   1: "NAME" / error
  660               ****************************************************
  661               * File  extablefile.s   268
  662               * ASSEMBLE
  663               * File  extablefile.s   269
  664 003AA 8               CON(1)        8                * Tell parser 'Non algebraic'
  665               * File  extablefile.s   270
  666               * RPL
  667               * File  extablefile.s   271
  668 003AB 000000          CON(6)  =~xGETNAME
  669 003B1         =xGETNAME
  670               * File  extablefile.s   272
  671 003B1 00000           CON(5)  =DOCOL
  672               * File  extablefile.s   273
  673 003B6 00000           CON(5)  =CK1&Dispatch
  674               * File  extablefile.s   274
  675 003BB 00000           CON(5)  =hxs
  676 003C0 00000           CON(5)  =DOCOL
  677 003C5 00000           CON(5)  =HXS>#
  678 003CA 00000           CON(5)  =DOROMP
  679 003CF 000000          CON(6)  =~getname
  680 003D5 00000           CON(5)  =?SEMI
  681 003DA 00000           CON(5)  =DOBINT
  682 003DF 10201           CON(5)  #10201
  683 003E4 00000           CON(5)  =DO#EXIT
  684 003E9 00000           CON(5)  =SEMI
  685               * File  extablefile.s   275
  686 003EE 00000           CON(5)  =SEMI
  687               * File  extablefile.s   276
  688
  689               ****************************************************
  690               * Get a list of entry starting with this chars
  691               * Input:
  692               *   1: "StartChars"
  693               * Output:
  694               *   1: { "NAMES" }
  695               ****************************************************
  696               * File  extablefile.s   284
  697               * ASSEMBLE
  698               * File  extablefile.s   285
  699 003F3 8               CON(1)        8                * Tell parser 'Non algebraic'
  700               * File  extablefile.s   286
  701               * RPL
  702               * File  extablefile.s   287
  703 003F4 000000          CON(6)  =~xGETNAMES
  704 003FA         =xGETNAMES
  705               * File  extablefile.s   288
  706 003FA 00000           CON(5)  =DOCOL
  707               * File  extablefile.s   289
  708 003FF 00000           CON(5)  =CK1&Dispatch
  709               * File  extablefile.s   290
  710 00404 00000           CON(5)  =str
  711 00409 00000           CON(5)  =DOROMP
  712 0040E 000000          CON(6)  =~getnames
  713               * File  extablefile.s   291
  714 00414 00000           CON(5)  =SEMI
  715               * File  extablefile.s   292
  716
  717               ****************************************************
  718               * Get a list of entry starting with this chars
  719               * Input:
  720               *   1: "StartChars"
  721               * Output:
  722               *   1: { "NAMES" }
  723               ****************************************************
  724               * File  extablefile.s   300
  725               * ASSEMBLE
  726               * File  extablefile.s   301
  727 00419 8               CON(1)        8                * Tell parser 'Non algebraic'
  728               * File  extablefile.s   302
  729               * RPL
  730               * File  extablefile.s   303
  731 0041A 000000          CON(6)  =~xGETNEAR
  732 00420         =xGETNEAR
  733               * File  extablefile.s   304
  734 00420 00000           CON(5)  =DOCOL
  735               * File  extablefile.s   305
  736 00425 00000           CON(5)  =CK1&Dispatch
  737               * File  extablefile.s   306
  738 0042A 00000           CON(5)  =str
  739 0042F 00000           CON(5)  =DOCOL
  740 00434 00000           CON(5)  =ONE
  741 00439 00000           CON(5)  =SEVEN
  742 0043E 00000           CON(5)  =SUB$
  743 00443 00000           CON(5)  =DOROMP
  744 00448 000000          CON(6)  =~getnear
  745 0044E 00000           CON(5)  =SEMI
  746               * File  extablefile.s   307
  747 00453 00000           CON(5)  =SEMI
  748               * File  extablefile.s   308
  749
  750               ****************************************************
  751               * Get the value of an entry from it's address
  752               * Input:
  753               *   1: "Name"
  754               * Output if entry exists:
  755               *   2: #value
  756               *   1: true
  757               * Output if entry does not exists:
  758               *   1: false
  759               ****************************************************
  760               * File  extablefile.s   319
  761 00458         =getadr
  762               * File  extablefile.s   320
  763 00458 00000           CON(5)  =DOCODE
  764 0045D AF000           REL(5)  LBL001
  765               * File  extablefile.s   321
  766 00462 143             A=DAT1  A
  767 00465 174             D1+     5
  768 00468 E7              D=D+    1       A
  769 0046A 8F00000         GOSBVL  =SAVPTR
  770               * File  extablefile.s   322
  771 00471 130             D0=A
  772 00474 164             D0+     5
  773 00477 146             C=DAT0  A
  774 0047A 818FA4          C=C-    5       A
  775               * File  extablefile.s   323
  776 00480 D1              B=0     A
  777 00482 AE5             B=C     B
  778 00485 8A1             ?B=C    A
  779 00488 71              SKIPYES{
  780 0048A 8F00000         GOSBVL  =GETPTR
  781 00491 3420201         LCHEX   10202
  782 00498 8D00000         GOVLNG  =ErrjmpC
  783               * File  extablefile.s   324
  784                       }
  785 0049F 164             D0+     5
  786 004A2 1F14328         D1=(5)  (_TempArea)
  787 004A9 8F00000         GOSBVL  =MOVEDOWN
  788               * File  extablefile.s   325
  789 004B0 1F02168         D1=(5)  (=ROMPTAB)+3
  790 004B7 32201           LCHEX   102
  791               * File  extablefile.s   326
  792                       {
  793 004BC 1533            A=DAT1  X
  794 004C0 17F             D1+     16
  795 004C3 936             ?C#A    X
  796 004C6 6F              UP
  797               * File  extablefile.s   327
  798                       }
  799 004C8 1C7             D1-     8
  800 004CB 147             C=DAT1  A
  801 004CE D7              D=C     A
  802 004D0 1C4             D1-     5
  803 004D3 147             C=DAT1  A
  804 004D6 135             D1=C
  805               * File  extablefile.s   328
  806 004D9 8AB             ?D=0    A
  807 004DC 80              SKIPYES{
  808 004DE DB              C=D     A
  809 004E0 7F60            GOSUB   .pcIsC
  810               * File  extablefile.s   329
  811                       }
  812 004E4 17C             D1+     13
  813 004E7 143             A=DAT1  A
  814               * File  extablefile.s   330
  815 004EA 137             CD1EX
  816 004ED CA              A=A+C   A
  817 004EF 818F09          A=A+    10      A
  818 004F5 131             D1=A
  819 004F8 147             C=DAT1  A
  820 004FB C2              C=C+A   A
  821 004FD 818F2F8         C=C+    20      A
            18F23
  822 00509 7640            GOSUB   .pcIsC
  823               * File  extablefile.s   331
  824 0050D D9              C=B     A
  825 0050F D7              D=C     A
  826 00511 819F3           DSRB.f  A
  827 00516 8F74508         GOSBVL  _GetAdrJmp
  828               * File  extablefile.s   332
  829 0051D 591             SKIPNC{
  830 00520 21              P=      1
  831 00522 8F04508         GOSBVL  _SwitchAdr
  832 00529 8F00000         GOSBVL  =GETPTR
  833 00530 8D00000         GOVLNG  =PushFLoop
  834               * File  extablefile.s   333
  835                       }
  836 00537 108             R0=C
  837 0053A 21              P=      1
  838 0053C 8F04508         GOSBVL  _SwitchAdr
  839 00543 8F00000         GOSBVL  =GETPTR
  840 0054A DA              A=C     A
  841 0054C 8D00000         GOVLNG  =Push#TLoop
  842               * File  extablefile.s   334
  843 00553         .pcIsC
  844 00553 81B3            PC=C
  845               * File  extablefile.s   335
  846 00557         LBL001
  847               * File  extablefile.s   336
  848
  849               ****************************************************
  850               * Get a list of entry starting with this chars
  851               * Input:
  852               *   1: "StartChars"
  853               * Output:
  854               *   1: { "NAMES" }
  855               ****************************************************
  856               * File  extablefile.s   344
  857 00557         =getnames
  858               * File  extablefile.s   345
  859 00557 00000           CON(5)  =DOCOL
  860 0055C 00000           CON(5)  =ERRSET
  861 00561 00000           CON(5)  =DOROMP
  862 00566 000000          CON(6)  =~getnames2
  863 0056C 00000           CON(5)  =ERRTRAP
  864 00571 00000           CON(5)  =DOCOL
  865 00576 00000           CON(5)  =GARBAGE
  866 0057B 00000           CON(5)  =DOROMP
  867 00580 000000          CON(6)  =~getnames2
  868 00586 00000           CON(5)  =SEMI
  869 0058B 00000           CON(5)  =SEMI
  870               * File  extablefile.s   346
  871
  872               * File  extablefile.s   347
  873 00590         =getnames2
  874               * File  extablefile.s   348
  875 00590 00000           CON(5)  =DOCODE
  876 00595 05100           REL(5)  LBL002
  877               * File  extablefile.s   349
  878 0059A 8F00000         GOSBVL  =SAVPTR
  879               * File  extablefile.s   350
  880 005A1 8F00000         GOSBVL  =MAKERAM$
  881 005A8 DB              C=D     A
  882 005AA 06              RSTK=C
  883 005AC 136             CD0EX
  884 005AF 81AF09          R1=C.f  A
  885               * File  extablefile.s   351
  886 005B5 1F02168         D1=(5)  (=ROMPTAB)+3
  887 005BC 32201           LCHEX   102
  888               * File  extablefile.s   352
  889                       {
  890 005C1 1533            A=DAT1  X
  891 005C5 17F             D1+     16
  892 005C8 936             ?C#A    X
  893 005CB 6F              UP
  894               * File  extablefile.s   353
  895                       }
  896 005CD 1C7             D1-     8
  897 005D0 147             C=DAT1  A
  898 005D3 D7              D=C     A
  899 005D5 1C4             D1-     5
  900 005D8 147             C=DAT1  A
  901 005DB 135             D1=C
  902               * File  extablefile.s   354
  903 005DE 8AB             ?D=0    A
  904 005E1 80              SKIPYES{
  905 005E3 DB              C=D     A
  906 005E5 78F0            GOSUB   .pcIsC3
  907               * File  extablefile.s   355
  908                       }
  909 005E9 17C             D1+     13
  910 005EC 143             A=DAT1  A
  911               * File  extablefile.s   356
  912 005EF 137             CD1EX
  913 005F2 CA              A=A+C   A
  914 005F4 818F09          A=A+    10      A
  915 005FA 131             D1=A
  916 005FD 147             C=DAT1  A
  917 00600 C2              C=C+A   A
  918 00602 818F2F8         C=C+    20      A
            18F23
  919 0060E 7FC0            GOSUB   .pcIsC3
  920               * File  extablefile.s   357
  921 00612 07              C=RSTK
  922 00614 D7              D=C     A
  923               * File  extablefile.s   358
  924 00616 8F00000         GOSBVL  =D1=DSKTOP
  925 0061D 147             C=DAT1  A
  926 00620 135             D1=C
  927               * File  extablefile.s   359
  928 00623 174             D1+     5
  929 00626 147             C=DAT1  A
  930 00629 818FA4          C=C-    5       A
  931 0062F 819F2           CSRB.f  A
  932 00634 D5              B=C     A
  933 00636 174             D1+     5
  934               * File  extablefile.s   360
  935 00639 8F55508         GOSBVL  _FindFirstJmp
  936               * File  extablefile.s   361
  937 00640 4F5             SKIPC{
  938               * File  extablefile.s   362
  939 00643 133             AD1EX
  940 00646 81AF21          AR1EX.f A
  941 0064C 133             AD1EX
  942               * File  extablefile.s   363
  943 0064F 818FB9          D=D-    10      A
  944 00655 4D7             GOC     .mem
  945               * File  extablefile.s   364
  946 00658 3400000         LC(5)   (=DOCSTR)
  947 0065F 145             DAT1=C  A
  948 00662 174             D1+     5
  949               * File  extablefile.s   365
  950 00665 D2              C=0     A
  951 00667 14E             C=DAT0  B
  952 0066A C6              C=C+C   A
  953 0066C E3              D=D-C   A
  954 0066E 446             GOC     .mem
  955               * File  extablefile.s   366
  956 00671 818F24          C=C+    5       A
  957 00677 145             DAT1=C  A
  958 0067A 818FA4          C=C-    5       A
  959 00680 174             D1+     5
  960               * File  extablefile.s   367
  961 00683 161             D0+     2
  962 00686 8F00000         GOSBVL  =MOVEDOWN
  963               * File  extablefile.s   368
  964 0068D 133             AD1EX
  965 00690 121             AR1EX
  966 00693 133             AD1EX
  967               * File  extablefile.s   369
  968 00696 8FC5508         GOSBVL  _FindNextJmp
  969 0069D 55A             UPNC
  970               * File  extablefile.s   370
  971               * File  extablefile.s   371
  972                       }
  973 006A0 21              P=      1
  974 006A2 8F04508         GOSBVL  _SwitchAdr
  975               * File  extablefile.s   372
  976 006A9 81AF19          C=R1.f  A
  977 006AF 134             D0=C
  978 006B2 8F00000         GOSBVL  =Shrink$List
  979 006B9 8F00000         GOSBVL  =GETPTR
  980 006C0 81AF10          A=R0.f  A
  981 006C6 141             DAT1=A  A
  982 006C9 142             A=DAT0  A
  983 006CC 164             D0=D0+  5
  984 006CF 808C            PC=(A)
  985               * File  extablefile.s   373
  986 006D3         .mem
  987 006D3 8F00000         GOSBVL  =GETPTR
  988 006DA 8D00000         GOVLNG  =DOMEMERR
  989               * File  extablefile.s   374
  990 006E1         .pcIsC3
  991 006E1 81B3            PC=C
  992               * File  extablefile.s   375
  993 006E5         LBL002
  994               * File  extablefile.s   376
  995
  996               ****************************************************
  997               * Get the name of an entry from it's address
  998               * Input:
  999               *   1: #value
 1000               * Output if entry exists:
 1001               *   2: "NAME"
 1002               *   1: true
 1003               * Output if entry does not exists:
 1004               *   1: false
 1005               ****************************************************
 1006               * File  extablefile.s   387
 1007 006E5         =getname
 1008               * File  extablefile.s   388
 1009 006E5 00000           CON(5)  =DOCODE
 1010 006EA 11100           REL(5)  LBL003
 1011               * File  extablefile.s   389
 1012 006EF 8F00000         GOSBVL  =POP#
 1013 006F6 100             R0=A
 1014 006F9 8F00000         GOSBVL  =SAVPTR
 1015               * File  extablefile.s   390
 1016 00700 1F02168         D1=(5)  (=ROMPTAB)+3
 1017 00707 32201           LCHEX   102
 1018               * File  extablefile.s   391
 1019                       {
 1020 0070C 1533            A=DAT1  X
 1021 00710 17F             D1+     16
 1022 00713 936             ?C#A    X
 1023 00716 6F              UP
 1024               * File  extablefile.s   392
 1025                       }
 1026 00718 1C7             D1-     8
 1027 0071B 147             C=DAT1  A
 1028 0071E D7              D=C     A
 1029 00720 1C4             D1-     5
 1030 00723 147             C=DAT1  A
 1031 00726 135             D1=C
 1032               * File  extablefile.s   393
 1033 00729 8AB             ?D=0    A
 1034 0072C 80              SKIPYES{
 1035 0072E DB              C=D     A
 1036 00730 73C0            GOSUB   .pcIsC2
 1037               * File  extablefile.s   394
 1038                       }
 1039 00734 17C             D1+     13
 1040 00737 143             A=DAT1  A
 1041               * File  extablefile.s   395
 1042 0073A 137             CD1EX
 1043 0073D CA              A=A+C   A
 1044 0073F 818F09          A=A+    10      A
 1045 00745 131             D1=A
 1046 00748 147             C=DAT1  A
 1047 0074B C2              C=C+A   A
 1048 0074D 818F2F8         C=C+    20      A
            18F23
 1049 00759 7A90            GOSUB   .pcIsC2
 1050               * File  extablefile.s   396
 1051 0075D 118             C=R0
 1052 00760 8FE4508         GOSBVL  _GetNameJmp
 1053               * File  extablefile.s   397
 1054 00767 591             SKIPNC{
 1055 0076A 21              P=      1
 1056 0076C 8F04508         GOSBVL  _SwitchAdr
 1057 00773 8F00000         GOSBVL  =GETPTR
 1058 0077A 8D00000         GOVLNG  =PushFLoop
 1059               * File  extablefile.s   398
 1060                       }
 1061 00781 137             CD1EX
 1062 00784 134             D0=C
 1063 00787 D2              C=0     A
 1064 00789 14E             C=DAT0  B
 1065 0078C B66             C=C+    1       B
 1066 0078F C6              C=C+C   A
 1067 00791 1F14328         D1=(5)  (_TempArea)
 1068 00798 8F00000         GOSBVL  =MOVEDOWN
 1069               * File  extablefile.s   399
 1070 0079F 21              P=      1
 1071 007A1 8F04508         GOSBVL  _SwitchAdr
 1072               * File  extablefile.s   400
 1073 007A8 1B14328         D0=(5)  (_TempArea)
 1074 007AF D2              C=0     A
 1075 007B1 14E             C=DAT0  B
 1076 007B4 C6              C=C+C   A
 1077 007B6 8F00000         GOSBVL  =MAKE$N
 1078               * File  extablefile.s   401
 1079 007BD 136             CD0EX
 1080 007C0 137             CD1EX
 1081 007C3 1B14328         D0=(5)  (_TempArea)
 1082 007CA D2              C=0     A
 1083 007CC 14E             C=DAT0  B
 1084 007CF C6              C=C+C   A
 1085 007D1 161             D0+     2
 1086 007D4 8F00000         GOSBVL  =MOVEDOWN
 1087               * File  extablefile.s   402
 1088 007DB 8F00000         GOSBVL  =GETPTR
 1089 007E2 81AF10          A=R0.f  A
 1090 007E8 1C4             D1-     5
 1091 007EB CF              D=D-    1       A
 1092 007ED 141             DAT1=A  A
 1093 007F0 8F00000         GOSBVL  =PushTLoop
 1094               * File  extablefile.s   403
 1095 007F7         .pcIsC2
 1096 007F7 81B3            PC=C
 1097               * File  extablefile.s   404
 1098 007FB         LBL003
 1099               * File  extablefile.s   405
 1100
 1101               ****************************************************
 1102               * Get a list of entry containing this chars
 1103               * Input:
 1104               *   1: "Chars"
 1105               * Output:
 1106               *   1: { "NAMES" }
 1107               ****************************************************
 1108               * File  extablefile.s   413
 1109 007FB         =getnear
 1110               * File  extablefile.s   414
 1111 007FB 00000           CON(5)  =DOCOL
 1112 00800 00000           CON(5)  =ERRSET
 1113 00805 00000           CON(5)  =DOROMP
 1114 0080A 000000          CON(6)  =~getnear2
 1115 00810 00000           CON(5)  =ERRTRAP
 1116 00815 00000           CON(5)  =DOCOL
 1117 0081A 00000           CON(5)  =GARBAGE
 1118 0081F 00000           CON(5)  =DOROMP
 1119 00824 000000          CON(6)  =~getnear2
 1120 0082A 00000           CON(5)  =SEMI
 1121 0082F 00000           CON(5)  =SEMI
 1122               * File  extablefile.s   415
 1123
 1124               * File  extablefile.s   416
 1125 00834         =getnear2
 1126               * File  extablefile.s   417
 1127 00834 00000           CON(5)  =DOCODE
 1128 00839 75100           REL(5)  LBL004
 1129 0083E         =asmgetnear
 1130               * File  extablefile.s   418
 1131 0083E 8F00000         GOSBVL  =SAVPTR
 1132               * File  extablefile.s   419
 1133 00845 8F00000         GOSBVL  =MAKERAM$
 1134 0084C DB              C=D     A
 1135 0084E 06              RSTK=C
 1136 00850 136             CD0EX
 1137 00853 81AF09          R1=C.f  A
 1138               * File  extablefile.s   420
 1139 00859 1F02168         D1=(5)  (=ROMPTAB)+3
 1140 00860 32201           LCHEX   102
 1141               * File  extablefile.s   421
 1142                       {
 1143 00865 1533            A=DAT1  X
 1144 00869 17F             D1+     16
 1145 0086C 936             ?C#A    X
 1146 0086F 6F              UP
 1147               * File  extablefile.s   422
 1148                       }
 1149 00871 1C7             D1-     8
 1150 00874 147             C=DAT1  A
 1151 00877 D7              D=C     A
 1152 00879 1C4             D1-     5
 1153 0087C 147             C=DAT1  A
 1154 0087F 135             D1=C
 1155               * File  extablefile.s   423
 1156 00882 8AB             ?D=0    A
 1157 00885 80              SKIPYES{
 1158 00887 DB              C=D     A
 1159 00889 7FF0            GOSUB   asmgetnear.pcIsC3
 1160               * File  extablefile.s   424
 1161                       }
 1162 0088D 17C             D1+     13
 1163 00890 143             A=DAT1  A
 1164               * File  extablefile.s   425
 1165 00893 137             CD1EX
 1166 00896 CA              A=A+C   A
 1167 00898 818F09          A=A+    10      A
 1168 0089E 131             D1=A
 1169 008A1 147             C=DAT1  A
 1170 008A4 C2              C=C+A   A
 1171 008A6 818F2F8         C=C+    20      A
            18F23
 1172 008B2 76D0            GOSUB   asmgetnear.pcIsC3
 1173               * File  extablefile.s   426
 1174 008B6 07              C=RSTK
 1175 008B8 D7              D=C     A
 1176               * File  extablefile.s   427
 1177 008BA 8F00000         GOSBVL  =D1=DSKTOP
 1178 008C1 147             C=DAT1  A
 1179 008C4 135             D1=C
 1180               * File  extablefile.s   428
 1181 008C7 174             D1+     5
 1182 008CA 147             C=DAT1  A
 1183 008CD 818FA5          C=C-    6       A
 1184 008D3 80D0            P=C     0
 1185 008D7 174             D1+     5
 1186 008DA 1571            C=DAT1  WP
 1187 008DE 80CF            C=P     15
 1188 008E2 20              P=      0
 1189               * File  extablefile.s   429
 1190 008E4 8F36508         GOSBVL  _FindFirstNearJmp
 1191               * File  extablefile.s   430
 1192 008EB 4F5             SKIPC{
 1193               * File  extablefile.s   431
 1194 008EE 133             AD1EX
 1195 008F1 81AF21          AR1EX.f A
 1196 008F7 133             AD1EX
 1197               * File  extablefile.s   432
 1198 008FA 818FB9          D=D-    10      A
 1199 00900 4D7             GOC     asmgetnear.mem
 1200               * File  extablefile.s   433
 1201 00903 3400000         LC(5)   (=DOCSTR)
 1202 0090A 145             DAT1=C  A
 1203 0090D 174             D1+     5
 1204               * File  extablefile.s   434
 1205 00910 D2              C=0     A
 1206 00912 14E             C=DAT0  B
 1207 00915 C6              C=C+C   A
 1208 00917 E3              D=D-C   A
 1209 00919 446             GOC     asmgetnear.mem
 1210               * File  extablefile.s   435
 1211 0091C 818F24          C=C+    5       A
 1212 00922 145             DAT1=C  A
 1213 00925 818FA4          C=C-    5       A
 1214 0092B 174             D1+     5
 1215               * File  extablefile.s   436
 1216 0092E 161             D0+     2
 1217 00931 8F00000         GOSBVL  =MOVEDOWN
 1218               * File  extablefile.s   437
 1219 00938 133             AD1EX
 1220 0093B 121             AR1EX
 1221 0093E 133             AD1EX
 1222               * File  extablefile.s   438
 1223 00941 8FA6508         GOSBVL  _FindNextNearJmp
 1224 00948 55A             UPNC
 1225               * File  extablefile.s   439
 1226               * File  extablefile.s   440
 1227                       }
 1228 0094B 21              P=      1
 1229 0094D 8F04508         GOSBVL  _SwitchAdr
 1230               * File  extablefile.s   441
 1231 00954 81AF19          C=R1.f  A
 1232 0095A 134             D0=C
 1233 0095D 8F00000         GOSBVL  =Shrink$List
 1234 00964 8F00000         GOSBVL  =GETPTR
 1235 0096B 81AF10          A=R0.f  A
 1236 00971 141             DAT1=A  A
 1237 00974 142             A=DAT0  A
 1238 00977 164             D0=D0+  5
 1239 0097A 808C            PC=(A)
 1240               * File  extablefile.s   442
 1241 0097E         asmgetnear.mem
 1242 0097E 8F00000         GOSBVL  =GETPTR
 1243 00985 8D00000         GOVLNG  =DOMEMERR
 1244               * File  extablefile.s   443
 1245 0098C         asmgetnear.pcIsC3
 1246 0098C 81B3            PC=C
 1247               * File  extablefile.s   444
 1248 00990         LBL004
 1249               * File  extablefile.s   445
 1250
 1251               ****************************************************
 1252               * This is an include of the table itself
 1253               ****************************************************
 1254               * File  extablefile.s   449
 1255               * ASSEMBLE
 1256               * File  extablefile.s   450
 1257 00990         _table
 1258               * File  extablefile.s   451
 1259                       INCLOB hptab49.hp
            t Liste
            d
 1260               * File  extablefile.s   452
 1261               * RPL
 1262               * File  extablefile.s   453
 1263
 1264               * File  extablefile.s   454
 1265 38597         =CONFIG
 1266               * File  extablefile.s   455
 1267 38597 00000           CON(5)  =DOCOL
 1268 3859C 00000           CON(5)  =DOBINT
 1269 385A1 20100           CON(5)  #102
 1270 385A6 00000           CON(5)  =TOSRRP
 1271 385AB 00000           CON(5)  =DOBINT
 1272 385B0 00100           CON(5)  #100
 1273 385B5 00000           CON(5)  =TOSRRP
 1274 385BA 00000           CON(5)  =SEMI
Saturn Assembler                                       Thu Aug 12 19:50:24 2010
V3.0.9 (04/15/2007)   Symbol Table                       extablefile.a  Page    2

 #>HXS                             Ext                   -   645
 .adjend                           Rel     553 #00000229 -   409   402
 .labelhere                        Rel     579 #00000243 -   435   436
 .labelhere2                       Rel     742 #000002E6 -   535   536
 .mem                              Rel    1747 #000006D3 -   986   944   954
 .pcIsC                            Rel    1363 #00000553 -   843   809   822
 .pcIsC2                           Rel    2039 #000007F7 -  1095  1036  1049
 .pcIsC3                           Rel    1761 #000006E1 -   990   906   919
 .skip                             Rel     679 #000002A7 -   492   473   479
 ?SEMI                             Ext                   -   680
 CK1&Dispatch                      Ext                   -   638   673   708
                                         736
=CONFIG                            Rel  230807 #00038597 -  1265
 CompareACbBytes                   Ext                   -   318   484
 D1=DSKTOP                         Ext                   -   924  1177
 DO#EXIT                           Ext                   -   648   683
 DOBINT                            Ext                   -   646   681  1268
                                        1271
 DOCODE                            Ext                   -    77   763   875
                                        1009  1127
 DOCOL                             Ext                   -   636   641   671
                                         676   706   734   739   859   864  1111
                                        1116  1267
 DOCSTR                            Ext                   -   946  1201
 DOMEMERR                          Ext                   -   988  1243
 DOROMP                            Ext                   -   642   678   711
                                         743   861   866  1113  1118
 ERRSET                            Ext                   -   860  1112
 ERRTRAP                           Ext                   -   863  1115
 ErrjmpC                           Ext                   -   782
 GARBAGE                           Ext                   -   865  1117
 GETPTR                            Ext                   -   780   832   839
                                         979   987  1057  1088  1234  1242
 HXS>#                             Ext                   -   677
 LBL000                            Rel     865 #00000361 -   616    78
 LBL001                            Rel    1367 #00000557 -   846   764
 LBL002                            Rel    1765 #000006E5 -   993   876
 LBL003                            Rel    2043 #000007FB -  1098  1010
 LBL004                            Rel    2448 #00000990 -  1248  1128
 MAKE$N                            Ext                   -  1077
 MAKERAM$                          Ext                   -   880  1133
 MOVEDOWN                          Ext                   -   787   962  1068
                                        1086  1217
 ONE                               Ext                   -   740
 POP#                              Ext                   -  1012
=PORT2EOS                          Abs  525632 #00080540 -   106   108
 Push#TLoop                        Ext                   -   841
 PushFLoop                         Ext                   -   833  1058
 PushTLoop                         Ext                   -  1093
=ROMPTAB                           Abs  549149 #0008611D -   122   789   886
                                        1016  1139
=RomId                             Abs     258 #00000102 -    18
 SAVPTR                            Ext                   -   769   878  1014
                                        1131
 SEMI                              Ext                   -   649   651   684
                                         686   714   745   747   868   869  1120
                                        1121  1274
 SEVEN                             Ext                   -   741
 SUB$                              Ext                   -   742
 Shrink$List                       Ext                   -   978  1233
 TOSRRP                            Ext                   -  1270  1273
 _111                              Rel     484 #000001E4 -   373   374
 _113                              Rel     458 #000001CA -   358   359
 _ExpOpStkStart                    Abs  533298 #00082332 -    96    98
 _ExpValueStkStart                 Abs  533170 #000822B2 -    94    96
 _FindFirst                        Rel     575 #0000023F -   432   201
 _FindFirstJmp                     Abs  525653 #00080555 -   114   935
 _FindFirstNear                    Rel     735 #000002DF -   531   221
 _FindFirstNearJmp                 Abs  525667 #00080563 -   118  1190
 _FindNext                         Rel     599 #00000257 -   452   211
 _FindNextJmp                      Abs  525660 #0008055C -   116   968
 _FindNextNear                     Rel     762 #000002FA -   552   231
 _FindNextNearJmp                  Abs  525674 #0008056A -   120  1223
 _GetAdr                           Rel     249 #000000F9 -   245   181
 _GetAdrJmp                        Abs  525639 #00080547 -   110   827
 _GetName                          Rel     450 #000001C2 -   352   191
 _GetNameJmp                       Abs  525646 #0008054E -   112  1052
 _InitTable                        Rel      36 #00000024 -   160   151
 _MaxLabSize                       Abs      64 #00000040 -    86
 _SCREEN                           Abs  533170 #000822B2 -    90    94
 _SwitchAdr                        Abs  525632 #00080540 -   108   110   112
                                         114   116   118   120   163   831   838
                                         974  1056  1071  1229
 _TableOffsets                     Rel      27 #0000001B -   149
 _TempArea                         Abs  533313 #00082341 -   104   247   281
                                         314   786  1067  1073  1081
 _TempAreaEnd                      Abs  533303 #00082337 -   100   102
 _TempAreaSize                     Abs  533308 #0008233C -   102   104
 _TempAreaStart                    Abs  533298 #00082332 -    98   100
 _l1                               Rel     297 #00000129 -   266   272
 _table                            Rel    2448 #00000990 -  1257   153   272
                                         359   374   436   536
=asmgetnear                        Rel    2110 #0000083E -  1129
 asmgetnear.mem                    Rel    2430 #0000097E -  1241  1199  1209
 asmgetnear.pcIsC3                 Rel    2444 #0000098C -  1245  1159  1172
 case                              Ext                   -   644
=getadr                            Rel    1112 #00000458 -   761
=getname                           Rel    1765 #000006E5 -  1007
=getnames                          Rel    1367 #00000557 -   857
=getnames2                         Rel    1424 #00000590 -   873
=getnear                           Rel    2043 #000007FB -  1109
=getnear2                          Rel    2100 #00000834 -  1125
 hxs                               Ext                   -   675
 lBlcB20                           Rel      73 #00000049 -   173
 lBlcB21                           Rel     282 #0000011A -   261
 lBlcB210                          Rel    1816 #00000718 -  1025
 lBlcB211                          Rel    1844 #00000734 -  1038
 lBlcB212                          Rel    1921 #00000781 -  1060
 lBlcB213                          Rel    2161 #00000871 -  1148
 lBlcB214                          Rel    2189 #0000088D -  1161
 lBlcB215                          Rel    2379 #0000094B -  1227
 lBlcB22                           Rel     425 #000001A9 -   326   319
 lBlcB23                           Rel     563 #00000233 -   416   399
 lBlcB24                           Rel     725 #000002D5 -   516
 lBlcB25                           Rel     700 #000002BC -   503   485
 lBlcB26                           Rel     856 #00000358 -   608   584
 lBlcB27                           Rel     833 #00000341 -   596
 lBlcB28                           Rel     828 #0000033C -   591
 lBlcB29                           Rel    1183 #0000049F -   784
 lBlcB2A                           Rel    1224 #000004C8 -   798
 lBlcB2B                           Rel    1252 #000004E4 -   811
 lBlcB2C                           Rel    1335 #00000537 -   835
 lBlcB2D                           Rel    1485 #000005CD -   895
 lBlcB2E                           Rel    1513 #000005E9 -   908
 lBlcB2F                           Rel    1696 #000006A0 -   972
 lBloB10                           Rel      63 #0000003F -   170
 lBloB10s                          Rel      73 #00000049 -   173   173   170
 lBloB11                           Rel     267 #0000010B -   254   259
 lBloB110                          Rel    1804 #0000070C -  1019  1023
 lBloB110s                         Rel    1816 #00000718 -  1025  1025
 lBloB111                          Rel    1838 #0000072E -  1034
 lBloB111s                         Rel    1844 #00000734 -  1038  1038  1034
 lBloB112                          Rel    1898 #0000076A -  1054
 lBloB112s                         Rel    1921 #00000781 -  1060  1060  1054
 lBloB113                          Rel    2149 #00000865 -  1142  1146
 lBloB113s                         Rel    2161 #00000871 -  1148  1148
 lBloB114                          Rel    2183 #00000887 -  1157
 lBloB114s                         Rel    2189 #0000088D -  1161  1161  1157
 lBloB115                          Rel    2286 #000008EE -  1192  1224
 lBloB115s                         Rel    2379 #0000094B -  1227  1227  1192
 lBloB11s                          Rel     282 #0000011A -   261   261
 lBloB12                           Rel     345 #00000159 -   288   304   310
                                         323
 lBloB12s                          Rel     425 #000001A9 -   326   326
 lBloB13                           Rel     477 #000001DD -   368   407   413
 lBloB13s                          Rel     563 #00000233 -   416   416
 lBloB14                           Rel     607 #0000025F -   457
 lBloB14s                          Rel     725 #000002D5 -   516   516   457
 lBloB15                           Rel     621 #0000026D -   465   500
 lBloB15s                          Rel     700 #000002BC -   503   503
 lBloB16                           Rel     765 #000002FD -   556   605
 lBloB16s                          Rel     856 #00000358 -   608   608
 lBloB17                           Rel     792 #00000318 -   570
 lBloB17s                          Rel     833 #00000341 -   596   596   570
 lBloB18                           Rel     810 #0000032A -   580   588
 lBloB18s                          Rel     828 #0000033C -   591   591
 lBloB19                           Rel    1162 #0000048A -   779
 lBloB19s                          Rel    1183 #0000049F -   784   784   779
 lBloB1A                           Rel    1212 #000004BC -   792   796
 lBloB1As                          Rel    1224 #000004C8 -   798   798
 lBloB1B                           Rel    1246 #000004DE -   807
 lBloB1Bs                          Rel    1252 #000004E4 -   811   811   807
 lBloB1C                           Rel    1312 #00000520 -   829
 lBloB1Cs                          Rel    1335 #00000537 -   835   835   829
 lBloB1D                           Rel    1473 #000005C1 -   889   893
 lBloB1Ds                          Rel    1485 #000005CD -   895   895
 lBloB1E                           Rel    1507 #000005E3 -   904
 lBloB1Es                          Rel    1513 #000005E9 -   908   908   904
 lBloB1F                           Rel    1603 #00000643 -   937   969
 lBloB1Fs                          Rel    1696 #000006A0 -   972   972   937
 str                               Ext                   -   640   710   738
=xGETADR                           Rel     872 #00000368 -   634
=xGETNAME                          Rel     945 #000003B1 -   669
=xGETNAMES                         Rel    1018 #000003FA -   704
=xGETNEAR                          Rel    1056 #00000420 -   732
=xnop                              Rel       7 #00000007 -    75
 ~getadr                           Ext                   -   643
 ~getname                          Ext                   -   679
 ~getnames                         Ext                   -   712
 ~getnames2                        Ext                   -   862   867
 ~getnear                          Ext                   -   744
 ~getnear2                         Ext                   -  1114  1119
 ~xGETADR                          Ext                   -   633
 ~xGETNAME                         Ext                   -   668
 ~xGETNAMES                        Ext                   -   703
 ~xGETNEAR                         Ext                   -   731
 ~xnop                             Ext                   -    74
Saturn Assembler                                       Thu Aug 12 19:50:24 2010
V3.0.9 (04/15/2007)   Statistics                         extablefile.a  Page    3

Input Parameters

  Source file name is extablefile.a

  Listing file name is extablefile.l

  Object file name is extablefile.o

  Flags set on command line
    None

Warnings:

  None

Errors:

  None
