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
