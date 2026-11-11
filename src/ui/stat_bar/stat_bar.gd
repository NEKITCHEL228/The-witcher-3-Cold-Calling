extends Control
class_name StatBar

## Top status bar displaying Day, Calls remaining, Player Money, and Quota progress.

@onready var day_label: Label = $HBox/DayLabel
@onready var calls_label: Label = $HBox/CallsLabel
@onready var cash_label: Label = $HBox/CashLabel
@onready var quota_label: Label = $HBox/QuotaLabel

func _ready() -> void:
	Events.day_started.connect(_on_day_started)
	Events.call_started.connect(_on_call_started)
	Events.player_balance_changed.connect(_on_balance_changed)
	Events.quota_updated.connect(_on_quota_updated)
	refresh_all()

func refresh_all() -> void:
	if day_label:
		day_label.text = "День: %d / %d" % [GameManager.current_day, GameManager.MAX_DAYS]
	if calls_label:
		calls_label.text = "Звонков осталось: %d" % GameManager.calls_remaining_today
	if cash_label:
		cash_label.text = "Кошелек: %d орен" % GameManager.player_cash
	if quota_label:
		quota_label.text = "План: %d / %d" % [GameManager.current_quota_progress, GameManager.target_quota]

func _on_day_started(day_num: int, _calls: int) -> void:
	if day_label:
		day_label.text = "День: %d / %d" % [day_num, GameManager.MAX_DAYS]
	refresh_all()

func _on_call_started(_monster: MonsterData) -> void:
	if calls_label:
		calls_label.text = "Звонков осталось: %d" % GameManager.calls_remaining_today

func _on_balance_changed(new_balance: int, _delta: int) -> void:
	if cash_label:
		cash_label.text = "Кошелек: %d орен" % new_balance

func _on_quota_updated(current_amount: int, target_amount: int) -> void:
	if quota_label:
		quota_label.text = "План: %d / %d" % [current_amount, target_amount]
		if current_amount >= target_amount:
			quota_label.modulate = Color.GREEN
		else:
			quota_label.modulate = Color.WHITE

