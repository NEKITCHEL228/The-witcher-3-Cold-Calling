extends Control
class_name DialogueBox

## Displays dialogue options dynamically (2, 3, or 4 options) and handles player input.

@onready var options_container: VBoxContainer = $OptionsVBox
@onready var prompt_label: Label = $PromptLabel

var _current_options: Array[DialogueOption] = []
var _is_busy: bool = false

func _ready() -> void:
	Events.call_started.connect(_on_call_started)
	Events.call_finished.connect(_on_call_finished)
	Events.outcome_resolved.connect(_on_outcome_resolved)

func _on_call_started(monster: MonsterData) -> void:
	_is_busy = false
	prompt_label.text = "Выберите ответ Геральта:"
	populate_options(monster)

func _on_call_finished(_is_success: bool, _loan_amount: int) -> void:
	_clear_buttons()
	prompt_label.text = "Звонок завершён."

func _on_outcome_resolved(_outcome: DialogueOutcome, monster_reaction: String) -> void:
	# Show reaction and re-populate options for next turn if call still in progress
	prompt_label.text = "Монстр: " + monster_reaction
	await get_tree().create_timer(1.2).timeout
	if GameManager.state == GameManager.GameState.CALL_IN_PROGRESS:
		_is_busy = false
		populate_options(GameManager.current_monster)

func populate_options(monster: MonsterData) -> void:
	_clear_buttons()
	if monster == null or monster.dialogue_pool.is_empty():
		return

	# Determine how many options to show based on GameManager.dialogue_slots
	var slots: int = GameManager.dialogue_slots
	var available_pool: Array[DialogueOption] = monster.dialogue_pool.duplicate()
	available_pool.shuffle()
	
	_current_options.clear()
	var count: int = mini(slots, available_pool.size())
	for i in range(count):
		_current_options.append(available_pool[i])

	# Create UI buttons
	for i in range(_current_options.size()):
		var option: DialogueOption = _current_options[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 48)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		var prefix: String = ""
		if not option.risk_label.is_empty():
			prefix = option.risk_label + " "
		btn.text = str(i + 1) + ". " + prefix + option.text
		
		btn.pressed.connect(_on_option_button_pressed.bind(option))
		options_container.add_child(btn)

func _on_option_button_pressed(option: DialogueOption) -> void:
	if _is_busy or GameManager.state != GameManager.GameState.CALL_IN_PROGRESS:
		return

	_is_busy = true
	# Disable all buttons
	for child in options_container.get_children():
		if child is Button:
			child.disabled = true

	Events.dialogue_chosen.emit(option)
	GameManager.process_dialogue_choice(option)

func _clear_buttons() -> void:
	for child in options_container.get_children():
		child.queue_free()

