
; ===============================================================
; ---------------------------------------------------------------
; Menu Header Object
; ---------------------------------------------------------------

_Ydisp = $28
_Yspeed = 4

; ---------------------------------------------------------------

Obj_Header:
	st.b	(a0)
	move.w	#_VRAM_CArt_T,2(a0)
	move.l	#Map_ObjHeader,4(a0)
	move.l	#@Move,$24(a0)
	move.w	#$120,8(a0)	; Xpos
	moveq	#0,d0
	move.b	(a4),d0
	move.b	d0,$1A(a0)	; set mapping frame according to current menu
	add.w	d0,d0
	add.w	d0,d0
	move.l	@HeaderPos(pc,d0.w),$A(a0)

@Move	move.w	$A(a0),d0
	addq.w	#_Yspeed,d0
	move.w	$C(a0),d1
	cmp.w	d1,d0		; compare to target pos
	blt.s	@0
	move.w	d1,d0
	move.l	#@Wait,$24(a0)

@0	move.w	d0,$A(a0)
	bra.s	@Disp        
	
@Wait	tst.b	$C(a4)		; msg = Quit?
	bpl.s	@Disp
	move.l	#@Hide,$24(a0)
	
@Hide	tst.b	$C(a4)
	bne.s	@Disp		; wait msg reset
	subq.w	#_Yspeed,$A(a0)
	bcc.s	@Disp
	jmp	DeleteObject

@Disp	jmp	DisplaySprite

; ===============================================================
; ---------------------------------------------------------------
; Y-Position for every header
; ---------------------------------------------------------------

@HeaderPos:
	;	Start		Target
	dc.w	0,		0		; $00
	dc.w	$80-$48,	$80+$30		; $01
	dc.w	$80-$28,	$80+$28		; $02

; ===============================================================
; ---------------------------------------------------------------
; Header Mappings
; ---------------------------------------------------------------

Map_ObjHeader:
@Lst
	dc.w	@Null-@Lst	; $00             
	dc.w	@Options-@Lst	; $01
	dc.w	@Extras-@Lst	; $02

; ---------------------------------------------------------------
@Null:

	dc.b	0

; ---------------------------------------------------------------
@Options:
_Xdisp = 6*8+4

	dc.b	4
	;	 YY  WWHH      TT  XX
	dc.b	-8, %1101, 0, $00, 0-_Xdisp	; OP
	dc.b	-8, %1001, 0, $08, $20-_Xdisp	; TI
	dc.b	-8, %0101, 0, $00, $38-_Xdisp	; O
	dc.b	-8, %1101, 0, $0E, $48-_Xdisp	; NS

; ---------------------------------------------------------------
@Extras:
_Xdisp = 6*8+4

	dc.b	4
	;	 YY  WWHH      TT  XX
	dc.b	-8, %1101, 0, $16, 0-_Xdisp	; EX
	dc.b	-8, %0101, 0, $08, $20-_Xdisp	; T
	dc.b	-8, %1101, 0, $1E, $30-_Xdisp	; RA
	dc.b	-8, %0101, 0, $12, $50-_Xdisp	; S



; ---------------------------------------------------------------

	even