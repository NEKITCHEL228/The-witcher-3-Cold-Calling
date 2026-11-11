# UI/UX & Game Feel Standards

## 1. Persuasion Meter (Шкала склонения)
- The core visual metric of the call:
  - Range: `-1.0` (-100%) to `+1.0` (+100%).
  - Midpoint: `0.0` (0% Neutral).
  - Positive zones: `+0.5` (+50% Leaning towards credit), `+1.0` (+100% Contract Approved!).
  - Negative zones: `-0.5` (-50% Leaning to refuse), `-1.0` (-100% Monster hangs up in rage).
- Visual feedback:
  - Indicator / pointer slides smoothly (tween or lerp) with bouncy audio cues.
  - Color gradient: Red (refusal) ➔ Yellow (neutral) ➔ Green (agreement).
  - Floating numbers: Show `+15%` or `-20%` floating text over the meter upon choice resolution.

## 2. Dynamic Dialogue Box
- Dynamically populates buttons inside a `VBoxContainer` based on available `DialogueOption` choices.
- Number of visible options can scale from 2 (baseline) to 3 or 4 (unlocked via shop items/perks).
- Each button displays the dialogue text and optional risk/reward indicators (e.g., "[Риск: Высокий] Потребовать залог").
- On hover, tooltip or status text explains potential effects or trait synergies.

## 3. Responsive Layout
- Designed for standard 16:9 / desktop resolutions (e.g. 1920x1080 or 1280x720) with `canvas_items` stretch mode and `expand` aspect.
- UI elements (stat bar, phone, dialogue box, monster portrait) must remain anchored properly and readable.

