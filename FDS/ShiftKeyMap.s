; Keymap for shift + key.
; Since Family BASIC does not support lowercase, this deos not insert anything
; when a letter key is typed (hence all the zero values).

tbl_ShiftedKeyMap:
	.byte	$03,$00,$00,$00,$00,$00,$0d,$18
	.byte	$00,$3d,$3f,$5f,$2b,$2a,$00,$17
	.byte	$00,'P',$3c,$3e,'K','L','O',$11
	.byte	$28,$29,'N','M','J','U','I',$10
	.byte	$26,$27,'V','B','H','G','Y',$0f
	.byte	$24,$25,'C','F','D','R','T',$0e
	.byte	$23,'E','Z','X','A','S','W',$06
	.byte	$22,$21,$00,$00,$00,'Q',$1b,$02
	.byte	$12,$08,$20,$1f,$1d,$1c,$1e,$0c
;
; org. tbl_ShiftedKeyMap:
;	.byte	$03,$00,$00,$00,$00,$00,$0d,$18
;	.byte	$00,$3d,$3f,$5f,$2b,$2a,$00,$17
;	.byte	$00,$00,$3c,$3e,$00,$00,$00,$11
;	.byte	$28,$29,$00,$00,$00,$00,$00,$10
;	.byte	$26,$27,$00,$00,$00,$00,$00,$0f
;	.byte	$24,$25,$00,$00,$00,$00,$00,$0e
;	.byte	$23,$00,$00,$00,$00,$00,$00,$06
;	.byte	$22,$21,$00,$00,$00,$00,$1b,$02
;	.byte	$12,$08,$20,$1f,$1d,$1c,$1e,$0c

