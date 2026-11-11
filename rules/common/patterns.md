# Architectural Patterns

The project relies strictly on three primary architectural pillars:

## 1. Data-Driven Design (Custom Resources)
All content is treated as data, not code:
- **`MonsterData`**: Contains monster name, portrait path, description, voice sfx, loan requested, base difficulty, and assigned traits (`Array[MonsterTrait]`).
- **`MonsterTrait`**: Defines susceptibility/resistance tags (e.g. `TraitTag.GREEDY`, `TraitTag.AGGRESSIVE`), modifying probabilities for dialogue choices with corresponding tags.
- **`DialogueOption`**: Text prompt (e.g. "Предложить льготный период под залог печени утопца"), required tags, base weight, and a list of possible outcomes (`Array[DialogueOutcome]`).
- **`DialogueOutcome`**: Weight/probability, persuasion delta (-100 to +100), money delta, reaction text, special effects (e.g. instant hang up, buff trigger).
- **`ShopItem`**: Item name, cost, icon, description, and passive effect type (e.g. luck boost, extra dialogue options, quota protection).

## 2. EventBus Pattern (`Events.gd`)
- All cross-scene communication flows through the global singleton `Events.gd`.
- Scenes and UI components do NOT hold hard references to each other.
- Example:
  - Dialogue button click -> `Events.dialogue_chosen.emit(option)`
  - `CallResolver` computes outcome -> `Events.persuasion_changed.emit(new_val, delta)`
  - UI `PersuasionMeter` listens to `persuasion_changed` and animates its slider.

## 3. Game State Machine (`GameManager.gd`)
- Manages the core roguelike progression:
  ```
  START_DAY ➔ CALL_IN_PROGRESS ➔ CALL_FINISHED ➔ (Repeat Calls) ➔ DAY_SUMMARY ➔ SHOP ➔ NEXT_DAY (or GAME_OVER / VICTORY)
  ```
- Tracks player persistent state across days:
  - `current_day`, `max_days`
  - `calls_remaining_today`, `max_calls_per_day`
  - `current_quota_progress`, `target_quota`
  - `player_cash` (money for shop)
  - `player_luck` (luck modifier for dialogue rolls)
  - `dialogue_slots` (number of choices generated, default 2, expandable to 3 or 4)
  - `inventory` (purchased `ShopItem` resources)

