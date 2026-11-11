# The Witcher 3: Cold Calling — AI Agent Guidelines & Architecture

Welcome to the project repository for **"The Witcher 3: Cold Calling" (Дикая неОхота)**.
This project adheres to the **ECC (Engineering / Coding Context)** harness framework inspired by `affaan-m/ecc`.

## 1. Quick Project Summary
- **Genre**: Narrative Roguelike / Cold Calling Simulator
- **Engine**: Godot 4.x (GDScript)
- **Jam**: "Дикая неОхота" (Wild Non-Hunt)
  - Core Rule: Hero does anything with monsters *except* fighting (18+ strictly prohibited).
  - Jam Themes: Побочный эффект, Не тот герой, Учитесь у своих врагов, Палка о двух концах, Проклятие знаний.
- **Premise**: Geralt took a cubicle desk job at a predatory payday loan call-center. He must pitch loans to famous Witcher universe monsters over the phone to meet his weekly quota and survive corporate layoffs.

## 2. Rule Hierarchy & Directory Map
All agents working on this project must consult the modular rules under `rules/`:

```
rules/
├── common/
│   ├── agents.md          # Agent behavior, workflow, verification loops
│   ├── coding-style.md    # GDScript formatting, typing, naming
│   ├── patterns.md        # Data-Driven, EventBus, State Machine
│   ├── security.md        # Asset safety, secret isolation, no 18+ content
│   └── gamejam.md         # Game jam constraints, tone, 5 themes integration
└── godot/
    ├── gdscript-rules.md  # Godot 4 idioms, typing, signal wiring
    ├── data-driven.md     # Custom Resource definitions and .tres standards
    └── ui-ux.md           # Persuasion meter (-100%..+100%), dynamic dialogues
```

## 3. Core Architectural Pillars
1. **Data-Driven (Custom Resources in `src/core/`)**:
   - `MonsterData`: Monster specifications, portraits, traits, dialogue pools.
   - `MonsterTrait`: Resistances and affinities towards dialogue styles.
   - `DialogueOption` & `DialogueOutcome`: Branching choices with probabilistic outcomes based on luck and monster traits.
   - `ShopItem`: Upgrades, consumables (e.g. coffee), perks, extra dialogue slots.
2. **EventBus (`src/autoload/events.gd`)**:
   - Central observer hub for signals (`call_started`, `persuasion_changed`, `call_finished`, `day_ended`, `quota_updated`).
3. **State Machine / Loop (`src/autoload/game_manager.gd`)**:
   - Manages days, calls per day, quota tracking, player balance, and scenes flow.

## 4. Key Gameplay Mechanics
- **Persuasion Meter**: -100% (Refused/Hang-up) to +100% (Deal closed/Success), with 0% as neutral center.
- **Roll & Resolution (`CallResolver`)**: Weighted outcome calculation factoring player luck and monster traits.
- **Progression Loop**: Office Calls ➔ Day Summary (Quota check) ➔ Shop (Spend money on buffs/slots) ➔ Next Day.

