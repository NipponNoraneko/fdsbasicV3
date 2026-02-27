;ts=8
; ----------------------------------------------------------------------------
tTokenTable:
	.byte	$80,"GOTO"
	.byte	$81,"GOSUB"
	.byte	$82,"RUN"
	.byte	$83,"RETURN"
	.byte	$84,"RESTORE"
	.byte	$85,"THEN"
	.byte	$86,"LIST"
	.byte	$87,"SYSTEM"
	.byte	$88,"TO"
	.byte	$89,"STEP"
	.byte	$8A,"SPRITE"
	.byte	$8B,"PRINT"
	.byte	$8C,"FOR"
	.byte	$8D,"NEXT"
	.byte	$8E,"PAUSE"
	.byte	$8F,"INPUT"
	.byte	$90,"LINPUT"
	.byte	$91,"DATA"
	.byte	$92,"IF"
	.byte	$93,"READ"
	.byte	$94,"DIM"
	.byte	$95,"REM"
	.byte	$96,"STOP"
	.byte	$97,"CONT"
	.byte	$98,"CLS"
	.byte	$99,"CLEAR"
	.byte	$9A,"ON"
	.byte	$9B,"OFF"
	.byte	$9C,"CUT"
	.byte	$9D,"NEW"
	.byte	$9E,"POKE"
	.byte	$9F,"CGSET"
	.byte	$A0,"VIEW"
	.byte	$A1,"MOVE"
	.byte	$A2,"END"
	.byte	$A3,"PLAY"
	.byte	$A4,"BEEP"
	.byte	$A5,"LOAD"
	.byte	$A6,"SAVE"
	.byte	$A7,"POSITION"
	.byte	$A8,"KEY"
	.byte	$A9,"COLOR"
	.byte	$AA,"DEF"
	.byte	$AB,"CGEN"
	.byte	$AC,"SWAP"
	.byte	$AD,"CALL"
	.byte	$AE,"LOCATE"
	.byte	$AF,"PALET"
	.byte	$B0,"ERA"
	.byte	$B1,"TR"
	.byte	$B2,"FIND"
	.byte	$B3,"FDS"
	.byte	$B4,"BGTOOL"
	.byte	$B5,"AUTO"
	.byte	$B6,"DELETE"
	.byte	$B7,"RENUM"
	.byte	$B8,"FILTER"
	.byte	$B9,"CLICK"
	.byte	$BA,"SCREEN"
	.byte	$BB,"BACKUP"
	.byte	$BC,"ERROR"
	.byte	$BD,"RESUME"
	.byte	$BE,"BGPUT"
	.byte	$BF,"BGGET"
	.byte	$C0,"CAN"
	.byte	$C1,"PCG"
	.byte	$C2,"MON"

	.byte	$EF,"XOR"
	.byte	$F0,"OR"
	.byte	$F1,"AND"
	.byte	$F2,"NOT"
	.byte	$F3,"<>"
	.byte	$F4,">="
	.byte	$F5,"<="
	.byte	$F6,'='
	.byte	$F7,'>'
	.byte	$F8,'<'
	.byte	$F9,'+'
	.byte	$FA,'-'
	.byte	$FB,"MOD"
	.byte	$FC,'/'
	.byte	$FD,'*'
	.byte	$CA,"ABS"
	.byte	$CB,"ASC"
	.byte	$CC,"STR$"
	.byte	$CD,"FRE"
	.byte	$CE,"LEN"
	.byte	$CF,"PEEK"
	.byte	$D0,"RND"
	.byte	$D1,"SGN"
	.byte	$D2,"SPC"
	.byte	$D3,"TAB"
	.byte	$D4,"MID$"
	.byte	$D5,"STICK"
	.byte	$D6,"STRIG"
	.byte	$D7,"XPOS"
	.byte	$D8,"YPOS"
	.byte	$D9,"VAL"
	.byte	$DA,"POS"
	.byte	$DB,"CSRLIN"
	.byte	$DC,"CHR$"
	.byte	$DD,"HEX$"
	.byte	$DE,"INKEY$"
	.byte	$DF,"RIGHT$"
	.byte	$E0,"LEFT$"
	.byte	$E1,"SCR$"
	.byte	$E2,"INSTR"
	.byte	$E3,"CRASH"
	.byte	$E4,"ERR"
	.byte	$E5,"ERL"
	.byte	$E6,"VCT."
	.byte	$E7,"REN"
	.byte	$E8,"DEL"
	.byte	$FF
; ----------------------------------------------------------------------------
tCommandAddr:
	.addr	GOTO				;
	.addr	GOSUB				;
	.addr	RUN				;
	.addr	RETURN				;
	.addr	RESTORE				;
	.addr	ErrorSyntax			; THEN
	.addr	LIST				;
	.addr	SYSTEM_BACKUP			;
	.addr	ErrorSyntax			; TO
	.addr	ErrorSyntax			; STEP
	.addr	SPRITE				;
	.addr	PRINT				;
	.addr	FOR				;
	.addr	NEXT				;
	.addr	PAUSE				;
	.addr	INPUT				;
	.addr	LINPUT				;
	.addr	DATA_REM			;
	.addr	IF				;
	.addr	READ				;
	.addr	DIM				;
	.addr	DATA_REM			;
	.addr	STOP				;
	.addr	CONT				;
	.addr	LAE0A				;
	.addr	CLEAR				;
	.addr	ON				;
	.addr	ErrorSyntax			; OFF
	.addr	CUT				;
	.addr	NEW				;
	.addr	POKE				;
	.addr	CGSET				;
	.addr	VIEW				;
	.addr	MOVE				;
	.addr	END				;
	.addr	PLAY				;
	.addr	BEEP				;
	.addr	LOAD				;
	.addr	SAVE				;
	.addr	POSITON				;
	.addr	KEY				;
	.addr	COLOR				;
	.addr	DEF				;
	.addr	CGEN				;
	.addr	SWAP				;
	.addr	CALL				;
	.addr	LOCATE				;
	.addr	PALET				;
	.addr	ERA				;
	.addr	TR				;
	.addr	FIND				;
	.addr	CmdFDS				;
	.addr	BGTOOL				;
	.addr	AUTO				;
	.addr	DELETE				;
	.addr	RENUM				;
	.addr	FILTER				;
	.addr	CLICK				;
	.addr	SCREEN				;
	.addr	SYSTEM_BACKUP			;
	.addr	ERROR_				;
	.addr	RESUME				;
	.addr	BGPUT				;
	.addr	BGGET				;
	.addr	CAN				;
	.addr	CmdPCG				;
	.addr	CmdMON				;

tFunctionPtr:
	.addr	FnABS				;
	.addr	FnASC				;
	.addr	FnSTR_STR			;
	.addr	FnFRE				;
	.addr	FnLEN				;
	.addr	FnPEEK				;
	.addr	FnRND				;
	.addr	FnSGN				;
	.addr	ErrorSyntax			; SPC
	.addr	ErrorSyntax			; TAB
	.addr	FnMID_STR			;
	.addr	FnSTICK				;
	.addr	FnSTRIG				;
	.addr	FnXPOS				;
	.addr	FnYPOS				;
	.addr	FnVAL				;
	.addr	FnPOS				;
	.addr	FnCSRLIN			;
	.addr	FnCHR_STR			;
	.addr	FnHEX_STR			;
	.addr	FnINKEY_STR			;
	.addr	FnRIGHT_STR			;
	.addr	FnLEFT_STR			;
	.addr	FnSCR_STR			;
	.addr	FnINSTR				;
	.addr	FnCRASH				;
	.addr	FnERR				;
	.addr	FnERL				;
	.addr	FnVCT				;
	.addr	ErrorSyntax			; REN
	.addr	ErrorSyntax			; DEL
; ----------------------------------------------------------------------------
