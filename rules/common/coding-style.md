# Coding Style & Architecture Boundaries

## 1. General Principles
- **Readability Over Cleverness**: Code must be understandable to any game designer reading the script in Godot.
- **Single Responsibility**: Separate presentation (UI scenes), state (`GameManager`), resolution mechanics (`CallResolver`), and data definitions (`Resource` classes).
- **File Size Guardrails**: Keep scripts focused. If a script exceeds 250 lines, evaluate if logic should be moved to a helper, system, or custom resource.

## 2. Naming Conventions (GDScript standard)
- **Files & Folders**: `snake_case` (e.g. `call_resolver.gd`, `persuasion_meter.tscn`, `monster_data.gd`).
- **Classes**: `PascalCase` using `class_name` (e.g. `class_name MonsterData extends Resource`).
- **Functions & Variables**: `snake_case` (e.g. `resolve_dialogue_choice()`, `current_persuasion`).
- **Constants & Enums**: `SCREAMING_SNAKE_CASE` (e.g. `MAX_CALLS_PER_DAY`, `enum OutcomeType { PERSUASION, MONEY, SPECIAL }`).
- **Private Variables / Helpers**: Leading underscore `_` (e.g. `var _is_calling: bool = false`, `func _on_option_pressed()`).
- **Signals**: Past tense or event descriptor in `snake_case` (e.g. `signal persuasion_changed(new_value, delta)`).

## 3. Strong Static Typing
- Always declare types for variables, parameters, and function return values:
  ```gdscript
  var current_balance: int = 0
  func calculate_outcome(option: DialogueOption, monster: MonsterData) -> DialogueOutcome:
  ```
- Use type-casting and assertions when needed, preventing runtime `null` errors.

