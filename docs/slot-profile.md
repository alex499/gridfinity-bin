# The slot, and the two plates that live in it

One slot, one profile, two plates. A short plate is the clip-on label card; a full-length one
is the sliding lid. Same thickness, same ledge, same detents — only the depth differs, and the
lid carries a tab at the front.

The bin picks between them: an undivided bin gets the card, a divided bin gets the lid, because
a lid is the only way to keep contents from crossing between cells when the bin is tipped.

## The profile

Cross-section in Y-Z through a side wall: wall on the right, cavity on the left. Horizontal
scale 0.1 mm per character, vertical 0.2 mm per line, so the proportions are roughly true. The
`abs` column is z in the model for a 3u bin; numbers are for the defaults, `wall_thickness = 1`.

```
   z     abs                      cavity │ wall
       17.25        ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       17.05        ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒    lip inner face
       16.85        ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       16.65        ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       16.45        ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
       16.25        ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  ╮ lip cone         45°, and what holds the plate
       16.05          ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  │
       15.85            ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  │                  not part of the slot, but it
       15.65              ▒▒▒▒▒▒▒▒▒▒▒▒▒  ╯                  starts where the slot ends
 2.0   15.45  ░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒  ← ceiling of the slot, and the top of the plate
 1.9   15.35  ░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒  ╮
 1.7   15.15  ░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒  │ slot       1.0   floor = the wall face itself
 1.5   14.95  ░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒  │
 1.3   14.75  ░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒  │                  ░ = the plate, 1.0 thick
 1.1   14.55  ░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒  ╯
 0.9   14.45        ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  ← the ledge, 0.9 proud of the wall face
 0.7   14.15          ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  ╮
 0.5   13.95            ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  │ ramp       0.9   45°, thickening the wall
 0.3   13.75              ▒▒▒▒▒▒▒▒▒▒▒▒▒  │
 0.1   13.55                ▒▒▒▒▒▒▒▒▒▒▒  ╯
 0.0   13.45  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄▒▒▒▒▒▒▒▒▒▒  ← wall face, nothing below this is slot
```

The wall thickens by `slot_ledge` through a 45° ramp and then steps back, and that step is the
ledge. The slot's floor *is* the wall face, so there is no groove depth to measure from — the
plate simply spans the opening and overlaps the ledge by 0.7 a side.

Nothing is built above the slot. The plate is held down by the lip's own 45° support cone,
which is lowered to land exactly on the ceiling of the slot.

`slot_ledge` = 0.9 is the largest ledge that stays inside the lip: any more and it would stand
proud of the lip's inner face. Every sloped face is 45° or shallower, so nothing in the slot
prints as an unsupported overhang.

## How much the plate can lift

Nothing presses the plate onto the ledge, so it floats until its outer top corner wedges into
the cone. There is no flat ceiling to stop it earlier: over the middle of the plate the bin is
open all the way to the rim, and the cone only comes down at the walls.

```
travel = slot_height - plate_thickness + plate_gap/2
```

The last term is the side clearance arriving through a 45° ramp: the corner sits `plate_gap/2`
in from the wall face, and the cone needs exactly that much height to reach it. At 1.0, 1.0
and 0.4 the travel is 0.2 — measured on the render as 0.216, and it tracks the formula to the
0.01 across thicknesses.

The plate is 1.0 rather than the 0.8 of the card it descends from for this reason alone: at
0.8 the travel was 0.42, and the plate would knock against the foot of a stacked bin. 1.2 is
the hard limit, where the corner touches the cone at rest and the plate no longer slides.

Chamfering the plate's edge to follow the cone — which is what the reference does — does not
help here. The travel is decided at the outer top corner, and a chamfer runs inward from that
corner without moving it. What it would buy is thickness in the middle, for stiffness, and
even that is capped: the foot of a stacked bin comes down to 15.90.

## Where the slot hangs

`slot_top(nz)` is `body_top(nz) - slot_drop`, and everything hangs down from there.
`slot_drop` = 0.8 is the one free number: it sets how far below the rim the plate sits. Lower
it and the plate goes with it.

## Numbers that follow

| | |
|---|---|
| ledge, top face | 14.45 |
| plate | 14.45 → 15.45 |
| ceiling of the slot | 15.45 |
| top of the dividers | 14.25 |
| card | 39.1 × 11.95 × 1.0 |
| lid, 1x1 | 41.49 × 40.3 × 6.2 |

## The detent

A round pin, Ø0.95, sunk into each side wall so that only part of it shows: its axis sits
0.115 outside the wall face, leaving it 0.59 proud into the slot. It runs the full height of
the slot. The plate has a matching seat cut with the same circle plus 0.05, so the pin drops
in with a little slop but no rattle.

The plate's edge stands 0.2 in from the wall face, so getting past the pin costs 0.39 a side.
That is the snap, and it is paid once, at the very end of travel — the seat is centred 3.05 in
from the back wall, where the plate stops.

Sinking the pin rather than standing it on the face is the point: what the plate's edge meets
is a curve it can ride up, not a corner it has to jump. Taken from the reference, whose
numbers these are; the card and the lid share both the pin and the seat, so either part snaps
into the same place.

## The mouth, and why it is exactly `corner_radius` deep

A lid can only be as wide as the narrowest point on its way in, and the way in is narrowed by
the rounded corners. So the front wall, the front of the lip and both front corners are cut
away from the ledge up — that cut is the mouth.

Cut it exactly `corner_radius` deep and both corner arcs disappear completely, leaving a
straight-sided channel at the full width of the cavity. This is exact, not a fit: the inner arc
ends at

```
inner_y/2 − inner_r = (outer_y/2 − w) − (corner_radius − w) = outer_y/2 − corner_radius
```

which is where the outer arc ends too, whatever the wall thickness. Measured on the render, the
opening is 19.75 half-width at every y from the mouth back, and the plate's back corners come
out concentric with the cavity's with 0.2 all round.

Only the back corners are rounded, and only because they have to follow the cavity. A card's
front edge stands in open cavity with nothing to follow, so it stays square and keeps the label
area. A lid's front edge is at the bin's outer face, so it takes the bin's own outer radius.

The reference this came from cuts 3.5 at a radius of 3.75 — the same place, to 0.25.

Consequence: with no lid inserted the lip is interrupted over 3.75 of 41.5 at the front, so a
bin stacked on top is unsupported there. The tab restores it, which means a divided bin stacks
properly only with its lid closed.

## The tab

The tab is the piece of wall and lip the mouth cut away, carried on the lid. Its outer face is
the bin's own outer surface, so it matches exactly, and its top lands on the lip top, 20.65,
never above.

Its inner face is *not* the bin's. On the bin the lip stands on a 45° cone that bridges it down
to the wall; the tab runs straight down at the lip's inner face instead. Copying the cone would
have left the lid with 44 mm² of 45° overhang hanging over its own plate, and it buys nothing —
the space under it is empty slot, in front of the mouth, where the plate does not reach.

The lid prints flat, plate down, and with that change it has **no downward-facing face above
the bed at all** — measured, not assumed.

## Dividers

Dividers stop 0.2 below the ledge, so the lid passes over them, and they carry nothing: no
rail, no ledge, no chamfer. That is the whole point of moving to a lid — once nothing has to be
held at the top of a cell, cells can be laid out freely.

`rows[i]` is how many cells row `i` is split into; rows run across X and are counted from the
front, and a zero drops the row. Rows are equal in height, cells equal in width within their
row, so `rows = [2, 3, 0, 0]` on a 1x1 gives a front row of two 19.25 cells and a back row of
three 12.5 cells.
