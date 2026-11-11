extends Node

## Central State Machine & Game Director for "The Witcher 3: Cold Calling".

enum GameState {
	MAIN_MENU,
	START_DAY,
	CALL_IN_PROGRESS,
	CALL_FINISHED,
	DAY_SUMMARY,
	SHOP,
	GAME_OVER,
	VICTORY
}

# --- Game State ---
var state: GameState = GameState.MAIN_MENU

# --- Persistent Run Parameters ---
var current_day: int = 1
const MAX_DAYS: int = 5

var calls_remaining_today: int = 3
const MAX_CALLS_PER_DAY: int = 3

var current_quota_progress: int = 0
var target_quota: int = 15000
var player_cash: int = 500 # Starting petty cash

# --- Player Stats & Roguelike Buffs ---
var player_luck: float = 0.0
var dialogue_slots: int = 2 # Default 2 options, upgradeable in shop to 3 or 4
var hangup_shield: bool = false
var initial_persuasion_bonus: float = 0.0
var next_turn_item_multiplier: float = 1.0 # Temporary multiplier from Option 9
var inventory: Array[ShopItem] = []

# --- Current Call Context ---
const BASE_CALL_TURNS: int = 6
var call_turns_remaining: int = BASE_CALL_TURNS
var current_monster: MonsterData = null
var current_persuasion: float = 0.0 # -1.0 (-100%) to +1.0 (+100%), 0.0 = neutral
var current_call_loan_amount: int = 0

# --- Monster & Actions Database ---
var monster_roster: Array[MonsterData] = []
var global_actions_pool: Array[DialogueOption] = []

func _ready() -> void:
	_load_monsters_roster()
	_load_global_actions()

func _load_global_actions() -> void:
	global_actions_pool.clear()
	for i in range(1, 11):
		var num_str := "%02d" % i
		var path := "res://src/data/dialogues/actions/action_%s.tres" % num_str
		if ResourceLoader.exists(path):
			var opt := load(path) as DialogueOption
			if opt != null:
				global_actions_pool.append(opt)

func _load_monsters_roster() -> void:
	# Load pre-configured monsters from data directory
	var monster_paths := [
		"res://src/data/monsters/ghoul.tres",
		"res://src/data/monsters/noonwraith.tres",
		"res://src/data/monsters/drowner.tres"
	]
	monster_roster.clear()
	for path in monster_paths:
		if ResourceLoader.exists(path):
			var m := load(path) as MonsterData
			if m != null:
				monster_roster.append(m)

func start_new_game() -> void:
	current_day = 1
	player_cash = 200
	player_luck = 0.0
	dialogue_slots = 2
	hangup_shield = false
	initial_persuasion_bonus = 0.0
	inventory.clear()
	start_day()

func start_day() -> void:
	state = GameState.START_DAY
	calls_remaining_today = MAX_CALLS_PER_DAY
	current_quota_progress = 0
	target_quota = QuotaManager.get_quota_for_day(current_day)
	
	Events.day_started.emit(current_day, calls_remaining_today)
	Events.quota_updated.emit(current_quota_progress, target_quota)
	
	# Transition to office
	get_tree().change_scene_to_file("res://src/scenes/office/office.tscn")

func start_next_call() -> void:
	if calls_remaining_today <= 0:
		end_day()
		return

	state = GameState.CALL_IN_PROGRESS
	calls_remaining_today -= 1
	call_turns_remaining = BASE_CALL_TURNS
	next_turn_item_multiplier = 1.0
	
	# Pick random or sequential monster from roster
	if not monster_roster.is_empty():
		current_monster = monster_roster.pick_random()
	else:
		# Fallback if roster not yet generated
		current_monster = MonsterData.new()
		current_monster.monster_name = "Дикий клиент"
		current_monster.base_loan_amount = 12000

	current_persuasion = clampf(initial_persuasion_bonus, -1.0, 1.0)
	current_call_loan_amount = current_monster.base_loan_amount

	Events.call_started.emit(current_monster)
	Events.call_turns_changed.emit(call_turns_remaining, 0)
	Events.persuasion_changed.emit(current_persuasion, 0.0)

func process_dialogue_choice(option: DialogueOption) -> DialogueOutcome:
	if state != GameState.CALL_IN_PROGRESS:
		return null

	var effective_luck: float = player_luck * next_turn_item_multiplier
	next_turn_item_multiplier = 1.0 # Reset temporary item multiplier

	var outcome: DialogueOutcome = CallResolver.resolve(option, current_monster, effective_luck)
	
	# 1. Apply persuasion shifts (including Option 1 half-scale shift)
	var delta: float = outcome.persuasion_delta
	if outcome.is_half_scale_shift:
		if outcome.persuasion_delta >= 0.0:
			delta = maxf(0.2, (1.0 - current_persuasion) * 0.5)
		else:
			delta = -maxf(0.2, (current_persuasion - (-1.0)) * 0.5)

	var old_persuasion: float = current_persuasion
	current_persuasion = clampf(current_persuasion + delta, -1.0, 1.0)
	
	# 2. Adjust loan amount
	current_call_loan_amount = int(float(current_call_loan_amount) * outcome.loan_amount_multiplier) + outcome.flat_money_delta
	current_call_loan_amount = maxi(1000, current_call_loan_amount)

	# 3. Turns management (Option 5, 8)
	call_turns_remaining -= 1
	if outcome.turns_delta != 0:
		call_turns_remaining = maxi(0, call_turns_remaining + outcome.turns_delta)
	Events.call_turns_changed.emit(call_turns_remaining, outcome.turns_delta - 1)

	# 4. Quota management (Option 10)
	if outcome.quota_percent_delta != 0.0:
		target_quota = maxi(1000, int(float(target_quota) * (1.0 + outcome.quota_percent_delta)))
		Events.quota_updated.emit(current_quota_progress, target_quota)

	# 5. Day calls limit modifier (Option 10)
	if outcome.day_calls_delta != 0:
		calls_remaining_today = maxi(0, calls_remaining_today + outcome.day_calls_delta)

	# 6. Item manipulation (Option 4)
	if outcome.duplicate_random_item and not inventory.is_empty():
		var dup_item: ShopItem = inventory.pick_random()
		inventory.append(dup_item)
		Events.log_message_posted.emit("Дублирован предмет: %s!" % dup_item.item_name, Color.CYAN)
	elif outcome.remove_random_item and not inventory.is_empty():
		var rem_item: ShopItem = inventory.pick_random()
		inventory.erase(rem_item)
		Events.log_message_posted.emit("Утрачен предмет: %s!" % rem_item.item_name, Color.CORAL)

	# 7. Next turn item multiplier (Option 9)
	if outcome.next_turn_item_multiplier != 1.0:
		next_turn_item_multiplier = outcome.next_turn_item_multiplier

	# Emit events
	Events.persuasion_changed.emit(current_persuasion, current_persuasion - old_persuasion)
	Events.outcome_resolved.emit(outcome, outcome.monster_reaction_text)

	# Check terminal conditions
	if outcome.is_instant_hangup:
		if hangup_shield:
			hangup_shield = false # Consume shield
			Events.log_message_posted.emit("Очки-авиаторы спасли вас от сброса трубки!", Color.GOLD)
		else:
			finish_call(false)
			return outcome

	if outcome.is_instant_success or current_persuasion >= 0.99:
		finish_call(true)
	elif current_persuasion <= -0.99:
		finish_call(false)
	elif call_turns_remaining <= 0:
		Events.log_message_posted.emit("Терпение клиента иссякло! Звонок прерван.", Color.SALMON)
		finish_call(false)

	return outcome

func finish_call(is_success: bool) -> void:
	state = GameState.CALL_FINISHED
	var final_amount: int = current_call_loan_amount if is_success else 0

	if is_success:
		current_quota_progress += final_amount
		var commission: int = QuotaManager.calculate_commission(final_amount)
		player_cash += commission
		Events.player_balance_changed.emit(player_cash, commission)
		Events.quota_updated.emit(current_quota_progress, target_quota)

	Events.call_finished.emit(is_success, final_amount)

func end_day() -> void:
	state = GameState.DAY_SUMMARY
	var quota_met: bool = QuotaManager.is_quota_satisfied(current_quota_progress, current_day)
	Events.day_ended.emit(current_day, quota_met, current_quota_progress)
	get_tree().change_scene_to_file("res://src/scenes/day_summary/day_summary.tscn")

func advance_to_shop() -> void:
	state = GameState.SHOP
	get_tree().change_scene_to_file("res://src/scenes/shop/shop.tscn")

func advance_to_next_day() -> void:
	current_day += 1
	if current_day > MAX_DAYS:
		# Player survived all 5 days of corporate probation!
		state = GameState.VICTORY
		get_tree().change_scene_to_file("res://src/scenes/game_over/game_over.tscn")
	else:
		start_day()

func trigger_game_over(_reason: String = "Уволен за невыполнение плана!") -> void:
	state = GameState.GAME_OVER
	get_tree().change_scene_to_file("res://src/scenes/game_over/game_over.tscn")

func buy_item(item: ShopItem) -> bool:
	if player_cash < item.cost:
		return false

	player_cash -= item.cost
	Events.player_balance_changed.emit(player_cash, -item.cost)
	inventory.append(item)

	# Apply item effects
	match item.item_type:
		ShopItem.ItemType.LUCK_BOOST:
			player_luck += item.effect_value
		ShopItem.ItemType.EXTRA_DIALOGUE_SLOT:
			dialogue_slots = clampi(dialogue_slots + int(item.effect_value), 2, 4)
		ShopItem.ItemType.HANGUP_PROTECTION:
			hangup_shield = true
		ShopItem.ItemType.PERSUASION_STARTER:
			initial_persuasion_bonus += item.effect_value
		ShopItem.ItemType.QUOTA_DISCOUNT:
			target_quota = maxi(1000, target_quota - int(item.effect_value))
			Events.quota_updated.emit(current_quota_progress, target_quota)

	Events.item_purchased.emit(item)
	return true
