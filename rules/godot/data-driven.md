# Data-Driven Design & Resource Management

## 1. Custom Resource Standard
- Every data type must be defined with `class_name <ClassName> extends Resource` in `src/core/`.
- Use descriptive exports with default sensible values and hints:
  ```gdscript
  class_name MonsterData extends Resource

  @export var id: String = ""
  @export var display_name: String = ""
  @export_multiline var description: String = ""
  @export var portrait: Texture2D
  @export var loan_amount_requested: int = 10000
  @export_range(0.0, 1.0) var base_difficulty: float = 0.5
  @export var traits: Array[MonsterTrait] = []
  @export var initial_lines: Array[String] = []
  @export var dialogue_pool: Array[DialogueOption] = []
  ```

## 2. Resource Directory Hierarchy
- Place actual resource instances (`.tres`) in `src/data/`:
  - `src/data/monsters/`: Monster profiles (`ghoul.tres`, `noonwraith.tres`, `drowner.tres`).
  - `src/data/traits/`: Trait modifiers (`greedy.tres`, `aggressive.tres`, `skeptical.tres`).
  - `src/data/dialogues/`: Modular dialogue packages.
  - `src/data/items/`: Shop inventory items (`coffee.tres`, `script_cheat_sheet.tres`).

## 3. Dynamic Dialogue & Outcome Probability
- `DialogueOption` holds an array of `DialogueOutcome`.
- Each outcome defines a weight, delta persuasion, delta loan money, and reaction message.
- Calculation formula in `CallResolver`:
  `EffectiveWeight = BaseWeight * TraitAffinityMultiplier * (1.0 + PlayerLuck)`
- This ensures high customizability and instant balancing in the Godot inspector.

