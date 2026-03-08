IRQ:
.ifdef	IRQ_EXPERIMANT
	pha
	txa
	pha
	tya
	pha

	lda	zpPpuMaskVal
	sta	PPU_MASK

	lda	#0
	;sta	testIRQ
	sta	$4022

	;sei

	pla
	tay
	pla
	tax
	pla
.endif
	rti
