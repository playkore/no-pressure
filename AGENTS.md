# No Pressure (Godot 4.5) — Agent Notes

2D **mobile** powerwashing game (portrait). Player controls the power washer with their **finger** to spray and clean dirt off targets (car, building, items, etc.). UI reference: coin counter + progress bar at top, pause/hint buttons, power/energy button bottom-left.

## Goals
- Fast “satisfying cleaning” loop: spray → dirt clears → progress/coins update → level complete.
- Mobile-first UX: single-finger control, large buttons, low friction.
- Performance-first for mid-tier phones: steady frame time, low overdraw, minimal allocations.

## Tech Constraints (Mobile)
- Prefer the **mobile renderer** defaults (already set in `project.godot`).
- Avoid heavy full-screen shaders/overdraw; keep particle counts modest; pool nodes for spray FX/decals.
- Keep per-frame CPU work minimal; avoid per-pixel CPU loops during gameplay.

## Project Structure (Preferred)
- `scenes/` for `.tscn` (e.g. `Main.tscn`, `LevelCar.tscn`, `UIHud.tscn`)
- `scripts/` for `.gd` (match scene names when possible, e.g. `LevelCar.gd`)
- `assets/` for textures/audio/fonts (already present)
- `autoload/` for global singletons (keep small: save data, audio, analytics stubs)
- `shaders/` for `.gdshader` (only when needed)

## Conventions
- Godot 4.5 + GDScript 2.0; prefer typed GDScript for public APIs and exported vars.
- Naming:
  - Scenes/nodes/classes: `PascalCase`
  - Variables/functions: `snake_case`
  - Signals: `snake_case`
- Prefer composition over inheritance; keep scenes small and reusable.
- Use `@export` for tunables (spray radius/strength, dirt opacity, reward values).

## Input (Touch First)
- Primary interaction is finger drag:
  - Track `InputEventScreenTouch` and `InputEventScreenDrag`.
  - Treat mouse as a dev fallback (support both where easy).
- Keep input handling centralized (e.g. `WasherController.gd`) and expose clean events like `spray_started(pos)`, `spray_moved(pos)`, `spray_ended()`.

## “Cleaning” Implementation Expectations
- Dirt should be a separate layer/mask so it can be revealed/erased smoothly.
- Track level completion by **percentage cleaned** (0–100%), and feed it into the top progress bar.
- Prefer GPU-friendly approaches (mask textures/viewport painting) over CPU pixel processing during play.

## Editing Rules (Repo Hygiene)
- Avoid hand-editing `.godot/`, `*.import`, and generated files unless explicitly necessary.
- Keep resources deterministic: don’t reorder serialized `.tscn/.tres` content without need.
- Add new assets under `assets/` and reference via `res://` paths.

## Run/Debug
- Open the folder in the Godot 4.5 editor and run the main scene.
- When adding a new entry scene, set it in Project Settings → Application → Run.

## Validation (Headless)
- Syntax/import check (CI-friendly):
  - `/Applications/Godot.app/Contents/MacOS/Godot --headless --check-only --quit --path <project path>`
