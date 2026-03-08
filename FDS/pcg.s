;ts=8

;------------------------------------------------------------------------------
zActAddr	=	zpPokeAddr
paletNo		=	zpPaletteNum
palNum		=	zpGameNum

charDirty	=	zpSavedCH
charEditPos	=	zpSavedCV

paletCursor	=	$2f0
paletCursor2	=	$2f4
markCursor	=	$2f8
editCursor	=	$2fc

;------------------------------------------------------------------------------
PCG_READ	=	$02
PCG_WRITE	=	$00

OBJ_TOP		=	0
BG_TOP		=	$10

PUT8X8_POS	=	$20a3
EDIT_CHAR_POS	=	$212c
CHARS_SHOW_POS	=	$206e

;------------------------------------------------------------------------------
.segment	"ORG_TOKEN_AREA"

flgBgObj:
	.byte	$08

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
;	zBufAddr = editCharNo * 16 + $7000
;
CalcCharAddr:
	lda	editCharNo

	sta	zBufAddr
	lda	#0
	sta	zBufAddr+1

	ldx	#4
@D88L10:
	asl	zBufAddr
	rol	zBufAddr+1
	dex
	bne	@D88L10

	lda	#$70
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

	sty	charDirty
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
	lda	editCharNo
	asl	a
	asl	a
	asl	a
	asl	a				; A:書き戻し先 lower
	ldx	#1				; X:転送キャラ数 1
	jsr	LoadTileset
vramPtr:.addr	$7000				; 転送元アドレス

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
Put8x8:
						;--- 表示位置
	ldx	#>PUT8X8_POS
	lda	#<PUT8X8_POS
	jsr	SetActAddr
						;--- 
	ldy	#0
@P88L05:					;--- 一行表示
	ldx	#0
@P88L10:
	lda	charBuf,y
	bne	@P88J10
@P88J10:
	clc
	adc	#$fc
	sta	lineBuffer80,x
	iny
	inx
	cpx	#8
	bne	@P88L10				; 一行未完

	sty	tmpY
	lda	#0
	sta	lineBuffer80,x			; デリミタ

	jsr	Buf2VRAM			; 一行表示
	jsr	NextLine

	ldy	tmpY
	cpy	#64
	bne	@P88L05				; 次行
						;--- 編集中キャラ表示
	ldx	#>EDIT_CHAR_POS
	lda	#<EDIT_CHAR_POS
	jsr	SetPpuAddr

	lda	editCharNo
	sta	PPU_DATA

	rts

;------------------------------------------------------------------------------
;	ShowChars:
;
ShowChars:
	lda	charDirty
	beq	@SCEnd

	ldx	#>CHARS_SHOW_POS
	lda	#<CHARS_SHOW_POS
	jsr	SetActAddr

	ldy	#16
	sty	tmpY
	lda	#0
	tax
@SCL10:
	sta	lineBuffer80,x
	clc
	adc	#1
	inx
	cpx	#16
	bne	@SCL10
						;---
	pha
	lda	#0
	sta	lineBuffer80,x			; 文字列デリミタ:0

	jsr	Buf2VRAM
	jsr	NextLine

	pla
	ldx	#00

	dec	tmpY
	bne	@SCL10

	sty	charDirty

	jsr	VOn
@SCEnd:
	rts

NextLine:
	lda	zActAddr
	clc
	adc	#32
	sta	zActAddr
	bcc	@NLEnd
	inc	zActAddr+1
@NLEnd:
	rts

;------------------------------------------------------------------------------
;	ShowPalet:	パレット表示

ShowPalet:
	lda	#$00
	sta	paletNo

	lda	#0
	sta	zpCH
	lda	#14
	sta	zpCV

	lda	#STR_PALLET
	jsr	PutStr
	jsr	DoCRLF
	lda	#STR_PALLET
	jsr	PutStr

	jsr	VOffWaitVsync
RestorePalDisp:
	ldx	#$23
	lda	#$e1
	jsr	SetPpuAddr

	lda	#$a0				; 00 00
						; 10 10
	sta	PPU_DATA

	lda	#$f5				; 01 01
						; 11 11
	sta	PPU_DATA

	jsr	VOn

	rts

;------------------------------------------------------------------------------
;	PaletUP:
;
;	A|B
;	C|D		paletNo = dd.cc.bb.aa
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
	sta	paletNo

ChangePalet:
	jsr	VOffWaitVsync

	ldx	#>BG_COLOR1_ADDR
	lda	#<BG_COLOR1_ADDR
	jsr	SetPpuAddr

	lda	paletNo
	ldx	#40
@FillLoop:
	sta	PPU_DATA
	dex
	bne	@FillLoop

	jsr	RestorePalDisp

	jsr	PaletCurUpdate

	rts

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

	ldx	#16-1
@IELoop:
	lda	cursTbl,x
	sta	paletCursor,x
	dex
	bpl	@IELoop
							;---- Edit Cursor Update
EditCurUpdate:
	lda	charEditPos
	pha
	and	#$07
	asl
	asl
	asl
	clc
	adc	#(1+2)*8
	sta	editCursor + X_POS

	pla
	and	#$f8
	clc
	adc	#(2+3)*8-1
	sta	editCursor + Y_POS

	rts

cursTbl:
paletCur:
	.byte	136,       $fa, $03, 16
pal2Cur:.byte	128-1,     $fb, $83, 24
markCur:.byte	24-1,      $f8, $03, 112 
editCur:.byte	(2+3)*8-1, $f9, $03, (1+2)*8

;------------------------------------------------------------------------------
;	Edit8x8:
;
Edit8x8:
	lda	#0
	sta	editCharNo
@E88L10:					;--- 拡大表示(8x8)
	jsr	Clr8x8
	jsr	Extent8x8
@E88Loop:
	jsr	Put8x8

	jsr	VOn

@KeyWait:
	jsr	ReadChar			; BASIC routine
	beq	@KeyWait

	cmp	#'Q'
	beq	@Exit

	jsr	KeyAct

	lda	charDirty
	bne	@E88L10
	beq	@E88Loop
@Exit:
	rts

;------------------------------------------------------------------------------
;	KeyAct:
;
;	IN	A:Key code
;
KeyAct:
	tay
	ldx	#0
@KeyActLoop:
	lda	#$ff
	cmp	keyActTbl,x
	beq	KAEnd				; End Table

	tya
	cmp	keyActTbl,x
	beq	KAJ10				; 第1 Key 一致
	inx
	cmp	keyActTbl,x
	beq	KAJ20				; 第2 Key 一致

	inx
	inx
	inx
	bne	@KeyActLoop
KAEnd:						; ここには到達しないはずだが
	rts					; 念の為
KAJ10:
	inx
KAJ20:
	inx
	lda	keyActTbl,x
	sta	zActAddr
	lda	keyActTbl+1,x
	sta	zActAddr+1

	jmp	(zActAddr)

;------------------------------------------------
keyActTbl:
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

	.byte	$ff

;------------------------------------------------------------------------------
PutDot:
	ldy	charEditPos
	lda	palNum
	and	#$03
	sta	charBuf,y

	inc	charDirty

	jsr	Pack8x8

	rts

;------------------------------------------------------------------------------
NextEditChar:
	lda	zpShiftKeyDn
	bne	@DecNo

	inc	editCharNo
	jmp	MarkUpdate
@DecNo:
	dec	editCharNo

MarkUpdate:
	lda	editCharNo
	pha
	and	#$0f
	asl	a
	asl	a
	asl	a
	clc
	adc	#112
	sta	markCursor + X_POS

	pla
	and	#$f0
	lsr	a
	clc
	adc	#24-1
	sta	markCursor + Y_POS

	jsr	Clr8x8
	jsr	Extent8x8

	rts

;------------------------------------------------------------------------------
CurDown:
	lda	charEditPos
	clc
	adc	#8
	jmp	CurUpdateEnd
CurUp:
	lda	charEditPos
	sec
	sbc	#8
	jmp	CurUpdateEnd
CurRight:
	inc	charEditPos
	lda	charEditPos
	jmp	CurUpdateEnd
CurLeft:
	dec	charEditPos
	lda	charEditPos
CurUpdateEnd:
	and	#$3f
	sta	charEditPos

	jsr	EditCurUpdate

	rts

;.byte	">$"

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
srcDist: .addr	$7000

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
XfrEnd:

.segment	"FDS_PATCH"
;------------------------------------------------------------------------------
xferTbl:
	.byte	$00|PCG_READ,  $10, 0, <$7000, >$7000		; $1000~$1fff -> $7000~ BGすべて
	.byte	$80|PCG_WRITE, $1f, 8, <$6c80, >$6c80		; $0f00~$0fff <- $6c00~ OBJ:F0~FF
	.byte	$80|PCG_READ,  $1f, 8, <$6c80, >$6c80		; $0f00~$0fff -> $6c00~ OBJ:F0~FF
	.byte	$80|PCG_WRITE, $0f, 8, <$6a00, >$6a00		; $7d90~$7d9f -> $0ff0~ '□'->OBJ:d9
	.byte	$c0|PCG_WRITE, $1f, 4, <$6a40, >$6a40		; $7d90~$7d9f -> $0ff0~ '□'->OBJ:d9
	
xferTbl2:
	.byte	$00|PCG_READ,  $00, 0, <$7000, >$7000		; $0000~$0fff -> $7000~ OBJすべて
	.byte	$80|PCG_WRITE, $0f, 8, <$6c00, >$6c00		; $0f00~$0fff <- $6c00~ OBJ:F0~FF
	.byte	$80|PCG_READ,  $0f, 8, <$6c00, >$6c00		; $0f00~$0fff -> $6c00~ BG:F0~FF
	.byte	$80|PCG_WRITE, $1f, 8, <$6a00, >$6a00		; $7d90~$7d9f -> $0ff0~ '□'->OBJ:d9
	.byte	$c0|PCG_WRITE, $0f, 4, <$aa40, >$6a40		; $7d90~$7d9f -> $0ff0~ '□'->OBJ:d9
	
xferEditTbl:
	.byte	$80|PCG_READ,  $0f, 8, <$6c00, >$6c00		; $0f80~$0fff -> $6c00~ OBJ:F0~FF
	.byte	$80|PCG_READ,  $1f, 8, <$6c80, >$6c80		; $1f80~$0fff -> $6c80~ BG:F0~FF
	.byte	$90|PCG_READ,  $0d, 1, <$6a00, >$6a00		; '└'->OBJ:FF
	.byte	$d0|PCG_READ,  $0d, 1, <$6a10, >$6a10		; '✛'->OBJ:FE
	.byte	$e0|PCG_READ,  $13, 1, <$6a20, >$6a20		; '>'->OBJ:FD
	.byte	$e0|PCG_READ,  $15, 1, <$6a30, >$6a30		; '^'->OBJ:FC
	.byte	$00|PCG_READ,  $12, 1, <$6a40, >$6a40		; ' '->OBJ:FC
	.byte	$d0|PCG_READ,  $1f, 3, <$6a50, >$6a50		; '■■■'-> OBJ:FC

xferRestoreTbl:
	.byte	$80|PCG_WRITE, $0f, 8, <$6c00, >$6c00		; $0f80~$0fff <- $6c00~ OBJ:F0~FF
	.byte	$80|PCG_WRITE, $1f, 8, <$6c80, >$6c80		; $1f80~$1fff <- $6c80~ BG:F0~FF

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
UpdateDisp:

	jsr	ShowChars
	jsr	ShowPalet
	
	rts

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
	sta	paletCursor + Y_POS

	pla
	and	#$07
	asl	a
	asl	a
	asl	a
	clc
	adc	#24
	sta	paletCursor2 + X_POS

	rts

;------------------------------------------------------------------------------
;	Edit8x8:
;------------------------------------------------------------------------------
;	CmdPCG:
CmdPCG:
	jsr	SaveBasWork

	lda	#$fc
	sta	zpCursorChar

	jsr	CmdFn_SPRITE_ON

	lda	#$c0
	sta	$100

	jsr	SetStrBufPtr

	lda	#0
	sta	paletNo
	sta	palNum

	lda	#$fc
	sta	charDirty
	jsr	CLS2

	jsr	InitEdCur
	jsr	FlipBgObj

	jsr	Edit8x8
@Exit:						;--- 終了
	jsr	WaitForVBlank
	jsr	RestoreChar
	jsr	ClearOam

	lda	#$fd
	sta	zpCursorChar

	jsr	VOn

	lda	#$08
	sta	flgBgObj

	lda	#$20
	jsr	CLS2

	jsr	RestoreBasWork
PCGEND:
	rts

.byte	">$"
