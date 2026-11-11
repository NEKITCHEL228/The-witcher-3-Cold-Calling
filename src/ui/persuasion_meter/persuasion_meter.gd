extends Control
class_name PersuasionMeter

## Persuasion meter representing the monster's inclination toward taking a loan:
## +100% (Top): Склонен к кредиту (Сделка закрыта!)
##  +50% (Top): Склоняется в сторону кредита
##    0% (Center): Нейтральный
##  -50% (Bottom): Склоняется отказаться от кредита
## -100% (Bottom): Отказался от кредита (Сброс трубки!)

@onready var progress_bar: VSlider = $MeterContainer/VSlider
@onready var status_label: Label = $StatusLabel
@onready var percentage_label: Label = $PercentageLabel
@onready var delta_label: Label = $DeltaLabel

var _current_tween: Tween

func _ready() -> void:
	Events.persuasion_changed.connect(_on_persuasion_changed)
	if progress_bar:
		# Range from -1.0 to +1.0 with step 0.01
		progress_bar.min_value = -1.0
		progress_bar.max_value = 1.0
		progress_bar.step = 0.01
		progress_bar.value = 0.0
		progress_bar.editable = false
	update_display(0.0, 0.0)

func _on_persuasion_changed(new_value: float, delta: float) -> void:
	animate_to(new_value, delta)

func animate_to(target_value: float, delta: float) -> void:
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()

	_current_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_current_tween.tween_property(progress_bar, "value", target_value, 0.4)
	_current_tween.parallel().tween_callback(func(): update_display(target_value, delta))
	
	# Show floating delta feedback
	if delta != 0.0 and delta_label:
		delta_label.text = ("+" if delta > 0 else "") + str(int(delta * 100)) + "%"
		delta_label.modulate = Color.GREEN if delta > 0 else Color.RED
		delta_label.visible = true
		
		var delta_tween := create_tween()
		delta_tween.tween_property(delta_label, "modulate:a", 0.0, 1.2).set_delay(0.5)
		delta_tween.tween_callback(func(): delta_label.visible = false)

func update_display(value: float, _delta: float) -> void:
	var percent_int := int(value * 100)
	if percentage_label:
		percentage_label.text = ("+" if percent_int > 0 else "") + str(percent_int) + "%"

	if status_label:
		if value >= 0.95:
			status_label.text = "Кредит оформлен (+100%)"
			status_label.modulate = Color(0.2, 0.9, 0.3)
		elif value >= 0.45:
			status_label.text = "Склоняется к кредиту (+50%)"
			status_label.modulate = Color(0.6, 0.9, 0.2)
		elif value <= -0.95:
			status_label.text = "Сброс трубки! (-100%)"
			status_label.modulate = Color(0.9, 0.2, 0.2)
		elif value <= -0.45:
			status_label.text = "Склоняется отказаться (-50%)"
			status_label.modulate = Color(0.9, 0.5, 0.2)
		else:
			status_label.text = "Нейтральный (0%)"
			status_label.modulate = Color(0.9, 0.9, 0.9)
