
; ---------------------------------------------------------------
; 'CLEAR SAVE DATA' handler
; ---------------------------------------------------------------

Hndl_ClearSave:
	move.b	#$01,($A130F1).l				; open access to S-Ram
	clr.b		($200002).l					; delete emeralds (S-RAM)
	clr.b		($200300).l					; delete Slow Motion state (S-RAM)
	clr.b		($200302).l					; delete Debug Mode state (S-RAM)
	clr.b		($200038).l					; delete emerald list state (S-RAM)
	clr.b		($200058).l					; delete unknown (S-RAM)
	clr.b		($200100).l					; delete unlockables (S-RAM)
	move.b	#$00,($A130F1).l				; close access to S-Ram

	clr.b 	($FFFFFE12).w				; delete emeralds
	clr.b		($FFFFFFE1).w				; delete Slow Motion state
	clr.b		($FFFFFFFA).w				; delete Debug Mode state
	clr.b		($FFFFFF38).w				; delete emerald list state
	clr.b		($FFFFFE58).w				; delete unknown
	clr.b		($FFFF8100).w				; delete unlockables

	rts

; ---------------------------------------------------------------
; 'MZ 1 DEMO' handler
; ---------------------------------------------------------------

Hndl_MZ1Demo:
	move.b	#$02,($FFFFFE10).w			; set level to Marble Zone
	move.b	#$00,($FFFFFE11).w			; set act to 1
	move.b	#$08,($FFFFF600).w			; set the screen mode to Demo
	jsr	PlayLevel
	jsr	Demo
	jmp	Level

; ---------------------------------------------------------------
; 'MAZE MINIGAME' handler
; ---------------------------------------------------------------

Hndl_MazeMini:
	move.b	#$00,($FFFFFE10).w			; set level to Green Hill Zone
	move.b	#$01,($FFFFFE11).w			; set act to 2
	move.b	#$0C,($FFFFF600).w			; set the screen mode to Level
	jsr	PlayLevel
	move.b	#1,($FFFF8666).w 
	jmp	Level

; ---------------------------------------------------------------
; 'SPECIAL STAGE DEBUGGER' handler
; ---------------------------------------------------------------

Hndl_SSDebug:
	move.b	#$01,($FFFFCFFF).w			; set flag, so it will go back to main menu after finish
	move.b	#$10,($FFFFF600).w			; set game mode to $10 (Special Stage)
	jmp		SpecialStage