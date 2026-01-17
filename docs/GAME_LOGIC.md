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

### Nozzle Point Definition
The power washer sprite must have a stable, author-defined nozzle location.

Implementation expectation:
- Store a local-space `nozzle_offset_px` on the washer sprite (in pixels), measured from the sprite's top-left corner (no scaling/rotation).
- `nozzle_point = washer_pos + nozzle_offset_px`

This avoids guessing where the nozzle is inside the texture.

### Translation-Only Placement (No Rotation, No Scaling)
The washer sprite never rotates and never scales. Instead, we move it (often partially off-screen) so the nozzle can still “shoot” at any `target_point`.

We define a constant screen-space offset that places the nozzle behind the target, toward the bottom-right:
- `nozzle_to_target_offset = Vector2(+x, +y)` (both positive)

Placement each frame while spraying:
1. Compute the desired nozzle position:
   - `desired_nozzle = target_point + nozzle_to_target_offset`
2. Convert that into the washer sprite position:
   - `washer_pos = desired_nozzle - nozzle_offset_px`

### Positioning (Keeping the Washer Off the Right Side)
We intentionally keep the washer on the right side of the screen, often partially off-screen, so the player sees the level and the stream rather than the entire tool.

Constraint:
- The **right edge of the washer sprite must never be inside the screen**.
  - It can be exactly on the right border, or outside the viewport.

Logic:
1. Compute `washer_pos` from the `target_point` (see “Translation-Only Placement”).
2. Enforce the “right edge” constraint using the unrotated texture bounds:
   - `right_edge_x = washer_pos.x + washer_texture_width`
   - If `right_edge_x < viewport_rect.end.x`, push it right by:
     - `washer_pos.x += viewport_rect.end.x - right_edge_x`

Outcome:
- For most targets, the washer is partially visible but clipped by the right edge.
- When the player targets the **bottom-right corner**, the needed rotation + constraint push can move the entire sprite outside the viewport, while the stream still hits the target point.

### Drawing the Water Stream
The stream is always drawn from `nozzle_point` to `target_point`:
- `stream_segment.start = nozzle_point`
- `stream_segment.end = target_point`

This stays correct even when the washer sprite is partially or fully off-screen.
