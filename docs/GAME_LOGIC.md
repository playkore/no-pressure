# Game Logic (WIP)

This document describes the game logic at a high level. Add new sections here as features land.

## Power Washer Placement + Water Stream

### Terms
- `viewport_rect`: visible screen rect in pixels (origin at top-left).
- `target_point`: point on the level the player is trying to wash (the red dot in the reference image). This is driven by the finger position.
- `nozzle_point`: point where the water stream starts (the end of the gun/nozzle).
- `stream_segment`: line from `nozzle_point` to `target_point` (green line in the reference image).

### Input → Target Point
1. Read the active touch position (or mouse position for desktop testing).
2. Clamp it to the viewport so it always stays on-screen:
   - `target_point = clamp_to_rect(input_pos, viewport_rect)`

Result:
- The player can point at any pixel on screen, so the water stream can “reach every point of the screen”.

### Contact Point Definition (`WaterContact`)
The washer scene defines a `WaterContact` point (an `Area2D` with a circular collision shape). This point represents where the water hits the level (the red dot).

We want the `WaterContact` point to be authorable in the scene editor, so its local position is never modified at runtime.

### Translation-Only Placement (Finger → `WaterContact`)
The washer never rotates and never scales. We only translate the entire washer so that `WaterContact` sits under the finger.

Placement each frame while spraying:
1. Compute the clamped `target_point` from the finger.
2. Shift the washer by the delta between the current contact point and the target:
   - `delta = target_point - water_contact.global_position`
   - `washer.global_position += delta`

Result:
- `water_contact.global_position == target_point`, so the water “reaches” every point on screen.

### Nozzle Point Definition
The washer scene also defines a `Nozzle` marker point. Later, the water stream will be drawn from `Nozzle.global_position` to `WaterContact.global_position`.

### Notes
- This model does not enforce “keep the washer on the right edge”. If we want that constraint again later, we can apply an additional post-step that pushes the washer right after aligning `WaterContact`.

### Drawing the Water Stream (Later)
The stream will be drawn from `Nozzle.global_position` to `WaterContact.global_position`.

This stays correct even when the washer sprite is partially or fully off-screen.
