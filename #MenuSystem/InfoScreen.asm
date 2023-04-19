
; ===============================================================
; Info Screen
; ===============================================================

_InfoScreen_BGM = $80

InfoScreen:
	moveq	#$FFFFFFE4,d0
	jsr	PlaySound_Special	; stop music
	jsr	ClearPLC		; clear pattern load cues
	jsr	Pal_FadeFrom		; fade out pallete
	move	#$2700,sr		; disable interrupts

	; Setup VDP registers
	lea	VDP_Ctrl,a6
	move.w	#$8004,(a6)		; Disable HInt
	move.w	#$8134,(a6)		; Disable DISPLAY
	move.w	#$8200+(_VRAM_PlaneA/$400),(a6)
	move.w	#$8400+(_VRAM_PlaneB/$2000),(a6)
	move.w	#$8700,(a6)     	; Backdrop color
	move.w	#$8B00,(a6)		; HScroll mode = 'full'
	   
	 ; Clear stuff
	moveq	#0,d0
	move.b	d0,WaterState
	move.l	d0,VScroll
	jsr	ClearScreen

	; Load font
	lea	Art_MenuFont,a0
	lea	KosOutput,a1
	jsr	KosDec
	MOVvram	KosOutput,$20*$74,_VRAM_Font	; Menu font
	
	; Load palette
	lea	PalActive,a0
	move.w	#$000,2(a0)
	move.w	#$EEE,$E(a0)
	move.w	#$000,$22(a0)
	move.w	#$0EE,$2E(a0)

	; Play music
	moveq	#$FFFFFF00|_InfoScreen_BGM,d0
	jsr	PlaySound
	
	; Enable DISPLAY
	move.w	#$8174,VDP_Ctrl

; ===============================================================

_MoveSpeed = $23
                                                         
	lea	VDP_Ctrl,a6
	lea	-4(a6),a5
	cmpi.b	#0,($FFFFFFA0).w ; check if demo end flag is off
	beq	Load_BetaInfoText      ; if yes, load Beta Info text
	cmpi.b	#1,($FFFFFFA0).w ; check if demo end flag is on
	beq	Load_DemoEndText       ; if yes, load Demo End text

Load_BetaInfoText:
	lea	InfoScreen_Data,a0

InfoScreen_Con:
	vram	_VRAM_PlaneA,d7		; d7 = VRAM Req Base
	moveq	#28,d6			; d6 = Row number
	moveq	#15,d5			; d5 = Row counter
	move.b	#$24,GameMode
	bra.s	InfoScreen_DrawString

InfoScreen_Loop:
	move.b	#2,VBlankSub
	jsr	DelayProgram
	
	tst.b	Joypad|Press		; Start pressed?
	bmi.s	InfoScreen_Quit
	tst.w	d5			; Strings over?
	beq.s	InfoScreen_Quit

	; Scroll screen
	move.l	VScroll,d0
	move.l	d0,d1
	swap	d1			; d1 = Old pos
	addi.l	#_MoveSpeed<<8,d0
	move.l	d0,VScroll
	swap	d0			; d0 = New pos
	eor.w	d1,d0
	andi.w	#$10,d0
	beq.s	InfoScreen_Loop		; if row didn't change, branch

	; Draw new string
InfoScreen_DrawString:
	bsr.s	InfoScreen_CalcStringPos	; d0 = VRAM addr
	pea	InfoScreen_Loop
	move.b	(a0)+,d1
	beq.s	InfoScreen_ClearString
	bmi.s	InfoScreen_ClearString_End
	moveq	#0,d3				; d3 = pattern
	subq.b	#1,d1
	beq	Menu_DrawText
	move.w	#_pal1,d3
	bra	Menu_DrawText

InfoScreen_Quit:
	rts


; ===============================================================

InfoScreen_ClearString_End:
	subq.w	#1,a0
	subq.w	#1,d5

InfoScreen_ClearString:
	moveq	#0,d2		; d2 = fill pattern
	moveq	#1,d3		; d3 = number of rows
                                                                  
@0	move.l	d0,(a6)
	moveq	#38/2-1,d1	; d1 = number of chars in row / 2

@1	move.l	d2,(a5)
	dbf	d1,@1
	
	addi.l	#$80<<16,d0
	dbf	d3,@0
	rts

; ===============================================================

InfoScreen_CalcStringPos:
  	move.l	d6,d0		; d0 = Row
	addq.b	#2,d6
	andi.b	#$1F,d6
	lsl.w	#7,d0		; d0 = Row * $80
	addq.w	#2,d0		; +1 tile
	swap	d0
	add.l	d7,d0		; d0 = VRAM offset
	rts


; ===============================================================
; ---------------------------------------------------------------
; Info screen data array
; ----------------------------------------------------------------

InfoScreen_Data:

	dc.b	2,'       SONIC 1: THE SPECIAL STAGES    ',0
	dc.b	2,'           PRIVATE BETA BUILD         ',0
	dc.b	2,'         BUILD DATE: 21/1/2013        ',0
	dc.b	0
	dc.b	1,'TEXT GOES HERE                        ',0
	dc.b	1,'                                      ',0
	dc.b	1,'                                      ',0
	dc.b	1,'    YADAYADAYADA                      ',0
	dc.b	1,'                                      ',0
	dc.b	0

	dc.b	-1	; End of screen
	even

InfoScreen_DemoEnd:

	dc.b	1,'                                      ',0
	dc.b	1,'      DEMO END TEXT GOES HERE =P      ',0
	dc.b	1,'                                      ',0

	dc.b	-1	; End of screen
	even

Load_DemoEndText:
	lea	InfoScreen_DemoEnd,a0
	jmp	InfoScreen_Con