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

## Dirt Removal (Mask Reveal)

We render two images:
- Dirty layer: `res://assets/levels/demo/dirty.png` (top)
- Clean layer: `res://assets/levels/demo/clean.png` (underneath)

The clean layer is revealed by a mask that is “painted” by the moving `WaterContact` point.

### Mask Model
- The mask is an 8-bit grayscale image the same resolution as the level art (one pixel per texel).
- Each mask pixel has **256 grades**: `0..255`
  - `0` = fully dirty (clean image fully hidden)
  - `255` = fully clean (clean image fully visible)

Mask initialization:
- Start the level with all pixels at `0` (fully dirty everywhere).

### Water Strength
Define `water_strength` as:
- `mask_grades_per_second` (how many mask grades are removed/added per second at the center of the spray)

For the demo behavior:
- Remove `1` grade every millisecond ⇒ `water_strength = 1000 mask_grades_per_second`

Per-frame application (for each affected mask pixel):
- `mask[p] = clamp(mask[p] + water_strength * delta_seconds * influence(p), 0, 255)`

Where:
- `influence(p)` is `1.0` at the contact center and falls off toward the edge of the spray radius.
- Spray radius comes from `PowerWasher.contact_radius_px` (e.g. `20px`).

Recommended influence function (simple, smooth):
- `t = clamp(distance(p, contact_center) / radius, 0, 1)`
- `influence = (1.0 - t) ^ 2`

### Rendering (Dirty Over Clean Using the Mask)
Conceptually, final color per pixel:
- `a = mask / 255.0`
- `final = mix(dirty, clean, a)`

Implementation options in Godot:
- Two `Sprite2D` nodes (`Clean` below, `Dirty` above) and a shader/material on the dirty sprite that samples:
  - `dirty_texture`
  - `clean_texture`
  - `mask_texture`
  and outputs the blend described above.

### Completion Condition
The level is complete when at least **95%** of the pixels are “clean enough”.

Definition:
- A pixel is considered “visible clean” when `mask[p] >= 255` (or a slightly lower threshold like `>= 230` if we want softer completion later).
- Completion is reached when:
  - `clean_visible_pixels / total_pixels >= 0.95`

No UI is shown yet; completion can be a boolean state (e.g. emit a signal or log for now).
