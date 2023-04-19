
; ===============================================================
; ---------------------------------------------------------------
; MD Boot Screen
; ---------------------------------------------------------------
; Programmed by Vladikcomper
; Based on art and concepts by Zana
; ---------------------------------------------------------------

; ---------------------------------------------------------------
; RAM Addresses / Ports
; ---------------------------------------------------------------

;VDP_Data	= $C00000
;VDP_Ctrl	= $C00004

; VRAM settings
_pal0		equ	0	; palette select
_pal1		equ	1<<13	;
_pal2		equ	2<<13	;
_pal3		equ	3<<13	;
_pr		equ	$8000	; high priority flag
_fvh		equ	3<<11	; flip
_fv		equ	2<<11	;
_fh		equ	1<<11	;

; VRAM locations
VRAM_BG		= $20
VRAM_BG_Pat	= (VRAM_BG/$20)
VRAM_Logo	= $500
VRAM_Logo_Pat	= (VRAM_Logo/$20)
VRAM_LogoShades = $1400
VRAM_LogoShades_Pat = (VRAM_LogoShades/$20)
VRAM_Loading	= $1800
VRAM_Loading_Pat = (VRAM_Loading/$20)

; Constants
ArtSize_BG	= $4A0
ArtSize_Logo	= $EA0
ArtSize_LogoShades = $320
ArtSize_Loading	= $120

; RAM locations
KosBuff		= $00FF0000
EniBuff		= $00FF0000
Palette_Actual	= $FFFFFB00
Palette_Target	= $FFFFFB80

Pal_FadePos	= $FFFFF626
Pal_FadeLen	= $FFFFF627

;VBlankSub	= $FFFFF62A

;WaterState	= $FFFFF64E

; ---------------------------------------------------------------
; Variables for this screen mode
; ---------------------------------------------------------------

			rsset	$FFFFA000

BS_Timer1		rs.b	1
BS_Timer2		rs.b	1
BS_Timer3		rs.b	1
BS_Timer4		rs.b	1
BS_MainTimer		rs.w	1

BS_PalPos_BG_Red	rs.w	1
BS_PalPos_BG_Green	rs.w	1
BS_PalPos_Logo_Red	rs.w	1
BS_PalPos_Logo_Green	rs.w	1
BS_PalPos_LogoShades	rs.w	1

; ---------------------------------------------------------------
; Macros
; ---------------------------------------------------------------

; Set VDP to VRAM write
vram	macro	offset,operand
	if (narg=1)
		move.l	#($40000000+(((\offset)&$3FFF)<<16)+(((\offset)&$C000)>>14)),VDP_Ctrl
	else
		move.l	#($40000000+(((\offset)&$3FFF)<<16)+(((\offset)&$C000)>>14)),\operand
	endc
	endm

; Set VDP to CRAM write
cram	macro	offset,operand
	if (narg=1)
		move.l	#($C0000000+(\1<<16)),VDP_Ctrl
	else
		move.l	#($C0000000+(\1<<16)),\operand
	endc
	endm

; DMA Transfer to VRAM
MOVvram	macro	src,dest,len
	lea	VDP_Ctrl,a6
	move.l	#$94000000+(((\len>>1)&$FF00)<<8)+$9300+((\len>>1)&$FF),(a6)
	move.l	#$96000000+(((\src>>1)&$FF00)<<8)+$9500+((\src>>1)&$FF),(a6)
	move.w	#$9700+((((\src>>1)&$FF0000)>>16)&$7F),(a6)
	move.w	#$4000+(\dest&$3FFF),(a6)
	move.w	#$80+((\dest&$C000)>>14),-(sp)
	move.w	(sp)+,(a6)
	endm

; DMA Transfer to CRAM
MOVcram	macro	src,dest,len
	lea	VDP_Ctrl,a6
	move.l	#$94000000+(((\len>>1)&$FF00)<<8)+$9300+((\len>>1)&$FF),(a6)
	move.l	#$96000000+(((\src>>1)&$FF00)<<8)+$9500+((\src>>1)&$FF),(a6)
	move.w	#$9700+((((\src>>1)&$FF0000)>>16)&$7F),(a6)
	move.w	#$C000+(\dest&$3FFF),(a6)
	move.w	#$80+((\dest&$C000)>>14),-(sp)
	move.w	(sp)+,(a6)
	endm

; Loads Kos art into VRAM
LoadKosArt macro scr,dest,len
	lea	(\scr),a0
	lea	KosBuff,a1
	jsr	KosDec
	MOVvram KosBuff,\dest,\len
	endm

; Loads palette
DrawEniMap macro scr,dest,w,h,base
	lea	(\scr),a0
	move	#\base,d0
	lea	EniBuff,a1
	jsr	EniDec
	lea	EniBuff,a1
	vram	(\dest),d0
	moveq	#\w-1,d1	; width
	moveq	#\h-1,d2	; height
	jsr	ShowVDPGraphics
	endm
	
; Loads palette
LoadPal	macro	scr,dest,sc,numc
	lea	(\scr),a0
	lea	(\dest+\sc*2),a1
	moveq	#\numc-1,d0
@cx\@	move.w	(a0)+,(a1)+
	dbf	d0,@cx\@
	endm
	
; Executes timer
RunTimer macro	addr,value
	subq.b	#1,\addr
	bmi.s	@st\@
	rts
@st\@	move.b	#\value-1,\addr
	endm

; ===============================================================












; ===============================================================
; ---------------------------------------------------------------
; Screen mode init code
; ---------------------------------------------------------------

BootScreen:
	moveq	#$FFFFFFE4,d0
	jsr	PlaySound_Special	; reset SMPS
	jsr	ClearPLC		; clear PLC queue
	jsr	Pal_FadeFrom		; fade the previous screen

	; Setup VDP
	lea	VDP_Ctrl,a6
	move	#$2700,sr		; disable interrupts
	move.w	#$8004,(a6)		; VDP -> Disable HInt
	move.w	#$8134,(a6)		; VDP -> Disable DISPLAY
	move.w	#$8230,(a6)		; VDP -> Plane A nametable
	move.w	#$8407,(a6)		; VDP -> Plane B nametable
	move.w	#$8700,(a6)		; VDP -> Backdrop color
	move.w	#$8B00,(a6)
	jsr	ClearScreen

	; Reset variables
	sf.b	WaterState

	; Load stuff	=========================================

	; Art		Source		Destination	Size in bytes
 	LoadKosArt	Art_BG,		VRAM_BG,	ArtSize_BG
 	LoadKosArt	Art_Logo,	VRAM_Logo,	ArtSize_Logo
 	LoadKosArt	Art_LogoShades,	VRAM_LogoShades,ArtSize_LogoShades
 	LoadKosArt	Art_Loading,	VRAM_Loading,	ArtSize_Loading

	; Mappings	Source		Destination	Width/Height	Tile Base
 	DrawEniMap	Map_BG,		$E000,		40, 28,		VRAM_BG_Pat
 	DrawEniMap	Map_Logo,	$C412,		22, 10,		VRAM_Logo_Pat+_pal1

	; Palettes	Source		Destination	Start color / Num Colors
	LoadPal		Pal_Loading,	Palette_Target,	48, 4

 	; Build logo shades map
 	lea	VDP_Data,a6
	vram	$C434,d0		; d0 = VRAM address
	move.l	#$80<<16,d1		; d1 = Row factor
	moveq	#5-1,d2			; d2 = height
	move.w	#VRAM_LogoShades_Pat+_pal2,d4	; d4 = tile
@1a	move.l	d0,4(a6)
	moveq	#5-1,d3			; d3 = width
@2a	move.w	d4,(a6)			; draw a tile
	addq.w	#1,d4
	dbf	d3,@2a
	add.l	d1,d0			; go to next screen row
	dbf	d2,@1a

	; Draw loading text
	vram	$CAA0,4(a6)
	move.w	#VRAM_Loading_Pat+_pal3,d1
	moveq	#8,d0			; do 9 tiles
@3a	move.w	d1,(a6)
	addq.w	#1,d1
	dbf	d0,@3a          

	move.w	#$8174,VDP_Ctrl		; VDP -> Enable DISPLAY

; ---------------------------------------------------------------
; Pre-Intro sequence, loading text appears
; ---------------------------------------------------------------

	move.b	#$60,Pal_FadePos
	move.b	#$F,Pal_FadeLen
	move.w	#90,BS_MainTimer	; set timer

BootScreen_PreIntroLoop:
 	move.b	#2,VBlankSub
 	jsr	DelayProgram

	; Fade in loading text
	jsr	Boot_Loading_FadeIn
	subq.w	#1,BS_MainTimer
	bne.s	BootScreen_PreIntroLoop


; ---------------------------------------------------------------
; Intro sequence, BG and Logo Shades fade in
; ---------------------------------------------------------------

	; Init variales for pal cycle routines
	move.w	#PalCyc_Red_Shadowed-PalCyc_Red,BS_PalPos_BG_Red
	move.w	#PalCyc_Green_Shadowed-PalCyc_Green,BS_PalPos_BG_Green
	
	clr.w	BS_PalPos_LogoShades

BootScreen_IntroLoop:
 	move.b	#2,VBlankSub
 	jsr	DelayProgram

	; Fade in BG and run Logo Shades animation
	jsr	Boot_BG_FadeIn
	jsr	Boot_LogoShades_Intro
	tst.w	BS_PalPos_LogoShades		; has logo shades animation been finished?
	bne.s	BootScreen_IntroLoop		; if not, branch


; ---------------------------------------------------------------
; Main sequence, when the shit is gettin' srs
; ---------------------------------------------------------------       

	; Init variales for pal cycle routines
	move.w	#PalCyc_Red_Shadowed-PalCyc_Red,BS_PalPos_Logo_Red
	move.w	#PalCyc_Green_Shadowed-PalCyc_Green,BS_PalPos_Logo_Green

	sf.b	BS_Timer3			; reset Logo Shades animation timer
	
	move.w	#4*60,BS_MainTimer		; set loading timer for 4 seconds

BootScreen_MainLoop:
 	move.b	#2,VBlankSub
 	jsr	DelayProgram

	; Fade in logo, run Logo Shades main animation
	jsr	Boot_Logo_FadeIn
	jsr	Boot_LogoShades_Active
	subq.w	#1,BS_MainTimer			; TIMER TIME?
	bne.s	BootScreen_MainLoop		; FUCK NO


; ---------------------------------------------------------------
; Quit sequence
; ---------------------------------------------------------------

	move.w	#75,BS_MainTimer	; defines delay after the loading text was faded out

BootScreen_QuitLoop1:

 	; Fade out loading text
 	move.b	#2,VBlankSub
 	jsr	DelayProgram
 	jsr	Boot_Loading_FadeOut
	jsr	Boot_LogoShades_Active
 	subq.w	#1,BS_MainTimer
 	bne.s	BootScreen_QuitLoop1

BootScreen_QuitLoop2: 

	; Wait until Logo Shades animation starts a new iteration
 	move.b	#2,VBlankSub
 	jsr	DelayProgram
	cmpi.w	#PalCyc_GreenShades_Active_Loop-PalCyc_GreenShades_Active,BS_PalPos_LogoShades
	beq.s	BootScreen_QuitLoop3
	jsr	Boot_LogoShades_Active
	bra.s	BootScreen_QuitLoop2

BootScreen_QuitLoop3:

 	; Fade everything out
 	move.b	#2,VBlankSub
 	jsr	DelayProgram
	jsr	Boot_BG_FadeOut
	jsr	Boot_Logo_FadeOut
	tst.w	BS_PalPos_LogoShades	; has logo shades animation been finished?
	beq	BootScreen_End		; if yes, branch
	jsr	Boot_LogoShades_Intro	; intro animation is also an outro
	bra.s	BootScreen_QuitLoop3

BootScreen_End:
	move.b	#$20,($FFFFF600).w			; set screen mode to "SSRG Screen"

; ===============================================================
















; ===============================================================
; ---------------------------------------------------------------
; Routines for BG animation
; ---------------------------------------------------------------

Boot_BG_FadeIn:

	; Run this routine every 4 frames
	RunTimer	BS_Timer1,	4

	; Change palette position for red cycle
	move.w	BS_PalPos_BG_Red,d0
	cmpi.w	#PalCyc_Red_BG-PalCyc_Red,d0
	beq.s	@1a
	subq.w	#2,d0
	move.w	d0,BS_PalPos_BG_Red

	; Change palette position for green cycle
@1a	move.w	BS_PalPos_BG_Green,d1
	cmpi.w	#PalCyc_Green_BG-PalCyc_Green,d1
	beq.s	@2a
	subq.w	#2,d1
	move.w	d1,BS_PalPos_BG_Green

@2a	bra	Boot_BG_TransferPalette

; ---------------------------------------------------------------

Boot_BG_FadeOut:

	; Run this routine every 2 frames
	RunTimer	BS_Timer1,	2

	; Change palette position for red cycle
	move.w	BS_PalPos_BG_Red,d0
	cmpi.w	#PalCyc_Red_Shadowed-PalCyc_Red,d0
	beq.s	@1a
	addq.w	#2,d0
	move.w	d0,BS_PalPos_BG_Red

	; Change palette position for green cycle
@1a	move.w	BS_PalPos_BG_Green,d1
	cmpi.w	#PalCyc_Green_Shadowed-PalCyc_Green,d1
	beq.s	@2a
	addq.w	#2,d1
	move.w	d1,BS_PalPos_BG_Green

@2a	bra	Boot_BG_TransferPalette


; ===============================================================
; ---------------------------------------------------------------
; Routines for logo animation
; ---------------------------------------------------------------

Boot_Logo_FadeIn:

	; Run this routine every 4 frames
	RunTimer	BS_Timer2,	4

	; Change palette position for red cycle
	move.w	BS_PalPos_Logo_Red,d0
	beq.s	@1a
	subq.w	#2,d0
	move.w	d0,BS_PalPos_Logo_Red

	; Change palette position for green cycle
@1a	move.w	BS_PalPos_Logo_Green,d1
	beq.s	@2a
	subq.w	#2,d1
	move.w	d1,BS_PalPos_Logo_Green

@2a	bra	Boot_Logo_TransferPalette

; ---------------------------------------------------------------

Boot_Logo_FadeOut:

	; Run this routine every 2 frames
	RunTimer	BS_Timer2,	2

	; Change palette position for red cycle
	move.w	BS_PalPos_Logo_Red,d0
	cmpi.w	#PalCyc_Red_Shadowed-PalCyc_Red,d0
	beq.s	@1a
	addq.w	#2,d0
	move.w	d0,BS_PalPos_Logo_Red

	; Change palette position for green cycle
@1a	move.w	BS_PalPos_Logo_Green,d1
	cmpi.w	#PalCyc_Green_Shadowed-PalCyc_Green,d1
	beq.s	@2a
	addq.w	#2,d1
	move.w	d1,BS_PalPos_Logo_Green

@2a	bra	Boot_Logo_TransferPalette

; ===============================================================
; ---------------------------------------------------------------
; Routines to animate logo shades
; ---------------------------------------------------------------

Boot_LogoShades_Intro:

	; Run this routine every 3 frames
	RunTimer	BS_Timer3,	3

	; Change palette position
	move.w	BS_PalPos_LogoShades,d0
	addq.w	#2,d0
	cmpi.w	#PalCyc_GreenShades_Intro_End-PalCyc_GreenShades_Intro,d0
	bne.s	@1a
	moveq	#0,d0

@1a	move.w	d0,BS_PalPos_LogoShades
	lea	PalCyc_GreenShades_Intro(pc,d0),a1
	bra	Boot_LogoShades_TransferPalette

; ---------------------------------------------------------------

Boot_LogoShades_Active:

	; Run this routine every 2 frames
	RunTimer	BS_Timer3,	2
	
	; Change palette position
	move.w	BS_PalPos_LogoShades,d0
	addq.w	#2,d0
	cmpi.w	#PalCyc_GreenShades_Active_End-PalCyc_GreenShades_Active,d0
	bne.s	@1a
	moveq	#PalCyc_GreenShades_Active_Loop-PalCyc_GreenShades_Active,d0

@1a	move.w	d0,BS_PalPos_LogoShades
	lea	PalCyc_GreenShades_Active(pc,d0),a1
	bra	Boot_LogoShades_TransferPalette

; ---------------------------------------------------------------
; Logo Shades palette cycles data
; ---------------------------------------------------------------

PalCyc_GreenShades_Intro:
	dc.w	0,0,0,0,0,0
	dc.w	$08E8,$06E6,$04E4,$00E0,$00C0,$00A0,$0080,$0060,$0040,$0020

PalCyc_GreenShades_Intro_End:
;	dc.w	0,0,0,0,0

; ---------------------------------------------------------------
PalCyc_GreenShades_Active:
	dc.w	0,0,0,0,0,0
	
PalCyc_GreenShades_Active_Loop:
	dc.w	$08E8,$06E6,$04E4,$00E0,$00C0,$00A0
	dc.w	$0080,$0080,$0080,$0080,$0080,$0080
	dc.w	$0080,$0080

PalCyc_GreenShades_Active_End:
	dc.w	$08E8,$06E6,$04E4,$00E0,$00C0

; ===============================================================
; ---------------------------------------------------------------
; Routines to fade loading text
; ---------------------------------------------------------------

Boot_Loading_FadeIn:

	; Run this routine every 3 frames
	RunTimer	BS_Timer4,	3

	jmp	Pal_FadeIn

; ---------------------------------------------------------------

Boot_Loading_FadeOut:

	; Run this routine every 3 frames
	RunTimer	BS_Timer4,	3


	jmp	Pal_FadeOut


; ===============================================================
; ---------------------------------------------------------------
; Routines to transfer palettes
; ---------------------------------------------------------------

Boot_BG_TransferPalette:

	; Transfer green colors
	lea	PalCyc_Green(pc,d1),a1
	lea	Palette_Actual+$02,a0
	move.l	(a1)+,(a0)+		; transfer 6 colors
	move.l	(a1)+,(a0)+		;
	move.l	(a1)+,(a0)+		;

	; Transfer red colors
	lea	PalCyc_Red(pc,d0),a1
	move.l	(a1)+,(a0)+		; transfer 6 colors
	move.l	(a1)+,(a0)+		;
	move.l	(a1)+,(a0)+		;

	rts

; ---------------------------------------------------------------

Boot_Logo_TransferPalette:

	; Transfer red colors
	lea	PalCyc_Red(pc,d0),a1
	lea	Palette_Actual+$22,a0
	move.l	(a1)+,(a0)+		; transfer 7 colors
	move.l	(a1)+,(a0)+		;
	move.l	(a1)+,(a0)+		;
	move.w	(a1)+,(a0)+		;

	; Transfer green colors
	lea	PalCyc_Green(pc,d1),a1
	move.l	(a1)+,(a0)+		; transfer 6 colors
	move.l	(a1)+,(a0)+		;
	move.l	(a1)+,(a0)+		;
	
	rts

; ---------------------------------------------------------------

Boot_LogoShades_TransferPalette:
	lea	Palette_Actual+$42,a0
	move.l	(a1)+,(a0)+		; transfer 6 colors
	move.l	(a1)+,(a0)+		;
	move.l	(a1)+,(a0)+		;
	rts

; ---------------------------------------------------------------
; BG / Logo palette cycles data
; ---------------------------------------------------------------

PalCyc_Red:

PalCyc_Red_Bright:
	dc.w	$066E,$044E,$022E,$000E,$000C
	
PalCyc_Red_BG:
	dc.w	$000A,$0008,$0006,$0004,$0002
	
PalCyc_Red_Shadowed:
	dc.w	0,0,0,0,0,0,0,0

; ---------------------------------------------------------------

PalCyc_Green:

PalCyc_Green_Bright:
	dc.w	$04E4,$00E0, $00C0
	
PalCyc_Green_BG:
	dc.w	$00A0,$0080,$0060,$0040,$0020
	
PalCyc_Green_Shadowed:
	dc.w	0,0,0,0,0,0,0,0

; ===============================================================















; ===============================================================
; ---------------------------------------------------------------
; Screen Data
; ---------------------------------------------------------------
   
; Palettes	=================================================

Pal_Loading:
	hex	00000EEE0ECC0EAA

; Mappings	=================================================

Map_Logo:
	incbin	'#BootScreen\Logo.map.eni'
	even

Map_BG:
	incbin	'#BootScreen\BG.map.eni'
	even


; Art		=================================================

Art_Logo:
	incbin	'#BootScreen\Logo.Tiles.kos'
	even

Art_LogoShades:
	incbin	'#BootScreen\Logo_Shades.Tiles.kos'
	even

Art_BG:
	incbin	'#BootScreen\BG.Tiles.kos'
	even
	
Art_Loading:
	incbin	'#BootScreen\Loading.Tiles.kos'
	even
