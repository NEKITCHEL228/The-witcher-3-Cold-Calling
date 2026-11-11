class_name DialogueOutcome extends Resource

## Represents one probabilistic result of choosing a dialogue option.

@export var outcome_title: String = "Успешный маневр"
@export_multiline var monster_reaction_text: String = ""

## Shift on persuasion meter (-1.0 to +1.0)
## Positive tilts toward credit agreement (+1.0 max)
## Negative tilts toward angry refusal (-1.0 max)
@export_range(-1.0, 1.0, 0.05) var persuasion_delta: float = 0.25

## Multiplier on the base loan amount (e.g., 1.2 = +20% loan size, 0.8 = discounted loan)
@export var loan_amount_multiplier: float = 1.0

## Flat monetary bonus/penalty to Geralt's commission or loan sum
@export var flat_money_delta: int = 0

## Base relative weight for RNG dice roll before luck & trait modifiers
@export_range(1.0, 100.0, 1.0) var base_weight: float = 50.0

## Special modifiers
@export var is_instant_hangup: bool = false
@export var is_instant_success: bool = false

## Side effect text (Jam theme: Побочный эффект / Палка о двух концах)
@export var side_effect_description: String = ""

