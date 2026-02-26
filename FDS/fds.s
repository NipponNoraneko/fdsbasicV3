; ts=8
;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------
zBufAddr	=	zpPokeAddr		; zpPokeAddrはPOKE以外で使われていない(多分)

;------------------------------------------------
diskID		=	diskInfoBlock+$0e
fileAmount	=	diskID+$0a
lineBuffer80	=	lineBuffer+$80		; temp use: BASIC lineBuffer($500~)の後半部分

;------------------------------------------------------------------------------
;	SaveBasWork:	 BASIC領域の退避
;
SaveBasWork:
	ldx	#$0f
@SBW10:
	lda	tempzp,x
	sta	tempzpSav,x
	lda	joypad,x
	sta	joypadSav,x
	dex
	bpl	@SBW10
						;--- PPU setting
	lda	zpPpuMaskVal
	sta	PPU_MASK_Mirror
	lda	zpPpuCtrlVal
	sta	PPU_CTRL_Mirror

	jsr	RBEnd
	sta	FDS_CTRL_Mirror

	rts

;------------------------------------------------------------------------------
;	RestoreBasWork:	BASIC領域の復元
;
RestoreBasWork:
	ldx	#$0f
@RBW10:
	lda	tempzpSav,x
	sta	tempzp,x
	lda	joypadSav,x
	sta	joypad,x
	dex
	bpl	@RBW10

	lda	zpPpuMaskVal
	sta	PPU_MASK
	lda	zpPpuCtrlVal
	ora	#$80
	sta	PPU_CTRL
RBEnd:
	lda	#$27
	sta	FDS_CTRL

	rts

;------------------------------------------------------------------------------
VsyncOn:
	lda	#$c0
	sta	NMI_FLAG

	lda	PPU_CTRL_Mirror
	ora	#$80
	bne	SetPPU

;------------------------------------------------
VsyncOff:
	lda	#$00
	sta	NMI_FLAG

	lda	PPU_CTRL_Mirror
	and	#$7f

;------------------------------------------------
SetPPU:
	sta	PPU_CTRL
	sta	PPU_CTRL_Mirror

	lda	zpPpuMaskVal
	sta	PPU_MASK
	sta	PPU_MASK_Mirror

	lda	#$27
	sta	FDS_CTRL

	rts

;------------------------------------------------------------------------------
;	ResetFDS:	FDSリセット
;
ResetFDS:
	jsr	EndFDS				; FDS Reset
						;----- BIOS Reset condition
	lda	#$c0				; user NMI
	sta	NMI_FLAG
	lda	#$80
	sta	IRQ_FLAG
	lda	#$53
	sta	RESET_TYPE

	rts

;------------------------------------------------------------------------------
;
EndFDS:
	lda	#$26				; $26: |H-SCRL|READ|M-STOP|RESET|
	sta	FDS_CTRL

	ldy	#$05
	jsr	Delayms

	lda	#$27				; $27: |H-SCRL|READ|M-STOP|NO-RESET|
	sta	FDS_CTRL
	sta	FDS_CTRL_Mirror

	lda	#$c0
	sta	IRQ_FLAG

	rts

;------------------------------------------------------------------------------
;	SenceCard:	DiskCard挿入状態
;
;	RET	A.d0 = 挿入状態
;
SenceCard:
	lda	FDS_DRIVE_STATUS
	and	#$01

	rts

;------------------------------------------------------------------------------
;	SenceBattly:	バッテリ・チェック
;
;	RET	CY = Battly bit
;
SenceBattly:
	lda	#$80
	sta	FDS_EXT
	lda	FDS_BATTERY_EXT

	asl	a

	rts

;------------------------------------------------------------------------------
;	ReadBtye:	1 byte読込み
;
;	RET:	A = 読込みデータ
;
ReadByte:
	lda	#$25				; $25: |H-SCRLL|READ|NO_RESET|
	sta	FDS_CTRL

	ldy	#$05
	jsr	Delayms

	lda	#$65				; $65: |CRC_CLR|H-SCRL|READ|NO_RESET|
	sta	FDS_CTRL
@RB10:						;--- Wait R/W Enable
	bit	FDS_STATUS
	bpl	@RB10

	lda	FDS_READ_DATA

	rts

;------------------------------------------------------------------------------
;	FDSStart:	
;
FDSStart:
	lda	#$00
	sta	readCnt
	sta	readCnt+1
	sta	fileCnt

	jsr	WaitForReady

	ldy	#$c5
	jsr	Delayms
	ldy	#$46
	jsr	Delayms

	rts

;------------------------------------------------------------------------------
;	SetReadCnt:
;
SetReadCnt1:
	sta	readCnt
	lda	#0
	sta	readCnt+1

	rts

;------------------------------------------------------------------------------
;	DecReadCnt:	readCnt - 1
;
DecReadCnt:
	dec	readCnt
	bne	@DRCEnd
	lda	readCnt+1
	beq	@DRCEnd
	dec	readCnt+1
@DRCEnd:
	rts

;------------------------------------------------------------------------------
;	ReadBlockNN:	one block read
;
;	IN	XY= read buffer address
;		X: address upper
;		Y: lower
;

ReadBlock01:
	ldx	#>diskInfoBlock
	ldy	#<diskInfoBlock

	lda	#DISK_INFO_BLK_SIZE-1
	jsr	SetReadCnt1

	lda	#01
	bne	ReadBlockNN

ReadBlock03:
	lda	#FILE_HDR_BLK_SIZE-1
	jsr	SetReadCnt1

	lda	#03
;	bne	ReadBlockNN

;ReadBlock04:
;	lda	#04
ReadBlockNN:
	sty	zBufAddr
	stx	zBufAddr+1

	jsr	CheckBlockType
						;---
	ldy	#$00
RBlk10:
	jsr	XferByte
	sta	(zBufAddr),y

	iny
	cpy	readCnt
	bne	RBlk10

	jsr	EndOfBlockRead

	rts

;------------------------------------------------------------------------------
;	SkipBlockNN
;	Skip reading Block
;
;	IN	readCnt = num of skip byte
;		A = Block No.
;
SkipBlockNN:
	jsr	CheckBlockType
@SkpBlk10:
	jsr	XferByte

	jsr	DecReadCnt
	bne	@SkpBlk10	
@SkpBlkEnd:
	jsr	EndOfBlockRead

	rts

PutTotalFileSize:

	rts


;------------------------------------------------------------------------------
;	ReadCardInfo:	カード情報取得
;
ReadCardInfo:
	jsr	FDSStart

	jsr	ReadBlock01				; Block 01

	ldx	#>block03Buf
	stx	zBufAddr+1
	ldy	#<block03Buf
	sty	zBufAddr

							;----- Block 02 (ファイル数)
	jsr	GetNumFiles
	ldx	tempzp+6
	stx	fileAmount
	stx	fileCnt
							;----- Block 03
@FLLoop:
	ldx	zBufAddr+1
	ldy	zBufAddr
	jsr	ReadBlock03				; Block 03 読込み
							;--- Block 04 (Skip reading)
							; block04バイト数
	ldy	#$0c
	lda	(zBufAddr),y
	sta	readCnt
	iny
	lda	(zBufAddr),y
	sta	readCnt+1

	lda	#$04
	jsr	SkipBlockNN				; Block 04読み飛ばし
							;--- 次block03アドレス
	lda	zBufAddr
	clc
	adc	#$10
	bcc	@FL15

	inc	zBufAddr+1
@FL15:
	sta	zBufAddr
							;--- to Next block03
	dec	fileCnt
	bne	@FLLoop
							;--- 終了
	jsr	EndFDS

	rts

; in A,X
PutHexDat:
	stx	tmpX
	clc
	jsr	Bin2Hex
	ldx	tmpX

	lda	hexDat+1
	sta	lineBuffer80,x
	inx
	lda	hexDat
	sta	lineBuffer80,x
	inx

	rts

tmpX:	.res	1

;------------------------------------------------------------------------------
;	MakeFileListLine:	詳細ファイル行作成
;
MakeFileListLine:
	ldx	#0
	jsr	QueueFileName

	lda	#' '
	sta	lineBuffer80,x
	inx
						;--- store address	
	lda	(tmpAccm),y
	jsr	PutHexDat

	dey
	lda	(tmpAccm),y
	jsr	PutHexDat

	lda	#' '
	sta	lineBuffer80,x
	inx
						;--- file size
	iny
	iny
	iny
	lda	(tmpAccm),y
	jsr	PutHexDat
	dey
	lda	(tmpAccm),y
	jsr	PutHexDat

	lda	#' '
	sta	lineBuffer80,x
	inx
						;--- file type
	iny
	iny
	lda	(tmpAccm),y
	ora	#'0'
	sta	lineBuffer80,x
	inx

	rts

;------------------------------------------------------------------------------
;
PrintFileLine:
	jsr	SetBlk03Ptr

	lda	#<lineBuffer80
	sta	zpOutputStr
	lda	#>lineBuffer80
	sta	zpOutputStr+1

	ldx	#>block03Buf
	stx	zBufAddr+1
	ldy	#<block03Buf
	sty	zBufAddr

	ldx	fileAmount
	stx	fileCnt
@PFL10:
	jsr	MakeFileListLine		; 表示行作成
	jsr	PrintString
	jsr	DoCRLF
	jsr	Add16

	dec	fileCnt
	bne	@PFL10

	rts

;------------------------------------------------------------------------------
;	FileList:	詳細ファイル・リスト取得
;
FileList:
	jsr	VsyncOff

	jsr	ReadCardInfo

	lda	#$02					; インデックス取得種別
	sta	diskInfoStat

	jsr	VsyncOn

	jsr	PrintFileLine

	rts

;------------------------------------------------------------------------------
;	LoadFile:
;
LoadFile:
						;--- 引数チェック
	jsr	EvalByteInteger
	jsr	BIN2BCD
	sta	loadList
	jsr	SearchFileID
	bcs	@LFErr

	jsr	VsyncOff
	jsr	VINTWait
	jsr	LoadFiles
	.addr	diskID
	.addr	loadList
	bne	@LFErr				; Error
	
	tya
	beq	@LFErr				; ファイル無し
						;--- BASIC file check
	ldy	$6001
	cpy	#'S'
	bne	@LFEnd
	ldy	$6000
	cpy	#'B'
	bne	@LFEnd

	sty	loadFileType

;--- Set zpTXTTAB,ZpTXTEND
	ldx	#$03
@LF30:
	lda	$6002,x
	sta	tempzpSav+zpTXTTAB,x
	dex
	bpl	@LF30

;--- ヘッダ部クリア ------------------------
	lda	#$00
	ldx	#$05
@LF50:
	sta	$6000,x
	dex
	bpl	@LF50
@LFErr:
	jsr	QueueErrMsg
	jsr	ShortBeep
@LFEnd:
	jsr	VsyncOn

	rts

;--------------------------------------------
loadList:
	.byte	$81,$FF

;--------------------------------------------
sLoadFile:
	.asciiz	"LOADING..."


;------------------------------------------------------------------------------
;
;		IN	X: col position
;
QueueFileName:
	lda	#' '
	sta	lineBuffer80,x
	inx
						;--- fileID
	ldy	#$00
	lda	(tmpAccm),y
	jsr	PutHexDat

	lda	#':'
	sta	lineBuffer80,x
	inx
						;--- file name
	ldy	#1
@QFN10:
	lda	(tmpAccm),y
	bne	@QFN20
	lda	#$20				; ' '
@QFN20:
	sta	lineBuffer80,x
	inx
	iny
	cpy	#10-1
	bne	@QFN10

	iny

	rts

;------------------------------------------------------------------------------
ClrLineBuf:
	lda	#0
	ldy	#28-1
@CLB10:
	sta	lineBuffer80,y
	dey
	bpl	@CLB10

	rts

;------------------------------------------------------------------------------
;
ShortFileList:
	lda	fileAmount
	sta	fileCnt

	lda	#<lineBuffer80
	sta	zpOutputStr
	lda	#>lineBuffer80
	sta	zpOutputStr+1

	jsr	SetBlk03Ptr
@SFL05:
	jsr	ClrLineBuf
	ldx	#0
	lda	#2
@SFL10:
	pha
	jsr	QueueFileName

	jsr	Add16

	pla
	dec	fileCnt
	bne	@SFL30
@SFLPrint:
	jsr	PrintString
	jsr	DoCRLF

	rts
@SFL30:
	sec
	sbc	#1
	bne	@SFL10

	jsr	@SFLPrint

	jmp	@SFL05

;------------------------------------------------------------------------------
;
SetBlk03Ptr:
	pha
	lda	#>(block03Buf+1)
	sta	tmpAccm+1
	lda	#<(block03Buf+1)
	sta	tmpAccm

						; set record size
	lda	#$10
	sta	tmpAccm+2
	lda	#0
	sta	tmpAccm+3
	pla
	rts

;------------------------------------------------------------------------------
;	GetMaxFileID:	最大fileID
;
;		OUT	A: Max FileID
;
GetMaxFileID:
	jsr	SetBlk03Ptr

	lda	#0
	tay
	ldx	fileAmount
@GMFLoop:
	cmp	(tmpAccm),y
	bpl	@J10
	lda	(tmpAccm),y
@J10:
	jsr	Add16
	dex
	bne	@GMFLoop

	rts

;------------------------------------------------------------------------------
;	SearchFileID:
;
;		IN	A:file ID
;		OUT	CY: set = not found
;
SearchFileID:
	jsr	SetBlk03Ptr
						;--- ファイルID比較
	ldx	#0
	ldy	#0
@SFILoop:
	cmp	(tmpAccm),y
	clc
	beq	@SFIEnd
@SFINext:
	jsr	Add16
	
	inx
	cpx	fileAmount
	bcc	@SFILoop
@SFIEnd:
	rts

;------------------------------------------------------------------------------
;
SearchFileName:
	jsr	SetBlk03Ptr
						;--- ファイル名比較
	ldx	#0
@SFN10:
	ldy	#8
@SFNLoop:
	lda	fileHeader,y
	cmp	(tmpAccm),y
	bne	@SFNNext
	dey
	bne	@SFNLoop

	stx	fileNumber
	lda	(tmpAccm),y			; file ID
	tay
	clc
	bne	@End
@SFNNext:
	jsr	Add16
	
	inx
	cpx	fileAmount
	bcc	@SFN10
@End:
	rts

;------------------------------------------------------------------------------
;
SetBasHeader:
						;--- コマンド:ファイル名有無
	jsr	GetFileNameArg
	lda	zpHaveFNameArg
	beq	@SBHEnd				; no file name

	jsr	TxtPtrIncr
						;--- copy file name
	ldx	#8-1
@fnLoop:
	lda	lineBuffer80,x
	bne	@fn10
	lda	#' '
@fn10:
	sta	sFileName,x
	dex
	bpl	@fnLoop
						;--- ファイル名チェック
	jsr	SearchFileName
	bcc	@fn20				; 有り
						;--- 無し
	jsr	GetMaxFileID

	jsr	IncBCD
	tay

	ldx	#0
@fn20:
	sty	fileID				; file ID
	stx	fileNumber
						;--- file index "BS"
	ldx	#1
@SBH10:
	lda	sBS,x
	sta	$6000,x
	dex
	bpl	@SBH10
						;--- basPrg Start,End Address
	ldx	#3
@SBH20:
	lda	tempzpSav+zpTXTTAB,x
	sta	$6002,x
	dex
	bpl	@SBH20
@SBHEnd:
	rts

;------------------------------------------------
sBS:	.byte	"BS"

;------------------------------------------------------------------------------
;	FileSave:	ファイル・セーブ
;
FileSave:
	lda	#0
	sta	fileNumber

	jsr	SetBasHeader				;--- 

	jsr	VsyncOff
	jsr	VINTWait
							;--- 既存ファイルNo.チェック
	ldx	fileAmount
	lda	fileNumber
	bne	@FS10
	stx	fileNumber
	inc	fileAmount
	lda	#$ff					; append file
@FS10:
	stx	tempzp+6

	jsr	WriteFile
	.addr	diskID
	.addr	fileHeader
	bne	@FSEnd
							;--- ファイル数更新
	lda	fileAmount
	jsr	SetFileCount
	.addr	diskID
@FSEnd:
	pha
	jsr	VsyncOn
	pla
	jsr	QueueErrMsg

	rts

;------------------------------------------------
fileNumber:
	.byte	$00
fileHeader:
fileID:
	.byte	$84
sFileName:
	.byte	"TESTSAV3"
	.addr	$6000
	.addr	$1000
	.byte	$00
	.addr	$6000
	.byte	$00


;------------------------------------------------------------------------------
;	GetCardInfo:	DiskInfoBlock取得
;
GetCardInfo:
	jsr	SenceCard
	bne	ErrNoCard
	
	jsr	VsyncOff

	jsr	ReadCardInfo

	jsr	VsyncOn

	jsr	ShortFileList

	lda	#0
	jsr	QueueErrMsg

	rts

;------------------------------------------------------------------------------
;	ErrNoCard:	DiskCard未挿入
;
ErrNoCard:
	jsr	QueueErrMsg
	jsr	ShortBeep

	lda	#$00
	sta	diskInfoStat

	jmp	CFDSEnd


;------------------------------------------------------------------------------
;	DeleteFile:
;
DeleteFile:
	jsr	EvalByteInteger
	jsr	BIN2BCD
	cmp	#$10
	bmi	@DFErr
	jsr	SearchFileID
	bcc	@DFEnd
@DFErr:
	jsr	ShortBeep
@DFEnd:
	rts

;------------------------------------------------------------------------------
;	RenameFile:
;
RenameFile:
	jsr	EvalByteInteger
	jsr	SkipCommaOrSynErr
	jsr	GetFileNameArg
	lda	zpHaveFNameArg
	beq	@RFNoFN				; ファイル名無し
@RFNoFN:
@RFEnd:
	rts

;------------------------------------------------------------------------------
;	ArgCheck:	引数チェック
;
funcPtr	=	DoFunc+1
ArgCheck:
	tay
	ldx	#$00
@AC02:
	tya
	cmp	tArg,x
	bne	@AC05

	jsr	TxtPtrIncrAndGetChar
	lda	tArg+1,x
	sta	funcPtr
	lda	tArg+2,x
	sta	funcPtr+1
	clc
	jmp	ACEnd
@AC05:
	inx
	inx
	inx
	tay
	lda	tArg,x
	cmp	#$ff
	bne	@AC02
@ACNone:
	sec
ACEnd:
	rts

;------------------------------------------------
tArg:
	.byte	$00				; DiskInfo
	.addr	GetCardInfo
	.byte	$86				; LIST
	.addr	FileList
	.byte	$a5				; LOAD
	.addr	LoadFile
	.byte	$a6				; SAVE
	.addr	FileSave
	.byte	$e7				; REN
	.addr	RenameFile
	.byte	$e8				; DELETE
	.addr	DeleteFile
	.byte	$ff

;------------------------------------------------------------------------------
;	CmdFDS:	FDSコマンド・エントリ
;
CmdFDS:
	jsr	ArgCheck			; 引数チェック
	bcs	CFDSEnd2

	jsr	SenceCard
	bne	ErrNoCard			; No DiskCard
						;---- exec command
	jsr	SaveBasWork			; Save BASIC work
DoFunc:	jsr	NoOpe
CFDSEnd:
	jsr	RestoreBasWork
						;--- file type check
	lda	loadFileType
	cmp	#'B'
	bne	CFDSEnd2			; not BASIC file
						;--- BASIC file
	lda	#$00
	sta	loadFileType
	jsr	CLEAR				; zpVALTBL,zpVALEND初期化
CFDSEnd2:					;---- print Result
	jsr	QueueNullForOutput
	jsr	PrintOutBuf

@J10:
	jsr	IsEndOfCmd
	beq	@End

	jsr	TxtPtrIncr
	jmp	@J10
@End:
	lda	#$c0
	sta	$101
NoOpe:
	rts


;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------

;--- FDS,BASIC work save Area -----------------
tempzpSav:
	.res	$10
joypadSav:
	.res	$10

;------------------------------------------------------------------------------
bufPtr:	.res	2
fileCnt:.res	1
readCnt:.res	2
;------------------------------------------------
diskInfoBlock:
	.res	DISK_INFO_BLK_SIZE
block03Buf:
	.res	FILE_HDR_BLK_SIZE * $10


