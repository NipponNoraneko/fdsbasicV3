.segment	"FDS_PATCH"
.ifdef IRQ_TEST
;--------------------------------------------
testIRQ:.res	1
irqTime:.addr	$1d80
irqTime2:.addr	$097b
testData:.byte	$20
testCnt:.res	1
palDat:.res	1
.endif
IRQ:
.ifdef IRQ_TEST
	pha
	txa
	pha
	tya
	pha

	lda	#0
	sta	$4022
	sta	PPU_MASK
	tay
	ldx	PPU_STATUS
	lda	testData
	sta	PPU_SCROLL
	sty	PPU_SCROLL

	clc
	adc	#1
	sta	testData
	bne	@IRQJ10
	lda	zpPpuCtrlVal
	eor	#$01
	and	#$7f
	sta	PPU_CTRL
	lda	zpPpuCtrlVal
@IRQJ10:
	lda	#$1e
	sta	PPU_MASK
@IRQExit:
	pla
	tay
	pla
	tax
	pla
.endif
	rti
.ifdef IRQ_TEST
SetTimer2:
	lda	irqTime2
	sta	$4020
	lda	irqTime2+1
	sta	$4021

	lda	#$02				; タイマスタート
	sta	$4022

	rts
;--------------------------------------------
SetTimer:
	;lda	testIRQ
	;beq	@NMIJ10

	lda	zpPpuMaskVal
	sta	PPU_MASK

	lda	#0
	sta	$4022				; timer stop
	sta	testCnt

	ldx	PPU_STATUS
	sta	PPU_SCROLL
	sta	PPU_SCROLL

	lda	#1
	sta	palDat

	lda	#$c0
	sta	IRQ_FLAG


;	lda	#$20
;	sta	testData

	lda	irqTime
	sta	$4020
	lda	irqTime+1
	sta	$4021

	lda	#$02				; タイマスタート
	sta	$4022

	cli
@NMIJ10:
	rts
.endif
