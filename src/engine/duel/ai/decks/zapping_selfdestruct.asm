AIActionTable_ZappingSelfdestruct:
	dw AIMainTurnLogic                ; .do_turn (unused)
	dw AIMainTurnLogic                ; .do_turn
	dw .start_duel
	dw AIDecideBenchPokemonToSwitchTo ; .forced_switch
	dw AIDecideBenchPokemonToSwitchTo ; .ko_switch
	dw AIPickPrizeCards               ; .take_prize

.start_duel
	call InitAIDuelVars
	call .store_list_pointers
	call SetUpBossStartingHandAndDeck
	call TrySetUpBossStartingPlayArea
	ret nc
	jp AIPlayInitialBasicCards

.list_arena
	db KANGASKHAN
	db ELECTABUZZ_LV35
	db TAUROS
	db MAGNEMITE_LV13
	db VOLTORB
	db $00

.list_bench
	db MAGNEMITE_LV13
	db VOLTORB
	db ELECTABUZZ_LV35
	db TAUROS
	db KANGASKHAN
	db $00

.list_retreat
	ai_retreat VOLTORB, -1
	db $00

.list_energy
	ai_energy MAGNEMITE_LV13,  3, +1
	ai_energy MAGNETON_LV28,   4, +0
	ai_energy VOLTORB,         3, +1
	ai_energy ELECTRODE_LV35,  3, +0
	ai_energy ELECTABUZZ_LV35, 1, +0
	ai_energy KANGASKHAN,      2, -2
	ai_energy TAUROS,          3, +0
	db $00

.list_prize
	db KANGASKHAN
	db $00

.store_list_pointers
	store_list_pointer wAICardListAvoidPrize, .list_prize
	store_list_pointer wAICardListArenaPriority, .list_arena
	store_list_pointer wAICardListBenchPriority, .list_bench
	store_list_pointer wAICardListPlayFromHandPriority, .list_bench
	store_list_pointer wAICardListRetreatBonus, .list_retreat
	store_list_pointer wAICardListEnergyBonus, .list_energy
	ret
