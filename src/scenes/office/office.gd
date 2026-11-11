extends Control

## Office scene matching the user's handwritten sketch design 1-to-1:
## Top Left: Geralt with headset, "щас денег" (current cash) and "+322 $" (credit commission).
## Top Center: "Шкала доверия" (Persuasion meter with "ЗАЕБИСЬ" and "ХУЁВО").
## Top Right: "Нечисть" (Monster portrait with speech bubble).
## Bottom Left: "Варики диалога" (Choices with odds % up / % down, dashed locked slots).
## Bottom Center: "ТУТ ЭФФЕКТЫ РАСПИСАНЫ ТИПО" (Breakdown of hovered/active effects).
## Bottom Right: "ПРЕДМЕТЫ" (Inventory and passive buffs).

# --- Top Left (Geralt) Nodes ---
@onready var cash_label: Label = $TopContainer/GeraltPanel/GeraltHeader/CashBox/CashValue
@onready var loan_bonus_label: Label = $TopContainer/GeraltPanel/GeraltHeader/CreditBox/CreditValue
@onready var day_info_label: Label = $TopContainer/GeraltPanel/GeraltHeader/DayInfoLabel
@onready var dial_button: Button = $TopContainer/GeraltPanel/DialButton

# --- Top Center (Persuasion Meter) ---
@onready var persuasion_meter: PersuasionMeter = $TopContainer/PersuasionMeter

# --- Top Right (Monster) Nodes ---
@onready var monster_name_label: Label = $TopContainer/MonsterPanel/MonsterHeader/MonsterNameLabel
@onready var monster_traits_container: HBoxContainer = $TopContainer/MonsterPanel/MonsterHeader/TraitsHBox
@onready var monster_speech_label: Label = $TopContainer/MonsterPanel/SpeechBubble/SpeechLabel
@onready var monster_portrait: TextureRect = $TopContainer/MonsterPanel/MonsterPortrait

# --- Bottom Left (Dialogue Options) ---
@onready var dialogue_box: DialogueBox = $BottomContainer/DialogueBox

# --- Bottom Center (Effects Panel: "ТУТ ЭФФЕКТЫ РАСПИСАНЫ ТИПО") ---
@onready var effect_approach_label: Label = $BottomContainer/EffectsPanel/VBox/ApproachBadge
@onready var effect_desc_label: Label = $BottomContainer/EffectsPanel/VBox/EffectDescLabel
@onready var effect_trait_synergy_label: Label = $BottomContainer/EffectsPanel/VBox/TraitSynergyLabel
@onready var effect_side_label: Label = $BottomContainer/EffectsPanel/VBox/SideEffectLabel
@onready var effect_loan_delta_label: Label = $BottomContainer/EffectsPanel/VBox/LoanDeltaLabel

# --- Bottom Right (Items / "ПРЕДМЕТЫ") ---
@onready var items_container: VBoxContainer = $BottomContainer/ItemsPanel/Scroll/ItemsVBox

func _ready() -> void:
	Events.call_started.connect(_on_call_started)
	Events.call_finished.connect(_on_call_finished)
	Events.outcome_resolved.connect(_on_outcome_resolved)
	Events.player_balance_changed.connect(_on_balance_changed)
	Events.quota_updated.connect(_on_quota_updated)
	Events.item_purchased.connect(func(_item): _refresh_inventory())

	dialogue_box.option_hovered.connect(_on_dialogue_option_hovered)
	dial_button.pressed.connect(_on_dial_pressed)

	_refresh_player_stats()
	_refresh_inventory()

	if GameManager.state == GameManager.GameState.START_DAY:
		_prepare_desk_for_call()

func _refresh_player_stats() -> void:
	cash_label.text = "%d $" % GameManager.player_cash
	day_info_label.text = "День %d/%d (Звонков: %d)" % [
		GameManager.current_day,
		GameManager.MAX_DAYS,
		GameManager.calls_remaining_today
	]
	var commission: int = QuotaManager.calculate_commission(GameManager.current_call_loan_amount)
	loan_bonus_label.text = "+%d $" % commission

func _refresh_inventory() -> void:
	for child in items_container.get_children():
		child.queue_free()

	if GameManager.inventory.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Пусто\n(Купите в магазине)"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 11)
		empty_lbl.modulate = Color(0.7, 0.7, 0.7, 0.6)
		items_container.add_child(empty_lbl)
		return

	for item in GameManager.inventory:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(0, 36)
		var hbox := HBoxContainer.new()
		slot.add_child(hbox)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(28, 28)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = item.icon
		hbox.add_child(icon)

		var name_lbl := Label.new()
		name_lbl.text = item.item_name
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		hbox.add_child(name_lbl)

		slot.tooltip_text = "%s\n%s" % [item.description, item.side_effect_text]
		items_container.add_child(slot)

func _prepare_desk_for_call() -> void:
	dial_button.visible = true
	dial_button.text = "Набрать клиента (%d осталось)" % GameManager.calls_remaining_today
	monster_name_label.text = "Клиент: —"
	monster_speech_label.text = "..."
	loan_bonus_label.text = "+0 $"
	_clear_traits()
	_reset_effects_panel()

func _on_dial_pressed() -> void:
	dial_button.visible = false
	monster_speech_label.text = "*Гудки в телефонной трубке... соединение...*"
	GameManager.start_next_call()

func _on_call_started(monster: MonsterData) -> void:
	_refresh_player_stats()
	monster_name_label.text = monster.monster_name
	if not monster.opening_lines.is_empty():
		monster_speech_label.text = monster.opening_lines.pick_random()
	else:
		monster_speech_label.text = "Слушаю вас..."
	_display_traits(monster)

func _on_outcome_resolved(outcome: DialogueOutcome, monster_reaction: String) -> void:
	monster_speech_label.text = monster_reaction
	_refresh_player_stats()

	# Display resolved outcome in effects panel
	effect_approach_label.text = "[РЕЗУЛЬТАТ: %s]" % outcome.outcome_title
	effect_desc_label.text = "Сдвиг доверия: %s%d%%" % [
		("+" if outcome.persuasion_delta >= 0 else ""),
		int(outcome.persuasion_delta * 100)
	]
	effect_trait_synergy_label.text = "Текущий кредит: %d орен" % GameManager.current_call_loan_amount
	if not outcome.side_effect_description.is_empty():
		effect_side_label.text = "Побочный эффект: %s" % outcome.side_effect_description
	else:
		effect_side_label.text = ""

func _on_call_finished(is_success: bool, loan_amount: int) -> void:
	if is_success:
		monster_speech_label.text = "«СОГЛАСЕН! ОФОРМЛЯЙТЕ КРЕДИТ!»\nСделка закрыта на %d орен!" % loan_amount
	else:
		monster_speech_label.text = "«ПОШЛИ ВОН ИЗ МОЕГО ЛОГОВА!»\n*Клиент в бешенстве бросил трубку*"

	_refresh_player_stats()
	await get_tree().create_timer(1.8).timeout

	if GameManager.calls_remaining_today > 0:
		_prepare_desk_for_call()
	else:
		monster_speech_label.text = "Смена завершена. Подведение итогов плана..."
		await get_tree().create_timer(1.2).timeout
		GameManager.end_day()

func _on_dialogue_option_hovered(option: DialogueOption) -> void:
	if option == null:
		_reset_effects_panel()
		return

	effect_approach_label.text = "ПОДХОД: [%s] %s" % [option.approach_tag.to_upper(), option.risk_label]
	effect_desc_label.text = "Реплика: «%s»" % option.text

	# Check trait synergy
	if GameManager.current_monster:
		var has_synergy: bool = false
		for m_trait in GameManager.current_monster.traits:
			if m_trait and option.approach_tag in m_trait.weak_against_approaches:
				effect_trait_synergy_label.text = "★ СЛАБОСТЬ МОНСТРА к [%s] (+50%% шанс согласия!)" % m_trait.trait_name
				effect_trait_synergy_label.modulate = Color(0.3, 1.0, 0.4)
				has_synergy = true
				break
			elif m_trait and option.approach_tag in m_trait.strong_against_approaches:
				effect_trait_synergy_label.text = "⚠ СОПРОТИВЛЕНИЕ МОНСТРА к [%s] (Высок риск отказа!)" % m_trait.trait_name
				effect_trait_synergy_label.modulate = Color(1.0, 0.35, 0.35)
				has_synergy = true
				break
		if not has_synergy:
			effect_trait_synergy_label.text = "Обычный эффект на монстра (нейтральная реакция)"
			effect_trait_synergy_label.modulate = Color(0.85, 0.85, 0.85)

	effect_side_label.text = "Возможен побочный эффект при броске кубика"
	var commission: int = QuotaManager.calculate_commission(GameManager.current_call_loan_amount)
	effect_loan_delta_label.text = "Ожидаемый бонус: +%d $ при успехе" % commission

func _reset_effects_panel() -> void:
	effect_approach_label.text = "НАВЕДИТЕСЬ НА ВАРИАНТ ДИАЛОГА"
	effect_desc_label.text = "Здесь отображаются эффекты, риски и слабости монстра."
	effect_trait_synergy_label.text = ""
	effect_side_label.text = ""
	effect_loan_delta_label.text = ""

func _display_traits(monster: MonsterData) -> void:
	_clear_traits()
	for m_trait in monster.traits:
		if m_trait == null:
			continue
		var badge := Button.new()
		badge.text = "[%s]" % m_trait.trait_name
		badge.tooltip_text = "%s\nСлабость к: %s" % [m_trait.description, ", ".join(m_trait.weak_against_approaches)]
		badge.disabled = true
		monster_traits_container.add_child(badge)

func _clear_traits() -> void:
	for child in monster_traits_container.get_children():
		child.queue_free()

func _on_balance_changed(_new_balance: int, _delta: int) -> void:
	_refresh_player_stats()

func _on_quota_updated(_cur: int, _target: int) -> void:
	_refresh_player_stats()
