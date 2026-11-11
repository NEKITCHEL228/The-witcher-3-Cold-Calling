class_name DialogueOption extends Resource

## A choice presented to Geralt during a call.

@export var option_id: String = ""
@export_multiline var text: String = "Предложить оформить займ под залог трофеев"

## Strategy / Approach type (e.g. "bureaucracy", "intimidation", "flattery", "greed_appeal", "folklore")
## Interacts with MonsterTrait vulnerabilities/resistances.
@export var approach_tag: String = "bureaucracy"

## Optional UI badge (e.g., "[Риск: Высокий]", "[Убеждение]", "[Палка о двух концах]")
@export var risk_label: String = ""

## List of possible outcomes. The CallResolver picks one based on weighted probability.
@export var possible_outcomes: Array[DialogueOutcome] = []

## Required shop item id or unlock condition (empty if available by default)
@export var required_unlock_id: String = ""

