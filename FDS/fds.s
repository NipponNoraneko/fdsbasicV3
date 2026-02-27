; ts=8
;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------
zBufAddr	=	zpPokeAddr		; zpPokeAddrはPOKE以外で使われていない(多分)

;------------------------------------------------
diskID		=	diskInfoBlock+$0e
fileAmount	=	diskID+$0a
lineBuffer80	=	lineBuffer+$80		; temp use: BASIC lineBuffer($500~)の後半部分

;------------------------------------------------
tmpX:	.res	1				; 苦し紛れ
tmpY:	.res	1				; 苦し紛れ

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
	lda	#$27				; |H-SCRL|READ|M-OFF|NO-RESET|
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

	lda	#$27				; $27: |H-SCRL|READ|M-OFF|NO-RESET|
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
	lda	#$80				; disk status
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
	sta	NMI_FLAG			; $DFFA(GAME2)
	sta	IRQ_FLAG			; $DFFE

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
							;----- Block 01
	jsr	ReadBlock01
							;----- Block 02 (ファイル数)
	jsr	GetNumFiles
	ldx	tempzp+6
	stx	fileAmount
	stx	fileCnt
							;----- Info buffer addr set
	ldx	#>block03Buf
	stx	zBufAddr+1
	ldy	#<block03Buf
	sty	zBufAddr
@RCILoop:						;----- Block 03
	ldx	zBufAddr+1
	ldy	zBufAddr
	jsr	ReadBlock03				; Block 03 読込み
							;--- Block 04 (スキップ)
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
	bcc	@RCI15

	inc	zBufAddr+1
@RCI15:
	sta	zBufAddr
							;--- to Next block03
	dec	fileCnt
	bne	@RCILoop
							;--- 終了
	jsr	EndFDS

	rts

;------------------------------------------------------------------------------
;	PutHexDat:
;		IN	A: bin data
;			X: put position
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
	lda	#0
	sta	lineBuffer80,x
	

	rts

;------------------------------------------------------------------------------
;
PrintFileLine:
	jsr	SetBlk03Ptr

	lda	#<lineBuffer80
	sta	zpOutputStr
	lda	#>lineBuffer80
	sta	zpOutputStr+1

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
;	QueueFileName:
;
;	IN	X: col position
;
QueueFileName:
	ldx	#0

	lda	#' '
	sta	lineBuffer80,x
	inx
						;--- fileID
	ldy	#$01
	lda	(tmpAccm),y
	jsr	PutHexDat

	lda	#':'
	sta	lineBuffer80,x
	inx
						;--- file name
	ldy	#2
@QFN10:
	lda	(tmpAccm),y
	bne	@QFN20
	lda	#$20				; ' '
@QFN20:
	sta	lineBuffer80,x
	inx
	iny
	cpy	#10
	bne	@QFN10
	lda	#0
	sta	lineBuffer80,x
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
;	ShortFileList:
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
	ldy	#1
	lda	(tmpAccm),y
	bpl	@SFL20
	pla
	clc
	adc	#1
	pha
	jmp	@SFL25
@SFL20:
	jsr	QueueFileName
	jsr	PrintString
@SFL25:
	jsr	Add16

	pla
	dec	fileCnt
	bne	@SFL30
@SFLPrint:
;	jsr	PrintString
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
	lda	#>block03Buf
	sta	tmpAccm+1
	lda	#<block03Buf
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
	iny
	ldx	fileAmount
@GMFLoop:
	cmp	(tmpAccm),y
	bcs	@J10
	lda	(tmpAccm),y
@J10:
	jsr	Add16
	dex
	bne	@GMFLoop

	cmp	#$80
	bcc	@End
	and	#$7f
@End:

	rts

;------------------------------------------------------------------------------
;	SearchFileID:
;
;	IN	A:file ID
;	OUT	CY: set = not found
;		X: 一致位置
;
SearchFileID:
	jsr	SetBlk03Ptr
						;--- ファイルID比較
	ldx	#0
	ldy	#1
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
;	SearchFileName:
;
SearchFileName:
	jsr	SetBlk03Ptr
						;--- ファイル名比較
	ldx	#0
	stx	fileNumber
@SFN10:
	ldy	#9
	ldx	#8
@SFNLoop:
	lda	fileNumber,y
	cmp	(tmpAccm),y
	bne	@SFNNext
	dey
	dex
	bne	@SFNLoop
						;--- ファイル名一致
	lda	(tmpAccm),y			; file ID
	and	#$7f				; 削除済ファイルの場合、復活させる
	sta	fileID
	tay
	clc
	bne	@End
@SFNNext:
	jsr	Add16
	
	inc	fileNumber
	ldx	fileNumber
	cpx	fileAmount
	bcc	@SFN10
@End:
	rts

;------------------------------------------------------------------------------
;
SetBasHeader:
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
						;--- コマンド:ファイル名有無
	jsr	GetFileNameArg
	lda	zpHaveFNameArg
	beq	@FSExit				; ファイル名無し

	jsr	TxtPtrIncr
						;--- ファイル名コピー
	ldx	#8-1
@FSCopyLoop:
	lda	lineBuffer80,x
	cmp	#$20
	bpl	@FSJ03
	lda	#$20
@FSJ03:
	sta	sFileName,x
	dex
	bpl	@FSCopyLoop
						;--- check save file name
	jsr	SearchFileName
	bcc	@FSJ05				; 有り

	jsr	GetMaxFileID			; 最大fileID
	jsr	IncBCD
	sta	fileID
	inc	fileAmount
	lda	fileAmount
	lda	#$ff
	sta	tempzp+14			; file append
	sta	fileNumber
@FSJ05:
	jsr	SetBasHeader			;--- 

	jsr	VINTWait

	lda	fileNumber

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
@FSExit:
	rts

;------------------------------------------------
fileNumber:
	.byte	$00
fileHeader:
fileID:
	.byte	$84
sFileName:
	.byte	"TEMPSAVE"
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
;	RewriteBlk03:
;
RewriteBlk03:
	jsr	FDSStart
	jsr	VINTWait
							;--- Block 01
	jsr	ReadBlock01
							;--- Block 02 (ファイル数)
	jsr	GetNumFiles
	ldx	tempzp+6
	stx	fileAmount
							;--- ファイルスキップ
	lda	tmpX
	sta	tempzp+6
	jsr	SkipFiles
							;--- set Info buffer addr
;	ldx	#>block03Buf
;	ldy	#<block03Buf
;	jsr	ReadBlock03
	lda	#03
	jsr	WriteBlockType

	ldy	#0
	ldx	#FILE_HDR_BLK_SIZE-1
@RB03Loop:
	lda	(tmpAccm),y
	stx	tmpX
	jsr	XferByte
	iny
	ldx	tmpX
	dex
	bpl	@RB03Loop

	jsr	XferDone

	jsr	VsyncOn

							;--- 終了
	jsr	EndFDS

	rts

;------------------------------------------------------------------------------
;	DeleteFile:
;
DeleteFile:
	jsr	EvalByteInteger
	jsr	BIN2BCD
	cmp	#$10
	bmi	@DFErr

	jsr	SearchFileID
	bcs	@DFEnd

	stx	tmpX
	ldy	#1
	lda	(tmpAccm),y
	ora	#$80
	sta	(tmpAccm),y

	jsr	RewriteBlk03
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
;	ErrNoCard:	DiskCard未挿入
;
ErrNoCard:
	jsr	QueueErrMsg
	jsr	ShortBeep

	lda	#$00
	sta	diskInfoStat

	jmp	CFDSEnd


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


