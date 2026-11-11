extends Control

## Game Over / Victory screen.

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var desc_label: Label = $Panel/VBox/DescLabel
@onready var restart_button: Button = $Panel/VBox/HBox/RestartButton
@onready var menu_button: Button = $Panel/VBox/HBox/MenuButton

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	if GameManager.state == GameManager.GameState.VICTORY:
		title_label.text = "ПОБЕДА: ЛУЧШИЙ СОТРУДНИК МЕСЯЦА!"
		title_label.modulate = Color(0.3, 0.9, 0.3)
		desc_label.text = "Геральт успешно закрыл все квоты и навязал кредиты всей нечисти Новиграда и Велена.\nВам выдана корпоративная грамота и новая гарнитура!"
	else:
		title_label.text = "ВЫ УВОЛЕНЫ!"
		title_label.modulate = Color(0.95, 0.3, 0.3)
		desc_label.text = "Начальство колл-центра посчитало ваши показатели неприемлемыми.\nГеральт снова вынужден бродить по трактам без гроша в кармане..."

func _on_restart_pressed() -> void:
	GameManager.start_new_game()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/main_menu/main_menu.tscn")

