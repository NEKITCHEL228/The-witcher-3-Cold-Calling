extends Control

# Состояние звонка и экономики
var money: int = 9999
var money_gain: int = 67
var trust_level: float = 45.0 # 0 to 100
var call_seconds: int = 24
var active_client_index: int = 0
var tween: Tween

# Список клиентов для демонстрации
var clients = [
	{
		"name": "Леший «Древний»",
		"org": "ООО «Брокилонская Чаща»",
		"offer": "Кредит 'Эко-Берлога' (150 000 ¤)",
		"quote": "«Я триста лет сплю на мху. Зачем мне ваша плавающая ставка?!»",
		"avatar_icon": "(🌲 ಠ_ಠ 🌲)",
		"color": Color(0.18, 0.32, 0.22)
	},
	{
		"name": "Прибожек Ивасик",
		"org": "Болота Велена, Курган #3",
		"offer": "Микрозайм до получки (500 ¤)",
		"quote": "«А если я не отдам, вы мне опять голос в кувшин спрячете?!»",
		"avatar_icon": "(🐸 ^‿^ 🐸)",
		"color": Color(0.2, 0.35, 0.45)
	},
	{
		"name": "Катакан Граф фон Дракулеску",
		"org": "Новиградский Склеп & Co",
		"offer": "Премиум-Ипотека на Мавзолей (2 000 000 ¤)",
		"quote": "«Ваш банк работает ночью? Днем я в гробу видел ваших коллекторов!»",
		"avatar_icon": "(🦇 ◥(ºwº)◤ 🦇)",
		"color": Color(0.4, 0.15, 0.22)
	},
	{
		"name": "Кладбищенская Баба",
		"org": "Погост у Залипья",
		"offer": "Потребительский кредит на котел",
		"quote": "«Супчику наваристого хотите? А проценты костями принимаете?»",
		"avatar_icon": "(👵 ♨_♨ 👵)",
		"color": Color(0.35, 0.28, 0.2)
	}
]

# Набор реплик для текущего раунда
var dialogue_pool = [
	{
		"text": "«Понимаю ваше недоверие, но ставка зафиксирована сургучом Банка Вивальди!»",
		"chance": 75,
		"gain": 18,
		"fail_loss": 12,
		"tag": "[Аргумент]"
	},
	{
		"text": "«*Применить знак Аксий*: Вы о-о-очень хотите подписать договор рефинансирования...»",
		"chance": 60,
		"gain": 28,
		"fail_loss": 25,
		"tag": "[Аксий]"
	},
	{
		"text": "«Только сегодня: при оформлении карты — серебряный купон на чеканную монету!»",
		"chance": 85,
		"gain": 12,
		"fail_loss": 8,
		"tag": "[Скидка]"
	},
	{
		"text": "«Если откажетесь — ваш адрес в лесу передадут ведьмакам Школы Кота.»",
		"chance": 40,
		"gain": 35,
		"fail_loss": 35,
		"tag": "[Давление]"
	},
	{
		"text": "«Между прочим, Лютик уже взял у нас автокредит на новую лютню и очень доволен!»",
		"chance": 65,
		"gain": 20,
		"fail_loss": 15,
		"tag": "[Авторитет]"
	}
]

# Баффы
var active_buffs = [
	{
		"name": "☕ Остывший кофе из корчмы",
		"desc": "+10% к скорости диалога, руки меньше дрожат."
	},
	{
		"name": "🔮 Аксий (I ранг)",
		"desc": "Шанс гипноза в диалогах повышен на 15%."
	},
	{
		"name": "📜 Скрипт Вивальди",
		"desc": "При первом срыве клиент не сбрасывает трубку."
	},
	{
		"name": "👔 Рубаха клерка +1",
		"desc": "Доверие монстров растет на +5% быстрее."
	}
]

# Инвентарь
var inventory_items = [
	{"name": "Сургучная печать", "count": 3, "desc": "+25% к шансу успеха следующего юридического довода."},
	{"name": "Зелье 'Черная чайка'", "count": 1, "desc": "Снимает панику оператора, сбрасывает стресс."},
	{"name": "Купон на 50 флоренов", "count": 2, "desc": "Мгновенно дает +15% доверия клиенту."},
	{"name": "Трубка краснолюда", "count": 1, "desc": "Пауза в разговоре не наказывается штрафом."},
	{"name": "Черный список Велена", "count": 1, "desc": "Позволяет скипнуть безнадежного монстра без штрафа."},
	{"name": "Договор мелким шрифтом", "count": 4, "desc": "+50% к финальной комиссии при успешной сделке."}
]

@onready var label_money = %LabelMoney
@onready var label_money_gain = %LabelMoneyGain
@onready var trust_progress = %TrustProgress
@onready var label_trust_value = %LabelTrustValue
@onready var label_client_name = %LabelClientName
@onready var label_client_org = %LabelClientOrg
@onready var label_client_offer = %LabelClientOffer
@onready var label_monster_speech = %LabelMonsterSpeech
@onready var monster_icon = %MonsterIcon
@onready var label_call_timer = %LabelCallTimer
@onready var monster_avatar_rect = %MonsterAvatarRect
@onready var dialogue_container = %DialogueContainer
@onready var buffs_container = %BuffsContainer
@onready var inventory_grid = %InventoryGrid
@onready var log_label = %LogLabel
@onready var timer = $CallTimer
@onready var btn_next_client = %BtnNextClient

func _ready():
	_update_ui()
	_populate_dialogues()
	_populate_buffs()
	_populate_inventory()
	
	if timer:
		timer.timeout.connect(_on_timer_tick)
		timer.start()
		
	if btn_next_client:
		btn_next_client.pressed.connect(_next_client)

func _on_timer_tick():
	call_seconds += 1
	var mins: int = int(call_seconds / 60.0)
	var secs: int = call_seconds % 60
	if label_call_timer:
		label_call_timer.text = "%02d:%02d" % [mins, secs]

func _update_ui():
	if label_money:
		label_money.text = "%d ¤" % money
	if label_money_gain:
		label_money_gain.text = "+%d ¤" % money_gain
		
	# Плавная анимация доверия
	if trust_progress:
		if tween and tween.is_valid():
			tween.kill()
		tween = create_tween()
		tween.tween_property(trust_progress, "value", trust_level, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if label_trust_value:
		label_trust_value.text = "%d%%" % int(trust_level)
		if trust_level < 30.0:
			label_trust_value.modulate = Color(1.0, 0.35, 0.35)
		elif trust_level < 70.0:
			label_trust_value.modulate = Color(1.0, 0.85, 0.3)
		else:
			label_trust_value.modulate = Color(0.4, 1.0, 0.5)

	var current_client = clients[active_client_index]
	if label_client_name:
		label_client_name.text = current_client["name"]
	if label_client_org:
		label_client_org.text = current_client["org"]
	if label_client_offer:
		label_client_offer.text = "Цель: " + current_client["offer"]
	if label_monster_speech:
		label_monster_speech.text = current_client["quote"]
	if monster_icon:
		monster_icon.text = current_client.get("avatar_icon", "(🌲 ಠ_ಠ 🌲)")
	if monster_avatar_rect:
		monster_avatar_rect.color = current_client["color"]

func _populate_dialogues():
	if not dialogue_container:
		return
		
	# Очищаем только активные кнопки
	for child in dialogue_container.get_children():
		if child.is_in_group("dynamic_dialogue_btn"):
			child.queue_free()
			
	for i in range(mini(3, dialogue_pool.size())):
		var d = dialogue_pool[i]
		var btn = Button.new()
		btn.add_to_group("dynamic_dialogue_btn")
		btn.custom_minimum_size = Vector2(0, 52)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.focus_mode = Control.FOCUS_NONE
		
		# Формируем читаемый двухстрочный текст с процентами
		var chance_text = " [ Шанс: %d%% ↑  |  Риск: %d%% ↓ ]" % [d["chance"], 100 - d["chance"]]
		btn.text = "%s %s\n%s" % [d["tag"], d["text"], chance_text]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		var index = i
		btn.pressed.connect(func(): _on_dialogue_selected(index))
		
		dialogue_container.add_child(btn)
		dialogue_container.move_child(btn, i)

func _on_dialogue_selected(index: int):
	var d = dialogue_pool[index]
	var roll = randi_range(1, 100)
	var success = roll <= d["chance"]
	
	if success:
		trust_level = clamp(trust_level + d["gain"], 0.0, 100.0)
		money += money_gain
		_set_log("✔ УСПЕХ: " + d["tag"] + " Клиент заинтересовался! Доверие +" + str(d["gain"]) + "%")
	else:
		trust_level = clamp(trust_level - d["fail_loss"], 0.0, 100.0)
		_set_log("✖ СРЫВ: Клиент заподозрил обман! Доверие -" + str(d["fail_loss"]) + "%")
		
	_update_ui()
	
	if trust_level >= 100.0:
		_on_deal_closed()
	elif trust_level <= 0.0:
		_on_call_failed()
	else:
		dialogue_pool.shuffle()
		_populate_dialogues()

func _on_deal_closed():
	_set_log("🎉 СДЕЛКА ЗАКЛЮЧЕНА! Кредит оформлен! Награда: +500 ¤")
	money += 500
	_next_client()

func _on_call_failed():
	_set_log("📞 ГУДКИ... Клиент бросил трубку! Штраф от Банка Вивальди: -100 ¤")
	money = maxi(0, money - 100)
	_next_client()

func _next_client():
	trust_level = 40.0
	call_seconds = 0
	active_client_index = (active_client_index + 1) % clients.size()
	_update_ui()
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
		panel.custom_minimum_size = Vector2(0, 36)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var lbl = Label.new()
		lbl.text = " " + b["name"]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(lbl)
		
		buffs_container.add_child(panel)

func _populate_inventory():
	if not inventory_grid:
		return
	for child in inventory_grid.get_children():
		child.queue_free()
		
	for item in inventory_items:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(70, 70)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.text = "%s\n(x%d)" % [item["name"].substr(0, 10), item["count"]]
		btn.tooltip_text = item["name"] + "\n" + item["desc"] + "\n\n[Кликните, чтобы применить]"
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(func(): _use_item(item))
		inventory_grid.add_child(btn)

func _use_item(item: Dictionary):
	if item["count"] > 0:
		item["count"] -= 1
		trust_level = clamp(trust_level + 15.0, 0.0, 100.0)
		_set_log("✔ Предмет: " + item["name"] + " использован! Доверие +15%")
		_update_ui()
		_populate_inventory()
