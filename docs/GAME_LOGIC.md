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

### Progress Mask (Scoring Area)
We also have a separate black/white image:
- `res://assets/levels/demo/mask.png`

This image does **not** define initial cleanliness. It defines which pixels count toward progress/score:
- White pixels (`>= 0.5`) = counted toward progress
- Black pixels (`< 0.5`) = ignored for progress

You can still clean pixels outside this region; they just don’t add progress.

### Mask Model
- The mask is an 8-bit grayscale image the same resolution as the level art (one pixel per texel).
- Each mask pixel has **256 grades**: `0..255`
  - `0` = fully dirty (clean image fully hidden)
  - `255` = fully clean (clean image fully visible)

Mask initialization:
- Start the level with all pixels at `0` (fully dirty everywhere), regardless of `mask.png`.

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
- Only pixels inside the progress mask participate:
  - `progress_total = count(mask.png is white)`
  - `progress_clean = count(mask[p] >= 255 AND mask.png is white)`
- A pixel is considered “visible clean” when `mask[p] >= 255` (or a slightly lower threshold like `>= 230` if we want softer completion later).
- Completion is reached when `progress_clean / progress_total >= 0.95`.

No UI is shown yet; completion can be a boolean state (e.g. emit a signal or log for now).

## Water Stream + Particles (VFX, No Textures)

For the first iteration, we avoid textures entirely and draw everything with lines and circles.

We visualize spraying with two layers:
1. A continuous **water stream** from the washer nozzle to the water contact point.
2. **Impact dots** emitted at the contact point and moving away from it.

### Required Scene Points
The power washer scene provides:
- `Nozzle` (`Marker2D`): where the stream originates.
- `WaterContact` (`Area2D`): where the stream hits the level (kept under the finger).

All VFX are driven by:
- `nozzle_pos = Nozzle.global_position`
- `contact_pos = WaterContact.global_position`

### Stream Rendering (Lines)
The stream is a segment `nozzle_pos → contact_pos`.

Suggested drawing (each frame while spraying):
- Draw a thick, semi-transparent “glow” line first.
- Draw a slightly thinner bright line on top.
- Draw 2–5 extra thin lines with small perpendicular offsets (“multi-jet” look).
  - Offsets should jitter smoothly per frame, not teleport.

Visibility:
- Stream is visible only while spraying (finger down).

### Impact VFX (Circles)
At `contact_pos`:
- Draw a soft filled circle (low alpha).
- Draw a ring (arc) for a “splash” highlight.

Additionally, spawn small circle “droplets”:
- Each droplet has `pos`, `vel`, `life`, `age`, `radius`.
- Spawn while spraying; update each frame; fade alpha as `age / life` increases.
- Emit mostly back toward the player (opposite the stream direction) with a random cone spread:
  - `stream_dir = (contact_pos - nozzle_pos).normalized()`
  - `emit_dir ~= -stream_dir` with angular variance

### Layering / Z-Order
- Draw VFX above the level art but below UI.
- UI is on a `CanvasLayer` above everything.

### Strength Coupling (Optional)
Later, we can map `water_strength_grades_per_second` to VFX:
- Higher strength → higher droplet spawn rate and slightly higher speeds (clamped).
