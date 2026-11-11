extends Control

## Main menu screen for "The Witcher 3: Cold Calling".

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var credits_button: Button = $VBoxContainer/CreditsButton
@onready var exit_button: Button = $VBoxContainer/ExitButton

@onready var credits_popup: ConfirmationDialog = $CreditsPopup
@onready var settings_popup: ConfirmationDialog = $SettingsPopup

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_play_pressed() -> void:
	GameManager.start_new_game()

func _on_settings_pressed() -> void:
	if settings_popup:
		settings_popup.popup_centered()

func _on_credits_pressed() -> void:
	if credits_popup:
		credits_popup.popup_centered()

func _on_exit_pressed() -> void:
	get_tree().quit()

