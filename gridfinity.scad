/* [Bin size] */
units_x = 2;   // [1:10]
units_y = 2;   // [1:10]
units_z = 3;   // [1:10]

/* [Walls] */
wall_thickness = 1;    // [0.4:0.1:5]
floor_thickness = 1;   // [0.4:0.1:5]
scoop = true;
scoop_flush = false;
cover = true;

/* [Dividers] */
// cells in each row, front row first; 0 means the row is not there
rows = [1, 0, 0, 0];   // [0:6]

/* [Output] */
part = "bin";      // [bin, card, lid, assembled]

/* [Debug] */
split=false;

/* [Hidden] */
grid_unit = 42;
unit_height = 7;
corner_radius = 7.5 / 2;
clearance = 0.5;
scoop_radius = 10;
$fn = 92;

// foot profile (bottom to top)
foot_bottom_chamfer = 0.8;
foot_vertical = 1.8;
foot_top_chamfer = 2.15;
foot_height = foot_bottom_chamfer + foot_vertical + foot_top_chamfer;

foot_mid_radius  = 3.2 / 2;
foot_base_radius = 1.6 / 2;

// Slot the closing plate sits in, just under the lip. The wall thickens by slot_ledge
// through a 45 deg taper and then steps back, and the step is the ledge. See docs.
slot_ledge  = 0.9;   // how far the ledge stands proud of the wall face
slot_height = 1.0;   // the slot, floor to ceiling
slot_drop   = 0.8;   // ceiling of the slot below the rim; the one number setting plate height

// Detents on the side walls that the plate's edges snap over: a round pin sunk into the
// wall face, so what the plate meets is a curve rather than a corner.
slot_detent_radius = 0.475;
slot_detent_proud  = 0.59;   // how far it stands into the slot, more than its own radius
slot_detent_offset = 3.05;   // its centre, measured in from the back wall

// The plate: a card when it is short, a sliding lid when it runs the whole bin.
plate_thickness = 1.0;   // 0.2 under the slot: that difference is the plate's play, keep it small
plate_gap       = 0.4;           // its clearance in the slot, 0.2 a side
card_length     = 11.95;         // the short plate, and how far the ledge runs for it
lid_notch       = corner_radius; // depth of the mouth; see docs, this value is not free

divider_thickness = wall_thickness;

// stacking lip profile (bottom to top)
lip_bottom_chamfer = 0.7;
lip_vertical       = 1.8;
lip_top_chamfer    = 1.9;
lip_height = lip_bottom_chamfer + lip_vertical + lip_top_chamfer; // 4.4

// 45 deg cone bridging the wall up to the lip. Spec's 0.7 assumes a 1.2mm wall;
// for thinner walls the excess goes below body_top.
function lip_support() = max(0, lip_top_chamfer - wall_thickness);
function lip_extra()   = max(0, lip_support() - lip_bottom_chamfer);

// footprint of a single foot at its three levels, inset from the outer surface
function foot_top(inset)  = grid_unit - clearance - 2*inset;
function foot_mid(inset)  = foot_top(inset) - 2*foot_top_chamfer;
function foot_base(inset) = foot_mid(inset) - 2*foot_bottom_chamfer;

// outer dimensions of the bin
function outer_x(nx) = grid_unit * nx - clearance;
function outer_y(ny) = grid_unit * ny - clearance;
function body_top(nz) = unit_height * nz - foot_height;

// cross-section at a given depth from the outer surface
function inset_x(nx, d) = outer_x(nx) - 2*d;
function inset_y(ny, d) = outer_y(ny) - 2*d;
function inset_r(d)     = corner_radius - d;

// dimensions of the inner cavity
function inner_x(nx) = inset_x(nx, wall_thickness);
function inner_y(ny) = inset_y(ny, wall_thickness);
function inner_r()   = inset_r(wall_thickness);

// inner surfaces the scoop is tangent to
function wall_y(ny)  = -inner_y(ny)/2;          // front wall, inner face
function floor_z()   = -foot_height + wall_thickness;  // cavity floor, inside the foot
function scoop_wall()     = scoop_flush ? lip_top_chamfer : wall_thickness;
function scoop_wall_y(ny) = -outer_y(ny)/2 + scoop_wall();

// The slot hangs from its ceiling, which is where the lip's cone starts: that cone is what
// holds the plate down, so nothing has to be built above the slot.
function slot_top(nz)   = body_top(nz) - slot_drop;
function ledge_top(nz)  = slot_top(nz) - slot_height;
function ledge_bot(nz)  = ledge_top(nz) - slot_ledge;
function ledge_depth()  = wall_thickness + slot_ledge;

// centre of the detent pin: sunk into the wall face by the part of it that does not show
function detent_x(nx) = inner_x(nx)/2 - slot_detent_proud + slot_detent_radius;
function detent_y(ny) = inner_y(ny)/2 - slot_detent_offset;

// the plate stops against the back wall; the lid runs on from there to the outer face
function plate_back(ny) = inner_y(ny)/2 - plate_gap/2;
function lid_depth(ny)  = plate_back(ny) + outer_y(ny)/2;
function mouth_y(ny)    = -outer_y(ny)/2 + lid_notch;

// Compartments. rows[i] is how many cells that row is split into, so rows can differ from
// one another; a zero drops the row. Rows run across X and are counted from the front.
function row_list()      = [for (r = rows) if (r > 0) r];
function row_count()     = max(1, len(row_list()));
function row_n(i)        = len(row_list()) == 0 ? 1 : row_list()[i];
function cell_total(i=0) = i >= row_count() ? 0 : row_n(i) + cell_total(i+1);
function divided()       = cell_total() > 1;

function row_h(ny)        = (inner_y(ny) - (row_count()-1)*divider_thickness) / row_count();
function row_y0(ny, i)    = -inner_y(ny)/2 + i * (row_h(ny) + divider_thickness);
function cell_w(nx, i)    = (inner_x(nx) - (row_n(i)-1)*divider_thickness) / row_n(i);
function divider_x(nx, i, j) = -inner_x(nx)/2 + j*(cell_w(nx,i) + divider_thickness) - divider_thickness/2;
function divider_top(nz)  = ledge_top(nz) - 0.2;

module rounded_rect_2d(size_x, size_y, r) {
  hull() {
    translate([-size_x/2 + r, -size_y/2 + r])
      circle(r);
    translate([ size_x/2 - r, -size_y/2 + r])
      circle(r);
    translate([ size_x/2 - r,  size_y/2 - r])
      circle(r);
    translate([-size_x/2 + r,  size_y/2 - r])
      circle(r);
  }
}

module rounded_box(size_x, size_y, height, r, scale = 1) {
  linear_extrude(height, center = false, scale = scale) {
    rounded_rect_2d(size_x, size_y, r);
  }
}

module tapered_hull(x1, y1, r1, x2, y2, r2, height) {
  hull() {
    rounded_box(x1, y1, 0.01, r1);
    translate([0,0,height])
      rounded_box(x2, y2, 0.01, r2);
  }
}

module bin_foot_shape(inset = 0) {
  translate([0, 0, inset])
    union() {
      tapered_hull(
        foot_base(inset), foot_base(inset), foot_base_radius,
        foot_mid(inset),  foot_mid(inset),  foot_mid_radius,
        foot_bottom_chamfer
      );

      translate([0, 0, foot_bottom_chamfer])
        rounded_box(foot_mid(inset), foot_mid(inset), foot_vertical, foot_mid_radius);

      translate([0, 0, foot_bottom_chamfer + foot_vertical])
        tapered_hull(
          foot_mid(inset), foot_mid(inset), foot_mid_radius,
          foot_top(inset), foot_top(inset), corner_radius,
          foot_top_chamfer
        );
    }
}

module foot_grid(nx, ny) {
  for (i = [0 : nx-1], j = [0 : ny-1]) {
    x = (i - (nx-1)/2) * grid_unit;
    y = (j - (ny-1)/2) * grid_unit;
    translate([x, y, 0])
        children();
  }
}

module bin_foot_void(inset = 0) {
  translate([0, 0, inset])
    tapered_hull(
      foot_base(inset), foot_base(inset), foot_base_radius,
      foot_top(inset),  foot_top(inset),  corner_radius,
      foot_height
    );
}

module bin_void(nx, ny, nz) {
  union() {
    translate([0, 0, floor_thickness])
      rounded_box(
        inner_x(nx),
        inner_y(ny),
        body_top(nz) - floor_thickness + 1,
        inner_r()
      );

    translate([0, 0, -foot_height])
      foot_grid(nx, ny) bin_foot_void(inset = wall_thickness);
  }
}

module bin_scoop(nx, ny, nz) {
  // the pad must not reach into the slot, or it blocks the mouth a sliding lid comes in by
  pad_top = cover ? ledge_top(nz) : body_top(nz) + lip_bottom_chamfer;

  intersection() {
    bin_void(nx, ny, nz);

    union() {
      // square in the corner minus a cylinder = concave quarter fillet
      difference() {
        translate([-inner_x(nx)/2, scoop_wall_y(ny), floor_z()])
          cube([inner_x(nx), scoop_radius, scoop_radius]);

        translate([0, scoop_wall_y(ny) + scoop_radius, floor_z() + scoop_radius])
          rotate([0, 90, 0])
            cylinder(r = scoop_radius, h = inner_x(nx) + 2, center = true);
      }

      if (scoop_flush)
        translate([-inner_x(nx)/2, wall_y(ny), floor_z()])
          cube([
            inner_x(nx),
            scoop_wall() - wall_thickness,
            pad_top - floor_z()
          ]);
    }
  }
}

// Ledge the closing plate rests on, just under the lip. For a card it runs card_length in
// from the back wall; for a lid it runs the whole perimeter. The lip's own cone is what
// stops the plate lifting, so there is nothing to build above the slot.
module bin_slot(nx, ny, nz) {
  base = ledge_bot(nz);
  h    = slot_ledge + slot_height;
  d    = ledge_depth();

  union() {
    difference() {
      translate([0, 0, base])
        difference() {
          rounded_box(inner_x(nx), inner_y(ny), h, inner_r());

          union() {
            // 45 deg taper out to the wall face
            translate([0, 0, -0.1])
              tapered_hull(
                inner_x(nx) + 0.2, inner_y(ny) + 0.2, inner_r() + 0.1,
                inset_x(nx, d), inset_y(ny, d), inset_r(d),
                slot_ledge + 0.1
              );

            // the slot itself; its floor is the wall face, so this cut is the box's own
            // cross-section and needs the 0.2 oversize to stay manifold
            translate([0, 0, slot_ledge])
              rounded_box(inner_x(nx) + 0.2, inner_y(ny) + 0.2,
                          slot_height + 0.1, inner_r() + 0.1);
          }
        }

      if (!divided())
        translate([-outer_x(nx)/2 - 1, -outer_y(ny)/2 - 1, base - 1])
          cube([
            outer_x(nx) + 2,
            outer_y(ny) - wall_thickness - card_length + 1,
            h + 2
          ]);
    }

    // detents the plate snaps over, one on each side wall
    for (s = [-1, 1])
      translate([s * detent_x(nx), detent_y(ny), base + slot_ledge])
        cylinder(r = slot_detent_radius, h = slot_height);
  }
}

// Compartment walls, standing 0.2 clear of the ledge so the lid slides over them.
module bin_grid(nx, ny, nz) {
  t   = divider_thickness;
  top = divider_top(nz);

  intersection() {
    bin_void(nx, ny, nz);

    union() {
      if (row_count() > 1)
        for (i = [1 : row_count()-1])
          translate([-inner_x(nx)/2 - 1, row_y0(ny, i) - t, floor_z()])
            cube([inner_x(nx) + 2, t, top - floor_z()]);

      for (i = [0 : row_count()-1])
        if (row_n(i) > 1)
          for (j = [1 : row_n(i)-1])
            translate([divider_x(nx, i, j) - t/2, row_y0(ny, i) - 1, floor_z()])
              cube([t, row_h(ny) + 2, top - floor_z()]);
    }
  }
}

// The same scoop the front wall gets, repeated on the back face of every row divider, so
// each row is a little bin of its own with its own scoop, pointing the same way. Only the
// back face: the front of a row wants a wall to sweep against, not a ramp.
//
// Clamped to the row depth, or a shallow bin cut into many rows would try to scoop further
// than the row is deep.
module bin_row_scoops(nx, ny, nz) {
  r = min(scoop_radius, row_h(ny));

  intersection() {
    bin_void(nx, ny, nz);

    union() {
      if (row_count() > 1)
        for (i = [1 : row_count()-1]) {
          face = row_y0(ny, i);   // the divider's back face, looking into the row behind it

          // square in the corner minus a cylinder = concave quarter fillet, as the scoop
          difference() {
            translate([-inner_x(nx)/2 - 1, face, floor_z()])
              cube([inner_x(nx) + 2, r, r]);

            translate([-inner_x(nx)/2 - 2, face + r, floor_z() + r])
              rotate([0, 90, 0])
                cylinder(r = r, h = inner_x(nx) + 4);
          }
        }
    }
  }
}

// The mouth: the front wall, the front of the lip and both front corners, gone from the
// ledge up. Cutting exactly corner_radius deep is what makes the opening full width —
// both corner arcs end at outer_y/2 - corner_radius, whatever the wall thickness is.
module lid_notch_cut(nx, ny, nz) {
  translate([-outer_x(nx), -outer_y(ny)/2 - 1, ledge_top(nz)])
    cube([
      2*outer_x(nx),
      lid_notch + 1,
      body_top(nz) + lip_height - ledge_top(nz) + 2
    ]);
}

// The piece of wall and lip the mouth cut away, carried on the lid so a closed bin still
// stacks. Its outer face is the bin's own outer surface, so it matches exactly.
//
// The inner face is not the bin's. On the bin the lip sits on a 45 deg cone bridging it
// down to the wall; copying that cone here would leave the lid with a 45 deg overhang
// hanging over its own plate, and it buys nothing — the space under it is empty slot.
// So the tab runs straight down at the lip's inner face instead.
module lid_tab(nx, ny, nz) {
  lip_inner_x = outer_x(nx) - 2*lip_top_chamfer;
  lip_inner_y = outer_y(ny) - 2*lip_top_chamfer;
  lip_inner_r = corner_radius - lip_top_chamfer;

  z0      = ledge_top(nz);
  knife   = body_top(nz) + lip_bottom_chamfer + lip_vertical;   // where the lip's top chamfer starts
  lip_top = body_top(nz) + lip_height;

  intersection() {
    difference() {
      translate([0, 0, z0])
        rounded_box(outer_x(nx), outer_y(ny), lip_top - z0, corner_radius);

      union() {
        translate([0, 0, z0 - 1])
          rounded_box(lip_inner_x, lip_inner_y, knife - z0 + 1, lip_inner_r);

        // carried 0.2 past the outer surface so the knife edge comes from the prism
        translate([0, 0, knife])
          tapered_hull(
            lip_inner_x,       lip_inner_y,       lip_inner_r,
            outer_x(nx) + 0.4, outer_y(ny) + 0.4, corner_radius + 0.2,
            lip_top_chamfer + 0.2
          );
      }
    }

    // pulled back from the mouth by the gap, so the tab does not rub going in
    translate([-outer_x(nx), -outer_y(ny)/2 - 1, z0])
      cube([2*outer_x(nx), lid_notch + 1 - plate_gap/2, lip_top - z0 + 2]);
  }
}

// The plate that closes the bin. Short and it is the clip-on label card; run to the front
// face with a tab and it is the sliding lid. Same thickness, same ledge, same detents.
module plate(nx, ny, nz, depth, tab) {
  w  = inner_x(nx) - plate_gap;
  r  = inner_r() - plate_gap/2;
  y1 = plate_back(ny);
  y0 = y1 - depth;
  z0 = ledge_top(nz);

  translate([0, 0, -z0])
    union() {
      difference() {
        intersection() {
          // rounded at the back, where it has to follow the corners of the cavity. Carried
          // long so the front pair of corners falls outside and gets trimmed off square:
          // a card's front edge stands in open cavity and has nothing to follow.
          translate([0, y1 - (depth + 2*r)/2, z0])
            rounded_box(w, depth + 2*r, plate_thickness, r);

          translate([-outer_x(nx), y0, z0 - 1])
            cube([2*outer_x(nx), depth + 1, plate_thickness + 2]);

          // clipped to the shell, so a lid's front corners follow the bin's outer radius
          translate([0, 0, z0])
            rounded_box(outer_x(nx) - plate_gap, outer_y(ny) - plate_gap,
                        plate_thickness, inset_r(plate_gap/2));
        }

        // seat for the detent, concentric with it and 0.05 wider so it drops in
        for (s = [-1, 1])
          translate([s * detent_x(nx), detent_y(ny), z0 - 1])
            cylinder(r = slot_detent_radius + 0.05, h = plate_thickness + 2);
      }

      if (tab)
        lid_tab(nx, ny, nz);
    }
}

// Stacking lip: a ring standing on the top face of the body.
module bin_lip(nx, ny, nz) {
  lip_inner_x = outer_x(nx) - 2*lip_top_chamfer;
  lip_inner_y = outer_y(ny) - 2*lip_top_chamfer;
  lip_inner_r = corner_radius - lip_top_chamfer;

  // With a plate under it the cone starts at the ceiling of the slot instead of where it
  // would naturally sit, so it is the ramp that holds the plate down.
  support = lip_support();
  extra   = cover ? slot_drop : lip_extra();

  straight_top = extra + lip_bottom_chamfer + lip_vertical;

  translate([0, 0, body_top(nz) - extra])
    difference() {
      rounded_box(outer_x(nx), outer_y(ny), extra + lip_height, corner_radius);

      union() {
        if (support > 0)
          tapered_hull(
            inner_x(nx), inner_y(ny), inner_r(),
            lip_inner_x, lip_inner_y, lip_inner_r,
            support
          );

        translate([0, 0, support])
          rounded_box(lip_inner_x, lip_inner_y, straight_top - support, lip_inner_r);

        // carried 0.2 past the outer surface so the knife edge comes from the prism
        translate([0, 0, straight_top])
          tapered_hull(
            lip_inner_x,       lip_inner_y,       lip_inner_r,
            outer_x(nx) + 0.4, outer_y(ny) + 0.4, corner_radius + 0.2,
            lip_top_chamfer + 0.2
          );
      }
    }
}

module bin(nx, ny, nz) {
  difference() {
    union() {
      difference() {
        union() {
          translate([0, 0, -foot_height])
            foot_grid(nx, ny) bin_foot_shape();
          rounded_box(outer_x(nx), outer_y(ny), body_top(nz), corner_radius);
        }
        bin_void(nx, ny, nz);
      }

      if (scoop)
        bin_scoop(nx, ny, nz);

      if (divided())
        bin_grid(nx, ny, nz);

      if (scoop && divided())
        bin_row_scoops(nx, ny, nz);

      if (cover)
        bin_slot(nx, ny, nz);

      bin_lip(nx, ny, nz);
    }

    // a divided bin is closed by a sliding lid, which needs a mouth to come in by
    if (cover && divided())
      lid_notch_cut(nx, ny, nz);
  }
}


// the plate that closes this bin: a lid once it is divided, a card while it is not
module bin_plate(nx, ny, nz) {
  plate(nx, ny, nz, divided() ? lid_depth(ny) : card_length, divided());
}

if (part == "card") {
  plate(units_x, units_y, units_z, card_length, false);
} else if (part == "lid") {
  plate(units_x, units_y, units_z, lid_depth(units_y), true);
} else if (part == "assembled") {
  // for looking at, not for printing: the plate put back where it sits in the bin
  bin(units_x, units_y, units_z);
  translate([0, 0, ledge_top(units_z)])
    bin_plate(units_x, units_y, units_z);
} else if (split) {
  difference() {
    bin(units_x, units_y, units_z);
    translate([-60,0,0]) cube(100, center=true);
    //translate([0,-60,0]) cube(100, center=true);
  }
} else {
  bin(units_x, units_y, units_z);
}
