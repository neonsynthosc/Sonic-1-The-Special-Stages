
; ===============================================================
; MENU SYSTEM for SonicVaan
; Developed and Desgined (c) 2012 Vladikcomper
; ===============================================================

; ---------------------------------------------------------------
; This file contains menu prefences, textes and action scripts to
; be parsed by the menu core.
; ---------------------------------------------------------------

; ---------------------------------------------------------------
; NOTE:	Data Block should be placed in following order:
;	<InitScript>
;	<EntryList>
;	<TextPointers>
; ---------------------------------------------------------------

; ---------------------------------------------------------------
; ENTRY LIST METHODS:
;
;	_ME_TextID:	ID of Text string listed in <TextPointers>
;
;	_ME_Type:	Menu Entry Type
;				_ME_Normal = Normal selectable entry
;				_ME_Option = Option entry
;
;	_ME_Action:	Entry action when selected (if _ME_Type = _ME_Normal)
;				_ME_Nothing = No effect
;				_ME_GoToMenu = Go to menu set by _ME_ActionVal
;				_ME_GoToGameMode = Go to Game Mode set by _ME_ActionVal
;				_ME_CallHandler = Call handler routine set by _ME_ActionVal
;
;	_ME_ActionVal:	Value for _ME_Action (see above)
;
;	_ME_OpnNum:	Number of options, zero-based (if _ME_Type = _ME_Option)
;
;	_ME_OpnAddr:	Memory address that represents option field
;
;	_ME_OpnTextID:	Start ID of text string for option variants
;
;	_ME_OpnTextPos:	Text position of option text (in tiles)
;
; ---------------------------------------------------------------

; ---------------------------------------------------------------
; Prefences
; ---------------------------------------------------------------

_Menu_BGM		equ	$91
_Menu_Snd_Select	equ	$A1
_Menu_Snd_Switch	equ	$CD

; ---------------------------------------------------------------
; Menu Scripts constants
; ---------------------------------------------------------------

; Entry Types

_ME_Normal = 0
_ME_Option = 1

; Entry Actions

_ME_Nothing = 0
_ME_GoToMenu = 1
_ME_GoToGameMode = 2
_ME_CallHandler = -1	; Custom handler

; ---------------------------------------------------------------
; Main Macros
; ---------------------------------------------------------------

; Reset methods
_ME_TextID = 0
_ME_Type = 0
_ME_Action = 0
_ME_ActionVal = 0
_ME_OpnNum = 0
_ME_OpnAddr = 0
_ME_OpnTextID = 0
_ME_OpnTextPos = 0

_Menu_CreateEntry	macro
	dc.w	_ME_TextID
	dc.b	_ME_Type
	if _ME_Type=_ME_Normal
		dc.b	_ME_Action
		if _ME_Action=_ME_Nothing
			dc.l	0
		elseif _ME_Action=_ME_GoToMenu
			dc.b	_ME_ActionVal
			dc.b	0,0,0
		elseif _ME_Action=_ME_GoToGameMode
			dc.b	_ME_ActionVal
			dc.b	0,0,0
		else
			dc.l	_ME_ActionVal
		endc
	else
		dc.b	_ME_OpnNum
		dc.w	_ME_OpnAddr&$FFFF
		dc.b	_ME_OpnTextID
		dc.b	_ME_OpnTextPos
	endc
	endm

; ===============================================================
; ---------------------------------------------------------------
; Main Pointers array
; ---------------------------------------------------------------

Menu_DataPointers:
@Lst
	; $00 - Main Menu
	dc.w	MainMenu_InitScript-@Lst
	dc.w	MainMenu_EntryList-@Lst
	dc.w	MainMenu_TextPointers-@Lst
	
	; $01 - Options
	dc.w	Options_InitScript-@Lst
	dc.w	Options_EntryList-@Lst
	dc.w	Options_TextPointers-@Lst
	
	; $02 - Extras
	dc.w	Extras_InitScript-@Lst
	dc.w	Extras_EntryList-@Lst
	dc.w	Extras_TextPointers-@Lst

	; $03 - Debug Options 1
	dc.w	Debug_InitScript-@Lst
	dc.w	Debug_EntryList-@Lst
	dc.w	Debug_TextPointers-@Lst

	; $04 - Debug Options 2
	dc.w	Debug2_InitScript-@Lst
	dc.w	Debug2_EntryList-@Lst
	dc.w	Debug2_TextPointers-@Lst

	; $05 - Save Data
	dc.w	SaveData_InitScript-@Lst
	dc.w	SaveData_EntryList-@Lst
	dc.w	SaveData_TextPointers-@Lst

	; $06 - Statistics
	dc.w	Stats_InitScript-@Lst
	dc.w	Stats_EntryList-@Lst
	dc.w	Stats_TextPointers-@Lst

	; $07 - Special Stage Debugger
	dc.w	SSDbg_InitScript-@Lst
	dc.w	SSDbg_EntryList-@Lst
	dc.w	SSDbg_TextPointers-@Lst

; ===============================================================




; ===============================================================
; ---------------------------------------------------------------
; Main menu
; ---------------------------------------------------------------

MainMenu_InitScript:

	; Art Load Cues
	dc.w	0			; Number of cues ($0 = None)

	; External Objects
	dc.w	1			; Number of objects ($0 = None)
	dc.l	Obj_Emerald

	; Palettes
	dc.w	$A42,$C44,$C64		; BG Palette
	dc.w	$000,$EEE		; Normal Menu Entry
	dc.w	$000,$6E6		; Active Menu Entry
	hex	0000006000A000C600EA	; Emerald palette

	; Menu prefences
	dc.b	0			; Scroll Direction
	dc.b	5			; Number of entries (zero-based)
	dc.b	12, 8			; XY position of top left corner (in tiles)



; ---------------------------------------------------------------

MainMenu_EntryList:

	; START GAME
	_ME_TextID:	= 0
	_ME_Type:	= _ME_Normal
	_ME_Action:	= _ME_GoToGameMode
	_ME_ActionVal:	= $0C
	_Menu_CreateEntry

	; EXTRAS
	_ME_TextID:	= 1
	_ME_Type:	= _ME_Normal
	_ME_Action:	= _ME_GoToMenu
	_ME_ActionVal:	= $02
	_Menu_CreateEntry

	; STATISTICS
	_ME_TextID:	= 5
	_ME_Type:	= _ME_Normal
	_ME_Action:	= _ME_GoToMenu
	_ME_ActionVal:	= $06
	_Menu_CreateEntry

	; ???
	_ME_TextID:	= 4
	_ME_Type:	= _ME_Normal
	_ME_Action:	= _ME_Nothing
	_ME_ActionVal:	= $28
	_Menu_CreateEntry

	; OPTIONS
	_ME_TextID:	= 2
	_ME_Type:	= _ME_Normal
	_ME_Action:	= _ME_GoToMenu
	_ME_ActionVal:	= $01
	_Menu_CreateEntry

	; BETA INFO
	_ME_TextID:	= 3
	_ME_Type:	= _ME_Normal
	_ME_Action:	= _ME_GoToGameMode
	_ME_ActionVal:	= $28
	_Menu_CreateEntry


; ---------------------------------------------------------------

MainMenu_TextPointers:
@Lst	dc.w	@0-@Lst
	dc.w	@1-@Lst
	dc.w	@2-@Lst
	dc.w	@3-@Lst
	dc.w	@4-@Lst
	dc.w	@5-@Lst

@0	dc.b	'START GAME',0
@1	dc.b	'EXTRAS',0
@2	dc.b	'OPTIONS',0
@3	dc.b	'BETA INFO',0
@4	dc.b	'???',0
@5	dc.b	'STATISTICS',0
	even

; ===============================================================




; ===============================================================
; Options
; ===============================================================

Options_InitScript:

	; Art Load Cues
	dc.w	1			; Number of cues ($0 = None)
	dc.l	Art_MenuHeaders
	dc.w	_VRAM_CArt

	; External Objects
	dc.w	2			; Number of objects ($0 = None)
	dc.l	Obj_Header
	dc.l	Obj_Emerald

	; Palettes
	dc.w	$44A,$44C,$46C		; BG Palette
	dc.w	$000,$EEE		; Normal Menu Entry
	dc.w	$000,$0EE		; Active Menu Entry
	hex	00000024006800AC02EE

	; Menu prefences
	dc.b	1			; Scroll Direction
	dc.b	3			; Number of entries (zero-based)
	dc.b	8, 10			; XY position of top left corner (in tiles)

; ---------------------------------------------------------------

Options_EntryList:

	; DIFFICULTY
	_ME_TextID:	= 0
	_ME_Type:	= _ME_Option
	_ME_OpnNum:	= 3
	_ME_OpnAddr:	= $FFFFFF3E
	_ME_OpnTextID:	= 3
	_ME_OpnTextPos:	= 18
	_Menu_CreateEntry

	; DEBUG OPTIONS
	_ME_TextID:	= 1
	_ME_Type:	= _ME_Normal
	_ME_Action:	= _ME_GoToMenu
	_ME_ActionVal:	= $03
	_Menu_CreateEntry

	; CLEAR SAVE DATA
	_ME_TextID:	= 2
	_ME_Type:	= _ME_Normal
	_ME_Action:	= _ME_GoToMenu
	_ME_ActionVal:	= $05
	_Menu_CreateEntry

	; BACK TO MAIN MENU
	_ME_TextID:	= 9
	_ME_Type:	= _ME_Normal
	_ME_Action:	= _ME_GoToMenu
	_ME_ActionVal:	= $00
	_Menu_CreateEntry

; ---------------------------------------------------------------

Options_TextPointers:
@Lst	dc.w	@0-@Lst
	dc.w	@1-@Lst
	dc.w	@2-@Lst
	dc.w	@3-@Lst
	dc.w	@4-@Lst
	dc.w	@5-@Lst
	dc.w	@6-@Lst
	dc.w	@7-@Lst
	dc.w	@8-@Lst
	dc.w	@9-@Lst

@0	dc.b	'DIFFICULTY',0
@1	dc.b	'DEBUG OPTIONS',0
@2	dc.b	'CLEAR SAVE DATA',0
@3	dc.b	'NORMAL',0
@4	dc.b	'  HARD',0
@5	dc.b	'ERAZOR',0
@6	dc.b	'  EASY',0
@7	dc.b	'OFF',0
@8	dc.b	' ON',0
@9	dc.b	'BACK TO MAIN MENU',0
	even

; ===============================================================


	

; ===============================================================
; ---------------------------------------------------------------
; Extras
; ---------------------------------------------------------------

Extras_InitScript:

	; Art Load Cues
	dc.w	1			; Number of cues ($0 = None)
	dc.l	Art_MenuHeaders
	dc.w	_VRAM_CArt

	; External Objects
	dc.w	1			; Number of objects ($0 = None)
	dc.l	Obj_Header

	; Palettes
	dc.w	$444,$666,$888		; BG Palette
	dc.w	$000,$EEE		; Normal Menu Entry
	dc.w	$000,$0EE		; Active Menu Entry
	dc.w	$00E,$00E,$00E,$00E,$00E	; Emerald palette ###

	; Menu prefences
	dc.b	1			; Scroll Direction
	dc.b	2			; Number of entries (zero-based)
	dc.b	11, 22		; XY position of top left corner (in tiles)

; ---------------------------------------------------------------

Extras_EntryList:

	; MAZE MINIGAME
	_ME_TextID:	= 0
	_ME_Type:	= _ME_Normal
	_ME_Action:	= _ME_CallHandler
	_ME_ActionVal:	= Hndl_MazeMini
	_Menu_CreateEntry

	; MZ 1 DEMO
	_ME_TextID:	= 1
	_ME_Type:	= _ME_Normal
	_ME_Action:	= _ME_CallHandler
	_ME_ActionVal:	= Hndl_MZ1Demo
	_Menu_CreateEntry

	; BACK TO MAIN MENU
	_ME_TextID:	= 2
	_ME_Type:	= _ME_Normal
	_ME_Action:	= _ME_GoToMenu
	_ME_ActionVal:	= $00
	_Menu_CreateEntry

; ---------------------------------------------------------------

Extras_TextPointers:
@Lst	dc.w	@0-@Lst
	dc.w	@1-@Lst
	dc.w	@2-@Lst

@0	dc.b	'MAZE MINIGAME',0
@1	dc.b	'MZ 1 DEMO',0
@2	dc.b	'BACK TO MAIN MENU',0


; ===============================================================
; Debug Options
; ===============================================================

Debug_InitScript:

	; Art Load Cues
	dc.w	1			; Number of cues ($0 = None)
	dc.l	Art_MenuHeaders
	dc.w	_VRAM_CArt

	; External Objects
	dc.w	2			; Number of objects ($0 = None)
	dc.l	Obj_Header
	dc.l	Obj_Emerald

	; Palettes
	dc.w	$128,$12A,$14A		; BG Palette
	dc.w	$000,$EEE		; Normal Menu Entry
	dc.w	$000,$0EE		; Active Menu Entry
	hex	00000024006800AC02EE

	; Menu prefences
	dc.b	2			; Scroll Direction
	dc.b	5			; Number of entries (zero-based)
	dc.b	8, 10			; XY position of top left corner (in tiles)

; ---------------------------------------------------------------

Debug_EntryList:

	; SLOW MOTION
	_ME_TextID:	= 0
	_ME_Type:	= _ME_Option
	_ME_OpnNum:	= 1
	_ME_OpnAddr:	= $FFFFFFE1
	_ME_OpnTextID:	= 2
	_ME_OpnTextPos:	= 18
	_Menu_CreateEntry

	; DEBUG MODE
	_ME_TextID:	= 1
	_ME_Type:	= _ME_Option
	_ME_OpnNum:	= 1
	_ME_OpnAddr:	= $FFFFFFFA
	_ME_OpnTextID:	= 2
	_ME_OpnTextPos:	= 18
	_Menu_CreateEntry

	; LEVEL
	_ME_TextID:	= 5
	_ME_Type:	= _ME_Option
	_ME_OpnNum:	= 6
	_ME_OpnAddr:	= $FFFFFE10
	_ME_OpnTextID:	= 6
	_ME_OpnTextPos:	= 18
	_Menu_CreateEntry

	; ACT
	_ME_TextID:	= 13
	_ME_Type:	= _ME_Option
	_ME_OpnNum:	= 2
	_ME_OpnAddr:	= $FFFFFE11
	_ME_OpnTextID:	= 14
	_ME_OpnTextPos:	= 18
	_Menu_CreateEntry

	; NEXT PAGE
	_ME_TextID:	= 17
	_ME_Type:	= _ME_Normal
	_ME_Action:	= _ME_GoToMenu
	_ME_ActionVal:	= $04
	_Menu_CreateEntry

	; BACK TO MAIN MENU
	_ME_TextID:	= 4
	_ME_Type:	= _ME_Normal
	_ME_Action:	= _ME_GoToMenu
	_ME_ActionVal:	= $01
	_Menu_CreateEntry

; ---------------------------------------------------------------

Debug_TextPointers:
@Lst	dc.w	@0-@Lst
	dc.w	@1-@Lst
	dc.w	@2-@Lst
	dc.w	@3-@Lst
	dc.w	@4-@Lst
	dc.w	@5-@Lst
	dc.w	@6-@Lst
	dc.w	@7-@Lst
	dc.w	@8-@Lst
	dc.w	@9-@Lst
	dc.w	@10-@Lst
	dc.w	@11-@Lst
	dc.w	@12-@Lst
	dc.w	@13-@Lst
	dc.w	@14-@Lst
	dc.w	@15-@Lst
	dc.w	@16-@Lst
	dc.w	@17-@Lst

@0	dc.b	'SLOW MOTION',0
@1	dc.b	'DEBUG MODE',0
@2	dc.b	'   OFF',0
@3	dc.b	'    ON',0
@4	dc.b	'BACK TO OPTIONS',0
@5	dc.b	'LEVEL',0
@6	dc.b	'   GHZ',0
@7	dc.b	'    LZ',0
@8	dc.b	'    MZ',0
@9	dc.b	'   SLZ',0
@10	dc.b	'   SYZ',0
@11	dc.b	'   SBZ',0
@12	dc.b	'ENDING',0
@13	dc.b	'ACT',0
@14	dc.b	'     1',0
@15	dc.b	'     2',0
@16	dc.b	'     3',0
@17	dc.b	'NEXT PAGE',0
	even

; ===============================================================
; Debug Options 2
; ===============================================================

Debug2_InitScript:

	; Art Load Cues
	dc.w	1			; Number of cues ($0 = None)
	dc.l	Art_MenuHeaders
	dc.w	_VRAM_CArt

	; External Objects
	dc.w	2			; Number of objects ($0 = None)
	dc.l	Obj_Header
	dc.l	Obj_Emerald

	; Palettes
	dc.w	$128,$12A,$14A		; BG Palette
	dc.w	$000,$EEE		; Normal Menu Entry
	dc.w	$000,$0EE		; Active Menu Entry
	hex	00000024006800AC02EE

	; Menu prefences
	dc.b	2			; Scroll Direction
	dc.b	1			; Number of entries (zero-based)
	dc.b	8, 10			; XY position of top left corner (in tiles)

; ---------------------------------------------------------------

Debug2_EntryList:

	; SPECIAL STAGE DEBUGGER
	_ME_TextID:	= 0
	_ME_Type:	= _ME_Normal
	_ME_Action:	= _ME_GoToMenu
	_ME_ActionVal:	= $07
	_Menu_CreateEntry

	; PREVIOUS PAGE
	_ME_TextID:	= 1
	_ME_Type:	= _ME_Normal
	_ME_Action:	= _ME_GoToMenu
	_ME_ActionVal:	= $03
	_Menu_CreateEntry


; ---------------------------------------------------------------

Debug2_TextPointers:
@Lst	dc.w	@0-@Lst
	dc.w	@1-@Lst

@0	dc.b	'SPECIAL STAGE DEBUGGER',0
@1	dc.b	'PREVIOUS PAGE',0
	even


; ===============================================================
; Save Data
; ===============================================================

SaveData_InitScript:

	; Art Load Cues
	dc.w	1			; Number of cues ($0 = None)
	dc.l	Art_MenuHeaders
	dc.w	_VRAM_CArt

	; External Objects
	dc.w	2			; Number of objects ($0 = None)
	dc.l	Obj_Header
	dc.l	Obj_Emerald

	; Palettes
	dc.w	$128,$12A,$14A		; BG Palette
	dc.w	$000,$EEE		; Normal Menu Entry
	dc.w	$000,$0EE		; Active Menu Entry
	hex	00000024006800AC02EE

	; Menu prefences
	dc.b	3			; Scroll Direction
	dc.b	1			; Number of entries (zero-based)
	dc.b	8, 10			; XY position of top left corner (in tiles)

; ---------------------------------------------------------------

SaveData_EntryList:

	; DELETE
	_ME_TextID:	= 0
	_ME_Type:	= _ME_Normal
	_ME_Action:	= _ME_CallHandler
	_ME_ActionVal:	= Hndl_ClearSave
	_Menu_CreateEntry


	; BACK TO OPTIONS
	_ME_TextID:	= 1
	_ME_Type:	= _ME_Normal
	_ME_Action:	= _ME_GoToMenu
	_ME_ActionVal:	= $01
	_Menu_CreateEntry

; ---------------------------------------------------------------

SaveData_TextPointers:
@Lst	dc.w	@0-@Lst
	dc.w	@1-@Lst

@0	dc.b	'DELETE',0
@1	dc.b	'GO BACK TO OPTIONS',0
	even


; ===============================================================
; ---------------------------------------------------------------
; Statistics
; ---------------------------------------------------------------

Stats_InitScript:

	; Art Load Cues
	dc.w	0			; Number of cues ($0 = None)

	; External Objects
	dc.w	1			; Number of objects ($0 = None)
	dc.l	Obj_Emerald

	; Palettes
	dc.w	$941,$000,$1BB		; BG Palette
	dc.w	$000,$EEE		; Normal Menu Entry
	dc.w	$000,$6E6		; Active Menu Entry
	hex	0000006000A000C600EA	; Emerald palette

	; Menu prefences
	dc.b	1			; Scroll Direction
	dc.b	2			; Number of entries (zero-based)
	dc.b	12, 8			; XY position of top left corner (in tiles)



; ---------------------------------------------------------------

Stats_EntryList:

	; EMERALDS
	_ME_TextID:	= 0
	_ME_Type:	= _ME_Option
	_ME_OpnNum:	= 0
	_ME_OpnAddr:	= $FFFFFE12
	_ME_OpnTextID:	= 7
	_ME_OpnTextPos:	= 18
	_Menu_CreateEntry

	; UNLOCKABLES
	_ME_TextID:	= 1
	_ME_Type:	= _ME_Option
	_ME_OpnNum:	= 0
	_ME_OpnAddr:	= $FFFF8100
	_ME_OpnTextID:	= 4
	_ME_OpnTextPos:	= 18
	_Menu_CreateEntry


	; BACK TO MAIN MENU
	_ME_TextID:	= 3
	_ME_Type:	= _ME_Normal
	_ME_Action:	= _ME_GoToMenu
	_ME_ActionVal:	= $00
	_Menu_CreateEntry



; ---------------------------------------------------------------

Stats_TextPointers:
@Lst	dc.w	@0-@Lst
	dc.w	@1-@Lst
	dc.w	@2-@Lst
	dc.w	@3-@Lst
	dc.w	@4-@Lst
	dc.w	@5-@Lst
	dc.w	@6-@Lst
	dc.w	@7-@Lst
	dc.w	@8-@Lst
	dc.w	@9-@Lst
	dc.w	@10-@Lst
	dc.w	@11-@Lst
	dc.w	@12-@Lst
	dc.w	@13-@Lst
	dc.w	@14-@Lst
	dc.w	@15-@Lst
	dc.w	@16-@Lst
	dc.w	@17-@Lst
	dc.w	@18-@Lst
	dc.w	@19-@Lst
	dc.w	@20-@Lst
	dc.w	@21-@Lst
	dc.w	@22-@Lst
	dc.w	@23-@Lst
	dc.w	@24-@Lst
	dc.w	@25-@Lst
	dc.w	@26-@Lst
	dc.w	@27-@Lst

@0	dc.b	'EMERALDS',0
@1	dc.b	'UNLOCKABLES',0
@2	dc.b	'???',0
@3	dc.b	'BACK TO MAIN MENU',0
@4	dc.b	'  0/2',0
@5	dc.b	'  1/2',0
@6	dc.b	'  2/2',0
@7	dc.b	' 0/20',0
@8	dc.b	' 1/20',0
@9	dc.b	' 2/20',0
@10	dc.b	' 3/20',0
@11	dc.b	' 4/20',0
@12	dc.b	' 5/20',0
@13	dc.b	' 6/20',0
@14	dc.b	' 7/20',0
@15	dc.b	' 8/20',0
@16	dc.b	' 9/20',0
@17	dc.b	'10/20',0
@18	dc.b	'11/20',0
@19	dc.b	'12/20',0
@20	dc.b	'13/20',0
@21	dc.b	'14/20',0
@22	dc.b	'15/20',0
@23	dc.b	'16/20',0
@24	dc.b	'17/20',0
@25	dc.b	'18/20',0
@26	dc.b	'19/20',0
@27	dc.b	'20/20',0
	even

; ===============================================================
; Special Stage Debugger
; ===============================================================

SSDbg_InitScript:

	; Art Load Cues
	dc.w	1			; Number of cues ($0 = None)
	dc.l	Art_MenuHeaders
	dc.w	_VRAM_CArt

	; External Objects
	dc.w	2			; Number of objects ($0 = None)
	dc.l	Obj_Header
	dc.l	Obj_Emerald

	; Palettes
	dc.w	$121,$121,$141		; BG Palette
	dc.w	$000,$EEE		; Normal Menu Entry
	dc.w	$000,$0EE		; Active Menu Entry
	hex	00000024006800AC02EE

	; Menu prefences
	dc.b	2			; Scroll Direction
	dc.b	2			; Number of entries (zero-based)
	dc.b	8, 10			; XY position of top left corner (in tiles)

; ---------------------------------------------------------------

SSDbg_EntryList:

	; SPECIAL STAGE
	_ME_TextID:	= 0
	_ME_Type:	= _ME_Option
	_ME_OpnNum:	= 19
	_ME_OpnAddr:	= $FFFFFE16
	_ME_OpnTextID:	= 3
	_ME_OpnTextPos:	= 18
	_Menu_CreateEntry

	; START
	_ME_TextID:	= 1
	_ME_Type:	= _ME_Normal
	_ME_Action:	= _ME_CallHandler
	_ME_ActionVal:	= Hndl_SSDebug
	_Menu_CreateEntry

	; SPECIAL STAGE DEBUGGER
	_ME_TextID:	= 2
	_ME_Type:	= _ME_Normal
	_ME_Action:	= _ME_GoToMenu
	_ME_ActionVal:	= $03
	_Menu_CreateEntry

; ---------------------------------------------------------------

SSDbg_TextPointers:
@Lst	dc.w	@0-@Lst
	dc.w	@1-@Lst
	dc.w	@2-@Lst
	dc.w	@3-@Lst
	dc.w	@4-@Lst
	dc.w	@5-@Lst
	dc.w	@6-@Lst
	dc.w	@7-@Lst
	dc.w	@8-@Lst
	dc.w	@9-@Lst
	dc.w	@10-@Lst
	dc.w	@11-@Lst
	dc.w	@12-@Lst
	dc.w	@13-@Lst
	dc.w	@14-@Lst
	dc.w	@15-@Lst
	dc.w	@16-@Lst
	dc.w	@17-@Lst
	dc.w	@18-@Lst
	dc.w	@19-@Lst
	dc.w	@20-@Lst

@0	dc.b	'SPECIAL STAGE',0
@1	dc.b	'START',0
@2	dc.b	'BACK TO DEBUG OPTIONS',0
@3	dc.b	'1',0
@4	dc.b	'2',0
@5	dc.b	'3',0
@6	dc.b	'4',0
@7	dc.b	'5',0
@8	dc.b	'6',0
@9	dc.b	'7',0
@10	dc.b	'8',0
@11	dc.b	'9',0
@12	dc.b	'10',0
@13	dc.b	'11',0
@14	dc.b	'12',0
@15	dc.b	'13',0
@16	dc.b	'14',0
@17	dc.b	'15',0
@18	dc.b	'16',0
@19	dc.b	'17',0
@20	dc.b	'18',0
@21	dc.b	'19',0
@22	dc.b	'20',0
	even
