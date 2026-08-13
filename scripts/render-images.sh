#!/bin/sh
# Regenerates the images the README shows. Run from anywhere; needs openscad and ImageMagick.
set -e

here=$(cd "$(dirname "$0")" && pwd)
scad="$here/../gridfinity.scad"
out="$here/../docs/img"
mkdir -p "$out"

# Rendered at three times the final width and scaled down, which is the whole of the
# anti-aliasing: openscad draws hard pixel edges, so the smoothing has to come from the
# downscale. Border goes on after, or it would shrink with everything else.
# --render takes an optional argument, so it must not be the flag right before the file name
render() {
  name=$1; cam=$2; shift 2
  openscad --render --imgsize=3200,2500 --colorscheme=Tomorrow \
    --camera="$cam" --viewall --autocenter -o "$out/$name.png" "$@" >/dev/null 2>&1
  magick "$out/$name.png" -trim +repage -resize 940x \
    -bordercolor '#f5f5f5' -border 30 "$out/$name.png"
}

# the hero: the same bin, with its lid slid halfway out
hero=$(mktemp -t hero-XXXX.scad)
cat > "$hero" <<EOF
include <$scad>
units_x = 1; units_y = 1; units_z = 3;
cells = 4;
part = "bin";
translate([0, -21, ledge_top(units_z)]) bin_plate(units_x, units_y, units_z);
EOF

render lid-open 0,0,8,58,0,25,0 "$hero"
rm -f "$hero"

render bin-divided 0,0,8,60,0,25,0 \
  -D units_x=1 -D units_y=1 -D units_z=3 -D cells=3 "$scad"

render bin-card 0,0,8,55,0,20,0 \
  -D units_x=1 -D units_y=1 -D units_z=3 -D 'part="assembled"' "$scad"

render section 0,0,8,68,0,295,0 \
  -D units_x=1 -D units_y=1 -D units_z=3 -D split=true "$scad"
