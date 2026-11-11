class_name DialogueOption extends Resource

## A choice presented to Geralt during a call.

@export var option_id: String = ""
@export var option_name: String = "Маневр переговоров"
@export_multiline var text: String = "Предложить оформить займ под залог трофеев"

## Strategy / Approach type (e.g. "bureaucracy", "intimidation", "flattery", "greed_appeal", "folklore")
## Interacts with MonsterTrait vulnerabilities/resistances.
@export var approach_tag: String = "bureaucracy"

## Domain / Category (e.g. "Доверие", "Размер займа", "Ходы", "Инвентарь", "Квота")
@export var domain_category: String = "Переговоры"

## Optional UI badge (e.g., "[Риск: Высокий]", "[Убеждение]", "[Палка о двух концах]")
@export var risk_label: String = ""

## List of possible outcomes. The CallResolver picks one based on weighted probability.
@export var possible_outcomes: Array[DialogueOutcome] = []

## Required shop item id or unlock condition (empty if available by default)
@export var required_unlock_id: String = ""

## Returns a formatted odds string with colored icons and percentages
func get_short_odds_string() -> String:
	if possible_outcomes.is_empty():
		return ""
	
	var total_weight: float = 0.0
	for out in possible_outcomes:
		total_weight += out.base_weight
	if total_weight <= 0.0:
		total_weight = 1.0

	var badges: Array[String] = []
	for out in possible_outcomes:
		var pct := int(round(out.base_weight / total_weight * 100.0))
		if not out.short_badge.is_empty():
			badges.append(out.short_badge.replace("{pct}", str(pct) + "%"))
		else:
			if out.is_instant_success:
				badges.append("💎 " + str(pct) + "% ★")
			elif out.persuasion_delta > 0.0:
				badges.append("🟢 " + str(pct) + "% ↑")
			elif out.loan_amount_multiplier > 1.0:
				badges.append("🟡 " + str(pct) + "% 💰")
			elif out.turns_delta > 0:
				badges.append("⏳ " + str(pct) + "% ⏱")
			else:
				badges.append("🔴 " + str(pct) + "% ↓")

	return " | ".join(badges)
