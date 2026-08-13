**English** · [Русский](README.ru.md)

# gridfinity-bin

A parametric [Gridfinity](https://gridfinity.xyz/) bin generator written from scratch in
OpenSCAD, with no external libraries.

**[Configure one in your browser →](https://alex499.github.io/gridfinity-bin/)** — no
install, no account. The page runs this same `gridfinity.scad` through OpenSCAD compiled to
WebAssembly, so the STL it hands you is the one the command line would produce.

![A 1x1x3 bin with a two-by-two cell grid, its lid slid halfway out](docs/img/lid-open.png)

*A 1x1x3 bin with `cells = 4`, its lid halfway out —
[open this one in the configurator](https://alex499.github.io/gridfinity-bin/#units_x=1&units_y=1&units_z=3&cover=1&closure=auto&split_lid=0&scoop=1&wall_thickness=1&floor_thickness=1&card_length=15&scoop_flush=0&solid_foot=0&cells=4&view=bin).
Every picture on this page is rendered from this file by
[scripts/render-images.sh](scripts/render-images.sh).*

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
- A slot just under the lip that a closing plate slides into: the wall thickens 1.2 mm
  through a 45° ramp and steps back, and the step is the ledge the plate rests on. Nothing
  is built above it — the lip's own support cone is lowered onto the ceiling of the slot
  and is what holds the plate down. A round pin sunk into each side wall stands proud of it
  and the plate's edge snaps over it into a matching seat — 0.59 mm under a lid, 0.9 mm
  under a card, which is short and has nothing else gripping it
- Two plates use that slot, and `closure` picks between them. One is the clip-on label card,
  15 mm deep by default. The other is a **sliding lid** covering the whole bin. Same
  thickness, same ledge, same detents; the lid adds a tab that fills the mouth and restores
  the piece of lip it cut away, so a closed bin still stacks. Printed flat, the lid has no
  downward-facing face at all. On `auto` the bin decides for itself — card while it is
  undivided, lid once it is not, because a lid is the only thing that keeps contents from
  crossing between cells — but either plate can be asked for outright
- `split_lid` cuts the lid on the dividers between cells, one piece per cell, so a cell can
  be opened without pulling the whole lid off. Each piece slides into its own column through
  the same mouth and carries its slice of the tab. The divider under a seam becomes a rail
  and holds the two pieces on it the way a wall holds their outer edges: 1.2 mm of ledge
  under each edge, a cap 0.5 mm thick over it, and 45° flares into both so neither overhang
  needs support. The cap tops out level with the lid rather than with the rim, and the edge
  under it is chamfered on the same 45° to nest below it, so the closed lid is flat — nothing
  of the rail stands above it. The rail carries the same detent the walls do, one in each of
  its two grooves, so every piece snaps over a pair of pins just as the whole lid snaps over
  the pair in the walls. With two rows the bin gets a second mouth, in the back wall, so each
  row slides in from its own end — which is why a rail lying across the bin can keep its cap:
  no piece ever has to travel over one. There are always as many pieces as there are cells
- Dividers: `cells` is the whole layout, as one number — how many compartments the inside is
  split into. Two sit side by side, with the divider running the full depth; three put a row
  of two in front of a single one; four is two by two. They stop 0.2 mm below the ledge so
  the lid slides over them, and carry nothing themselves unless a seam lands on them — that
  is what moving to a lid buys. Every row gets the front wall's scoop grown from its own
  outer wall — the front row from the front, the back row from the back — so each row is a
  little bin of its own, facing its own end; it is clamped to the row depth.
  See [docs/slot-profile.md](docs/slot-profile.md) for the measured sections

| | |
|---|---|
| ![The same divided bin with the lid off](docs/img/bin-divided.png) | ![An undivided 1x1x3 bin with its label card in the slot](docs/img/bin-card.png) |
| `cells = 3`, lid off: a row of two in front of a single cell, each row scooped from the divider in front of it. The notch in the front wall is the mouth the lid slides through. | Undivided, so the same slot holds a label card instead, and the front wall is left whole. |

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

[`scripts/render-stl.sh`](scripts/render-stl.sh) renders a ready-to-print set into `stl/`:
every `cells` and closure combination of the 1x1x3, with its cards and lids. The files are
not in git — run the script after changing the model.

```sh
./scripts/render-stl.sh
```

## The browser configurator

[`web/`](web/) is a static page that renders this file in the browser: OpenSCAD itself,
compiled to WebAssembly, driven by the same `-D` flags you would type. There is no server
and nothing is uploaded — the model is fetched as plain text and rendered locally, taking
about 0.4 s for a 2x2x3 bin and under 3 s for the largest one the sliders allow.

The address bar always carries the whole configuration, so a link reproduces a bin exactly:
copy it to send someone a design, or bookmark it and let the browser sync it to the machine
next to the printer. Every parameter is written out rather than only the ones that differ
from a default, so an old link cannot quietly change meaning when a default does.

```sh
cd web
yarn install
yarn serve      # builds _site/ and serves it on http://localhost:8080
```

`node verify.js` checks the page against the CLI: it drives the real worker, compares signed
volume and bounding box for a spread of configurations, and sweeps every
`cells` x `split_lid` x `closure` x `part` combination for a clean render. The sweep alone
(`node verify.js sweep`) needs no OpenSCAD installed and is what CI runs before deploying.

Editing `gridfinity.scad` needs no change here — the page reads it at run time. Only a *new*
parameter needs a control adding to `web/index.html`.

The page opens on a 1x1x3 bin. The defaults in the table below are the file's own, which is
what the CLI gives you; the two are deliberately allowed to differ.

## Parameters

| Parameter | Default | Range | Meaning |
|---|---|---|---|
| `units_x`, `units_y` | 2 | 1–10 | Bin footprint in 42 mm grid units |
| `units_z` | 3 | 1–10 | Bin height in 7 mm units |
| `wall_thickness` | 1 | 0.4–5 | Side wall thickness |
| `floor_thickness` | 1 | 0.4–5 | Thickness of the flat floor above the feet |
| `solid_foot` | false | bool | Fill the feet in instead of letting the cavity dip into them |
| `scoop` | true | bool | Enable the front scoop fillet |
| `scoop_flush` | false | bool | Pad the scoop-side wall out to the lip's inner face |
| `cover` | true | bool | Cut the slot for the closing plate |
| `closure` | auto | auto, card, lid | Which plate the slot is cut for; `auto` is a card until the bin is divided, then a lid |
| `cells` | 1 | 1–4 | Compartments the inside is split into; 2 side by side, 3 a row of two in front of one, 4 two by two |
| `split_lid` | false | bool | Cut the lid into one piece per cell, each sliding in from its own end |
| `part` | bin | bin, card, lid, assembled | Which piece to render; `assembled` shows the bin with its plate in place |
| `card_length` | 15 | 5–40 | How deep the label card runs in from the back wall; the ledge follows it |
| `split` | false | bool | Debug: cut the model open to inspect the cross-section |
| `split_axis` | x | x, y, xy | Debug: which plane the cut runs on; `xy` leaves a quarter |

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

Both are generated by the same file, with the same `units_*` and `cells` you used for the
bin:

```sh
openscad -o card.stl -D 'units_x=1' -D 'units_y=1' -D 'part="card"' gridfinity.scad
openscad -o lid.stl  -D 'units_x=1' -D 'units_y=1' -D 'cells=4' \
                     -D 'part="lid"' gridfinity.scad
```

Print whichever one the bin was built for — that is `closure`, and on `auto` it follows the
layout. Both are per bin size — a card for a 1x1 will not span a 2x2 — and with `split_lid`
the lid follows the layout too, coming out as one piece per cell. The pieces are already
laid out, coplanar and a gap apart, so one render is the whole set.

`part = "assembled"` puts the plate back where it sits in the bin and renders both. It picks
whichever plate the slot was cut for, and is for looking at rather than printing:

```sh
openscad -D 'units_x=1' -D 'units_y=1' -D 'cells=4' \
         -D 'part="assembled"' gridfinity.scad
```

Nothing about the plate is copied from the UltraLight Bins card. That model recesses its
groove 2.0 mm into the wall; here the slot's floor is the wall face, so the plate spans the
full opening. Its plate is 0.8 mm thick; here it is 1.0, and the slot is not a measured
number at all — it is `plate_thickness + plate_play`, so the plate always fits and whatever
is left over is exactly how far it can float before the lip's cone catches it. That play is
0 by default, so the slot is the plate. A 1x1 card therefore comes out 39.3 x 15 x 1.0
rather than 37.4 x 11.95 x 0.8: more label area, and not interchangeable with that model's
cards.

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
