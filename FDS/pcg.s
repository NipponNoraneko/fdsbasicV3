;ts=8

;- zero page override ---------------------------------------------------------
zTempPtr	=	$00
zActAddr	=	zpPokeAddr
paletVal	=	zpPaletteNum
palNum		=	zpGameNum

;------------------------------------------------------------------------------
MODE_8X8	=	0
MODE_16X16	=	4

PCG_READ	=	$02
PCG_WRITE	=	$00

OBJ_TOP		=	0
BG_TOP		=	$10

PUT8X8_POS0	=	$20a3			;  3, 5 ( 24,  40)
PUT8X8_POS1	=	$20ab			; 11, 5 ( 88,  40)
PUT8X8_POS2	=	$21a3			;  3,13 ( 24, 104)
PUT8X8_POS3	=	$21ab			; 11,13 ( 88, 104)

EDIT_CHAR_POS0	=	$212c			; 編集中キャラクタ表示位置:8x8
EDIT_CHAR_POS1	=	$2331			;                         :16x16

CHARS_SHOW_POS0	=	$206e			; キャラクタ一覧表示開始位置:8x8
CHARS_SHOW_POS1	=	$2076			;                           :16x16

PALET_POS0	=	$23e1			; パレット表示開始位置:8x8
PALET_POS1	=	$23f1			;                     :16x16
						;--- 編集用スプライト
MARK_CURSOR	=	$2e0
MARK_CURSOR1	=	$2e4
MARK_CURSOR2	=	$2e8
MARK_CURSOR3	=	$2ec

PALET_CURSOR	=	$2f0
PALET_CURSOR2	=	$2f4
EDIT_CURSOR	=	$2f8

;- work / char data buf  -----------------------
.segment	"BSS"
currentEdCharNo:.res	1			; 編集キャラクタ番号
editCharNo:	.res	4			; 編集キャラクタ番号: 4 byte
preEditCharNo1:	.res	4			; 編集キャラクタ番号: 4 byte
preEditCharNo2:	.res	4			; 編集キャラクタ番号: 4 byte
oneCharBuf:	.res	16			; 8x8表示キャラクタバッファ:$10 byte
charBuf:	.res	64			; 8x8表示用バッファ: 64 byte

CUR_BG_SAVE_BUF:.res	$80			; BG編集用キャラクタ保存用
CUR_OBJ_SAVE_BUF:
		.res	$80			; スプライト編集用キャラクタ保存用

;- char data buf  ------------------------------
.segment	"BSS2"
EDIT_CHAR_BUF:	.res	$1000			; 編集キャラクタバッフ $10 x 256

;------------------------------------------------------------------------------
.segment	"FDS_PATCH"

editMode:
	.res	1
editX:	.res	1
editY:	.res	1

leftTopCharNo:
	.res	1
charEditPos:
	.res	1
markX:	.res	1
markY:	.res	1

putPos: .res	1
prePutPos:
	.res	1

charDirty:
	.res	1

flgBgObj:
	.byte	$08

;- 編集用スプライト ----------------------------
tblCurs:
markCur:.byte	24-1,      $f8, $03, 112 
paletCur:
	.byte	136,       $fa, $03, 16		;
pal2Cur:.byte	128-1,     $fb, $83, 24
editCur:.byte	(2+3)*8-1, $f9, $03, (1+2)*8

;------------------------------------------------------------------------------

.segment	"ORG_TOKEN_AREA"
;------------------------------------------------------------------------------
;	Clr8x8:
;
Clr8x8:
	lda	#0
	ldx	#64-1
@C88L10:
	sta	charBuf,x
	dex
	bpl	@C88L10

	rts

;------------------------------------------------------------------------------
;	CalcCharAddr:	キャラクタアドレス計算
;
;	zBufAddr = currentEdCharNo * 16 + EDIT_CHAR_BUF
;
CalcCharAddr:
	lda	currentEdCharNo
	sta	zBufAddr
	lda	#0
	sta	zBufAddr+1

	ldx	#4
@D88L10:
	asl	zBufAddr
	rol	zBufAddr+1
	dex
	bne	@D88L10

	lda	#>EDIT_CHAR_BUF
	clc
	adc	zBufAddr+1
	sta	zBufAddr+1

	rts

;------------------------------------------------------------------------------
;	Pack8x8:	2bpパッキング
;
;	charBufの内容を2bpにパッキングし、元のアドレスに書き戻す
;
Pack8x8:
	jsr	CalcCharAddr

	lda	#>charBuf
	sta	cbPtr+2
	lda	#<charBuf
	sta	cbPtr+1

	ldy	#0
@P88Loop:
	sty	tmpY
	jsr	PackByte
	sta	(zBufAddr),y

	jsr	PackByte
	tax
	tya
	clc
	adc	#8
	tay
	txa
	sta	(zBufAddr),y

	lda	cbPtr+1
	clc
	adc	#8
	sta	cbPtr+1
	bcc	@P88J10
	inc	cbPtr+2
@P88J10:
	inc	tmpY
	ldy	tmpY
	cpy	#8
	bne	@P88Loop
						;--- 書き戻し
	jsr	VOffWaitVsync

	lda	zBufAddr
	sta	vramPtr				; 転送元lower
	lda	zBufAddr+1
	sta	vramPtr+1			;       upper
	sec
	sbc	#$70
	tay					; Y:書き戻し先 upper
	ldx	#$08
	cpx	flgBgObj
	beq	@OBJ
	ora	#$10
	tay
@OBJ:
	lda	currentEdCharNo
	asl	a
	asl	a
	asl	a
	asl	a				; A:書き戻し先 lower
	ldx	#1				; X:転送キャラ数 1
	jsr	LoadTileset
vramPtr:.addr	EDIT_CHAR_BUF			; 転送元アドレス

	jsr	VOn
	jsr	ResetScroll

	rts

PackByte:
	ldx	#0
PBL20:
cbPtr:	lsr	charBuf,x
	rol	a
	inx
	cpx	#8
	bne	PBL20

	rts

;------------------------------------------------------------------------------
;	Extent8x8:	2bpデータ展開
;
;	2bpキャラクタデータを展開し、charBufに格納する
;
Extent8x8:
	jsr	Clr8x8

	jsr	CalcCharAddr			; キャラクタアドレス計算
						;--- キャラデータをテンポラリへ
	ldy	#15
@D88L15:
	lda	(zBufAddr),y
	sta	oneCharBuf,y
	dey
	bpl	@D88L15
						;--- ビットチェック
	ldx	#0
	stx	tmpX
	ldy	#8
@D88J01:
	jsr	@D88J05				; プレーン 1
	cpy	#16
	bne	@D88J01

	ldx	#0
	stx	tmpX
	ldy	#0
@D88J02:
	jsr	@D88J05				; プレーン 0
	cpy	#8
	bne	@D88J02

	sty	charDirty

	rts	

;-----------------------------------------------
@D88J05:
	ldx	tmpX
@D88L20:
	lda	oneCharBuf,y
	asl	a
	sta	oneCharBuf,y
	rol	charBuf,x
	inx
	txa
	and	#7
	cmp	#00
	bne	@D88L20

	stx	tmpX
	iny

	rts

;------------------------------------------------------------------------------
;	Put8x8:
;
;
Put8x8:
						;--- 表示開始アドレス
	lda	putPos
	and	#03
	asl	a
	tay
	ldx	put8Tbl+1,y
	lda	put8Tbl,y
	jsr	SetActAddr

	jsr	VOffWaitVsync
	jsr	SetLineAddr
						;--- 
	ldy	#0
	sty	charDirty
@P88L05:					;--- 一行表示
	ldx	#8-1
@P88L10:
	lda	charBuf,y
	clc
	adc	#$fc
	sta	PPU_DATA
	iny
	dex
	bpl	@P88L10

	jsr	NextLine

	cpy	#64
	bne	@P88L05				; 次行

	jsr	PutEditChar

	rts

put8Tbl:
	.addr	PUT8X8_POS0, PUT8X8_POS1, PUT8X8_POS2, PUT8X8_POS3

;------------------------------------------------------------------------------
;	ShowChars:	キャラクタ一覧表示
;
ShowChars:
	ldy	editMode
	lda	charsModeTbl+2,y
	sta	@lineCnt+1			; 行数
	lda	charsModeTbl+3,y
	sta	@charCnt+1			; 列数

	ldx	charsModeTbl+1,y		; 表示開始位置
	lda	charsModeTbl,y
	jsr	SetActAddr
@lineCnt:
	ldy	#16
	sty	tmpY

	jsr	VOffWaitVsync
	lda	#0
	sta	PPU_MASK
	jsr	SetLineAddr

	lda	#0
	tax
@SCL10:
	sta	PPU_DATA
	clc
	adc	#1
	inx
@charCnt:
	cpx	#16
	bne	@SCL10
						;---
	pha
	jsr	NextLine
	pla

	ldx	#00

	dec	tmpY
	bne	@SCL10

	jsr	VOn
@SCEnd:
	rts

;------------------------------------------------
NextLine:
	lda	zActAddr
	clc
	adc	#32
	sta	zActAddr
	bcc	@NLJ10
	inc	zActAddr+1
@NLJ10:
	jsr	SetLineAddr

	rts

;------------------------------------------------
charsModeTbl:
	.addr	CHARS_SHOW_POS0
	.byte	16,16
	.addr	CHARS_SHOW_POS1
	.byte	24, 8

;------------------------------------------------------------------------------
;	ShowPalet:	パレット表示

ShowPalet:
	lda	#$00
	sta	paletVal
						;--- 表示開始位置
	ldy	editMode
	lda	modePalTbl,y
	sta	zpCH
	lda	modePalTbl+1,y
	sta	zpCV

	lda	modePalTbl+2,y
	sta	attAddr+3
	lda	modePalTbl+3,y
	sta	attAddr+1
						;--- 表示
	lda	#STR_PALLET
	jsr	PutStr
	jsr	DoCRLF
	lda	#STR_PALLET
	jsr	PutStr
						;--- アトリビュート
	jsr	VOffWaitVsync
RestorePalDisp:
attAddr:ldx	#>PALET_POS0
	lda	#<PALET_POS0
	jsr	SetPpuAddr

	lda	#$a0				; 00 00
						; 10 10
	sta	PPU_DATA

	lda	#$f5				; 01 01
						; 11 11
	sta	PPU_DATA

	jsr	VOn

	rts

;------------------------------------------------
modePalTbl:
	.byte	0, 14				; 8x8
	.addr	PALET_POS0
	.byte	0, 22				; 16x16
	.addr	PALET_POS1

;------------------------------------------------------------------------------
;	PaletUP:
;
;	A|B
;	C|D		paletVal = dd.cc.bb.aa
;
PaletUp:
	lda	zpShiftKeyDn
	beq	@PUJ10

	dec	palNum
	jmp	@PUJ20
@PUJ10:
	inc	palNum
@PUJ20:
	lda	palNum
	and	#$0f
	sta	palNum

	lsr	a
	lsr	a
	tax
	lda	paletTbl,x
	sta	paletVal

ChangePalet:
	jsr	VOffWaitVsync

	ldx	#>BG_COLOR1_ADDR
	lda	#<BG_COLOR1_ADDR
	jsr	SetPpuAddr

	lda	paletVal
	ldx	#56
@FillLoop:
	sta	PPU_DATA
	dex
	bne	@FillLoop

	jsr	RestorePalDisp
	jsr	PaletCurUpdate

	rts

;------------------------------------------------
paletTbl:
	.byte	$00, $55, $aa, $ff

;------------------------------------------------------------------------------
;	InitEdCur:
;
InitEdCur:
	ldx	#>xferEditTbl
	lda	#<xferEditTbl
	jsr	SetActAddr

	ldx	#8
	jsr	CharXfer2

	lda	#0
	sta	charEditPos
						;--- マークカーソル
	jsr	InitMarkCur
						;--- その他のカーソル
	ldx	#12-1
@IELoop3:
	lda	tblCurs+4,x
	sta	PALET_CURSOR,x
	dex
	bpl	@IELoop3

;------------------------------------------------
UpdateEditCur:					;---- Edit Cursor Update
	lda	editX
	asl	a
	asl	a
	asl	a
	clc
	adc	#(1+2)*8
	sta	EDIT_CURSOR + X_POS

	lda	editY
	asl	a
	asl	a
	asl	a
	clc
	adc	#(2+3)*8-1
	sta	EDIT_CURSOR + Y_POS
@ECUEnd:
	rts

;------------------------------------------------------------------------------
;	Edit8x8:
;
Edit8x8:
@E88L10:					;--- 拡大表示(8x8)
	lda	#0
	sta	charDirty

	jsr	Extent8x8
	jsr	Put8x8
@E88Loop:
	jsr	VOn
@KeyWait:
	jsr	ReadChar			; BASIC routine
	beq	@KeyWait

	cmp	#'Q'
	beq	@Exit

	ldx	zpShiftKeyDn
	beq	@E88J10				; no SHIFT key

	ldx	#>tblSftKeyAct
	stx	zTempPtr+1
	ldx	#<tblSftKeyAct
	stx	zTempPtr

	jsr	KeyAct
	txa
	bcs	@E88J20
@E88J10:
	ldx	#>tblKeyAct
	stx	zTempPtr+1
	ldx	#<tblKeyAct
	stx	zTempPtr

	jsr	KeyAct
@E88J20:
	lda	charDirty
	bne	@E88L10
	beq	@E88Loop
@Exit:
	rts

;------------------------------------------------------------------------------
;	InitEditChar:
;
InitEditChar:
	ldx	#3
	txa
@IECL10:
	sta	editCharNo,x
	dex
	txa
	bpl	@IECL10

	rts

;------------------------------------------------------------------------------
;	PutDot:
;
PutDot:
	ldy	charEditPos
	lda	palNum
	and	#$03
	sta	charBuf,y

	lda	#1
	sta	charDirty

	jsr	Pack8x8

	rts

.byte	">&"

.segment	"FDS_PATCH"
;------------------------------------------------------------------------------
;	NextEditChar:	編集キャラクタ更新
;
NextEditChar:
	ldx	putPos

	lda	zpShiftKeyDn
	bne	@DecNo

	inc	editCharNo,x
	jmp	MarkUpdate
@DecNo:
	dec	editCharNo,x

;------------------------------------------------
MarkUpdate:
	lda	editCharNo,x
	sta	currentEdCharNo

	jsr	CalcMarkCurPos
						;--- キャラクタ展開
	jsr	Extent8x8

	rts


.segment	"OLD_GAME_COMMAND"
;------------------------------------------------------------------------------
;	SetActAddr:
;		IN	X:upper address
;			A:lower address
SetActAddr:
	stx	zActAddr+1
	sta	zActAddr

	rts

;------------------------------------------------------------------------------
;	CLS2:
;
ClsFC:
	lda	#$fc
CLS2:
	sta	$b48a				; Clear Char Code.

	lda	#0
	jsr	CLS				; BASIC command: CLS

	rts

;------------------------------------------------------------------------------
;	RestoreChar:	編集用キャラ書き戻し
;
RestoreChar:
	ldx	#>xferRestoreTbl
	lda	#<xferRestoreTbl
	jsr	SetActAddr

	ldx	#2
	jsr	CharXfer2

	lda	zpPpuCtrlVal
	and	#$e7
	ora	#$10
	sta	PPU_CTRL
	sta	zpPpuCtrlVal
	sta	PPU_CTRL_Mirror

	rts

;------------------------------------------------------------------------------
;	CharRW:
;		ALL REGISER BREAK
;
CharRW:
dirAddrL:
	lda	#PCG_READ
addrH:	ldy	#$10
xfrNum:	ldx	#0
	jsr	LoadTileset
srcDist: .addr	EDIT_CHAR_BUF

	rts

;------------------------------------------------------------------------------
;	CharXfer:	キャラクタ転送
;
CharXfer:
	ldx	#5
CharXfer2:
	stx	tmpX

	jsr	VOffWaitVsync
	lda	#$00
	sta	PPU_MASK

	ldy	#0
	sty	tmpY
@CTLoop:
	lda	(zActAddr),y
	sta	dirAddrL+1
	iny
	lda	(zActAddr),y
	sta	addrH+1
	iny
	lda	(zActAddr),y
	sta	xfrNum+1
	iny
	lda	(zActAddr),y
	sta	srcDist
	iny
	lda	(zActAddr),y
	sta	srcDist+1
	iny
	sty	tmpY

	jsr	CharRW

	ldy	tmpY
	dec	tmpX
	bne	@CTLoop

	jsr	VOn
	lda	#$0
	sta	PPU_MASK

	rts	

.byte	"ADDF"

.segment	"FDS_PATCH"
;------------------------------------------------------------------------------
xferTbl:
	.byte	$00|PCG_READ,  $10, 0, <EDIT_CHAR_BUF,    >EDIT_CHAR_BUF	; $1000~$1fff -> $7000~ BGすべて
	.byte	$80|PCG_WRITE, $1f, 8, <CUR_OBJ_SAVE_BUF, >CUR_OBJ_SAVE_BUF	; $0f00~$0fff <- $6c00~ OBJ:F0~FF
	.byte	$80|PCG_READ,  $1f, 8, <CUR_OBJ_SAVE_BUF, >CUR_OBJ_SAVE_BUF	; $0f00~$0fff -> $6c00~ OBJ:F0~FF
	.byte	$80|PCG_WRITE, $0f, 8, <$6e80, >$6e80				; $7d90~$7d9f -> $0ff0~ '□'->OBJ:d9
	.byte	$c0|PCG_WRITE, $1f, 4, <$6ec0, >$6ec0				; $7d90~$7d9f -> $0ff0~ '□'->OBJ:d9
	
xferTbl2:
	.byte	$00|PCG_READ,  $00, 0, <EDIT_CHAR_BUF,   >EDIT_CHAR_BUF		; $0000~$0fff -> $7000~ OBJすべて
	.byte	$80|PCG_WRITE, $0f, 8, <CUR_BG_SAVE_BUF, >CUR_BG_SAVE_BUF	; $0f00~$0fff <- $6c00~ OBJ:F0~FF
	.byte	$80|PCG_READ,  $0f, 8, <CUR_BG_SAVE_BUF, >CUR_BG_SAVE_BUF	; $0f00~$0fff -> $6c00~ BG:F0~FF
	.byte	$80|PCG_WRITE, $1f, 8, <$6e80, >$6e80				; $7d90~$7d9f -> $0ff0~ '□'->OBJ:d9
	.byte	$c0|PCG_WRITE, $0f, 4, <$6ec0, >$6ec0				; $7d90~$7d9f -> $0ff0~ '□'->OBJ:d9
	
xferEditTbl:
	.byte	$80|PCG_READ,  $0f, 8, <CUR_BG_SAVE_BUF,  >CUR_BG_SAVE_BUF	; $0f80~$0fff -> $6c00~ OBJ:F0~FF
	.byte	$80|PCG_READ,  $1f, 8, <CUR_OBJ_SAVE_BUF, >CUR_OBJ_SAVE_BUF	; $1f80~$0fff -> $6c80~ BG:F0~FF
	.byte	$90|PCG_READ,  $0d, 1, <$6e80, >$6e80		; '└'->OBJ:FF
	.byte	$d0|PCG_READ,  $0d, 1, <$6e90, >$6e90		; '✛'->OBJ:FE
	.byte	$e0|PCG_READ,  $13, 1, <$6ea0, >$6ea0		; '>'->OBJ:FD
	.byte	$e0|PCG_READ,  $15, 1, <$6eb0, >$6eb0		; '^'->OBJ:FC
	.byte	$00|PCG_READ,  $12, 1, <$6ec0, >$6ec0		; ' '->OBJ:FC
	.byte	$d0|PCG_READ,  $1f, 3, <$6ed0, >$6ed0		; '■■■'-> OBJ:FC

xferRestoreTbl:
	.byte	$80|PCG_WRITE, $0f, 8, <CUR_BG_SAVE_BUF,  >CUR_BG_SAVE_BUF	; $0f80~$0fff <- $6c00~ OBJ:F0~FF
	.byte	$80|PCG_WRITE, $1f, 8, <CUR_OBJ_SAVE_BUF, >CUR_OBJ_SAVE_BUF	; $1f80~$1fff <- $6c80~ BG:F0~FF

;------------------------------------------------------------------------------
;	FlipBgObj:
;
FlipBgObj:
	lda	flgBgObj
	eor	#$18
	sta	flgBgObj

	pha
	sta	zpCursFlashCtr
	jsr	$aedd				; CGEN
	lda	zpPpuCtrlVal
	sta	PPU_CTRL_Mirror
	pla

	cmp	#$08				; BG
	bne	@FBJ10				; yes
						;--- OBJ
	ldy	#>xferTbl2
	ldx	#<xferTbl2
	bne	@FBJ20
@FBJ10:						;--- BG
	ldy	#>xferTbl
	ldx	#<xferTbl
@FBJ20:
	sty	zActAddr+1
	stx	zActAddr
	jsr	CharXfer

;------------------------------------------------------------------------------
;	UpdateDisp:
;
UpdateDisp:

	jsr	ShowChars
	jsr	ShowPalet
	jsr	ReDisp

	rts

;------------------------------------------------------------------------------
;	PutEditChar:	編集中キャラクタ表示
;
PutEditChar:
	ldy	#0
	lda	editMode
	beq	@PECJ10				; 8x8 mode
						;--- 16x16 mode
	ldy	putPos
	iny
	tya
	asl	a
	tay
@PECJ10:
	ldx	putEdCharPos+1,y
	lda	putEdCharPos,y
	jsr	SetPpuAddr
	lda	currentEdCharNo
	sta	PPU_DATA

	rts

;------------------------------------------------
putEdCharPos:
	.addr	EDIT_CHAR_POS0
	.addr	EDIT_CHAR_POS1, EDIT_CHAR_POS1+1, EDIT_CHAR_POS1+32, EDIT_CHAR_POS1+33

;------------------------------------------------------------------------------
;	PaletCurUpdate:
;
PaletCurUpdate:
	lda	palNum
	pha
	and	#$f8
	bne	@PCUJ10
	lda	#136
	bne	@PCUJ20
@PCUJ10:
	lda	#136+8
@PCUJ20:
	ldx	editMode
	beq	@PCUJ30
	clc
	adc	#64
@PCUJ30:
	sta	PALET_CURSOR + Y_POS

	lda	#128-1
	ldx	editMode
	beq	@PCUJ40
	lda	#192-1
@PCUJ40:
	sta	PALET_CURSOR2 + Y_POS

	pla
	and	#$07
	asl	a
	asl	a
	asl	a

	adc	#24
	sta	PALET_CURSOR2 + X_POS

	rts

;------------------------------------------------------------------------------
;	ChangeMode:	編集モード切り替え
;
ChangeMode:
	lda	#0
	sta	putPos
	sta	charEditPos
	sta	editX
	sta	editY
	jsr	UpdateEditCur

	lda	editMode
	clc
	adc	#MODE_16X16
	and	#$07
	sta	editMode

	jsr	ClsFC
	jsr	ShowChars
	jsr	PaletCurUpdate
	jsr	ShowPalet
ReDisp:
	ldx	#0
	lda	editMode
	bne	@CMJ10				; 16x16

	jsr	@CMSub

	rts

;------------------------------------------------
@CMJ10:
	ldx	#4-1
	stx	putPos
@CMLoop:
	txa
	pha

	;eor	#$03
	tax

	lda	#1
	sta	charDirty

	jsr	@CMSub
	jsr	CalcMarkCurPos

	dec	putPos

	pla
	tax
	dex
	bpl	@CMLoop

	inx
	stx	putPos

	lda	editCharNo,x
	sta	currentEdCharNo

	rts

;------------------------------------------------
@CMSub:
	lda	editCharNo,x
	sta	currentEdCharNo

	jsr	Extent8x8
	jsr	Put8x8

	rts

;------------------------------------------------------------------------------
;	KeyAct:
;
;	IN	A:Key code
;
KeyAct:
	tax
	ldy	#0
@KeyActLoop:
	lda	#$ff
	cmp	(zTempPtr),y
	beq	KAEnd				; End Table

	txa
	cmp	(zTempPtr),y
	beq	KAJ10				; 第1 Key 一致
	iny
	cmp	(zTempPtr),y
	beq	KAJ20				; 第2 Key 一致

	iny
	iny
	iny
	bne	@KeyActLoop
KAEnd:
	clc

	rts

;------------------------------------------------
KAJ10:
	iny
KAJ20:
	iny

	lda	(zTempPtr),y
	sta	zActAddr
	iny
	lda	(zTempPtr),y
	sta	zActAddr+1

	jmp	(zActAddr)

;------------------------------------------------
tblKeyAct:
	.byte	'J',DOWN_KEY
	.addr	CurDown
	.byte	'K',UP_KEY
	.addr	CurUp
	.byte	'L',LEFT_KEY
	.addr	CurRight
	.byte	'H',RIGHT_KEY
	.addr	CurLeft

	.byte	'P',$00				; パレット変更
	.addr	PaletUp
	.byte	'N',$00				; 次キャラクタ
	.addr	NextEditChar
	.byte	' ',$00				; Dot変更
	.addr	PutDot
	.byte	'S',$00				; OBJ/BG切り替え
	.addr	FlipBgObj
	.byte	'M',$00				; 8x8,16x16切り替え
	.addr	ChangeMode

	.byte	$ff

tblSftKeyAct:
	.byte	'J',DOWN_KEY
	.addr	MarkCurDown
	.byte	'K',UP_KEY
	.addr	MarkCurUp
	.byte	'L',LEFT_KEY
	.addr	MarkCurRight
	.byte	'H',RIGHT_KEY
	.addr	MarkCurLeft

	.byte	$ff

MarkCurDown:
	lda	#8
	bne	MCUJ10
MarkCurUp:
	lda	#$f8
MCUJ10:
	clc
	adc	markY
	sta	markY
	jmp	MCEnd

MarkCurRight:
	lda	#8
	bne	MCLJ10
MarkCurLeft:
	lda	#$f8
MCLJ10:
	clc
	adc	markX
	sta	markX
MCEnd:
	jsr	CalcMarkCurPos

	sec

	rts

;------------------------------------------------------------------------------
;	InitMarkCur:
;
InitMarkCur:
	ldx	#16-1
@IELoop:
	ldy	#4-1
@IELoop2:
	lda	tblCurs,y
	sta	MARK_CURSOR,x
	dex
	dey
	bpl	@IELoop2

	inx
	dex
	bpl	@IELoop

	inx
	ldy	#$00
@IMCL20:
	lda	tblMarkAttr,y
	sta	MARK_CURSOR + OBJ_ATTR,x
	lda	#$f8
	sta	MARK_CURSOR + OBJ_NO,x
	inx
	inx
	inx
	inx
	iny
	cpy	#4
	bne	@IMCL20

	rts

;------------------------------------------------
tblMarkAttr:
	.byte	$83, $c3, $03, $43

;------------------------------------------------------------------------------
;	CalcMarkCurPos:
;
CalcMarkCurPos:
						; 編集モードチェック
	lda	editMode
	bne	@CMCPJ10			; 16x16
						;--- 8x8
	ldx	#$0f
	lda	#112
	bne	@CMCPJ15
@CMCPJ10:					;--- 16x16
	ldx	#$07
	lda	#176
@CMCPJ15:
	stx	zTempPtr
	sta	zTempPtr+1
						;--- カーソル
	lda	putPos
	asl	a
	asl	a
	tax					; カーソル用スプライト:MARK_CURSOR + putPos * 4

	lda	currentEdCharNo			; カーソル:X_POS
	and	zTempPtr
	asl	a
	asl	a
	asl	a
	clc
	adc	zTempPtr+1			; CharNo * 8 + 112
	sta	MARK_CURSOR + X_POS,x
						; カーソル:Y_POS
	lda	zTempPtr
	eor	#$ff
	and	currentEdCharNo

	ldy	editMode
	bne	@CMCPJ20
	lsr	a
@CMCPJ20:
	clc
	adc	#24-1
	sta	MARK_CURSOR + Y_POS,x

	rts

;------------------------------------------------------------------------------
;	CurDown:
;	CurUp:
;	CurRight:
;	CurLeft:
;
CurDown:
	inc	editY
	jmp	CLJ10
CurUp:
	dec	editY
	jmp	CLJ10
CurRight:
	inc	editX
	bne	CLJ10
CurLeft:
	dec	editX
CLJ10:
	jsr	AdjustCur
	jsr	UpdateEditCur

	rts

;------------------------------------------------
;	AdjustCur:
;
AdjustCur:
	lda	putPos
	sta	prePutPos

	ldx	#$07

	lda	editMode
	beq	@ACJ10				; 8x8

	ldx	#$0f
@ACJ10:
	txa
	and	editX
	sta	editX
	lsr	a
	lsr	a
	lsr	a
	sta	putPos

	txa
	and	editY
	sta	editY
	pha

	lsr	a
	lsr	a
	and	#$02
	ora	putPos
	sta	putPos
	cmp	prePutPos
	beq	@ACJ20

	sta	charDirty
	tax
	lda	editCharNo,x
	sta	currentEdCharNo
	jsr	Extent8x8
@ACJ20:
	pla
	and	#$07
	asl	a
	asl	a
	asl	a
	sta	charEditPos
	lda	editX
	and	#$07
	clc
	adc	charEditPos
	sta	charEditPos
;@End:
	rts

;------------------------------------------------------------------------------
;	CmdPCG:	キャラクタ編集
;
CmdPCG:
	jsr	SaveBasWork

	dec	zpCursorChar			; now cursor char no. <- $fc

	jsr	CmdFn_SPRITE_ON

	lda	#$c0
	sta	NMI_FLAG
						;--- 初期化
	jsr	SetStrBufPtr

	lda	#0
	sta	editMode			; 8x8 mode
	sta	palNum
	sta	paletVal
	sta	putPos

	sta	editX
	sta	editY
	sta	markX
	sta	markY

	lda	#$08
	sta	flgBgObj
	sta	charDirty

	jsr	ClsFC
	jsr	InitEditChar
	jsr	InitEdCur
	jsr	FlipBgObj
						;--- 編集
	jsr	Edit8x8
@Exit:						;--- 終了
	jsr	WaitForVBlank
	jsr	RestoreChar
	jsr	ClearOam

	inc	zpCursorChar			; cursor char no. <- $fd

	jsr	VOn

	lda	#$08
	sta	flgBgObj

	lda	#$20
	jsr	CLS2

	jsr	RestoreBasWork
PCGEND:
	rts

.byte	">&"
