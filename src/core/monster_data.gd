class_name MonsterData extends Resource

## Full profile and dialogue pool for a monster customer.

@export var id: String = ""
@export var monster_name: String = "Гуль"
@export_multiline var description: String = "Обычный кладбищенский падальщик. Нуждается в средствах на покупку свежих погребальных курганов."
@export var portrait: Texture2D

## Monetary value of credit they seek (counts towards daily quota if approved)
@export var base_loan_amount: int = 15000

## Difficulty rating from 0.0 (very easy to persuade) to 1.0 (extremely stubborn)
@export_range(0.0, 1.0, 0.05) var difficulty: float = 0.3

## Psychological and behavioral traits
@export var traits: Array[MonsterTrait] = []

## Lines spoken when call connects
@export var opening_lines: Array[String] = [
	"Алё? Кто это? Если вы опять из ритуального бюро, я уже сыт!",
	"Слушаю вас... Говорите быстрее, солнце садится."
]

## Lines spoken when credit is signed (+100% persuasion)
@export var success_lines: Array[String] = [
	"Уговорили! Куда ставить кровавый отпечаток лапы?",
	"Под 45% годовых? Отличная сделка, оформляйте!"
]

## Lines spoken when call is terminated or hangs up (-100% persuasion)
@export var rejection_lines: Array[String] = [
	"Тьфу на вас! Я лучше в Вызиме в ломбард схожу! *Бросил трубку*",
	"Зараза, хватит мне названивать! *Короткие гудки*"
]

## Pool of dialogue choices available when talking to this monster
@export var dialogue_pool: Array[DialogueOption] = []

