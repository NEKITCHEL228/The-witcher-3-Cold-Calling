extends Control

## Shop scene: purchasing upgrades, coffee, and perks with commission money.

@onready var cash_label: Label = $Header/CashLabel
@onready var items_container: VBoxContainer = $ScrollContainer/ItemsVBox
@onready var start_day_button: Button = $Footer/StartDayButton

var available_items: Array[ShopItem] = []

func _ready() -> void:
	start_day_button.pressed.connect(_on_start_day_pressed)
	Events.player_balance_changed.connect(_on_balance_changed)
	_load_shop_items()
	_refresh_display()

func _load_shop_items() -> void:
	var item_paths := [
		"res://src/data/items/coffee.tres",
		"res://src/data/items/script_cheat_sheet.tres",
		"res://src/data/items/aviator_glasses.tres",
		"res://src/data/items/sales_mastery_course.tres"
	]
	available_items.clear()
	for path in item_paths:
		if ResourceLoader.exists(path):
			var it := load(path) as ShopItem
			if it != null:
				available_items.append(it)

func _refresh_display() -> void:
	cash_label.text = "Баланс Геральта: %d орен" % GameManager.player_cash
	_clear_items()

	for item in available_items:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, 90)

		var hbox := HBoxContainer.new()
		hbox.theme_override_constants.separation = 16
		panel.add_child(hbox)

		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)

		var title := Label.new()
		title.text = item.item_name + " — " + str(item.cost) + " орен"
		title.theme_override_font_sizes.font_size = 16
		title.modulate = Color.GOLD
		info_vbox.add_child(title)

		var desc := Label.new()
		desc.text = item.description
		desc.theme_override_font_sizes.font_size = 13
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_vbox.add_child(desc)

		if not item.side_effect_text.is_empty():
			var jam_note := Label.new()
			jam_note.text = "[" + item.jam_theme_tag + "]: " + item.side_effect_text
			jam_note.theme_override_font_sizes.font_size = 11
			jam_note.modulate = Color(0.9, 0.6, 0.4)
			info_vbox.add_child(jam_note)

		var buy_btn := Button.new()
		buy_btn.custom_minimum_size = Vector2(130, 40)
		buy_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		buy_btn.text = "Купить"
		buy_btn.disabled = GameManager.player_cash < item.cost
		buy_btn.pressed.connect(_on_buy_item_pressed.bind(item))
		hbox.add_child(buy_btn)

		items_container.add_child(panel)

func _on_buy_item_pressed(item: ShopItem) -> void:
	if GameManager.buy_item(item):
		_refresh_display()

func _on_balance_changed(_new_balance: int, _delta: int) -> void:
	_refresh_display()

func _on_start_day_pressed() -> void:
	GameManager.advance_to_next_day()

func _clear_items() -> void:
	for child in items_container.get_children():
		child.queue_free()

