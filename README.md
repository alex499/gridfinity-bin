# gridfinity-bin

A parametric [Gridfinity](https://gridfinity.xyz/) bin generator written from scratch in
OpenSCAD, with no external libraries.

This project is a compilation of two existing Gridfinity bin designs — it takes the
features of both and reimplements them as a single parametric model driven by the
OpenSCAD Customizer:

- [Gridfinity Bins medium size](https://www.printables.com/model/710839-gridfinity-bins-medium-size) by Plastic Flow
- [Gridfinity UltraLight Bins – Modular Clip-On Label System](https://www.printables.com/model/1481418-gridfinity-ultra-light-bins-modular-clip-on-label) by Muad'Dib

The geometry was matched against the published STLs by measuring their cross-sections,
rather than by converting or editing the meshes. The scoop, for example, is a concave
fillet of radius 10 mm, tangent to both the inner front wall and the cavity floor —
numbers taken from the ultra-light bin's actual profile. Where the two sources disagree
with the official Gridfinity dimensions, the spec wins: the stacking lip is built to
spec rather than copied from either model.

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
  wall, and a thinner wall needs a longer run to avoid an unsupported ledge
- Optional flush front wall, padding the scoop side out to the lip's inner face so a
  swept-out part meets no ledge on the way to the rim

## Not implemented yet

- Magnet and screw holes
- Dividers
- Label tab

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
| `scoop_flush` | true | bool | Pad the scoop-side wall out to the lip's inner face |
| `split` | true | bool | Debug: cut the model open to inspect the cross-section |

`scoop_radius` (default 10 mm) is currently in the hidden group; move it out of
`/* [Hidden] */` to expose it in the Customizer.

A note on `wall_thickness`: it sets the side walls, and the same value is used as the
skin left inside the feet. Because the foot cavity is a single taper, that skin is
thinner than `wall_thickness` where the taper passes closest to the outer surface —
0.69 mm at the default of 1 mm. Raise `wall_thickness` if your nozzle needs more.

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

## License

**CC BY-NC-SA 4.0** — [Attribution–NonCommercial–ShareAlike 4.0 International](https://creativecommons.org/licenses/by-nc-sa/4.0/)

This is not a free choice. One of the two source designs (UltraLight Bins by Muad'Dib)
is published under CC BY-NC-SA 4.0, whose ShareAlike term requires derivative works to
carry the same license, and whose NonCommercial term forbids commercial use. The other
source (CC BY 4.0) is compatible with being combined into that. So the combined result
cannot be released under anything more permissive.

In practice this means:

- attribution to the authors above is required
- no commercial use
- remixes must stay under CC BY-NC-SA 4.0
