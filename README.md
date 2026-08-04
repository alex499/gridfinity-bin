**English** · [Русский](README.ru.md)

# gridfinity-bin

A parametric [Gridfinity](https://gridfinity.xyz/) bin generator written from scratch in
OpenSCAD, with no external libraries.

![A 2x2x3 bin with a two-row cell grid, its lid slid halfway out](docs/img/lid-open.png)

*A 2x2x3 bin with `rows = [2, 3, 0, 0]`, its lid halfway out. Every picture on this page is
rendered from this file by [docs/render-images.sh](docs/render-images.sh).*

This project is a compilation of three existing Gridfinity bin designs — it takes the
features of each and reimplements them as a single parametric model driven by the
OpenSCAD Customizer:

- [Gridfinity Bins medium size](https://www.printables.com/model/710839-gridfinity-bins-medium-size) by Plastic Flow
- [Gridfinity UltraLight Bins – Modular Clip-On Label System](https://www.printables.com/model/1481418-gridfinity-ultra-light-bins-modular-clip-on-label) by Muad'Dib
- [Gridfinity inserts with cover, divided in multiple ways](https://www.printables.com/model/665798) by mhejjas

The geometry was matched against the published STLs by measuring their cross-sections,
rather than by converting or editing the meshes. The scoop, for example, is a concave
fillet of radius 10 mm, tangent to both the inner front wall and the cavity floor —
numbers taken from the ultra-light bin's actual profile. Where the sources disagree
with the official Gridfinity dimensions, the spec wins: the stacking lip is built to
spec rather than copied from any of them.

## What is implemented

- Outer shell sized to the Gridfinity grid (42 mm pitch, 7 mm height unit) with rounded
  corners. Total height is `units_z * 7 + 4.4` mm, measured from the bottom of the feet —
  the feet are part of the height unit, not added on top of it
- Hollow interior with independent wall and floor thickness
- Full Gridfinity foot profile (0.8 mm chamfer / 1.8 mm vertical / 2.15 mm chamfer)
- Hollow feet, so the cavity extends down into the base and only a thin bottom skin
  remains — the "ultra light, no magnets" approach. The cavity inside a foot is a single
  taper rather than a copy of the stepped outer profile: less plastic and no horizontal
  overhang ledges to print
- Optional scoop: a concave fillet in the floor-to-front-wall corner, added as material
  inside the cavity, so its radius is never limited by wall or floor thickness
- Stacking lip to spec (0.7 / 1.8 / 1.9 mm, 4.4 mm total). Its bottom chamfer is derived
  from the wall thickness instead of being hard-coded: the spec's 0.7 mm assumes a 1.2 mm
  wall, and a thinner wall needs a longer run to avoid an unsupported ledge. With a plate
  under it that run starts lower still, so the same cone doubles as the slot's ceiling
- Optional flush front wall, padding the scoop side out to the lip's inner face so a
  swept-out part meets no ledge on the way to the rim
- A slot just under the lip that a closing plate slides into: the wall thickens 0.9 mm
  through a 45° ramp and steps back, and the step is the ledge the plate rests on. Nothing
  is built above it — the lip's own support cone is lowered onto the ceiling of the slot
  and is what holds the plate down. A round pin sunk into each side wall stands 0.59 mm
  proud of it, and the plate's edge snaps over it into a matching seat
- Two plates use that slot, and the bin picks between them. Undivided, it is the 11.95 mm
  clip-on label card. Divided, it is a **sliding lid** covering the whole bin, because a
  lid is the only thing that keeps contents from crossing between cells. Same thickness,
  same ledge, same detents; the lid adds a tab that fills the mouth and restores the piece
  of lip it cut away, so a closed bin still stacks. Printed flat, the lid has no
  downward-facing face at all
- Dividers on a free grid: `rows` gives the number of cells per row, and rows can differ
  from one another. They stop 0.2 mm below the ledge so the lid slides over them, and
  carry nothing themselves — that is what moving to a lid buys. The ones separating rows
  carry the same scoop as the front wall on their back face, so every row is a little bin
  of its own, scooped the same way; it is clamped to the row depth.
  See [docs/slot-profile.md](docs/slot-profile.md) for the measured sections

| | |
|---|---|
| ![The same divided bin with the lid off](docs/img/bin-divided.png) | ![An undivided 1x1x3 bin with its label card in the slot](docs/img/bin-card.png) |
| Divided, lid off: two rows of two and three cells, each row scooped from the divider in front of it. The notch in the front wall is the mouth the lid slides through. | Undivided, so the same slot holds an 11.95 mm label card instead, and the front wall is left whole. |

## Not implemented yet

- Magnet and screw holes

## Usage

Open in the GUI and use the Customizer panel:

```sh
openscad gridfinity.scad
```

Render an STL:

```sh
openscad -o bin.stl gridfinity.scad
```

Override parameters without editing the file:

```sh
openscad -o bin_1x1x3.stl -D 'units_x=1' -D 'units_y=1' -D 'units_z=3' gridfinity.scad
```

## Parameters

| Parameter | Default | Range | Meaning |
|---|---|---|---|
| `units_x`, `units_y` | 2 | 1–10 | Bin footprint in 42 mm grid units |
| `units_z` | 3 | 1–10 | Bin height in 7 mm units |
| `wall_thickness` | 1 | 0.4–5 | Side wall thickness |
| `floor_thickness` | 1 | 0.4–5 | Thickness of the flat floor above the feet |
| `scoop` | true | bool | Enable the front scoop fillet |
| `scoop_flush` | false | bool | Pad the scoop-side wall out to the lip's inner face |
| `cover` | true | bool | Cut the slot for the closing plate |
| `rows` | `[1,0,0,0]` | 0–6 each | Cells in each row, front row first; 0 drops the row |
| `part` | bin | bin, card, lid, assembled | Which piece to render; `assembled` shows the bin with its plate in place |
| `split` | false | bool | Debug: cut the model open to inspect the cross-section |

`scoop_radius` (default 10 mm) is currently in the hidden group; move it out of
`/* [Hidden] */` to expose it in the Customizer.

A note on `wall_thickness`: it sets the side walls, and the same value is used as the
skin left inside the feet. Because the foot cavity is a single taper, that skin is
thinner than `wall_thickness` where the taper passes closest to the outer surface —
0.69 mm at the default of 1 mm. Raise `wall_thickness` if your nozzle needs more.

![A 1x1x3 bin cut open, showing the scoop, the slot and a detent](docs/img/section.png)

*`split = true` cuts the model open. Visible here: the scoop sweeping up the front wall, the
slot running around under the rim with its ledge, and one of the two detents — the small pin
in the side wall that the plate snaps over.*

## Cards and lids

Both are generated by the same file, with the same `units_*` and `rows` you used for the
bin:

```sh
openscad -o card.stl -D 'units_x=1' -D 'units_y=1' -D 'part="card"' gridfinity.scad
openscad -o lid.stl  -D 'units_x=1' -D 'units_y=1' -D 'rows=[2,3,0,0]' \
                     -D 'part="lid"' gridfinity.scad
```

An undivided bin takes the card; a divided one takes the lid. Both are per bin size — a
card for a 1x1 will not span a 2x2 — and a lid is per bin size only, not per layout, since
it covers everything regardless of how the cells are arranged.

`part = "assembled"` puts the plate back where it sits in the bin and renders both. It picks
the right plate for the layout on its own, and is for looking at rather than printing:

```sh
openscad -D 'units_x=1' -D 'units_y=1' -D 'rows=[2,3,0,0]' \
         -D 'part="assembled"' gridfinity.scad
```

The slot's height came from the UltraLight Bins card, measured off the mesh. Its 2.0 mm
groove depth did not: that model recesses the groove into the wall, and here the slot's
floor is the wall face, so the plate spans the full opening. Nor did the 0.8 mm thickness —
the plate is 1.0 mm, because the difference between it and the slot is exactly how far the
plate can float before the lip's cone catches it. A 1x1 card therefore comes out
39.1 x 11.95 x 1.0 rather than 37.4 x 11.95 x 0.8: more label area, and not interchangeable
with that model's cards.

The sliding lid, the free divider grid and the round detent come from [Gridfinity inserts
with cover, divided in multiple ways](https://www.printables.com/model/665798) by mhejjas,
measured the same way.

## Credits

- **Gridfinity** is a storage system designed by
  [Zack Freedman](https://www.youtube.com/@ZackFreedman). This project is an independent
  implementation of the format, not affiliated with him.
- **Gridfinity Bins medium size** by **Plastic Flow** — licensed CC BY 4.0 —
  <https://www.printables.com/model/710839-gridfinity-bins-medium-size>
  (itself a remix of Zack Freedman's Divider Bins)
- **Gridfinity UltraLight Bins – Modular Clip-On Label System** by **Muad'Dib** —
  licensed CC BY-NC-SA 4.0 —
  <https://www.printables.com/model/1481418-gridfinity-ultra-light-bins-modular-clip-on-label>
- **Gridfinity 1 x 1 x 2 and 1 x 1 x 3 inserts with cover, divided in multiple ways** by
  **mhejjas** — licensed CC BY 4.0 — <https://www.printables.com/model/665798>
  (the sliding lid, the free divider grid and the round detent)

## License

**CC BY-NC-SA 4.0** — [Attribution–NonCommercial–ShareAlike 4.0 International](https://creativecommons.org/licenses/by-nc-sa/4.0/)

This is not a free choice. One of the three source designs (UltraLight Bins by Muad'Dib)
is published under CC BY-NC-SA 4.0, whose ShareAlike term requires derivative works to
carry the same license, and whose NonCommercial term forbids commercial use. The other two
sources (both CC BY 4.0) are compatible with being combined into that. So the combined
result cannot be released under anything more permissive.

In practice this means:

- attribution to the authors above is required
- no commercial use
- remixes must stay under CC BY-NC-SA 4.0
