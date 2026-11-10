extends Control

# Экономика и сессия Геральта в Банке Вивальди
var total_orens: int = 9999
var earned_orens: int = 67 # Заработано Геральтом за сессию, меняется динамически!
var trust_level: float = 45.0 # 0.0 до 100.0
var call_seconds: int = 24
var active_client_index: int = 0
var tween_arrow: Tween

# Клиенты для звонков
var clients = [
	{
		"name": "Леший «Древний»",
		"org": "ООО «Брокилонская Чаща»",
		"offer": "Кредит 'Эко-Берлога' (150 000 Orens)",
		"quote": "«Я триста лет сплю на мху. Зачем мне ваша плавающая ставка?!»",
		"fee": 67
	},
	{
		"name": "Прибожек Ивасик",
		"org": "Болота Велена, Курган #3",
		"offer": "Микрозайм до получки (500 Orens)",
		"quote": "«А если я не отдам, вы мне опять голос в кувшин спрячете?!»",
		"fee": 45
	},
	{
		"name": "Катакан Граф фон Дракулеску",
		"org": "Новиградский Склеп & Co",
		"offer": "Премиум-Ипотека на Мавзолей (2 000 000 Orens)",
		"quote": "«Ваш банк работает ночью? Днем я в гробу видел ваших коллекторов!»",
		"fee": 120
	}
]

# Пул реплик в средневековом стиле
var dialogue_pool = [
	{
		"type": "Убеждение",
		"text": "Успокойся, мы найдем твоих детенышей и снизим процент.",
		"chance": 67,
		"gain": 22,
		"fail_loss": 15,
		"reward": 25
	},
	{
		"type": "Угроза",
		"text": "Если не замолчишь, я приду с серебряным мечом и приставом.",
		"chance": 25,
		"gain": 35,
		"fail_loss": 30,
		"reward": 50
	},
	{
		"type": "Торг",
		"text": "Сколько тебе заплатить, чтобы ты подписал договор сегодня?",
		"chance": 50,
		"gain": 18,
		"fail_loss": 10,
		"reward": 15
	},
	{
		"type": "Аксий",
		"text": "*Знак Аксий*: Ты о-о-очень хочешь оформить кредитную карту...",
		"chance": 60,
		"gain": 28,
		"fail_loss": 25,
		"reward": 35
	},
	{
		"type": "Юмор",
		"text": "Лютик уже рефинансировал у нас лютню и пока еще жив.",
		"chance": 75,
		"gain": 15,
		"fail_loss": 12,
		"reward": 20
	}
]

# Баффы (Окно 5)
var active_buffs = [
	{"name": "☕ Остывший кофе из корчмы", "desc": "+10% к скорости диалога, руки меньше дрожат."},
	{"name": "🔮 Аксий (I ранг)", "desc": "Шанс гипноза в диалогах повышен на 15%."},
	{"name": "📜 Скрипт Вивальди", "desc": "При первом срыве клиент не сбрасывает трубку."},
	{"name": "👔 Рубаха клерка +1", "desc": "Доверие монстров растет на +5% быстрее."}
]

# Инвентарь (Окно 6)
var inventory_items = [
	{"name": "Сургучная печать", "count": 3, "desc": "+25% к шансу успеха следующего юридического довода."},
	{"name": "Зелье 'Черная чайка'", "count": 1, "desc": "Снимает панику оператора, сбрасывает стресс."},
	{"name": "Купон на 50 флоренов", "count": 2, "desc": "Мгновенно дает +15% доверия клиенту."},
	{"name": "Трубка краснолюда", "count": 1, "desc": "Пауза в разговоре не наказывается штрафом."},
	{"name": "Черный список Велена", "count": 1, "desc": "Позволяет скипнуть безнадежного монстра без штрафа."},
	{"name": "Договор мелким шрифтом", "count": 4, "desc": "+50% к финальной комиссии при успешной сделке."}
]

@onready var label_total_orens = %LabelTotalOrens
@onready var label_session_orens = %LabelSessionOrens
@onready var label_trust_percent = %LabelTrustPercent
@onready var meter_arrow = %MeterArrow
@onready var meter_track = %MeterTrack
@onready var label_client_name = %LabelClientName
@onready var label_client_meta = %LabelClientMeta
@onready var label_monster_speech = %LabelMonsterSpeech
@onready var label_call_timer = %LabelCallTimer
@onready var dialogue_vbox = %DialogueVBox
@onready var buffs_container = %BuffsContainer
@onready var inventory_grid = %InventoryGrid
@onready var log_label = %LogLabel
@onready var call_timer = $CallTimer
@onready var btn_skip_client = %BtnSkipClient

func _ready():
	_update_money_ui()
	_update_client_ui()
	_update_trust_meter(false)
	_populate_dialogues()
	_populate_buffs()
	_populate_inventory()
	
	if call_timer:
		call_timer.timeout.connect(_on_timer_tick)
		call_timer.start()
		
	if btn_skip_client:
		btn_skip_client.pressed.connect(_next_client)
		
	_capture_test_screenshot()

func _capture_test_screenshot():
	await get_tree().create_timer(0.5).timeout
	var vp = get_viewport()
	if vp:
		var img = vp.get_texture().get_image()
		if img:
			img.save_png("res://screenshot_witcher_ui.png")

func _on_timer_tick():
	call_seconds += 1
	var mins: int = int(call_seconds / 60.0)
	var secs: int = call_seconds % 60
	if label_call_timer:
		label_call_timer.text = "%02d:%02d" % [mins, secs]

func _update_money_ui():
	if label_total_orens:
		label_total_orens.text = "%d Orens" % total_orens
	if label_session_orens:
		if earned_orens >= 0:
			label_session_orens.text = "+%d Orens" % earned_orens
			label_session_orens.modulate = Color(0.95, 0.88, 0.7)
		else:
			label_session_orens.text = "%d Orens" % earned_orens
			label_session_orens.modulate = Color(1.0, 0.4, 0.4)

func _update_client_ui():
	var cur = clients[active_client_index]
	if label_client_name:
		label_client_name.text = cur["name"]
	if label_client_meta:
		label_client_meta.text = "%s  •  Цель: %s" % [cur["org"], cur["offer"]]
	if label_monster_speech:
		label_monster_speech.text = cur["quote"]

func _update_trust_meter(animate: bool = true):
	if label_trust_percent:
		label_trust_percent.text = "%d%%" % int(trust_level)
		if trust_level < 30.0:
			label_trust_percent.modulate = Color(1.0, 0.35, 0.35)
		elif trust_level < 70.0:
			label_trust_percent.modulate = Color(0.95, 0.85, 0.45)
		else:
			label_trust_percent.modulate = Color(0.4, 1.0, 0.5)
			
	if meter_arrow and meter_track:
		var track_height = meter_track.size.y
		if track_height <= 0:
			track_height = 462.0
		# Красный низ: ~80% высоты, Зеленый верх: ~8% высоты
		var top_y = track_height * 0.08
		var bottom_y = track_height * 0.82
		var target_y = lerp(bottom_y, top_y, trust_level / 100.0)
		
		if animate:
			if tween_arrow and tween_arrow.is_valid():
				tween_arrow.kill()
			tween_arrow = create_tween()
			tween_arrow.tween_property(meter_arrow, "position:y", target_y, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			meter_arrow.position.y = target_y

func _populate_dialogues():
	if not dialogue_vbox:
		return
		
	for child in dialogue_vbox.get_children():
		if child.is_in_group("dialogue_btn"):
			child.queue_free()
			
	for i in range(mini(3, dialogue_pool.size())):
		var d = dialogue_pool[i]
		var btn = Button.new()
		btn.add_to_group("dialogue_btn")
		btn.custom_minimum_size = Vector2(0, 40)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.focus_mode = Control.FOCUS_NONE
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		var chance_success = d["chance"]
		var chance_fail = 100 - chance_success
		btn.text = " [%s] %s   (%d%% ↑  %d%% ↓)" % [d["type"], d["text"], chance_success, chance_fail]
		
		# Стиль реплики под референс
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.18, 0.16, 0.14, 0.95)
		normal_style.border_width_left = 2
		normal_style.border_width_top = 2
		normal_style.border_width_right = 2
		normal_style.border_width_bottom = 2
		normal_style.border_color = Color(0.55, 0.45, 0.32, 0.9)
		normal_style.corner_radius_top_left = 4
		normal_style.corner_radius_top_right = 4
		normal_style.corner_radius_bottom_right = 4
		normal_style.corner_radius_bottom_left = 4
		normal_style.content_margin_left = 12
		normal_style.content_margin_right = 12
		
		var hover_style = normal_style.duplicate()
		hover_style.border_color = Color(0.9, 0.75, 0.45, 1.0)
		hover_style.bg_color = Color(0.26, 0.22, 0.18, 0.98)
		
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("pressed", hover_style)
		btn.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8))
		btn.add_theme_font_size_override("font_size", 12)
		
		var idx = i
		btn.pressed.connect(func(): _on_dialogue_selected(idx))
		dialogue_vbox.add_child(btn)
		dialogue_vbox.move_child(btn, i)

func _on_dialogue_selected(index: int):
	var d = dialogue_pool[index]
	var roll = randi_range(1, 100)
	var success = roll <= d["chance"]
	
	if success:
		trust_level = clamp(trust_level + d["gain"], 0.0, 100.0)
		var gain = d["reward"]
		earned_orens += gain
		total_orens += gain
		_set_log("✔ [%s]: Клиент заинтересовался! Доверие +%d%% | Заработано: +%d Orens" % [d["type"], d["gain"], gain])
	else:
		trust_level = clamp(trust_level - d["fail_loss"], 0.0, 100.0)
		_set_log("✖ [%s]: Клиент раздражен! Доверие -%d%%" % [d["type"], d["fail_loss"]])
		
	_update_money_ui()
	_update_trust_meter(true)
	
	if trust_level >= 100.0:
		_on_deal_closed()
	elif trust_level <= 0.0:
		_on_call_failed()
	else:
		dialogue_pool.shuffle()
		_populate_dialogues()

func _on_deal_closed():
	var bonus = 500
	earned_orens += bonus
	total_orens += bonus
	_set_log("🎉 СДЕЛКА ЗАКЛЮЧЕНА! Кредит оформлен! Награда Геральту: +%d Orens" % bonus)
	_update_money_ui()
	_next_client()

func _on_call_failed():
	var penalty = 100
	earned_orens -= penalty
	total_orens = maxi(0, total_orens - penalty)
	_set_log("📞 ГУДКИ... Клиент бросил трубку! Штраф Банка Вивальди: -%d Orens" % penalty)
	_update_money_ui()
	_next_client()

func _next_client():
	trust_level = 45.0
	call_seconds = 0
	active_client_index = (active_client_index + 1) % clients.size()
	_update_client_ui()
	_update_trust_meter(true)
	dialogue_pool.shuffle()
	_populate_dialogues()

func _set_log(msg: String):
	if log_label:
		log_label.text = msg

func _populate_buffs():
	if not buffs_container:
		return
	for child in buffs_container.get_children():
		child.queue_free()
		
	for b in active_buffs:
		var panel = PanelContainer.new()
		panel.tooltip_text = b["desc"]
		panel.custom_minimum_size = Vector2(0, 32)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.14, 0.12, 0.1, 0.9)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.45, 0.38, 0.28, 0.8)
		sb.corner_radius_top_left = 3
		sb.corner_radius_top_right = 3
		sb.corner_radius_bottom_right = 3
		sb.corner_radius_bottom_left = 3
		sb.content_margin_left = 8
		panel.add_theme_stylebox_override("panel", sb)
		
		var lbl = Label.new()
		lbl.text = b["name"]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
		panel.add_child(lbl)
		
		buffs_container.add_child(panel)

func _populate_inventory():
	if not inventory_grid:
		return
	for child in inventory_grid.get_children():
		child.queue_free()
		
	for item in inventory_items:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(65, 65)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.text = "%s\n(x%d)" % [item["name"].substr(0, 9), item["count"]]
		btn.tooltip_text = item["name"] + "\n" + item["desc"] + "\n\n[Кликните, чтобы применить]"
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.12, 0.1, 0.09, 0.9)
		btn_style.border_width_left = 1
		btn_style.border_width_top = 1
		btn_style.border_width_right = 1
		btn_style.border_width_bottom = 1
		btn_style.border_color = Color(0.45, 0.38, 0.28, 0.8)
		btn_style.corner_radius_top_left = 4
		btn_style.corner_radius_top_right = 4
		btn_style.corner_radius_bottom_right = 4
		btn_style.corner_radius_bottom_left = 4
		
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(func(): _use_item(item))
		inventory_grid.add_child(btn)

func _use_item(item: Dictionary):
	if item["count"] > 0:
		item["count"] -= 1
		trust_level = clamp(trust_level + 15.0, 0.0, 100.0)
		earned_orens += 10
		total_orens += 10
		_set_log("✔ Предмет '%s' использован! Доверие +15%%, +10 Orens" % item["name"])
		_update_money_ui()
		_update_trust_meter(true)
		_populate_inventory()
