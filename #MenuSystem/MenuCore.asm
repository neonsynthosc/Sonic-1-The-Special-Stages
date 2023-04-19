
; ===============================================================
; MENU SYSTEM for SonicVaan
; Developed and Desgined (c) 2012 Vladikcomper
; ===============================================================

; ---------------------------------------------------------------
; Menu memory struct
; ---------------------------------------------------------------

MenuVars	equ	$FFFF8000	; base addr FF40

;	$00	b	Menu Id
;	$01	b	Scroll Dir (see values)
;	$02	b	Number Entries
;	$03	b	Currently Selected Entry
;	$04	w	HScroll base address
;	$06	w	Position from Left
;	$08	w	Timer/Variable
;	$0A	w	Timer/Variable
;	$0C	b	Menu Status ($00 - normal, $01 - entry select, $FF - quit)
;	$0D	b	Timer/Variable

; ---------------------------------------------------------------
; Memory variables
; ---------------------------------------------------------------

VDP_Data	equ	$C00000
VDP_Ctrl	equ	$C00004

KosOutput	equ	$FF0000
HScrollBuff	equ	$FFFFCC00	; $380	Hscroll Buffer
ObjectsRAM	equ	$FFFFD000	; $1000	Objects RAM
PalActive	equ	$FFFFFB00	; $80	Active palette buffer
PalTarget	equ	$FFFFFB80	; $80	Target palette
PLCBuffer	equ	$FFFFF680	; $60	PLC buffer

GameMode	equ	$FFFFF600	; b
Joypad	equ	$FFFFF604
VScroll	equ	$FFFFF616	; l	VScroll (A/B)     
PalFadePos	equ	$FFFFF626	; b
PalFadeLen	equ	$FFFFF627	; b
VBlankSub	equ	$FFFFF62A	; b
WaterState	equ	$FFFFF64E	; b

; ---------------------------------------------------------------
; Global constants
; ---------------------------------------------------------------

; VRAM Offsets

_VRAM_PlaneA	equ	$C000
_VRAM_PlaneB	equ	$E000
_VRAM_BG	equ	$0020
_VRAM_BG_T	equ	(_VRAM_BG/$20)
_VRAM_Emer	equ	$0120
_VRAM_Emer_T	equ	(_VRAM_Emer/$20)
_VRAM_Font	equ	$840
_VRAM_Font_T	equ	(_VRAM_Font/$20)
_VRAM_CArt	equ	$4000
_VRAM_CArt_T	equ	(_VRAM_CArt/$20)

; VRAM flags

_pal0		equ	0	; palette select
_pal1		equ	1<<13	;
_pal2		equ	2<<13	;
_pal3		equ	3<<13	;
_pr		equ	$8000	; high priority flag
_fvh		equ	3<<11	; flip
_fv		equ	2<<11	;
_fh		equ	1<<11	;

; Joypads Setup

Held		equ	0
Press		equ	1

iStart		equ 	7
iA		equ 	6
iC		equ 	5
iB		equ 	4
iRight		equ 	3
iLeft		equ 	2
iDown		equ 	1
iUp		equ 	0

Start		equ 	1<<7
A		equ 	1<<6
C		equ 	1<<5
B		equ 	1<<4
Right		equ 	1<<3
Left		equ 	1<<2
Down		equ 	1<<1
Up		equ 	1

; ---------------------------------------------------------------
; Main macros
; ---------------------------------------------------------------

; Get VRAM write access
vram	macro	offset,operand
	if (narg=1)
		move.l	#($40000000+(((\offset)&$3FFF)<<16)+(((\offset)&$C000)>>14)),VDP_Ctrl
	else
		move.l	#($40000000+(((\offset)&$3FFF)<<16)+(((\offset)&$C000)>>14)),\operand
	endc
	endm
	
; Send data to VRAM via DMA
MOVvram	macro	src,len,dest
	move.l	#$94000000+(((\len>>1)&$FF00)<<8)+$9300+((\len>>1)&$FF),(a6)
	move.l	#$96000000+(((\src>>1)&$FF00)<<8)+$9500+((\src>>1)&$FF),(a6)
	move.w	#$9700+((((\src>>1)&$FF0000)>>16)&$7F),(a6)
	move.w	#$4000+(\dest&$3FFF),(a6)
	move.w	#$80+((\dest&$C000)>>14),(a6)
	endm
	
; VRAM request const
DCvram	macro	offset
	dc.l	($40000000+(((\offset)&$3FFF)<<16)+(((\offset)&$C000)>>14))
	endm
	
; Convert string
cstr	macro	string
	dc.b	\string
	if *&1=1
	dc.b	0
	else
	dc.b	' ',0
	endc
	endm

; Fuck
fuck	macro
	bra.s	*
	endm
	

; ===============================================================
; ---------------------------------------------------------------
; Menu Initialization
; ---------------------------------------------------------------

MenuScreen:
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
	move.w	#$8B02,(a6)		; HScroll mode = 'cell'

        ; Clear stuff
	moveq	#0,d0
	move.b	d0,WaterState
	move.l	d0,VScroll
	jsr	ClearScreen
        
        ; Load menu gfx
	lea	VDP_Ctrl,a6
	lea	Art_MenuBG,a0
	lea	KosOutput,a1
	jsr	KosDec
        MOVvram	KosOutput,$20*8,_VRAM_BG	; Menu BG

	lea	Art_MenuFont,a0
	lea	KosOutput,a1
	jsr	KosDec
	MOVvram	KosOutput,$20*$74,_VRAM_Font	; Menu font
	
	vram	_VRAM_Emer
	lea	Nem_SSEmerald,a0
	jsr	NemDec				; Emerald Cursor

	; Generate da BG!
	bsr	Menu_GenerateBG

        ; Clear objects RAM
	lea	ObjectsRAM,a0
	move.w	#$1000/4-1,d0		; $1000 bytes
	moveq	#0,d1
@0	move.l	d1,(a0)+
	dbf	d0,@0

	; Play menu music
	moveq	#$FFFFFF00|_Menu_BGM,d0
	jsr	PlaySound

; ---------------------------------------------------------------
; Initialize menu based on menu id
; ---------------------------------------------------------------

Menu_Init:
	clr.b		($FFFFFFA0).w ; clear demo end flag
	move.b	#2,VBlankSub
	jsr	DelayProgram		; synchronize 
	move.w	#$8134,VDP_Ctrl		; disable DISPLAY

	bsr	Menu_ClearEntries
	bsr	Menu_ClearObjects

	lea	MenuVars,a4		; a4 = Menu variable space

	moveq	#0,d0
	bsr	Menu_GetDataPtr		; a3 = InitScript

	; Load art
	move.w	(a3)+,d0
	beq.s	@LoadObjects		; if none art is present, branch
	subq.w	#1,d0
	lea	PLCBuffer,a0

@0	move.l	(a3)+,(a0)+		; fill buffer
	move.w	(a3)+,(a0)+
	dbf	d0,@0
	
	movem.l	a2-a3,-(sp)		; save data ptr
@1	move.b	#$12,VBlankSub		; hold PLC decompressing
	jsr	DelayProgram
	jsr	RunPLC_RAM
	tst.l	PLCBuffer		; are there cues inda buffa?
	bne.s	@1			; if yay, loop
	movem.l	(sp)+,a2-a3

	; Load objects
@LoadObjects:
	move.w	(a3)+,d0
	beq.s	@LoadPalettes		; if none object is present, branch
	subq.w	#1,d0
	lea	ObjectsRAM,a0
@1b	move.l	(a3)+,$24(a0)
	lea	$40(a0),a0
	dbf	d0,@1b
	
	; Load palettes
@LoadPalettes:
	lea	PalActive,a0
	moveq	#0,d0
	move.w	d0,(a0)			; setup backdrop color to black
	lea	$10+$80(a0),a1		; BG palette (+$80 = PalTarget)
	move.l	(a3)+,(a1)+		;
	move.w	(a3)+,(a1)+		;
	move.w	(a3)+,2(a0)		; Normal Menu Item
	move.w	(a3)+,$E(a0)		;
	move.w	(a3)+,$22(a0)		; Active Menu Item
	move.w	(a3)+,$2E(a0)		;
	lea	4+$20(a0),a1		; Emerald Palette
	move.l	(a3)+,(a1)+		;
	move.l	(a3)+,(a1)+		;
	move.w	(a3)+,(a1)+		;

	; Load menu prefences
	move.b	(a3)+,1(a4)		; Scroll Direction ###
	move.b	(a3)+,2(a4)		; Number of entries
	moveq	#0,d0
	move.b	d0,3(a4)		; Currently selected entry
	move.b	(a3)+,d0		; d0 = tiles from left
	lsl.w	#3,d0
	move.w	d0,6(a4)		; Position from Left
	moveq	#0,d0
	move.b	(a3)+,d0		; d0 = tiles from top
	lsl.w	#3,d0			; d0 = Tiles * 8
	move.w	d0,d1
	add.w	d1,d1
	add.w	d1,d1			; d1 = Tiles * $20 (<<2+3)
	addi.w	#HScrollBuff,d1
	move.w	d1,4(a4)		; HScroll base offset
	neg.w	d0
	move.w	d0,VScroll		; Position from top
	
	; Draw menu text
	moveq	#0,d0
	move.b	2(a4),d1		; d1 = Number of entries
	move.w	#_pal1,d3		; highlight first item

@2	bsr	Menu_DrawEntry
	addq.b	#1,d0
	moveq	#0,d3			; don't highlight items
	cmp.b	d1,d0
	bls.s	@2

	; Init HSRAM
	movea.w	4(a4),a1
	moveq	#0,d7
	move.b	2(a4),d7		; d7 = number of entires
	move.w	#320,d0			; d0 = Initial scroll
@3	move.w	d0,(a1)
	move.w	d0,$20(a1)
	lea	$60(a1),a1
	dbf	d7,@3

	move.b	#2,VBlankSub
	jsr	DelayProgram		; synchronize HSRAM
	move.w	#$8174,VDP_Ctrl		; Enable Display

; ===============================================================

















; ===============================================================
; ---------------------------------------------------------------
; Menu intro sequence
; ---------------------------------------------------------------

_MoveSpeed = 8
_MoveDelay = 8


	move.w	#0,8(a4)		; reset counter
	move.b	#$10,PalFadePos		; setup fading
	move.b	#2,PalFadeLen		;
	move.b	#$E,$A(a4)		;

Menu_AppearLoop:
	move.b	#2,VBlankSub
	jsr	DelayProgram
	bsr	Menu_Scroll
	bsr	Menu_RunObjects

	btst	#1,HScrollBuff+3
	beq.s	@NoFade			; branch every even frame
	move.b	$A(a4),d4
	beq.s	@NoFade			; branch, if fading is done
	jsr	Pal_FadeIn
	subq.b	#2,d4
	move.b	d4,$A(a4)
@NoFade:

	movea.w	4(a4),a1		; a1 = HScroll base addr
	move.w	8(a4),d1		; d1 = Counter
	addq.w	#1,d1
	move.w	d1,8(a4)
	moveq	#0,d2			; d2 = AcceptFactor
	move.w	d2,d3
	move.b	2(a4),d3		; d3 = number of entries
	move.w	6(a4),d4		; d4 = Target Scroll position

@0	cmp.w	d2,d1			; Counter > AcceptFactor?
	bcs.s	Menu_AppearLoop		; if not, branch

	move.w	(a1),d0			; d0 = Scroll value
	subi.w	#_MoveSpeed,d0
	cmp.w	d4,d0			; Current < Target?
	bgt.s	@1
	move.w	d4,d0

@1	move.w	d0,(a1)			; update scrolling
	move.w	d0,$20(a1)		;

	lea	$60(a1),a1		; next scroll row
	addi.w	#_MoveDelay,d2		; delay between appearences
	dbf	d3,@0

	cmp.w	d4,d0			; has the last item finished scrolling?
	bne.s	Menu_AppearLoop		; if not, branch

; ---------------------------------------------------------------
; Menu control loop
; ---------------------------------------------------------------

Menu_MainLoop:
	move.b	#2,VBlankSub
	jsr	DelayProgram
	bsr	Menu_Scroll
	bsr	Menu_NoOption       
	bsr	Menu_Control
	bsr	Menu_RunObjects

	tst.b	$C(a4)
	beq.s	Menu_MainLoop
	bmi.s	@0

	pea	Menu_MainLoop		; if Msg = $01
	bra.s	Menu_SelectInit

@0	pea	Menu_QuitInit		; if Msg = $FF

; ---------------------------------------------------------------
; Menu select loop
; ---------------------------------------------------------------

Menu_SelectInit:         
	moveq	#$FFFFFF00|_Menu_Snd_Select,d0
	jsr	PlaySound
	move.w	PalActive+$E,8(a4)
	move.w	PalActive+$2E,$A(a4)
	move.b	#15,$D(a4)

Menu_SelectLoop:
	move.b	#2,VBlankSub
	jsr	DelayProgram
	bsr	Menu_Scroll
	bsr	Menu_RunObjects

	move.b	HScrollBuff+3,d0
	andi.b	#7,d0
	beq.s	Menu_SelectLoop
	subq.b	#1,$D(a4)
	beq.s	@EndLoop
	move.l	8(a4),d0
	swap	d0
	move.w	d0,PalActive+$2E
	move.l	d0,8(a4)
	bra.s	Menu_SelectLoop

@EndLoop:
	sf.b	$C(a4)		; reset menu msg
	rts

; ---------------------------------------------------------------
; Menu select loop
; ---------------------------------------------------------------
        
Menu_QuitInit:
	move.b	#15,PalFadeLen
	move.b	#0,PalFadePos

Menu_QuitLoop:
	move.b	#2,VBlankSub
	jsr	DelayProgram
	bsr	Menu_Scroll
	bsr	Menu_RunObjects

	movea.w	4(a4),a1		; a1 = HScroll Base
	moveq	#0,d0
	move.b	3(a4),d0		; d0 = current entry
	move.w	d0,d1
	add.w	d0,d0
	add.w	d1,d0			; d0 = Entry * 3
	lsl.w	#5,d0			; d0 = Entry * 3 * $20
	adda.w	d0,a1			; a1 = Scroll for this entry
	move.w	(a1),d0			; d0 = Scroll val
	subq.w	#8,d0
	move.w	d0,(a1)			; apply scroll
	move.w	d0,$20(a1)		;
	cmpi.w	#-24*8,d0
	ble.s	Menu_Quit
	
	btst	#1,HScrollBuff+3
	beq.s	Menu_QuitLoop
	jsr	Pal_FadeOut
	bra.s	Menu_QuitLoop

; ---------------------------------------------------------------

Menu_Quit:
	cmpi.b	#$24,GameMode		; Game Mode changed?
	beq	Menu_Init
	rts				; leave screen mode

Menu_NoOption:
	cmpi.b	#5,(a4)
	bne.s		@0
	andi.b	#Start+A+B+C+Up+Down,Joypad|Press
@0
	rts
; ===============================================================















; ===============================================================
; ---------------------------------------------------------------
; Subroutine to control the menu
; ---------------------------------------------------------------

Menu_Control:
	movem.l	d4-a1,-(sp)

        move.b	Joypad|Press,d3
        andi.b	#+Start+C+Up+Down+Left+Right,d3
        beq.w	@Quit

        move.b	3(a4),d0	; d0 = Current Entry
        move.b	d0,d1		; d1 = New Entry

; ---------------------------------------------------------------

; Pressed Up
        btst	#iUp,d3
        beq.s	@ChkDown
        subq.b	#1,d1
        bpl.s	@0
        move.b	2(a4),d1	; d1 = Bottom Entry

@0	bsr	Menu_ChangeEntry
	moveq	#$FFFFFF00|_Menu_Snd_Switch,d0
	jsr	PlaySound
	bra.s	@Quit

; Pressed Down
@ChkDown:     
	btst	#iDown,d3
	beq.s	@ChkOption
	addq.b	#1,d1
	cmp.b	2(a4),d1
	bls.s	@1
	moveq	#0,d1		; d1 = Top Entry

@1	bsr	Menu_ChangeEntry
	moveq	#$FFFFFF00|_Menu_Snd_Switch,d0
	jsr	PlaySound
	bra.s	@Quit

; ---------------------------------------------------------------

; Check if this is option entry
@ChkOption:
	bsr	Menu_GetEntry	; a2 = Entry Data

	tst.b	2(a2)		; is entry option?
	beq.s	@ChkSelect	; if not, branch

	movea.w	4(a2),a1	; a1 = Memory Address
	move.b	(a1),d1		; d1 = Option value

; Pressed Left
	btst	#iLeft,d3
	beq.s	@ChkRight
	subq.b	#1,d1
	bpl.s	@RedrawOption
	move.b	3(a2),d1	; d1 = MaxVal
	bra.s	@RedrawOption

; Pressed Right
@ChkRight:
	btst	#iRight,d3
	beq.s	@ChkSelect
	addq.b	#1,d1
	cmp.b	3(a2),d1
	bls.s	@RedrawOption
	moveq	#0,d1		; d1 = MinVal

@RedrawOption:
	move.b	d1,(a1)		; update option value
	move.w	#_pal1,d3	; highlight!
	bsr	Menu_DrawEntry
	bra.s	@Quit

; ---------------------------------------------------------------

; Check if entry was selected
@ChkSelect:
	andi.b	#Start+C,d3
	beq.s	@Quit
	tst.b	2(a2)		; is entry option?
	bne.s	@Quit		; if yes, branch
	bsr.s	Menu_ExecuteEntry

; ---------------------------------------------------------------

@Quit	movem.l	(sp)+,d4-a1
	rts

; ---------------------------------------------------------------
; Subroutine to launch current entry
; ---------------------------------------------------------------

Menu_ExecuteEntry:
	move.b	#1,$C(a4)	; msg = Entry_Select
	move.b	3(a2),d1	; d1 = Action id
	ext.w	d1
	bpl.s	@0

	movea.l	4(a2),a1	; d1 = $FF (_ME_Action_CallHandler)
	jmp	(a1)
		
@0	dbf	d1,@1		; d1 = $00 (_ME_Action_Nothing)
	rts

@1	dbf	d1,@2		; d1 = $01 (_ME_Action_GoToMenu)
	move.b	4(a2),(a4)
	st.b	$C(a4)		; msg = Quit
	rts

@2	dbf	d1,@3		; d1 = $02 (_ME_Action_GoToGameMode)
	move.b	4(a2),GameMode
	st.b	$C(a4)		; msg = Quit

@3	rts

; ---------------------------------------------------------------
; Subroutine to change current menu entry
; ---------------------------------------------------------------
; INPUT:
;	d0 = Old Entry
;	d1 = New Entry
; ---------------------------------------------------------------

Menu_ChangeEntry:            

	; Redraw Old Entry
	moveq	#0,d3			; Don't Highlight
	bsr	Menu_DrawEntry

	; Redraw New Entry
	move.b	d1,d0
	move.b	d0,3(a4)		; Current Entry
	move.w	#_pal1,d3		; Highlight


; ---------------------------------------------------------------
; Subroutine to redraw entry
; ---------------------------------------------------------------
; INPUT:
;	d0 = Entry
;	d3 = Highlighter
; ---------------------------------------------------------------

Menu_DrawEntry:
	movem.l	d0-d1,-(sp)

	; Get main data arrays
	move.b	d0,d4			; save d0
	moveq	#4,d0
	bsr	Menu_GetDataPtr		; a3 = Text Pointers
	move.b	d4,d0			; load saved d0
	bsr	Menu_GetEntry		; a2 = Entry Data

	; Calculate VRAM address
	moveq	#0,d1
	move.b	d0,d1
	move.w	d1,d2
	add.w	d1,d1
	add.w	d2,d1			; d1 = Entry * 3
	lsl.w	#7,d1			; d1 = Entry * 3 * $80
	swap	d1
	vram	_VRAM_PlaneA,d0		; d0 = Base VRAM addr
	add.l	d1,d0			; d0 = Final VRAM addr

        ; Draw da texto
	move.w	(a2),d1			; d1 = TextId
	add.w	d1,d1
	lea	(a3),a0
	adda.w	(a0,d1.w),a0		; a0 = String
	bsr	Menu_DrawText		; Disaplay text

	; Redraw option (if present)
	tst.b	2(a2)
	beq.s	@0			; if entry type != option, branch
	subi.l	#$100<<16,d0		; restore ptr
	movea.w	4(a2),a1		; a1 = Memory address
	moveq	#0,d1
	move.b	(a1),d1			; d1 = Option value
	add.b	6(a2),d1		; d1 = Option value + TextId
	add.w	d1,d1
	lea	(a3),a0
	adda.w	(a0,d1.w),a0		; a0 = String
	moveq	#0,d1
	move.b	7(a2),d1		; d1 = Pos
	add.w	d1,d1			; d1 = Pos * 2
	swap	d1
	add.l	d1,d0			; Calc screen pos
	bsr	Menu_DrawText		; Disaplay text

@0	movem.l	(sp)+,d0-d1
	rts


; ===============================================================
















; ===============================================================
; ---------------------------------------------------------------
; Load menu data pointer in A3
; ---------------------------------------------------------------
; INPUT:
;	d0 = Data Select
; ---------------------------------------------------------------

Menu_GetDataPtr:
	moveq	#0,d1
	move.b	(a4),d1			; d1 = MenuId
	add.w	d1,d1			; d1 = MenuId*2
	move.w	d1,d2
	add.w	d1,d1			; d1 = MenuId*4
	add.w	d2,d1			; d1 = MenuId*6
	add.w	d0,d1			; d1 = MenuId*6 + DataSelect
	lea	Menu_DataPointers,a3
	adda.w	(a3,d1.w),a3
	rts

; ---------------------------------------------------------------
; Load menu entry data in A2
; ---------------------------------------------------------------
; INPUT:
;	d0 = Entry Number
; ---------------------------------------------------------------

Menu_GetEntry:
	moveq	#0,d1
	move.b	(a4),d1			; d1 = MenuId
	add.w	d1,d1			; d1 = MenuId*2
	move.w	d1,d2
	add.w	d1,d1			; d1 = MenuId*4
	add.w	d2,d1			; d1 = MenuId*6
	lea	Menu_DataPointers,a2
	adda.w	2(a2,d1.w),a2		; a2 = Menu Entries table
	move.b	d0,d1
	andi.w	#$FF,d1
	lsl.w	#3,d1			; d1 = Entry*8
	adda.w	d1,a2			; a2 = Record of current entry
	rts


; ---------------------------------------------------------------
; Subroutine to run objects
; ---------------------------------------------------------------

Menu_RunObjects:
	lea	ObjectsRAM,a0
	moveq	#($1000/$40)-1,d7	; d7 = Obj counter
	
@0	move.l	$24(a0),d0
	beq.s	@1
	movea.l	d0,a1
	jsr	(a1)			; execute object, Vladikcomper style!

@1	lea	$40(a0),a0
	dbf	d7,@0
	move.w	a4,-(sp)
	jsr	BuildSprites
	movea.w	(sp)+,a4
	rts

; ---------------------------------------------------------------
; Subroutine to kill existing objects
; ---------------------------------------------------------------

Menu_ClearObjects:
	lea	ObjectsRAM,a0
	moveq	#($1000/$40)-1,d7	; d7 = Obj counter
	
@0	tst.b	(a0)
	beq.s	@1
	jsr	DeleteObject

@1	lea	$40(a0),a0
	dbf	d7,@0
	rts

; ---------------------------------------------------------------
; Subroutine to clear menu entries
; ---------------------------------------------------------------

Menu_ClearEntries:
	lea	VDP_Ctrl,a6
	lea	-4(a6),a5		; VDP_Data
	vram	_VRAM_PlaneA,d0		; d0 = Plane Setup
	move.l	#$80<<16,d4		; d4 = row factor
	moveq	#0,d1			; d1 = fill pattern
	moveq	#7,d5			; d5 = number of entries to clear

@DoEntry:
	moveq	#1,d6			; d6 = number of rows in entry

@ClearEntry:
        move.l	d0,(a6)			; setup VDP access
	moveq	#24/2-1,d7		; d7 = number of 2 tiles on row

@ClearRow:
	move.l	d1,(a5)
	dbf	d7,@ClearRow

	add.l	d4,d0			; next row
	dbf	d6,@ClearEntry

	add.l	d4,d0
	dbf	d5,@DoEntry
	
	rts


; ---------------------------------------------------------------
; Subroutine to generate menu BG
; ---------------------------------------------------------------

Menu_GenerateBG:
	lea	VDP_Ctrl,a6
	lea	-4(a6),a5		; VDP_Data

	lea	@BG_Data,a0
	move.l	(a0)+,(a6)		; d0 = VRAM addr
	move.l	(a0)+,d1		; d1 = pattern base (doubled)
	move.l	(a0)+,d2		; d2 = row factor
	moveq	#4,d7			; d7 = blocks row switcher

	move.w	#7,d6			; d6 = number of 64px block rows

@DrawRowOfBlocks:
	moveq	#3,d5			; d5 = number rows in block

@DrawRow:
	moveq	#7,d4			; d4 = number of block pairs in row

@DrawBlocksInRow:
	jsr	@BlocksTbl(pc,d7.w)
	jsr	@BlocksTbl+2(pc,d7.w)
	dbf	d4,@DrawBlocksInRow

	dbf	d5,@DrawRow

	swap	d7			; swap blocks
	dbf	d6,@DrawRowOfBlocks
	rts

; ---------------------------------------------------------------
@BlocksTbl:
	bra.s	@Block1_Flip	; $00
	bra.s	@Block0		; $02
	bra.s	@Block0		; $04
	bra.s	@Block1_Normal	; $06

; ---------------------------------------------------------------
@Block0:
	move.l	d1,(a5)
	move.l	d1,(a5)
	rts

; ---------------------------------------------------------------
@Block1_Flip:
	move.w	d5,d3
	addq.w	#4,d3
	bra.s	@B1_0

@Block1_Normal:
	move.w	d5,d3
@B1_0	lsl.w	#3,d3
	lea	(a0,d3.w),a1
	move.l	(a1)+,(a5)
	move.l	(a1)+,(a5)
	rts

; ---------------------------------------------------------------
@BG_Data:
	dcvram	_VRAM_PlaneB			; VRAM base addr
	dc.l	(_VRAM_BG_T)<<16|(_VRAM_BG_T)	; pattern base (dobled)
	dc.l	$80<<16				; row factor

	dc.w	_VRAM_BG_T+1, _VRAM_BG_T+1, _VRAM_BG_T+1, _VRAM_BG_T+1	; Block 1 map (normal)
	dc.w	_VRAM_BG_T+5, _VRAM_BG_T+6, _VRAM_BG_T+7, _VRAM_BG_T+1
	dc.w	_VRAM_BG_T+1, _VRAM_BG_T+3, _VRAM_BG_T+4, _VRAM_BG_T+1
	dc.w    _VRAM_BG_T+1, _VRAM_BG_T+1, _VRAM_BG_T+2, _VRAM_BG_T+1

	dc.w	(_VRAM_BG_T+1)|_fh, (_VRAM_BG_T+1)|_fh, (_VRAM_BG_T+1)|_fh, (_VRAM_BG_T+1)|_fh	; Block 1 map (flip)
	dc.w	(_VRAM_BG_T+1)|_fh, (_VRAM_BG_T+7)|_fh, (_VRAM_BG_T+6)|_fh, (_VRAM_BG_T+5)|_fh
	dc.w	(_VRAM_BG_T+1)|_fh, (_VRAM_BG_T+4)|_fh, (_VRAM_BG_T+3)|_fh, (_VRAM_BG_T+1)|_fh
	dc.w    (_VRAM_BG_T+1)|_fh, (_VRAM_BG_T+2)|_fh, (_VRAM_BG_T+1)|_fh, (_VRAM_BG_T+1)|_fh
	

; ---------------------------------------------------------------
; Subroutine to scroll menu
; ---------------------------------------------------------------

Menu_Scroll:
	move.w	VScroll+2,d0		; d0 = Vscroll (B)
	subq.w	#1,d0
	move.w	d0,VScroll+2		; Update scroll

	tst.b	1(a4)
	bne.s	@FF
	neg.w	d0
@FF	lea	HScrollBuff+2,a1
	moveq	#27,d1			; d0 = number of tiles

@0	move.w	d0,(a1)
	lea	$20(a1),a1
	dbf	d1,@0
	rts

; ---------------------------------------------------------------
; Subroutine to draw text on screen
; ---------------------------------------------------------------
; INPUT:
;	d0 = VRAM addr
;	d3 = Pattern base
;	a0 = Text
; ---------------------------------------------------------------

Menu_DrawText:
	lea	VDP_Ctrl,a6
	lea	-4(a6),a5
	moveq	#1,d1		; d1 = tile switcher
	swap	d1

@0	lea	(a0),a1		; a1 = copy of text
	move.l	d0,(a6)

@1	moveq	#0,d2
	move.b	(a1)+,d2	; d2 = char
	beq.s	@3
	cmpi.b	#' ',d2		; is char space?
	bls.s	@2
	add.w	d2,d2
	add.w	d3,d2
	add.w	d1,d2
	move.w	d2,(a5)		; display char
	bra.s	@1

@2	moveq	#0,d2
	move.w	d2,(a5)		; display space
	bra.s	@1

@3	addi.l	#$80<<16,d0	; next row
	swap	d1
	tst.w	d1
	bne.s	@0
	lea	(a1),a0		; skip char array (useful ^_^)
	rts

; ===============================================================


















; ===============================================================
; ---------------------------------------------------------------
; Menu Objects
; ---------------------------------------------------------------         

	include	'#MenuSystem\Objects\Header.asm'
	include	'#MenuSystem\Objects\Emerald.asm'

; ===============================================================















; ===============================================================
; ---------------------------------------------------------------
; Menu Data
; ---------------------------------------------------------------
                                                
	include	'#MenuSystem\MenuHandlers.asm'
	include	'#MenuSystem\MenuScripts.asm'

Art_MenuBG:
	incbin	'#MenuSystem\Data\BG.4bpp.kos'
	even
	
Art_MenuFont:
	incbin	'#MenuSystem\Data\MenuFont.4bpp.kos'
	even
	
Art_MenuHeaders:
	incbin	'#MenuSystem\Data\Headers.4bpp.nem'
	even

