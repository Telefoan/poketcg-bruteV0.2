; doubles the damage at de if Swords Dance or Focus Energy was used
; in the last turn by the turn holder's Active Pokémon.
; preserves bc
; input:
;	de = damage being dealt
HandleDoubleDamageSubstatus::
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS3
	get_turn_duelist_var
	bit SUBSTATUS3_THIS_TURN_DOUBLE_DAMAGE_F, a
	ret z
;	fallthrough

; output:
;	de *= 2
DoubleDamage::
	ld a, e
	or d
	ret z
	sla e
	rl d
	ret


; checks if the Defending Pokemon (turn holder's Active Pokemon) has anything
; that reduces the damage dealt to it this turn (SUBSTATUS1 or Pokemon Powers).
; also checks if the Attacking Pokemon (non-turn holder's Active Pokemon)
; has any substatus that reduces the damage dealt this turn (SUBSTATUS2).
; input:
;	de = damage being dealt
; output:
;	de = updated damage
HandleDamageReduction::
	call HandleDamageReductionExceptSubstatus2
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	call GetNonTurnDuelistVariable
	or a
	ret z
	cp SUBSTATUS2_REDUCE_BY_20
	jr z, ReduceDamageBy20
	cp SUBSTATUS2_REDUCE_BY_10
	ret nz
;	fallthrough

; output:
;	de -= 10
ReduceDamageBy10::
	ld hl, -10
	add hl, de
	ld e, l
	ld d, h
	ret

; output:
;	de -= 20
ReduceDamageBy20::
	ld hl, -20
	add hl, de
	ld e, l
	ld d, h
	ret


; output:
;	de = 0:  if input de < 40
PreventAllDamage_IfLessThan40::
	ld bc, 40
	call CompareDEtoBC
	ret nc ; return if damage is at least 40
	jr PreventAllDamage

; output:
;	de = 0:  if input de ≥ 30
PreventAllDamage_IfMoreThan20::
	ld bc, 30
	call CompareDEtoBC
	ret c ; return if damage is less than 30
;	fallthrough

; output:
;	de = 0
PreventAllDamage::
	ld de, 0
	ret


; checks if the Defending Pokemon (turn holder's Active Pokemon) has anything
; that reduces the damage dealt to it this turn. (SUBSTATUS1 or Pokemon Powers).
; assumes that it isn't possible for a Pokémon to have both a SUBSTATUS1
; and a Pokémon Power that reduces damage.
; input:
;	de = damage being dealt
;	[wLoadedAttack] = Attacking Pokémon card's attack data (atk_data_struct)
;	[wTempNonTurnDuelistCardID] = card ID of the Pokémon being attacked
; output:
;	de = updated damage
HandleDamageReductionExceptSubstatus2::
	ld a, [wNoDamageOrEffect]
	or a
	jr nz, PreventAllDamage

	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	get_turn_duelist_var
	or a
	jr z, .not_affected_by_substatus1

	cp SUBSTATUS1_NO_DAMAGE
	jr z, PreventAllDamage
	cp SUBSTATUS1_REDUCE_BY_10
	jr z, ReduceDamageBy10
	cp SUBSTATUS1_REDUCE_BY_20
	jr z, ReduceDamageBy20
	cp SUBSTATUS1_HARDEN
	jr z, PreventAllDamage_IfLessThan40
	cp SUBSTATUS1_HALVE_DAMAGE
	jr z, HalveDamage_RoundedDown

.not_affected_by_substatus1
	call CheckIsIncapableOfUsingPkmnPower_ArenaCard
	ret c ; return if Pokemon Powers can't be used because of status or Toxic Gas
.pkmn_power
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	ret z ; return if the damage is being dealt by a Pokémon Power
	ld a, [wTempNonTurnDuelistCardID]
	cp MR_MIME
	jr z, PreventAllDamage_IfMoreThan20 ; Invisible Wall
	cp KABUTO
	ret nz
;	fallthrough

; output:
;	de /= 2 (rounded down to the nearest 10)
HalveDamage_RoundedDown::
	sra d
	rr e
	bit 0, e
	ret z
	ld hl, -5
	add hl, de
	ld e, l
	ld d, h
	ret


; checks for Invisible Wall, Kabuto Armor, Neutralizing Shield, or Transparency.
; if found, then reduce or nullify the damage at de accordingly.
; input:
;	de = damage being dealt
;	[wLoadedAttack] = Attacking Pokémon card's attack data (atk_data_struct)
;	[wTempPlayAreaLocation_cceb] = play area location offset of the Pokémon being attacked
; output:
;	de = updated damage
HandleDamageReductionOrNoDamageFromPkmnPowerEffects::
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	ret z ; return if the damage is being dealt by a Pokémon Power
	call CheckIfPkmnPowersAreCurrentlyDisabled
	ret c ; return if Pokémon Powers can't be used
	ld a, [wTempPlayAreaLocation_cceb]
	or a
	call nz, HandleDamageReductionExceptSubstatus2.pkmn_power
	push de ; push damage from call above, which handles Invisible Wall and Kabuto Armor
	call HandleNoDamageOrEffectSubstatus.pkmn_power
	call nc, HandleTransparency
	pop de ; restore damage
	jr c, PreventAllDamage ; set damage to 0 if either Neutralizing Shield or Transparency was activated
	ret


; preserves bc
; input:
;	a = wNoDamageOrEffect ID (NO_DAMAGE_OR_EFFECT_* constant)
; output:
;	hl = text ID from NoDamageOrEffectTextIDTable (only if check succeeds)
;	carry = set:  if the target has anything affecting it that would prevent
;	              any damage or effect done to it during this turn
CheckNoDamageOrEffect::
	ld a, [wNoDamageOrEffect]
	or a
	ret z
	bit 7, a
	jr nz, .dont_print_text ; already been here so don't repeat the text
	ld hl, wNoDamageOrEffect
	set 7, [hl]
	dec a
	add a
	ld e, a
	ld d, $0
	ld hl, NoDamageOrEffectTextIDTable
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	scf
	ret

.dont_print_text
	ld hl, $0000
	scf
	ret

NoDamageOrEffectTextIDTable::
	tx NoDamageOrEffectDueToAttackText       ; NO_DAMAGE_OR_EFFECT_ATTACK
	tx NoDamageOrEffectDueToTransparencyText ; NO_DAMAGE_OR_EFFECT_TRANSPARENCY
	tx NoDamageOrEffectDueToNShieldText      ; NO_DAMAGE_OR_EFFECT_NSHIELD


; preserves bc
; input:
;	[wLoadedAttack] = Attacking Pokémon card's attack data (atk_data_struct)
;	[wTempNonTurnDuelistCardID] = card ID of the Pokémon being attacked
; output:
;	hl = ID for notification text
;	carry = set:  if the Defending Pokemon (turn holder's Active Pokemon) is affected by
;	              a substatus that prevents any damage or effect dealt to it for the turn.
;	[wNoDamageOrEffect] = correct index (NO_DAMAGE_OR_EFFECT_* constant)
HandleNoDamageOrEffectSubstatus::
	xor a
	ld [wNoDamageOrEffect], a
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	ret z ; return nc if the damage is being dealt by a Pokémon Power
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS1
	get_turn_duelist_var
	ld e, NO_DAMAGE_OR_EFFECT_ATTACK
	ldtx hl, NoDamageOrEffectDueToAttackText
	cp SUBSTATUS1_IMMUNITY
	jr z, .no_damage_or_effect
	call CheckIsIncapableOfUsingPkmnPower_ArenaCard
	ccf
	ret nc ; return if Pokemon Power can't be used because of a Special Condition or Toxic Gas

.pkmn_power
	ld a, [wTempNonTurnDuelistCardID]
	cp MEW_LV8
	jr z, .neutralizing_shield
	or a
	ret

.neutralizing_shield
	ld a, [wIsDamageToSelf]
	or a
	ret nz ; return nc if the damage isn't being dealt by an opponent's Pokémon
	; prevent damage if attacked by a non-Basic Pokemon
	ld a, [wTempTurnDuelistCardID]
	ld e, a
	ld d, $0
	call LoadCardDataToBuffer2_FromCardID
	ld a, [wLoadedCard2Stage]
	or a
	ret z ; return nc if the damage is being dealt by a Basic Pokemon
	ld e, NO_DAMAGE_OR_EFFECT_NSHIELD
	ldtx hl, NoDamageOrEffectDueToNShieldText
.no_damage_or_effect
	ld a, e
	ld [wNoDamageOrEffect], a
	scf
	ret


; if the Pokemon being attacked is HAUNTER_LV17 and its Transparency is active,
; there is a 50% chance that any damage or effect is prevented.
; input:
;	[wLoadedAttack] = Attacking Pokémon card's attack data (atk_data_struct)
;	[wTempNonTurnDuelistCardID] = card ID of the Pokémon being attacked
;	[wTempPlayAreaLocation_cceb] = play area location offset of the Pokémon being attacked
; output:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if Transparency successfully protected Haunter from the attack
HandleTransparency::
	ld a, [wTempNonTurnDuelistCardID]
	cp HAUNTER_LV17
	jr z, .transparency
.done
	or a
	ret

.transparency
	ld a, [wLoadedAttackCategory]
	cp POKEMON_POWER
	ret z ; return nc if the damage is being dealt by a Pokémon Power
	ld a, [wTempPlayAreaLocation_cceb]
	call CheckIsIncapableOfUsingPkmnPower
	jr c, .done
	xor a
	ld [wDuelDisplayedScreen], a
	ldtx de, TransparencyCheckText
	call TossCoin
	ret nc ; return if tails
	ld e, NO_DAMAGE_OR_EFFECT_TRANSPARENCY
	ldtx hl, NoDamageOrEffectDueToTransparencyText
	jr HandleNoDamageOrEffectSubstatus.no_damage_or_effect


; preserves bc and de
; output:
;	hl = text ID explaining why the Active Pokémon is unable to attack
;	carry = set:  if the turn holder's Active Pokemon is unable to attack
CheckUnableToAttackDueToEffect::
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	get_turn_duelist_var
	or a
	jr z, CheckIfActiveCardIsParalyzedOrAsleep
	ldtx hl, UnableToAttackThatPokemonText
	cp SUBSTATUS2_CANNOT_ATTACK_THIS
	jr z, CheckIfActiveCardIsParalyzedOrAsleep.set_carry
	ldtx hl, UnableToAttackText
	cp SUBSTATUS2_CANNOT_ATTACK
	jr z, CheckIfActiveCardIsParalyzedOrAsleep.set_carry
;	fallthrough

; preserves bc and de
; output:
;	hl = text ID for the appropriate Special Condition
;	carry = set:  if the turn holder's Active Pokemon is Paralyzed or Asleep
CheckIfActiveCardIsParalyzedOrAsleep::
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	and CNF_SLP_PRZ
	ldtx hl, UnableDueToParalysisText
	cp PARALYZED
	jr z, .set_carry
	ldtx hl, UnableDueToSleepText
	cp ASLEEP
	jr z, .set_carry
	or a
	ret

.set_carry
	scf
	ret


; preserves bc and de
; input:
;	[wSelectedAttack] = chosen attack (0 = first attack, 1 = second attack)
; ouput:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if the turn holder's Active Pokemon cannot use the attack
;	              at wSelectedAttack because it's affected by Amnesia
HandleAmnesiaSubstatus::
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	get_turn_duelist_var
	cp SUBSTATUS2_AMNESIA
	jr z, .affected_by_amnesia
.not_the_disabled_atk
	or a
	ret

.affected_by_amnesia
	ld a, DUELVARS_ARENA_CARD_DISABLED_ATTACK_INDEX
	get_turn_duelist_var
	ld a, [wSelectedAttack]
	cp [hl]
	jr nz, .not_the_disabled_atk
	ldtx hl, UnableToUseAttackDueToAmnesiaText
	scf
	ret


; preserves bc and de
; output:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if the turn holder's Active Pokemon cannot retreat because of an effect
CheckUnableToRetreatDueToEffect::
	call CheckIfActiveCardIsParalyzedOrAsleep
	ret c
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS2
	get_turn_duelist_var
	or a
	ret z ; return nc if the Active Pokémon isn't affected by any SUBSTATUS2 effects
	ldtx hl, UnableToRetreatDueToAcidText
	cp SUBSTATUS2_UNABLE_RETREAT
	scf
	ret z ; return carry if the Active Pokémon can't retreat because of a Substatus
	or a
	ret


; preserves bc and de
; output:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if the turn holder can't play any Trainer cards because of an effect
CheckCantUseTrainerDueToEffect::
	ld a, DUELVARS_ARENA_CARD_SUBSTATUS3
	get_turn_duelist_var
	bit SUBSTATUS3_HEADACHE_F, a
	ret z
	ldtx hl, UnableToUseTrainerDueToHeadacheText
	scf
	ret


; preserves bc and de
; output:
;	hl = ID for notification text:  if the below condition is true
;	carry = set:  if there's an Aerodactyl in play with an active Prehistoric Power
IsPrehistoricPowerActive::
	ld a, AERODACTYL
	call CountPokemonWithActivePkmnPowerInBothPlayAreas
	ret nc ; return if there isn't an Aerodactyl in play
	call CheckIfPkmnPowersAreCurrentlyDisabled
	ldtx hl, UnableToEvolveDueToPrehistoricPowerText
	ccf
	ret


; preserves all registers except af
; output:
;	carry = set:  if the turn holder has an Omanyte with an active Clairvoyance Pokemon Power
IsClairvoyanceActive::
	call CheckIfPkmnPowersAreCurrentlyDisabled
	ccf
	ret nc ; return no carry if Pokémon Powers can't be used
	ld a, OMANYTE
;	fallthrough

; checks the turn holder's play area for a specific Pokemon, but the Active Pokemon
; is ignored if it's Asleep, Confused, or Paralyzed (i.e. Pokemon Power-incapable).
; preserves all registers except af
; input:
;	a = card ID of the Pokémon to look for
; output:
;	a = number of Pokemon with the ID from input that are in the turn holder's play area
;	carry = set:  if there's at least 1 of that Pokemon in the turn holder's play area
CountTurnDuelistPokemonWithActivePkmnPower::
	push hl
	push de
	push bc
	ld b, a ; originally stored in wTempPokemonID_ce7c
	ld c, 0 ; initial counter
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	get_turn_duelist_var
	ld d, a
	ld e, PLAY_AREA_ARENA
	ld l, DUELVARS_ARENA_CARD_STATUS
	ld a, [hl]
	and CNF_SLP_PRZ
	jr nz, .next_bench_slot ; skip the Active Pokémon if it's Alseep, Confused, or Paralyzed

.loop_play_area
	ld a, DUELVARS_ARENA_CARD
	add e
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	cp b
	jr nz, .next_bench_slot
	inc c
.next_bench_slot
	inc e
	dec d
	jr nz, .loop_play_area

.done
	ld a, c
	or a
	jr z, .return ; return no carry if none of that Pokémon were found with an active power
	scf
.return
	pop bc
	pop de
	pop hl
	ret


; checks both play areas for a Muk with an active Toxic Gas Pokémon Power.
; preserves all registers except af
; output:
;	a = number of Muk in play with an active Toxic Gas Pokémon Power
;	carry = set:  if Toxic Gas is preventing Pokémon Powers from being used
CheckIfPkmnPowersAreCurrentlyDisabled::
	ld a, MUK
;	fallthrough

; checks both play areas for a specific Pokemon, but the Active Pokemon is
; ignored if it's Asleep, Confused, or Paralyzed (i.e. Pokemon Power-incapable).
; preserves all registers except af
; input:
;	a = card ID of the Pokémon to look for
; output:
;	a = number of Pokemon with the ID from input that are in either play area
;	carry = set:  if there's at least 1 of that Pokemon in either play area
CountPokemonWithActivePkmnPowerInBothPlayAreas::
	push bc
	ld b, a
	call CountTurnDuelistPokemonWithActivePkmnPower
	ld c, a
	rst SwapTurn
	ld a, b
	call CountTurnDuelistPokemonWithActivePkmnPower
	rst SwapTurn
	add c
	or a
	jr z, .return ; return no carry if none of that Pokémon were found
	scf
.return
	pop bc
	ret


; preserves bc and de
; output:
;	carry = set:  if the turn holder's Active Pokémon can be given a Special Conditions
CheckIfActiveCardCanBeAffectedByStatus::
	ld a, DUELVARS_ARENA_CARD
	get_turn_duelist_var
	call _GetCardIDFromDeckIndex
	cp CLEFAIRY_DOLL ; Trainer Pokémon are unaffected
	ret z ; return no carry if the Active Pokémon is a Clefairy Doll
	cp MYSTERIOUS_FOSSIL ; Trainer Pokémon are unaffected
	ret z ; return no carry if the Active Pokémon is a Mysterious Fossil
	cp SNORLAX ; Snorlax's Thick Skinned Pokémon Power may make it unaffected
	scf
	ret nz ; return carry if the Active Pokémon isn't a Snorlax
;	fallthrough

; checks whether the Active Pokémon can use a Pokémon Power, more specifically,
; if the Active Pokémon is Asleep, Confused, or Paralyzed or if Toxic Gas is active.
; preserves bc and de
; output:
;	hl = ID for notification text
;	carry = set:  if the turn holder's Active Pokémon is unable to use its Pokémon Power
CheckIsIncapableOfUsingPkmnPower_ArenaCard::
	xor a ; PLAY_AREA_ARENA
;	fallthrough

; checks whether the Pokémon in the given location can use a Pokémon Power by
; looking for a Muk in the play area and checking it for Special Conditions if a = 0.
; preserves bc and de
; input:
;	a = play area location offset of the Pokémon to check (PLAY_AREA_* constant)
; output:
;	hl = ID for notification text
;	carry = set:  if the Pokémon in the given location is unable to use its Pokémon Power
CheckIsIncapableOfUsingPkmnPower::
	or a
	jr nz, .check_toxic_gas
	ld a, DUELVARS_ARENA_CARD_STATUS
	get_turn_duelist_var
	and CNF_SLP_PRZ
	ldtx hl, CannotUseDueToStatusText
	scf
	ret nz ; return carry if it's Asleep, Confused, or Paralyzed
.check_toxic_gas
	ld a, MUK
	call CountPokemonWithActivePkmnPowerInBothPlayAreas
	ldtx hl, UnableDueToToxicGasText
	ret
