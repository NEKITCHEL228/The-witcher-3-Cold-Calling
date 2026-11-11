# Godot 4 & GDScript Rules

## 1. Engine Version & Features
- Target engine: **Godot 4.x** (Forward+ / Compatibility / D3D12 / Vulkan).
- Use GDScript 2.0 features: `@export`, `@export_range`, `@export_group`, `@onready`, static typing, and annotations.
- Never use Godot 3 syntax (no `export(int)`, no `yield`, no `connect("signal", self, "method")`). Use `signal.connect(callable)` and `await`.

## 2. Autoload Singletons
- Keep autoloads clean and decoupled:
  - `Events`: Only holds signal declarations and utility signal forwarders. No complex game state.
  - `GameManager`: Holds current run state, loop logic, player inventory, persistent stats, and progression.
  - `AudioManager`: Global sound effects (phone rings, clicks, monster roars, ambient office buzz) and BGM.

## 3. Node & Resource Lifecycle
- Remember: `Resource` objects are ref-counted (`RefCounted`). Duplicate mutable resources when instancing if they should not share state across sessions.
- Free nodes with `queue_free()`, never `free()` directly during signal callbacks.
- Connect signals safely using callable:
  ```gdscript
  Events.persuasion_changed.connect(_on_persuasion_changed)
  ```
- Always disconnect or rely on automatic cleanup when nodes are freed.

