class_name MonsterTrait extends Resource

## Defines behavioral tendencies and negotiation vulnerabilities of a monster.

@export var id: String = ""
@export var trait_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D

## Category tag for affinity checks (e.g., "greedy", "aggressive", "skeptical", "prideful", "desperate")
@export var tag: String = ""

## Multiplier for dialogue approaches matching this trait.
## > 1.0 means more susceptible (positive outcomes more likely)
## < 1.0 means resistant (negative outcomes more likely)
@export var affinity_multiplier: float = 1.3

## Specific approach tags that this trait is weak against (e.g., ["bureaucracy", "folklore_flattery", "urgency"])
@export var weak_against_approaches: Array[String] = []

## Specific approach tags that provoke resistance (e.g., ["intimidation", "lowballing", "condescending"])
@export var strong_against_approaches: Array[String] = []

