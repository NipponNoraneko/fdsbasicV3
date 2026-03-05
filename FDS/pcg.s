;ts=8
;------------------------------------------------------------------------------
zActAddr	=	zpPokeAddr
paletNo		=	zpPaletteNum
palNum		=	zpGameNum

charDirty	=	zpSavedCH
charEditPos	=	zpSavedCV

;------------------------------------------------------------------------------
PCG_READ	=	$02
PCG_WRITE	=	$00

OBJ_TOP		=	0
BG_TOP		=	$10

PALET_CUR	=	$2f0
PAL2_CUR	=	$2f4
MARK_CUR	=	$2f8
EDIT_CUR	=	$2fc

.enum
	Y_POS		=	0
	OBJ_NO
	OBJ_ATTR
	X_POS
.endenum
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
	jsr	VOff
	jsr	WaitVsync

	lda	zBufAddr
	sta	vramPtr				; 転送元lower
	lda	zBufAddr+1
	sta	vramPtr+1			;       upper
	sec
	sbc	#$60
	tay					; Y:書き戻し先 upper
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
;	Extent8x8:
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
	lda	#$a3
	sta	zActAddr
	lda	#$20
	sta	zActAddr+1

	lda	#0
	tay					; A,X,Y = 0
@P88L05:
	ldx	#0
@P88L10:
	lda	charBuf,y
	bne	@P88J10

	lda	#$20
	bne	@P88J20
@P88J10:
	clc
	adc	#$fc
@P88J20:
	sta	lineBuffer80,x
	iny
	inx
	cpx	#8
	bne	@P88L10

	sty	tmpY
	lda	#0
	sta	lineBuffer80,x

	jsr	Buf2VRAM
	jsr	NextLine

	ldy	tmpY
	cpy	#64
	bne	@P88L05
;212c
;	jsr	VOff
;	jsr	WaitVsync
	ldx	#$21
	lda	#$2c
	jsr	SetPpuAddr
	lda	editCharNo
	sta	PPU_DATA

	rts

;------------------------------------------------------------------------------
;	ShowChars:
;
ShowChars:
	lda	#$6e
	sta	zActAddr
	lda	#$20
	sta	zActAddr+1

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
	sta	lineBuffer80,x			;

	jsr	Buf2VRAM
	jsr	NextLine

	pla
	ldx	#00

	dec	tmpY
	bne	@SCL10

	jsr	VOn

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

	jsr	VOff
	jsr	WaitVsync

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

;	lda	#$31				; 01 00
						; 11 00
;	sta	PPU_DATA

	jsr	VOn

	rts

;------------------------------------------------------------------------------
;	PaletUP:
;
;		A|B
;		C|D		paletNo = dd.cc.bb.aa
;
PaletUp:
	lda	zpShiftKeyDn
	bne	@PUJ10

	inc	palNum
	lda	palNum
	and	#$0f
	sta	palNum
	jmp	ChangePalet
@PUJ10:
	lda	paletNo
	clc
	adc	#$55
	bcc	@Skip
	lda	#0
@Skip:
	sta	paletNo

ChangePalet:
	jsr	VOff
	jsr	WaitVsync

	ldx	#$23
	lda	#$c0
	jsr	SetPpuAddr

	lda	paletNo
	ldx	#40
@FillLoop:
	sta	PPU_DATA
	dex
	bne	@FillLoop

	jsr	RestorePalDisp

	rts

;------------------------------------------------------------------------------
InitEdCur:
	lda	#0
	sta	charEditPos

	ldx	#16-1
@IELoop:
	lda	paletCur,x
	sta	PALET_CUR,x
	dex
	bpl	@IELoop
							;---- Edit Cursor Update
UpdateCur:
	lda	charEditPos
	pha
	and	#$07
	asl
	asl
	asl
	clc
	adc	#(1+2)*8
	sta	EDIT_CUR + X_POS

	pla
	and	#$f8
	clc
	adc	#(2+3)*8-1
	sta	EDIT_CUR + Y_POS

	rts

paletCur:.byte	136, $fd, $03, 16
pal2Cur:.byte	128-1, $fc, $83, 24
markCur:.byte	24-1, $ff, $03, 112 
editCur:.byte	(2+3)*8-1, $fe, $03, (1+2)*8

;------------------------------------------------------------------------------
;	Edit8x8:
Edit8x8:
	lda	#0
	sta	editCharNo
	sta	preChar
@E88L10:					;--- 拡大表示(8x8)
	jsr	Clr8x8
	jsr	Extent8x8
@E88Loop:
	jsr	Put8x8

	jsr	VOn

@KeyWait:
	ldy	#5
	jsr	WaitVsyncY

	jsr	ReadKeyInsMacros
	bne	@KWJ10
	lda	preChar
	bne	@KWJ20
@KWJ10:
	sta	preChar
	beq	@KeyWait
@KWJ20:
	cmp	#'Q'
	beq	@Exit

	jsr	KeyAct
	lda	charDirty
	bne	@E88L10
	beq	@E88Loop
@Exit:
	rts

preChar:.res	1

;------------------------------------------------------------------------------
;	KeyAct:
;
;	IN	A:Key code
;
KeyAct:
	tay
	ldx	#0
	stx	preChar
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
	.addr	IncEditChar
	.byte	' ',$00				; Dot変更
	.addr	PutDot

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
IncEditChar:
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
@MUEnd:
	sta	MARK_CUR + X_POS
	pla
	and	#$f0
	lsr	a
	clc
	adc	#24-1
	sta	MARK_CUR + Y_POS

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

	jsr	UpdateCur

	rts

.segment	"FDS_PATCH"
;------------------------------------------------------------------------------
;	CmdPCG:
CmdPCG:
	lda	#0
	jsr	$ae0a
	jsr	SaveBasWork

	jsr	VOff
	lda	#$00
	sta	PPU_MASK
	sta	$100
	jsr	VINTWait
						;--- $1000~$1fff -> $7000~ BGすべて
	lda	#PCG_READ
	ldy	#$10
	ldx	#0
	jsr	LoadTileset
	.addr	$7000
						;--- $0f00~$0fff -> $6c00~ OBJ:F0~FF
	lda	#PCG_READ | $00
	ldy	#$0f
	ldx	#16
	jsr	LoadTileset
	.addr	$6c00
						;--- $7b00~$7b0f -> $0ff0~ '□'->OBJ:FF
	lda	#PCG_WRITE | $f0
	ldy	#$0f
	ldx	#1
	jsr	LoadTileset
	.addr	$7b00
						;--- $7dd0~$7ddf -> $0ff0~ '✛'->OBJ:FE
	lda	#PCG_WRITE | $e0
	ldy	#$0f
	ldx	#1
	jsr	LoadTileset
	.addr	$7dd0
						;--- $73e0~$73ef -> $0ff0~ '>'->OBJ:FD
	lda	#PCG_WRITE | $d0
	ldy	#$0f
	ldx	#1
	jsr	LoadTileset
	.addr	$73e0
						;--- $75e0~$75ef -> $0ff0~ '^'->OBJ:FC
	lda	#PCG_WRITE | $c0
	ldy	#$0f
	ldx	#1
	jsr	LoadTileset
	.addr	$75e0

	jsr	VOn
	lda	zpPpuMaskVal
	sta	PPU_MASK

	jsr	RestoreBasWork
	lda	#$c0
	sta	$100
						;--- キャラクタ一覧表示
	jsr	SetStrBufPtr
	jsr	ShowChars
						;--- パレット表示
	lda	#0
	sta	paletNo
	sta	palNum
	jsr	ShowPalet

	jsr	InitEdCur
	jsr	Edit8x8
@Exit:						;--- 終了:全体書き戻し
	jsr	SaveBasWork

	jsr	VOff
	lda	#$00
	sta	PPU_MASK

	lda	#PCG_WRITE
	ldy	#$10
	ldx	#0
	jsr	LoadTileset
	.addr	$7000
						;--- $0f00~$0fff <- $6c00~ OBJ:F0~FF
	lda	#PCG_WRITE | $00
	ldy	#$0f
	ldx	#16
	jsr	LoadTileset
	.addr	$6c00

	jsr	VOn
	lda	zpPpuMaskVal
	sta	PPU_MASK

	jsr	RestoreBasWork
PCGEND:
	rts
