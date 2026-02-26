;.include	"fnc.inc"
; ----------------------------------------------------------------------------
tTokenTable:
	.byte   $80,"GOTO"
	.byte   $81,"GOSUB"
	.byte   $82,"RUN"
	.byte   $83,"RETURN"
	.byte   $84,"RESTORE"
	.byte   $85,"THEN"
	.byte   $86,"LIST"
	.byte   $87,"SYSTEM"
	.byte   $88,"TO"
	.byte   $89,"STEP"
	.byte   $8A,"SPRITE"
	.byte   $8B,"PRINT"
	.byte   $8C,"FOR"
	.byte   $8D,"NEXT"
	.byte   $8E,"PAUSE"
	.byte   $8F,"INPUT"
	.byte   $90,"LINPUT"
	.byte   $91,"DATA"
	.byte   $92,"IF"
	.byte   $93,"READ"
	.byte   $94,"DIM"
	.byte   $95,"REM"
	.byte   $96,"STOP"
	.byte   $97,"CONT"
	.byte   $98,"CLS"
	.byte   $99,"CLEAR"
	.byte   $9A,"ON"
	.byte   $9B,"OFF"
	.byte	$9C,"CUT"
	.byte   $9D,"NEW"
	.byte   $9E,"POKE"
	.byte   $9F,"CGSET"
	.byte   $A0,"VIEW"
	.byte   $A1,"MOVE"
	.byte   $A2,"END"
	.byte   $A3,"PLAY"
	.byte   $A4,"BEEP"
	.byte   $A5,"LOAD"
	.byte   $A6,"SAVE"
	.byte   $A7,"POSITION"
	.byte   $A8,"KEY"
	.byte   $A9,"COLOR"
	.byte   $AA,"DEF"
	.byte   $AB,"CGEN"
	.byte   $AC,"SWAP"
	.byte   $AD,"CALL"
	.byte   $AE,"LOCATE"
	.byte   $AF,"PALET"
	.byte   $B0,"ERA"
	.byte   $B1,"TR"
	.byte   $B2,"FIND"
	.byte   $B3,"FDS"
	.byte   $B4,"BGTOOL"
	.byte   $B5,"AUTO"
	.byte   $B6,"DELETE"
	.byte   $B7,"RENUM"
	.byte   $B8,"FILTER"
	.byte   $B9,"CLICK"
	.byte   $BA,"SCREEN"
	.byte   $BB,"BACKUP"
	.byte   $BC,"ERROR"
	.byte   $BD,"RESUME"
	.byte   $BE,"BGPUT"
	.byte   $BF,"BGGET"
	.byte   $C0,"CAN"
	.byte   $C1,"PCG"
	.byte   $C2,"MON"

	.byte   $EF,"XOR"
	.byte   $F0,"OR"
	.byte   $F1,"AND"
	.byte   $F2,"NOT"
	.byte   $F3,"<>"
	.byte   $F4,">="
	.byte   $F5,"<="
	.byte   $F6,'='
	.byte   $F7,'>'
	.byte   $F8,'<'
	.byte   $F9,'+'
	.byte   $FA,'-'
	.byte   $FB,"MOD"
	.byte   $FC,'/'
	.byte   $FD,'*'
	.byte   $CA,"ABS"
	.byte   $CB,"ASC"
	.byte   $CC,"STR$"
	.byte   $CD,"FRE"
	.byte   $CE,"LEN"
	.byte   $CF,"PEEK"
	.byte   $D0,"RND"
	.byte   $D1,"SGN"
	.byte   $D2,"SPC"
	.byte   $D3,"TAB"
	.byte   $D4,"MID$"
	.byte   $D5,"STICK"
	.byte   $D6,"STRIG"
	.byte   $D7,"XPOS"
	.byte   $D8,"YPOS"
	.byte   $D9,"VAL"
	.byte   $DA,"POS"
	.byte   $DB,"CSRLIN"
	.byte   $DC,"CHR$"
	.byte   $DD,"HEX$"
	.byte   $DE,"INKEY$"
	.byte   $DF,"RIGHT$"
	.byte   $E0,"LEFT$"
	.byte   $E1,"SCR$"
	.byte   $E2,"INSTR"
	.byte   $E3,"CRASH"
	.byte   $E4,"ERR"
	.byte   $E5,"ERL"
	.byte   $E6,"VCT."
	.byte	$E7,"REN"
	.byte	$E8,"DEL"
	.byte	$FF
; ----------------------------------------------------------------------------
tCommandAddr:
        .addr   GOTO                            ;
        .addr   GOSUB                           ;
        .addr   RUN                             ;
        .addr   RETURN                          ;
        .addr   RESTORE                         ;
        .addr   ErrorSyntax                     ;
        .addr   LIST                            ;
        .addr   SYSTEM_BACKUP                   ;
        .addr   ErrorSyntax                     ;
        .addr   ErrorSyntax                     ;
        .addr   SPRITE                          ;
        .addr   PRINT                           ;
        .addr   FOR                             ;
        .addr   NEXT                            ;
        .addr   PAUSE                           ;
        .addr   INPUT                           ;
        .addr   LINPUT                          ;
        .addr   DATA_REM                        ;
        .addr   IF                              ;
        .addr   READ                            ;
        .addr   DIM                             ;
        .addr   DATA_REM                        ;
        .addr   STOP                            ;
        .addr   CONT                            ;
        .addr   LAE0A                           ;
        .addr   CLEAR                           ;
        .addr   ON                              ;
        .addr   ErrorSyntax                     ;
        .addr   CUT                             ;
        .addr   NEW                             ;
        .addr   POKE                            ;
        .addr   CGSET                           ;
        .addr   VIEW                            ;
        .addr   MOVE                            ;
        .addr   END                             ;
        .addr   PLAY                            ;
        .addr   BEEP                            ;
        .addr   LOAD                            ;
        .addr   SAVE                            ;
        .addr   POSITON                         ;
        .addr   KEY                             ;
        .addr   COLOR                           ;
        .addr   DEF                             ;
        .addr   CGEN                            ;
        .addr   SWAP                            ;
        .addr   CALL                            ;
        .addr   LOCATE                          ;
        .addr   PALET                           ;
        .addr   ERA                             ;
        .addr   TR                              ;
        .addr   FIND                            ;
        .addr   CmdFDS
        .addr   BGTOOL                          ; CF27 D1 BF                    ..
        .addr   AUTO                            ; CF29 DA 8B                    ..
        .addr   DELETE                          ; CF2B 58 87                    X.
        .addr   RENUM                           ; CF2D 30 8C                    0.
        .addr   FILTER                          ; CF2F B8 AE                    ..
        .addr   CLICK                           ; CF31 25 96                    %.
        .addr   SCREEN                          ; CF33 48 AE                    H.
        .addr   SYSTEM_BACKUP                   ; CF35 8F 81                    ..
        .addr   ERROR_                          ; CF37 10 95                    ..
        .addr   RESUME                          ; CF39 27 95                    '.
        .addr   BGPUT                           ; CF3B 01 B2                    ..
        .addr   BGGET                           ; CF3D B8 B1                    ..
        .addr   CAN                             ; CF3F 6C CC                    l.
	.addr	CmdPCG
	.addr	CmdMON

tFunctionPtr:
        .addr   FnABS                           ; CF41 84 A9                    ..
        .addr   FnASC                           ; CF43 28 AA                    (.
        .addr   FnSTR_STR                       ; CF45 A6 AA                    ..
        .addr   FnFRE                           ; CF47 1F A9                    ..
        .addr   FnLEN                           ; CF49 1D AA                    ..
        .addr   FnPEEK                          ; CF4B 73 A9                    s.
        .addr   FnRND                           ; CF4D BD A9                    ..
        .addr   FnSGN                           ; CF4F 9C A9                    ..
        .addr   ErrorSyntax                     ; CF51 91 84                    ..
        .addr   ErrorSyntax                     ; CF53 91 84                    ..
        .addr   FnMID_STR                       ; CF55 81 AC                    ..
        .addr   FnSTICK                         ; CF57 38 AD                    8.
        .addr   FnSTRIG                         ; CF59 47 AD                    G.
        .addr   FnXPOS                          ; CF5B 58 A9                    X.
        .addr   FnYPOS                          ; CF5D 61 A9                    a.
        .addr   FnVAL                           ; CF5F DF AA                    ..
        .addr   FnPOS                           ; CF61 33 A9                    3.
        .addr   FnCSRLIN                        ; CF63 E6 A8                    ..
        .addr   FnCHR_STR                       ; CF65 82 AA                    ..
        .addr   FnHEX_STR                       ; CF67 D6 AA                    ..
        .addr   FnINKEY_STR                     ; CF69 58 AB                    X.
        .addr   FnRIGHT_STR                     ; CF6B 41 AC                    A.
        .addr   FnLEFT_STR                      ; CF6D ED AB                    ..
        .addr   FnSCR_STR                       ; CF6F 3B AA                    ;.
        .addr   FnINSTR                         ; CF71 AF AB                    ..
        .addr   FnCRASH                         ; CF73 04 CC                    ..
        .addr   FnERR                           ; CF75 0D A9                    ..
        .addr   FnERL                           ; CF77 14 A9                    ..
        .addr   FnVCT                           ; CF79 6A A9                    j.
        .addr   ErrorSyntax                     ; REN
        .addr   ErrorSyntax                     ; DEL
; ----------------------------------------------------------------------------
