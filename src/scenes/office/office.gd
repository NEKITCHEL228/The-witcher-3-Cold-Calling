extends Control

## Main game loop / Office scene where Geralt makes cold calls.

@onready var stat_bar: StatBar = $StatBar
@onready var persuasion_meter: PersuasionMeter = $PersuasionMeter
@onready var dialogue_box: DialogueBox = $DialogueBox

@onready var monster_name_label: Label = $CallArea/MonsterCard/MonsterNameLabel
@onready var monster_desc_label: Label = $CallArea/MonsterCard/MonsterDescLabel
@onready var loan_request_label: Label = $CallArea/MonsterCard/LoanRequestLabel
@onready var monster_traits_container: HBoxContainer = $CallArea/MonsterCard/TraitsContainer
@onready var monster_speech_label: Label = $CallArea/MonsterCard/SpeechBubble/SpeechLabel

@onready var dial_button: Button = $CallArea/ActionButtons/DialButton
@onready var call_status_label: Label = $CallArea/CallStatusLabel

func _ready() -> void:
	Events.call_started.connect(_on_call_started)
	Events.call_finished.connect(_on_call_finished)
	Events.outcome_resolved.connect(_on_outcome_resolved)
	
	dial_button.pressed.connect(_on_dial_pressed)
	
	# Start first call if calls remaining
	if GameManager.state == GameManager.GameState.START_DAY:
		_prepare_desk_for_call()

func _prepare_desk_for_call() -> void:
	dial_button.visible = true
	dial_button.text = "Сделать звонок (" + str(GameManager.calls_remaining_today) + " осталось)"
	call_status_label.text = "Телефон свободен. Нажмите 'Сделать звонок', чтобы набрать клиента."
	monster_name_label.text = "—"
	monster_desc_label.text = "Ожидание соединения..."
	loan_request_label.text = ""
	monster_speech_label.text = "..."
	_clear_traits()

func _on_dial_pressed() -> void:
	dial_button.visible = false
	call_status_label.text = "Идет набор номера... *гудки*"
	GameManager.start_next_call()

func _on_call_started(monster: MonsterData) -> void:
	call_status_label.text = "Соединение установлено! Клиент на линии."
	monster_name_label.text = monster.monster_name
	monster_desc_label.text = monster.description
	loan_request_label.text = "Запрашиваемый кредит: " + str(monster.base_loan_amount) + " орен"
	
	# Display opening greeting line
	if not monster.opening_lines.is_empty():
		monster_speech_label.text = monster.opening_lines.pick_random()
	else:
		monster_speech_label.text = "Слушаю вас..."

	_display_traits(monster)

func _on_outcome_resolved(outcome: DialogueOutcome, monster_reaction: String) -> void:
	monster_speech_label.text = monster_reaction
	if not outcome.side_effect_description.is_empty():
		call_status_label.text = "Побочный эффект: " + outcome.side_effect_description
	loan_request_label.text = "Текущая сумма кредита: " + str(GameManager.current_call_loan_amount) + " орен"

func _on_call_finished(is_success: bool, loan_amount: int) -> void:
	if is_success:
		call_status_label.text = "УСПЕХ! Кредит на %d орен успешно выдан!" % loan_amount
		if GameManager.current_monster and not GameManager.current_monster.success_lines.is_empty():
			monster_speech_label.text = GameManager.current_monster.success_lines.pick_random()
	else:
		call_status_label.text = "СБРОС! Клиент отказался от кредита и повесил трубку."
		if GameManager.current_monster and not GameManager.current_monster.rejection_lines.is_empty():
			monster_speech_label.text = GameManager.current_monster.rejection_lines.pick_random()

	await get_tree().create_timer(1.8).timeout
	
	if GameManager.calls_remaining_today > 0:
		_prepare_desk_for_call()
	else:
		call_status_label.text = "Звонки на сегодня завершены. Подводим итоги смены..."
		await get_tree().create_timer(1.2).timeout
		GameManager.end_day()

func _display_traits(monster: MonsterData) -> void:
	_clear_traits()
	for m_trait in monster.traits:
		if m_trait == null:
			continue
		var badge := Button.new()
		badge.text = "[" + m_trait.trait_name + "]"
		badge.tooltip_text = m_trait.description + "\nСлабость к: " + ", ".join(m_trait.weak_against_approaches)
		badge.disabled = true
		monster_traits_container.add_child(badge)

func _clear_traits() -> void:
	for child in monster_traits_container.get_children():
		child.queue_free()
