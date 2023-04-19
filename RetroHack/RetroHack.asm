; ===========================================================================
; ---------------------------------------------------------------------------
; RetroHack Splash Screen
; ---------------------------------------------------------------------------

RetroHack:
		moveq	#$FFFFFFE4,d0				; set music ID to "stop music"
		jsr	PlaySound_Special			; play ID
		jsr	ClearPLC				; clear pattern load cues list
		jsr	Pal_FadeFrom				; fade palettes out
		jsr	ClearScreen				; clear the plane mappings
		lea	($FFFFD000).w,a1			; load object ram address to a1
		moveq	#$00,d0					; clear d0
		move.w	#$01FF,d1				; set repeat times

RH_ClearObjects:
		move.l	d0,(a1)+				; clear object ram
		move.l	d0,(a1)+				; ''
		move.l	d0,(a1)+				; ''
		move.l	d0,(a1)+				; ''
		dbf	d1,RH_ClearObjects			; repeat til all object slots are cleared
		move.l	d0,($FFFFF616).w			; set Y scroll positions to normal
		move	#$2700,sr				; set IRQ's (Disable interrupts)
		lea	($C00004).l,a6				; load VDP address port address
		move.w	#$8700,(a6)				; set backdrop colour to the very first colour
		move.w	#$8B03,(a6)				; set scroll mode to horizontal sliced (by line)
		move.w	#$8407,(a6)				; set Scroll Plane B Map Table VRam address
		move.w	#$9001,(a6)				; set VDP Screen Map Size
		move.l	#$40000000,($C00004).l			; set VDP to V-Ram write mode with address
		lea	Art_RHOld(pc),a0			; load "OLD" logo address
		jsr	NemDec					; decompress and dump
		move.l	#$40000001,($C00004).l			; set VDP to V-Ram write mode with address
		lea	Art_RHNew(pc),a0			; load "NEW" logo address
		jsr	NemDec					; decompress and dump
		move.l	#$40000002,($C00004).l			; set VDP to V-Ram write mode with address
		lea	Art_RHLetter(pc),a0			; load "NEW" logo address
		jsr	NemDec					; decompress and dump
		lea	Map_RHOld(pc),a0			; load "OLD" mappings address
		lea	($FFFF0000).l,a1			; set temporary ram space to dump to
		jsr	KosDec					; decompress and dump
		lea	($FFFF0000).l,a5			; load mappings of "OLD" to read
		moveq	#$27,d0					; set number of columns
		moveq	#$1B,d1					; set number of rows
		move.l	#$60000003,d2				; set to write to FG plane
		jsr	RHMapScreen				; write to the map plane
		lea	Map_RHNew(pc),a0			; load "NEW" mappings address
		lea	($FFFF0000).l,a1			; set temporary ram space to dump to
		jsr	KosDec					; decompress and dump
		lea	Map_RHLetter(pc),a0			; load "NEW" mappings address
		lea	($FFFF1000).l,a1			; set temporary ram space to dump to
		jsr	KosDec					; decompress and dump

		lea	Pal_RHColour(pc),a0			; load palette address to a0
		lea	($FFFFFB40).w,a1			; load palette buffer address to a1
		move.l	(a0)+,(a1)+				; dump palette
		move.l	(a0)+,(a1)+				; ''
		move.l	(a0)+,(a1)+				; ''
		move.l	(a0)+,(a1)+				; ''
		move.l	(a0)+,(a1)+				; ''
		move.l	(a0)+,(a1)+				; ''
		move.l	(a0)+,(a1)+				; ''
		move.l	(a0)+,(a1)+				; ''

		move	#$2300,sr				; set IRQ's (Enable interrupts)
		moveq	#$00,d0					; clear d0
		move.l	d0,($FFFF7800).l			; reset RetroHack timer/flags
		move.w	#$0080,($FFFF7804).l			; set starting special deform

; ---------------------------------------------------------------------------
; RetroHack Splash Screen loop 1 (Deforming the screen in (to white))
; ---------------------------------------------------------------------------

RetroHack_Loop01:
		move.b	#$04,($FFFFF62A).w			; set V-Blank routine to run
		jsr	DelayProgram				; hult til V-Blank begins
		addq.w	#$01,($FFFF7800).l			; increase timer
		move.b	($FFFF7801).l,d0			; load timer
		andi.b	#$07,d0					; has it been 8 frames?
		bne	RHL01_NoFade				; if not, branch
		lea	Pal_RHWhite(pc),a0			; load palette to fade to
		lea	($FFFFFB00).w,a1			; load palette line 1 to a1
		moveq	#$0F,d7					; set number of colours to fade
		bsr	PalColour_FadeIn			; fade it to white

RHL01_NoFade:
		bsr	DeformInOut				; continue deforming in
		tst.b	($FFFFF605).w				; has player 1 pressed start button?
		bmi	RetroHack_Finish			; if so, branch
		cmpi.w	#$0EEE,($FFFFFB02).w			; have all colours faded to white?
		bne	RetroHack_Loop01			; if not, branch

; ---------------------------------------------------------------------------
; RetroHack Splash Screen loop 2 (Deforming the screen in (to colour))
; ---------------------------------------------------------------------------

RetroHack_Loop02:
		move.b	#$04,($FFFFF62A).w			; set V-Blank routine to run
		jsr	DelayProgram				; hult til V-Blank begins
		addq.w	#$01,($FFFF7800).l			; increase timer
		move.b	($FFFF7801).l,d0			; load timer
		andi.b	#$07,d0					; has it been 8 frames?
		bne	RHL02_NoFade				; if not, branch
		lea	Pal_RHColour(pc),a0			; load palette to fade to
		lea	($FFFFFB00).w,a1			; load palette line 1 to a1
		moveq	#$0F,d7					; set number of colours to fade
		bsr	PalColour_FadeIn			; fade it to colour

RHL02_NoFade:
		bsr	DeformInOut				; continue deforming in
		tst.b	($FFFFF605).w				; has player 1 pressed start button?
		bmi	RetroHack_Finish			; if so, branch
		tst.w	($FFFF7804).l				; has timer finished deforming in?
		bne	RetroHack_Loop02			; if not, branch
		moveq	#$00,d0					; clear d0
		move.l	d0,($FFFF7800).l			; reset RetroHack timer/flags

; ---------------------------------------------------------------------------
; RetroHack Splash Screen loop 3 (wait for flash)
; ---------------------------------------------------------------------------

RetroHack_Loop03:
		move.b	#$04,($FFFFF62A).w			; set V-Blank routine to run
		jsr	DelayProgram				; hult til V-Blank begins
		addq.w	#$01,($FFFF7800).l			; increase timer
		cmpi.w	#$0020,($FFFF7800).l			; is it time to flash yet?
		blt	RetroHack_Loop03			; if not, branch
		move.l	#$0EEE0EEE,d0				; set d0 to white
		lea	($FFFFFB00).w,a1			; load palette buffer address
		moveq	#$01,d7					; set repeat times (number of lines to dump for)

RHL03_DumpWhite:
		move.l	d0,(a1)+				; dump white colour
		move.l	d0,(a1)+				; ''
		move.l	d0,(a1)+				; ''
		move.l	d0,(a1)+				; ''
		move.l	d0,(a1)+				; ''
		move.l	d0,(a1)+				; ''
		move.l	d0,(a1)+				; ''
		move.l	d0,(a1)+				; ''
		dbf	d7,RHL03_DumpWhite			; repeat til done
		moveq	#$00,d0					; clear d0
		move.l	d0,($FFFF7800).l			; reset RetroHack timer/flags
		move.b	#$04,($FFFFF62A).w			; set V-Blank routine to run
		jsr	DelayProgram				; hult til V-Blank begins
		addq.w	#$01,($FFFF7800).l			; increase timer
		bsr	RH_MapNew				; dump new mappings to V-Ram
		moveq	#$00,d0					; clear d0
		move.l	d0,($FFFF7800).l			; reset RetroHack timer/flags

; ---------------------------------------------------------------------------
; RetroHack Splash Screen loop 4 (fade from flash)
; ---------------------------------------------------------------------------

RetroHack_Loop04:
		move.b	#$04,($FFFFF62A).w			; set V-Blank routine to run
		jsr	DelayProgram				; hult til V-Blank begins
		addq.w	#$01,($FFFF7800).l			; increase timer
		move.b	($FFFF7801).l,d0			; load timer
		andi.b	#$03,d0					; has it been 4 frames?
		bne	RHL04_NoFade				; if not, branch
		lea	Pal_RHColour(pc),a0			; load palette to fade to
		lea	($FFFFFB00).w,a1			; load palette line 1 to a1
		moveq	#$0F,d7					; set number of colours to fade
		bsr	PalColour_FadeIn			; fade it to colour

RHL04_NoFade:
		moveq	#$00,d0					; clear d0
		move.w	($FFFF7800).l,d0			; load timer
		subq.w	#$01,d0					; decrease by 1 (to align correctly)
		lsr.w	#$01,d0					; divide by 2
		cmpi.w	#$001F,d0				; has it reached the end?
		bgt	RHL04_NoLetters01			; if so, branch
		move.w	#$2000,d2				; set to write tile palette line 2
		bsr	RH_MapLetters				; write letter line

RHL04_NoLetters01:
		subq.w	#$01,d0					; minus 1 (for previous letter)
		bmi	RHL04_NoLetters02			; if it hasn't started yet, branch
		cmpi.w	#$001F,d0				; has it reached the end?
		bgt	RHL04_NoLetters02			; if so, branch
		move.w	#$4000,d2				; set to write tile palette line 3
		bsr	RH_MapLetters				; write letter line

RHL04_NoLetters02:
		tst.b	($FFFFF605).w				; has player 1 pressed start button?
		bmi	RetroHack_Finish			; if so, branch
		cmpi.w	#$0042,($FFFF7800).l			; has timer finished?
		blt	RetroHack_Loop04			; if not, loop

; ---------------------------------------------------------------------------
; RetroHack Splash Screen loop 5 (Play PCM sample)
; ---------------------------------------------------------------------------

RetroHack_Loop05:
		move	#$2700,sr				; set IRQ's (Disable interrupts)
		move.w	#$0100,($A11100).l			; set Z80 hult on
		moveq	#$00,d0					; clear d0

RHL05_WaitZ80:
		btst	d0,($A11100).l				; has Z80 stopped yet?
		bne	RHL05_WaitZ80				; if not, branch
		lea	($A04000).l,a5				; load YM2612 address port
		lea	$01(a5),a6				; load YM2612 data port
		lea	(PCMData).l,a2				; load PCM sample start address
		move.w	#((PCMData_END-PCMData)-$01),d7		; set repeat times
		move.b	#$2B,(a5)				; set YM2612 mode to DAC switch
		nop						; delay (give YM2612 time to work)
		move.b	#$80,(a6)				; turn DAC on and FM6 off
		nop						; ''
		move.b	#$2A,(a5)				; set YM2612 mode to DAC data port
		nop						; ''

RHL05_NextByte:
		move.b	(a2)+,(a6)				; save PCM byte to DAC channel
		moveq	#$07,d6					; set delay time (pitch)

RHL05_WaitPitch:
		dbf	d6,RHL05_WaitPitch			; repeat til delay is over
		jsr	ReadJoypads				; get control pad button presses
		tst.b	($FFFFF605).w				; has player 1 pressed start button?
		bmi	RetroHack_Finish			; if so, branch
		dbf	d7,RHL05_NextByte			; repeat for all PCM bytes
		move.b	#$80,(a6)				; dump null PCM value
		move.w	#$0000,($A11100).l			; set Z80 hult off
		move	#$2300,sr				; set IRQ's (Enable interrupts)

; ---------------------------------------------------------------------------
; RetroHack Splash Screen loop 6 (Deforming the screen out (to white))
; ---------------------------------------------------------------------------

RetroHack_Loop06:
		move.b	#$04,($FFFFF62A).w			; set V-Blank routine to run
		jsr	DelayProgram				; hult til V-Blank begins
		addq.w	#$01,($FFFF7800).l			; increase timer
		move.b	($FFFF7801).l,d0			; load timer
		andi.b	#$07,d0					; has it been 8 frames?
		bne	RHL06_NoFade				; if not, branch
		lea	Pal_RHWhite(pc),a0			; load palette to fade to
		lea	($FFFFFB00).w,a1			; load palette line 1 to a1
		moveq	#$0F,d7					; set number of colours to fade
		bsr	PalColour_FadeIn			; fade it to white

RHL06_NoFade:
		bsr	DeformInOut				; continue deforming in
		tst.b	($FFFFF605).w				; has player 1 pressed start button?
		bmi	RetroHack_Finish			; if so, branch
		cmpi.w	#$0EEE,($FFFFFB02).w			; have all colours faded to white?
		bne	RetroHack_Loop06			; if not, branch

; ---------------------------------------------------------------------------
; RetroHack Splash Screen loop 7 (Deforming the screen out (to black))
; ---------------------------------------------------------------------------

RetroHack_Loop07:
		move.b	#$04,($FFFFF62A).w			; set V-Blank routine to run
		jsr	DelayProgram				; hult til V-Blank begins
		addq.w	#$01,($FFFF7800).l			; increase timer
		move.b	($FFFF7801).l,d0			; load timer
		andi.b	#$07,d0					; has it been 8 frames?
		bne	RHL07_NoFade				; if not, branch
		lea	Pal_RHBlack(pc),a0			; load palette to fade to
		lea	($FFFFFB00).w,a1			; load palette line 1 to a1
		moveq	#$0F,d7					; set number of colours to fade
		bsr	PalColour_FadeIn			; fade it to white

RHL07_NoFade:
		bsr	DeformInOut				; continue deforming in
		tst.b	($FFFFF605).w				; has player 1 pressed start button?
		bmi	RetroHack_Finish			; if so, branch
		cmpi.w	#$FF80,($FFFF7804).l			; has deform timer finished?
		bne	RetroHack_Loop07			; if not, branch
		moveq	#$00,d0					; clear d0
		move.l	d0,($FFFF7800).l			; reset RetroHack timer/flags

; ---------------------------------------------------------------------------
; RetroHack Splash Screen loop 8 (Wait for finish)
; ---------------------------------------------------------------------------

RetroHack_Loop08:
		move.b	#$04,($FFFFF62A).w			; set V-Blank routine to run
		jsr	DelayProgram				; hult til V-Blank begins
		addq.w	#$01,($FFFF7800).l			; increase timer
		tst.b	($FFFFF605).w				; has player 1 pressed start button?
		bmi	RetroHack_Finish			; if so, branch
		cmpi.w	#$0020,($FFFF7800).l			; has timer finished?
		blt	RetroHack_Loop08			; if not, loop

RetroHack_Finish:
		move.b	#$24,($FFFFF600).w			; set the screen mode to Title Screen
		rts						; return

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to fade a palette into colour
; ---------------------------------------------------------------------------

PalColour_FadeIn:
		move.w	(a1),d0					; load colour to fade
		bsr	GetColours_Part1			; get the colours into registers
		move.w	(a0)+,d3				; load colour to fade to
		bsr	GetColours_Part2			; get the colours into registers
		cmp.b	d3,d0					; is blue finished?
		beq	PCFI_NoBlue				; if so, branch
		blt	PCFI_FadeUpBlue				; if too dark, branch
		subq.b	#$04,d0					; decrease blue

PCFI_FadeUpBlue:
		addq.b	#$02,d0					; increase blue

PCFI_NoBlue:
		cmp.b	d4,d1					; is green finished?
		beq	PCFI_NoGreen				; if so, branch
		blt	PCFI_FadeUpGreen			; if too dark, branch
		subq.b	#$04,d1					; decrease green

PCFI_FadeUpGreen:
		addq.b	#$02,d1					; increase green

PCFI_NoGreen:
		cmp.b	d5,d2					; is red finished?
		beq	PCFI_NoRed				; if so, branch
		blt	PCFI_FadeUpRed				; if too dark, branch
		subq.b	#$04,d2					; decrease red

PCFI_FadeUpRed:
		addq.b	#$02,d2					; increase red

PCFI_NoRed:
		bsr	PutColours				; put colours together
		move.w	d0,(a1)+				; save colour
		dbf	d7,PalColour_FadeIn			; repeat til done
		rts						; return

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to load colours from d0 to d0, d1 and d2
; ---------------------------------------------------------------------------

GetColours_Part1:
		moveq	#$00,d1					; clear d1
		move.b	d0,d1					; load green and red
		move.w	d1,d2					; ''
		lsr.w	#$08,d0					; get only blue
		lsr.b	#$04,d1					; get only green
		andi.b	#$0F,d2					; get only red
		rts						; return

GetColours_Part2:
		moveq	#$00,d4					; clear d4
		move.b	d3,d4					; load green and red
		move.w	d4,d5					; ''
		lsr.w	#$08,d3					; get only blue
		lsr.b	#$04,d4					; get only green
		andi.b	#$0F,d5					; get only red
		rts						; return

; ---------------------------------------------------------------------------
; Subroutine to put colours together in d0
; ---------------------------------------------------------------------------

PutColours:
		lsl.w	#$08,d0					; align blue
		lsl.b	#$04,d1					; align green
		or.b	d2,d1					; save red onto green
		or.w	d1,d0					; save green and red onto blue
		rts						; return

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to map the new logo
; ---------------------------------------------------------------------------

RH_MapNew:
		lea	($FFFF0000).l,a5			; load mappings of "NEW" to read
		moveq	#$27,d0					; set number of columns
		moveq	#$1B,d1					; set number of rows
		move.l	#$60000003,d2				; set to write to FG plane
		bra	RHMapScreen				; write to the map plane

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to map a line of the letters
; ---------------------------------------------------------------------------

RH_MapLetters:
		lea	($C00000).l,a5				; load VDP data port address to a5
		lea	$04(a5),a6				; load VDP address port address to a6
		lea	($FFFF1000).l,a4			; load mappings of "NEW" to read
		moveq	#$00,d1					; clear d1
		move.w	d0,d1					; copy letter number to d1
		add.w	d1,d1					; multiply by 2
		adda.w	d1,a4					; advance to correct line
		swap	d1					; send left
		addi.l	#$46080003,d1				; add starting VRam address to d1
		move	#$2700,sr				; set IRQ's (Disable interrupts)
		move.w	#$8F80,(a6)				; set auto increment mode to 80 (new line)
		move.l	d1,(a6)					; set VDP mode
		move.w	(a4),d1					; load tile
		add.w	d2,d1					; add value
		move.w	d1,(a5)					; dump top tile
		lea	$40(a4),a4				; advance to next map line data
		move.w	(a4),d1					; load tile
		add.w	d2,d1					; add value
		move.w	d1,(a5)					; dump top middle tile
		lea	$40(a4),a4				; advance to next map line data
		move.w	(a4),d1					; load tile
		add.w	d2,d1					; add value
		move.w	d1,(a5)					; dump bottom middle tile
		lea	$40(a4),a4				; advance to next map line data
		move.w	(a4),d1					; load tile
		add.w	d2,d1					; add value
		move.w	d1,(a5)					; dump bottom tile
		move.w	#$8F02,(a6)				; set auto increment mode to 2 (normal 2 bytes)
		move	#$2300,sr				; set IRQ's (Enable interrupts)
		rts						; return

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to map tile to VDP screen
; ---------------------------------------------------------------------------

RHMapScreen:
		lea	($C00000).l,a6				; load VDP data port address to a6
		lea	$04(a6),a4				; load VDP address port address to a4
		move.l	#$00800000,d4				; prepare line add value

RHMapScreen_Row:
		move.l	d2,(a4)					; set VDP to VRam write mode
		move.w	d0,d3					; reload number of columns

RHMapScreen_Column:
		move.w	(a5)+,(a6)				; dump map to VDP map slot
		dbf	d3,RHMapScreen_Column			; repeat til columns have dumped
		add.l	d4,d2					; increae to next row on VRam
		dbf	d1,RHMapScreen_Row			; repeat til all rows have dumped
		rts						; return


; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to deform the screen in and out
; ---------------------------------------------------------------------------

DeformInOut:
		subq.w	#$01,($FFFF7804).l			; decrease timer
		move.w	($FFFF7804).l,d2			; load deform position
		lsl.w	#$03,d2					; multiply by 8
		bra	DeformSpecial				; deform the special effect

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to deform the screen in a special way
; ---------------------------------------------------------------------------

DeformSpecial:
		lea	($FFFFCC00).w,a1			; load the horizontal scroll buffer address
		moveq	#$00,d0					; clear d0
		move.b	($FFFF7801).l,d0			; load timer
		add.w	d0,d0					; multiply by 2
		lea	(SinewaveData).l,a0			; load start of sinewave data to a0
		adda.w	d0,a0					; advance to correct sinewave starting value
		moveq	#$00,d0					; clear d0
		moveq	#$00,d3
		moveq	#$6F,d7					; set repeat times

DS_Loop:
		move.w	$C0(a0),d0				; load sinewave value 1
		addq.l	#$02,a0					; advance to next sinewave value
		muls.w	d2,d0					; multiply by positional amount
		asr.l	#8,d0					; send right a byte
		move.w	d0,d3					; move to d3
		move.l	d3,(a1)+				; dump to horizontal scroll
		move.w	(a0)+,d0				; load sinewave value 2
		muls.w	d2,d0					; multiply by positional amount
		asr.l	#8,d0					; send right a byte
		move.w	d0,d3					; move to d3
		move.l	d3,(a1)+				; dump to horizontal scroll
		move.l	#SinewaveData+$200,d1			; load end address
		cmpa.l	d1,a0					; is it the end of the sinewave data?
		blt	DS_NoEnd				; if not, branch
		lea	(SinewaveData).l,a0			; reset to beginning again

DS_NoEnd:
		dbf	d7,DS_Loop				; repeat til done
		rts						; return

; ===========================================================================
; ---------------------------------------------------------------------------
; RetroHack Data
; ---------------------------------------------------------------------------
Pal_RHBlack:	dc.w	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
		dc.w	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
Pal_RHWhite:	dc.w	$0000,$0EEE,$0EEE,$0EEE,$0EEE,$0EEE,$0EEE,$0EEE
		dc.w	$0EEE,$0EEE,$0EEE,$0EEE,$0EEE,$0EEE,$0EEE,$0EEE
Pal_RHColour:	dc.w	$0000,$0822,$0A44,$0C66,$0E88,$0CCC,$0CAA,$0A88
		dc.w	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
		even
; ---------------------------------------------------------------------------
Art_RHOld:	incbin	"RetroHack/ArtOld.nem"
		even
Art_RHNew:	incbin	"RetroHack/ArtNew.nem"
		even
Art_RHLetter:	incbin	"RetroHack/ArtLetter.nem"
		even
; ---------------------------------------------------------------------------
Map_RHOld:	incbin	"RetroHack/MapOld.kos"
		even
Map_RHNew:	incbin	"RetroHack/MapNew.kos"
		even
Map_RHLetter:	incbin	"RetroHack/MapLetter.kos"
		even
; ---------------------------------------------------------------------------
SinewaveData:	incbin	"RetroHack/SinewaveData.bin"
		even
PCMData:	incbin	"RetroHack/RetroHack.pcm"
PCMData_End:	even
; ---------------------------------------------------------------------------
; ===========================================================================