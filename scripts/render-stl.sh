#!/bin/sh
# Regenerates the STLs in stl/. Run from anywhere; needs openscad.
set -e

here=$(cd "$(dirname "$0")" && pwd)
scad="$here/../gridfinity.scad"
out="$here/../stl"
mkdir -p "$out"

# every file there is a 1x1x3; the rest of the name is the flags below
size="-D units_x=1 -D units_y=1 -D units_z=3"

render() {
  name=$1; shift
  openscad -o "$out/$name.stl" $size "$@" "$scad" >/dev/null 2>&1
}

for c in 1 2 3 4; do
  render "bin-1x1x3-${c}cell-open"     -D cells=$c -D cover=false
  render "bin-1x1x3-${c}cell-for-card" -D cells=$c -D 'closure="card"'
  render "bin-1x1x3-${c}cell-for-lid"  -D cells=$c -D 'closure="lid"'
done

# one cell has nothing to split, so it takes the plain lid below
for c in 2 3 4; do
  render "bin-1x1x3-${c}cell-for-split-lid" -D cells=$c -D 'closure="lid"' -D split_lid=true
  render "lid-1x1x3-${c}cell-split"         -D cells=$c -D 'part="lid"'    -D split_lid=true
done

# the plates: a full lid spans the bin whatever the cells, and so does a card
render lid-1x1x3               -D 'part="lid"'
render card-1x1x3-for-card-bin -D 'part="card"'
