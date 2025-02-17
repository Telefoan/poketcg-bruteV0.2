; output:
;	carry = set:  if ?
HandleMoveModeAPress::
	ldh a, [hBankROM]
	push af
	ld l, MAP_SCRIPT_OBJECTS
	call GetMapScriptPointer
	jr nc, .handleSecondAPressScript
	ld a, BANK(FindPlayerMovementFromDirection)
	rst BankswitchROM
	call FindPlayerMovementFromDirection
	ld a, BANK(MapScripts)
	rst BankswitchROM
	ld a, [wPlayerDirection]
	ld d, a
.findAPressMatchLoop
	ld a, [hli]
	bit 7, a
	jr nz, .handleSecondAPressScript
	push bc
	push hl
	cp d
	jr nz, .noMatch
	ld a, [hli]
	cp b
	jr nz, .noMatch
	ld a, [hli]
	cp c
	jr nz, .noMatch
	ld a, [hli]
	ld [wNextScript], a
	ld a, [hli]
	ld [wNextScript+1], a
	ld a, [hli]
	ld [wDefaultObjectText], a
	ld a, [hli]
	ld [wDefaultObjectText+1], a
	ld a, [hli]
	ld [wCurrentNPCNameTx], a
	ld a, [hli]
	ld [wCurrentNPCNameTx+1], a
	pop hl
	pop bc
	pop af
	rst BankswitchROM
	scf
	ret
.noMatch
	pop hl
	ld bc, MAP_OBJECT_SIZE - 1
	add hl, bc
	pop bc
	jr .findAPressMatchLoop
.handleSecondAPressScript
	pop af
	rst BankswitchROM
	ld l, MAP_SCRIPT_PRESSED_A
	jp CallMapScriptPointerIfExists ; this function is in Bank $03


; sets a map script pointer in hl given the current map in wCurMap and which sub-script is in l
; preserves bc and de
; output:
;	hl = map script pointer
;	carry = set:  if the pointer was found
GetMapScriptPointer::
	push bc
	push hl
	ld a, [wCurMap]
	ld l, a
	ld h, $0
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	ld bc, MapScripts
	add hl, bc
	pop bc
	ld b, $0
	add hl, bc
	ldh a, [hBankROM]
	push af
	ld a, BANK(MapScripts)
	rst BankswitchROM
	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop af
	rst BankswitchROM
	ld a, l
	or h
	jr nz, .asm_3ae5
	scf
.asm_3ae5
	ccf
	pop bc
	ret


; finds a Script from the first byte and puts the next two bytes (usually arguments?) into cb
RunOverworldScript::
	ld hl, wScriptPointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [hli]
	ld c, [hl]
	inc hl
	ld b, [hl]
	push bc
	rlca
	ld c, a
	ld b, $0
	ld hl, OverworldScriptTable
	add hl, bc
	ldh a, [hBankROM]
	push af
	ld a, BANK(OverworldScriptTable)
	rst BankswitchROM
	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop af
	rst BankswitchROM
	pop bc
	jp hl


; preserves all registers except af
ResetAnimationQueue::
	ldh a, [hBankROM]
	push af
	ld a, BANK(_ResetAnimationQueue)
	rst BankswitchROM
	call _ResetAnimationQueue
	pop af
	jp BankswitchROM


; preserves de
FinishQueuedAnimations::
	ldh a, [hBankROM]
	push af
	ld a, BANK(ClearAndDisableQueuedAnimations)
	rst BankswitchROM
	call ClearAndDisableQueuedAnimations
	jr c, .skip_clear_frame_func
	xor a
	ld hl, wDoFrameFunction
	ld [hli], a
	ld [hl], a
.skip_clear_frame_func
	call ZeroObjectPositionsAndToggleOAMCopy
	pop af
	jp BankswitchROM


;----------------------------------------
;        UNREFERENCED FUNCTIONS
;----------------------------------------
;
; loads some configurations for the duel against
; the NPC whose deck ID is stored in wNPCDuelDeckID.
; this includes NPC portrait, his/her name text ID, and the number of prize cards.
; this was used in testing since these configurations
; are stored in the script-related NPC data for normal gameplay.
; preserves all registers except af
; input:
;	[wNPCDuelDeckID] = NPC's deck ID (*_DECK constant)
; output:
;	carry = set:  if a duel configuration was found for the given NPC deck ID
;GetNPCDuelConfigurations::
;	farcall _GetNPCDuelConfigurations
;	ret
;
;
;Func_3b11::
;	ldh a, [hBankROM]
;	push af
;	ld a, BANK(_GameLoop)
;	rst BankswitchROM
;	call _GameLoop
;	pop af
;	jp BankswitchROM
