extends Control
class_name PersuasionMeter

## Persuasion meter matching the game design sketch:
## Top: "Заебись" (+100% - Credit deal closed!)
## Track: Pointer indicator smoothly moving vertically
## Bottom: "Хуёво" (-100% - Hangup / Refusal!)

@onready var slider: VSlider = $VBox/MeterTrack/VSlider
@onready var pointer_icon: Label = $VBox/MeterTrack/PointerLabel
@onready var percentage_label: Label = $VBox/PercentageLabel
@onready var delta_label: Label = $DeltaLabel

var _current_tween: Tween

func _ready() -> void:
	Events.persuasion_changed.connect(_on_persuasion_changed)
	if slider:
		slider.min_value = -1.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.value = 0.0
		slider.editable = false
	update_display(0.0)

func _on_persuasion_changed(new_value: float, delta: float) -> void:
	animate_to(new_value, delta)

func animate_to(target_value: float, delta: float) -> void:
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()

	_current_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_current_tween.tween_property(slider, "value", target_value, 0.45)
	_current_tween.parallel().tween_callback(func(): update_display(target_value))

	# Show floating delta label (+25% / -30%)
	if delta != 0.0 and delta_label:
		delta_label.text = ("+" if delta > 0 else "") + str(int(delta * 100)) + "%"
		delta_label.modulate = Color(0.2, 1.0, 0.4) if delta > 0 else Color(1.0, 0.25, 0.25)
		delta_label.visible = true
		delta_label.position.y = 120.0
		
		var delta_tween := create_tween().set_parallel(true)
		delta_tween.tween_property(delta_label, "position:y", 90.0, 0.9)
		delta_tween.tween_property(delta_label, "modulate:a", 0.0, 0.9).set_delay(0.3)
		delta_tween.chain().tween_callback(func(): delta_label.visible = false)

func update_display(value: float) -> void:
	var percent_int := int(value * 100)
	if percentage_label:
		percentage_label.text = ("+" if percent_int > 0 else "") + str(percent_int) + "%"
		if percent_int > 40:
			percentage_label.modulate = Color(0.3, 1.0, 0.4)
		elif percent_int < -40:
			percentage_label.modulate = Color(1.0, 0.3, 0.3)
		else:
			percentage_label.modulate = Color(0.9, 0.9, 0.9)
