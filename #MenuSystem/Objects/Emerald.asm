
; ===============================================================
; ---------------------------------------------------------------
; Emerald Cursor Object
; ---------------------------------------------------------------

_MoveSpeed = 4

Obj_Emerald:
	st.b	(a0)
	move.w	#_VRAM_Emer_T+_pal1,2(a0)
	move.l	#Map_ObjEmer,4(a0)
	move.l	#ObjEmer_Appear,$24(a0)                 
	move.b	#1,$1A(a0)

	bsr.s	ObjEmer_CalcPos     
	move.w	d0,$A(a0)	; Y-pos
	move.w	d0,$C(a0)	; TargetY

	move.w	#320,d0
	move.w	6(a4),d1	; d1 = TargetX
	sub.w	d1,d0		; d0 = X-dist for entries
	asr.w	#1,d0
	addi.w	#$80-$18,d1
	sub.w	d0,d1		; d1 = X-pos
	move.w	d1,8(a0)

; ---------------------------------------------------------------
ObjEmer_Appear:
	move.w	8(a0),d0
	move.w	6(a4),d1
	addi.w	#$80-$18,d1
	addq.w	#4,d0
	move.w	d0,8(a0)
	cmp.w	d1,d0
	blt.s	ObjEmer_Display
	move.w	d1,8(a0)
	move.l	#ObjEmer_Main,$24(a0)

; ---------------------------------------------------------------
ObjEmer_Main:
	tst.b	$C(a4)
	bpl.s	ObjEmer_Main2
	move.l	#ObjEmer_Hide,$24(a0)

ObjEmer_Main2:
	move.w	$C(a0),d0
	sub.w	$A(a0),d0	; d0 = TargetY - Y
	beq.s	@1
	bmi.s	@0
	addq.w	#_MoveSpeed,$A(a0)
	bra.s	ObjEmer_Display

@0	subq.w	#_MoveSpeed,$A(a0)
	bra.s	ObjEmer_Display

@1	bsr.s	ObjEmer_CalcPos
	move.w	d0,$C(a0)

; ---------------------------------------------------------------
ObjEmer_Display:
	jmp	DisplaySprite

; ---------------------------------------------------------------
ObjEmer_CalcPos:
	moveq	#0,d0
	move.b	3(a4),d0	; d0 = Entry
	move.w	d0,d1
	add.w	d0,d0
	add.w	d1,d0		; d0 = Entry * 3
	lsl.w	#3,d0		; d0 = Entry * 3 * 8
	moveq	#-$80,d1	; d1 = Sprite Y-base
	add.w	VScroll,d1
	neg.w	d1		; d1 = Base Y-pos
	add.w	d1,d0		; d0 = Final Y-pos
	rts
	                                             
; ---------------------------------------------------------------
ObjEmer_Hide:
	tst.b	$C(a4)
	bne.s	ObjEmer_Main2
	subq.w	#8,8(a0)
	bne.s	ObjEmer_Display
	addq.w	#8,8(a0)
	rts

; ===============================================================

Map_ObjEmer:
@Lst
	dc.w	@0-@Lst
	dc.w	@1-@Lst
	
@0	dc.b	1
	dc.b	0, %0101, 0, $00, 0

@1	dc.b	1
	dc.b	0, %0101, 0, $08, 0
	
	even