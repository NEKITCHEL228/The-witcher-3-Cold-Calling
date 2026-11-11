extends Control
class_name DialogueBox

## Dialogue choices ("ВАРИКИ ДИАЛОГА") from the game design sketch:
## Shows choice buttons with odds percentages (e.g., 67% ↑  33% ↓)
## Displays dashed locked slot placeholders below active options.

signal option_hovered(option: DialogueOption)

@onready var options_container: VBoxContainer = $OptionsVBox
@onready var header_label: Label = $HeaderLabel

var _current_options: Array[DialogueOption] = []
var _is_busy: bool = false
const MAX_POSSIBLE_SLOTS: int = 4

func _ready() -> void:
	Events.call_started.connect(_on_call_started)
	Events.call_finished.connect(_on_call_finished)
	Events.outcome_resolved.connect(_on_outcome_resolved)

func _on_call_started(monster: MonsterData) -> void:
	_is_busy = false
	header_label.text = "ВАРИКИ ДИАЛОГА:"
	populate_options(monster)

func _on_call_finished(_is_success: bool, _loan_amount: int) -> void:
	_clear_all()
	header_label.text = "Звонок завершён."

func _on_outcome_resolved(_outcome: DialogueOutcome, _monster_reaction: String) -> void:
	await get_tree().create_timer(1.2).timeout
	if GameManager.state == GameManager.GameState.CALL_IN_PROGRESS:
		_is_busy = false
		populate_options(GameManager.current_monster)

func populate_options(monster: MonsterData) -> void:
	_clear_all()

	var unlocked_slots: int = GameManager.dialogue_slots
	var available_pool: Array[DialogueOption] = []
	if monster and not monster.dialogue_pool.is_empty():
		available_pool.append_array(monster.dialogue_pool)
	available_pool.append_array(GameManager.global_actions_pool)
	available_pool.shuffle()
	
	if available_pool.is_empty():
		return

	_current_options.clear()
	var count: int = mini(unlocked_slots, available_pool.size())
	for i in range(count):
		_current_options.append(available_pool[i])

	# 1. Create Active Unlocked Option Buttons
	for i in range(_current_options.size()):
		var option: DialogueOption = _current_options[i]
		var btn := _create_option_button(i + 1, option)
		options_container.add_child(btn)

	# 2. Create Dashed Locked Slot Placeholders (as seen in sketch: "типо доп варианты")
	for j in range(count, MAX_POSSIBLE_SLOTS):
		var locked_box := _create_locked_slot_button(j + 1)
		options_container.add_child(locked_box)

	# Hover first option by default to fill the effects preview
	if not _current_options.is_empty():
		option_hovered.emit(_current_options[0])

func _create_option_button(index: int, option: DialogueOption) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 42)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 10
	hbox.offset_right = -10
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hbox)

	var text_lbl := Label.new()
	text_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var display_title := option.option_name if not option.option_name.is_empty() else option.text
	text_lbl.text = "%d. %s" % [index, display_title]
	text_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(text_lbl)

	# Calculate odds for the right side: e.g. "🟢 50% ↑ | 🔴 50% ↓"
	var odds_str := option.get_short_odds_string()
	if odds_str.is_empty():
		odds_str = _calculate_odds_string(option)
	var odds_lbl := Label.new()
	odds_lbl.text = odds_str
	odds_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.4))
	odds_lbl.add_theme_font_size_override("font_size", 12)
	odds_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(odds_lbl)

	btn.pressed.connect(_on_option_button_pressed.bind(option))
	btn.mouse_entered.connect(func(): option_hovered.emit(option))
	btn.focus_entered.connect(func(): option_hovered.emit(option))

	return btn

func _create_locked_slot_button(index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 36)
	panel.modulate = Color(0.65, 0.65, 0.7, 0.55)

	var lbl := Label.new()
	lbl.text = "[... %d. Доп. вариант: купите шпаргалку в магазине ...]" % index
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)
	panel.add_child(lbl)

	return panel

func _calculate_odds_string(option: DialogueOption) -> String:
	var pos_weight: float = 0.0
	var neg_weight: float = 0.0

	for outcome in option.possible_outcomes:
		if outcome.persuasion_delta >= 0.0:
			pos_weight += outcome.base_weight
		else:
			neg_weight += outcome.base_weight

	var total := pos_weight + neg_weight
	if total <= 0.0:
		return "50% ↑ 50% ↓"

	var pos_percent := int(round(pos_weight / total * 100.0))
	var neg_percent := 100 - pos_percent
	return "%d%% ↑  %d%% ↓" % [pos_percent, neg_percent]

func _on_option_button_pressed(option: DialogueOption) -> void:
	if _is_busy or GameManager.state != GameManager.GameState.CALL_IN_PROGRESS:
		return

	_is_busy = true
	for child in options_container.get_children():
		if child is Button:
			child.disabled = true

	Events.dialogue_chosen.emit(option)
	GameManager.process_dialogue_choice(option)

func _clear_all() -> void:
	for child in options_container.get_children():
		child.queue_free()
