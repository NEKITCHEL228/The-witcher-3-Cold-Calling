class_name DialogueOutcome extends Resource

## Represents one probabilistic result of choosing a dialogue option.

@export var outcome_title: String = "Успешный маневр"
@export_multiline var monster_reaction_text: String = ""

## Shift on persuasion meter (-1.0 to +1.0)
## Positive tilts toward credit agreement (+1.0 max)
## Negative tilts toward angry refusal (-1.0 max)
@export_range(-1.0, 1.0, 0.05) var persuasion_delta: float = 0.25

## If true, changes persuasion by half of the remaining/filled meter (Option 1)
@export var is_half_scale_shift: bool = false

## Multiplier on the base loan amount (e.g., 1.2 = +20% loan size, 0.8 = discounted loan)
@export var loan_amount_multiplier: float = 1.0

## Flat monetary bonus/penalty to Geralt's commission or loan sum
@export var flat_money_delta: int = 0

## Base relative weight for RNG dice roll before luck & trait modifiers
@export_range(1.0, 100.0, 1.0) var base_weight: float = 50.0

## Special terminal modifiers
@export var is_instant_hangup: bool = false
@export var is_instant_success: bool = false

## Call turns modifier (+1, +2 or -1 turns left in current call)
@export var turns_delta: int = 0

## Quota modifier for today (-0.15 = -15% quota, +0.10 = +10% quota)
@export var quota_percent_delta: float = 0.0

## Day calls limit modifier (+1 or -1 calls today)
@export var day_calls_delta: int = 0

## Item manipulation effects (Option 4)
@export var duplicate_random_item: bool = false
@export var remove_random_item: bool = false

## Multiplier on item effects for the next turn (Option 9: 2.0 = +100%, 0.5 = -50%)
@export var next_turn_item_multiplier: float = 1.0

## Short badge label for button display (e.g., "🟢 50% ↑", "🟡 34% 💰")
@export var short_badge: String = ""

## Side effect text (Jam theme: Побочный эффект / Палка о двух концах)
@export var side_effect_description: String = ""

## Returns exact, concrete mechanical description of what this outcome does
func get_concrete_effect_text() -> String:
	if is_instant_success:
		return "Мгновенное согласие на кредит (100% закрытие сделки)!"
	if is_instant_hangup:
		return "Клиент в ярости бросает трубку (провал)!"

	var parts: Array[String] = []

	# 1. Шкала доверия
	if is_half_scale_shift:
		if persuasion_delta >= 0.0:
			parts.append("Шкала доверия увеличится на +50% от шкалы")
		else:
			parts.append("Шкала доверия уменьшится на -50% от шкалы")
	elif persuasion_delta != 0.0:
		if persuasion_delta > 0.0:
			parts.append("Шкала доверия увеличится на +%d%%" % int(persuasion_delta * 100))
		else:
			parts.append("Шкала доверия уменьшится на -%d%%" % int(abs(persuasion_delta) * 100))

	# 2. Кредит / Деньги
	if loan_amount_multiplier != 1.0:
		if loan_amount_multiplier > 1.0:
			parts.append("Сумма кредита увеличится на +%d%%" % int(round((loan_amount_multiplier - 1.0) * 100)))
		else:
			parts.append("Сумма кредита уменьшится на -%d%%" % int(round((1.0 - loan_amount_multiplier) * 100)))
	if flat_money_delta != 0:
		parts.append("%+d орен к займу" % flat_money_delta)

	# 3. Ходы звонка
	if turns_delta != 0:
		if turns_delta > 0:
			parts.append("+%d доп. хода к звонку" % turns_delta)
		else:
			parts.append("-%d ход звонка" % abs(turns_delta))

	# 4. Инвентарь
	if duplicate_random_item:
		parts.append("Случайный предмет из инвентаря дублируется")
	if remove_random_item:
		parts.append("Случайный предмет из инвентаря теряется")
	if next_turn_item_multiplier != 1.0:
		if next_turn_item_multiplier > 1.0:
			parts.append("Все предметы усилятся на +%d%% на следующем ходу" % int((next_turn_item_multiplier - 1.0) * 100))
		else:
			parts.append("Все предметы ослабнут на -%d%% на следующем ходу" % int((1.0 - next_turn_item_multiplier) * 100))

	# 5. Квота и звонки
	if quota_percent_delta != 0.0:
		if quota_percent_delta < 0.0:
			parts.append("Дневная квота снизится на %d%%" % int(abs(quota_percent_delta) * 100))
		else:
			parts.append("Дневная квота вырастет на +%d%%" % int(quota_percent_delta * 100))
	if day_calls_delta != 0:
		if day_calls_delta > 0:
			parts.append("+%d доп. звонок на сегодня" % day_calls_delta)
		else:
			parts.append("-%d звонок на сегодня" % abs(day_calls_delta))

	if parts.is_empty():
		return "Никаких изменений (статус-кво)"

	return ", ".join(parts)
