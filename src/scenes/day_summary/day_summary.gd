extends Control

## Day summary screen: checks quota completion, reports earnings, allows going to shop.

@onready var day_title_label: Label = $Panel/VBox/TitleLabel
@onready var quota_result_label: Label = $Panel/VBox/QuotaResultLabel
@onready var earnings_label: Label = $Panel/VBox/EarningsLabel
@onready var days_left_label: Label = $Panel/VBox/DaysLeftLabel
@onready var verdict_label: Label = $Panel/VBox/VerdictLabel

@onready var shop_button: Button = $Panel/VBox/ButtonsHBox/ShopButton
@onready var next_day_button: Button = $Panel/VBox/ButtonsHBox/NextDayButton

func _ready() -> void:
	shop_button.pressed.connect(_on_shop_pressed)
	next_day_button.pressed.connect(_on_next_day_pressed)
	_display_summary()

func _display_summary() -> void:
	var day := GameManager.current_day
	var current := GameManager.current_quota_progress
	var target := GameManager.target_quota
	var days_left := GameManager.MAX_DAYS - day
	var quota_met := QuotaManager.is_quota_satisfied(current, day)

	day_title_label.text = "ИТОГИ СМЕНЫ — ДЕНЬ %d" % day
	quota_result_label.text = "Выдано кредитов: %d орен из %d плана" % [current, target]
	earnings_label.text = "Заработано комиссионных: +%d орен (Баланс: %d)" % [
		QuotaManager.calculate_commission(current),
		GameManager.player_cash
	]
	days_left_label.text = "Дней до конца испытательного срока: %d" % days_left

	if quota_met:
		verdict_label.text = "ПЛАН ВЫПОЛНЕН! Руководство довольно."
		verdict_label.modulate = Color(0.3, 0.9, 0.3)
	else:
		verdict_label.text = "ПЛАН НЕ ВЫПОЛНЕН! Начальник оставил выговор."
		verdict_label.modulate = Color(0.95, 0.4, 0.3)

	if day >= GameManager.MAX_DAYS and not quota_met:
		next_day_button.text = "Получить расчёт (Увольнение)"

func _on_shop_pressed() -> void:
	GameManager.advance_to_shop()

func _on_next_day_pressed() -> void:
	if GameManager.current_day >= GameManager.MAX_DAYS and not QuotaManager.is_quota_satisfied(GameManager.current_quota_progress, GameManager.current_day):
		GameManager.trigger_game_over("Не выполнен недельный план кредитования!")
	else:
		GameManager.advance_to_next_day()

