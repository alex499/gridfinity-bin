/* [Bin size] */
units_x = 2;   // [1:10]
units_y = 2;   // [1:10]
units_z = 3;   // [1:10]

/* [Walls] */
wall_thickness = 1;    // [0.4:0.1:5]
floor_thickness = 1;   // [0.4:0.1:5]
// fill the feet in instead of letting the cavity dip into them
solid_foot = false;
scoop = true;
scoop_flush = false;
cover = true;
// which plate the slot is cut for; auto is a card until the bin is divided, then a lid
closure = "auto";   // [auto, card, lid]

/* [Dividers] */
// how many cells to split the inside into: 2 side by side, 3 a row of two in front of a
// single one, 4 two by two
cells = 1;   // [1:4]
// cut the lid into one piece per cell, each sliding in from its own end of the bin
split_lid = false;

/* [Output] */
part = "bin";      // [bin, card, lid, assembled]
// how deep the label card runs in from the back wall, and how far the ledge follows it
card_length = 15;   // [5:0.05:40]

/* [Debug] */
split=false;
split_axis = "x";   // [x, y, xy]

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

// The plate: a card when it is short, a sliding lid when it runs the whole bin.
plate_thickness = 1;
plate_play      = 0;             // how far it floats in the slot before the lip's cone catches it
plate_gap       = 0.2;           // its clearance in the slot, 0.1 a side
lid_notch       = corner_radius; // depth of the mouth; see docs, this value is not free
lid_cap         = 0.5;           // how much of a piece's edge a rail holds over it; also its thickness

// Slot the closing plate sits in, just under the lip. The wall thickens by slot_ledge
// through a 45 deg taper and then steps back, and the step is the ledge. See docs.
slot_ledge  = 1.2;   // how far the ledge stands proud of the face it grows out of, wall or rail
slot_height = plate_thickness + plate_play;   // the slot, floor to ceiling
slot_drop   = 0.8;   // ceiling of the slot below the rim; the one number setting plate height

// Detents on the side walls that the plate's edges snap over: a round pin sunk into the
// wall face, so what the plate meets is a curve rather than a corner.
slot_detent_radius = 0.475;
slot_detent_proud  = 0.59;   // how far it stands into the slot, more than its own radius
card_detent_proud  = 0.9;    // a card is short and gripped by nothing else, so its catch is deeper
slot_detent_offset = 3.05;   // its centre, measured in from the back wall

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
// cavity floor: inside the foot, or on top of it once the foot is filled in
function floor_z()   = solid_foot ? floor_thickness : -foot_height + wall_thickness;
// flush pads out to the lip's inner face, what stands furthest in above the scoop. A lid's
// mouth takes the lip and the ledge with it, so there is nothing left to pad out to.
function scoop_wall()     = !scoop_flush || lidded() ? wall_thickness : lip_top_chamfer;
function scoop_wall_y(ny) = -outer_y(ny)/2 + scoop_wall();

// The slot hangs from its ceiling, which is where the lip's cone starts: that cone is what
// holds the plate down, so nothing has to be built above the slot.
function slot_top(nz)   = body_top(nz) - slot_drop;
function ledge_top(nz)  = slot_top(nz) - slot_height;
function ledge_bot(nz)  = ledge_top(nz) - slot_ledge;
function ledge_depth()  = wall_thickness + slot_ledge;

// centre of the detent pin: sunk into the wall face by the part of it that does not show
function detent_proud() = lidded() ? slot_detent_proud : card_detent_proud;
function detent_x(nx)   = inner_x(nx)/2 - detent_proud() + slot_detent_radius;
// A piece snaps over a pin near the end of its own travel: the back wall when its row is the
// only one, the seam between rows when there are two. Rows are given in their own frame, the
// one the row is built in, so both rows read the same number.
function detent_y(ny)   = seamed() && two_rows() ? -(seam_face() + slot_detent_offset)
                                                 : inner_y(ny)/2 - slot_detent_offset;

// the plate stops against the back wall; the lid runs on from there to the outer face
function plate_back(ny) = inner_y(ny)/2 - plate_gap/2;
function lid_depth(ny)  = plate_back(ny) + outer_y(ny)/2;
function mouth_y(ny)    = -outer_y(ny)/2 + lid_notch;

// Compartments. cells is the whole layout: one cell, two side by side, three as a row of
// two in front of a single one, four as two by two. Rows run across X, counted from the
// front, and row_list()[i] is how many cells the i-th row holds.
function row_list()  = cells >= 4 ? [2, 2]
                     : cells >= 3 ? [2, 1]
                     : cells >= 2 ? [2]
                     :              [1];
function row_count() = len(row_list());
function row_n(i)    = row_list()[i];
function divided()   = cells > 1;

// which plate the slot is built for. Only a lid gets a mouth, a ledge round the whole
// perimeter and a tab; a card gets a ledge card_length long and an unbroken front wall
function lidded() = cover && (closure == "lid" || (closure == "auto" && divided()));

function row_h(ny)        = (inner_y(ny) - (row_count()-1)*divider_thickness) / row_count();
function row_y0(ny, i)    = -inner_y(ny)/2 + i * (row_h(ny) + divider_thickness);
function cell_w(nx, i)    = (inner_x(nx) - (row_n(i)-1)*divider_thickness) / row_n(i);
function divider_x(nx, i, j) = -inner_x(nx)/2 + j*(cell_w(nx,i) + divider_thickness) - divider_thickness/2;
function divider_top(nz)  = ledge_top(nz) - 0.2;

// A divider that runs the full depth of the bin lies along the way the lid slides, so the
// lid can be cut on it: one piece per cell, each going into its own column on its own. The
// divider becomes a rail and holds the two pieces meeting on it exactly the way a wall holds
// their outer edges — a groove down either face, capped by a top that is flush with the rim.
// Two rows split the inside evenly, so the seam between them is the centreline and the back
// row is the front one mirrored in Y. Each row goes in through its own mouth, which is why a
// rail across the bin can keep its cap: no piece ever has to travel over one.
function seamed()    = split_lid && lidded() && cells > 1;
function two_rows()  = row_count() > 1;
function seam_face() = divider_thickness/2;              // the cross rail's face, at y = 0
function seam_edge() = seam_face() + plate_gap/2;        // where a piece stops against it
function ledge_w()     = divider_thickness + 2*slot_ledge;   // the rail under the pieces
function rail_w()      = divider_thickness + 2*lid_cap;    // and the cap over them
function groove_h()    = slot_height - lid_cap;

// Every rail carries the same detent the walls do, one in each of its two grooves, so each
// piece snaps over a pair of them just as the whole lid snaps over the pair in the walls.
function rail_detent_x(nx, i, j, s) = divider_x(nx, i, j)
                                      + s*(divider_thickness/2 + slot_detent_proud
                                           - slot_detent_radius);

// which rows carry their own pair of wall pins, and where each row's pair sits for real
function detent_rows()       = seamed() && two_rows() ? [0, 1] : [0];
function row_detent_y(ny, i) = i == 0 ? detent_y(ny) : -detent_y(ny);


// a piece runs wall slot to groove, groove to groove, or groove to wall slot
function piece_x0(nx, i, j) = j == 0 ? -outer_x(nx)
                                     : divider_x(nx, i, j) + divider_thickness/2 + plate_gap/2;
function piece_x1(nx, i, j) = j == row_n(i)-1 ? outer_x(nx)
                                              : divider_x(nx, i, j+1) - divider_thickness/2
                                                - plate_gap/2;
// how far back a row's piece runs: to the back wall alone, or up to the cross rail
function piece_y1(ny) = two_rows() ? -seam_edge() : outer_y(ny);

// In the mouth there is no rail — the cut took it away with the wall — so the tabs meet
// there on the centreline and close the front face between them.
function tab_x0(nx, i, j) = j == 0 ? -outer_x(nx) : divider_x(nx, i, j) + plate_gap/2;
function tab_x1(nx, i, j) = j == row_n(i)-1 ? outer_x(nx)
                                            : divider_x(nx, i, j+1) - plate_gap/2;
function tab_back(ny)  = mouth_y(ny) - plate_gap/2;   // clear of the cap on the way in

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

    if (!solid_foot)
      translate([0, 0, -foot_height])
        foot_grid(nx, ny) bin_foot_void(inset = wall_thickness);
  }
}

// The scoop grows from the outer wall of its own row: the front row sweeps against the bin's
// front wall, the back row against the back wall, which is the same thing mirrored. Clamped
// to the row depth, or a shallow row would try to scoop deeper than it is.
module bin_scoop(nx, ny, nz) {
  for (i = [0 : row_count()-1])
    if (i == 0) row_scoop(nx, ny, nz);
    else        mirror([0, 1, 0]) row_scoop(nx, ny, nz);
}

module row_scoop(nx, ny, nz) {
  r = min(scoop_radius, row_h(ny));
  // the pad runs up to the lip, and only a card has one in this wall to run up to
  pad_top = body_top(nz) + lip_bottom_chamfer;

  intersection() {
    bin_void(nx, ny, nz);

    union() {
      // square in the corner minus a cylinder = concave quarter fillet
      difference() {
        translate([-inner_x(nx)/2, scoop_wall_y(ny), floor_z()])
          cube([inner_x(nx), r, r]);

        translate([0, scoop_wall_y(ny) + r, floor_z() + r])
          rotate([0, 90, 0])
            cylinder(r = r, h = inner_x(nx) + 2, center = true);
      }

      if (scoop_flush && !lidded())
        translate([-inner_x(nx)/2, wall_y(ny), floor_z()])
          cube([
            inner_x(nx),
            scoop_wall() - wall_thickness,
            pad_top - floor_z()
          ]);
    }
  }
}

// The mouth ends the wall at the ledge, so the ledge there sits on the wall's cut top
// holding nothing, and catches whatever is lifted out over it. Cut square along the ledge's
// own inner face, so the side runs stay straight into the corner instead of curling round it.
module ledge_mouth_cut(nx, ny, nz) {
  w = inset_x(nx, ledge_depth());

  translate([-w/2, -outer_y(ny)/2 - 1, ledge_bot(nz) - 1])
    cube([w, wall_thickness + inner_r() + 1, slot_ledge + slot_height + 2]);
}

// Ledge the closing plate rests on, just under the lip. For a card it runs card_length in
// from the back wall; for a lid it runs the whole perimeter but its mouths. The lip's own
// cone is what stops the plate lifting, so there is nothing to build above the slot.
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

      if (!lidded())
        translate([-outer_x(nx)/2 - 1, -outer_y(ny)/2 - 1, base - 1])
          cube([
            outer_x(nx) + 2,
            outer_y(ny) - wall_thickness - card_length + 1,
            h + 2
          ]);

      // a mouth in the wall takes the ledge with it, at whichever end the lid comes in
      if (lidded()) {
        ledge_mouth_cut(nx, ny, nz);

        if (seamed() && two_rows())
          mirror([0, 1, 0])
            ledge_mouth_cut(nx, ny, nz);
      }
    }

    // detents the plate snaps over, one on each side wall
    for (s = [-1, 1], i = detent_rows())
      translate([s * detent_x(nx), row_detent_y(ny, i), base + slot_ledge])
        cylinder(r = slot_detent_radius, h = slot_height);
  }
}

// A length of divider wall running along X, centred on y = 0. Tapers from w0 to w1 over its
// height, so a straight run and a 45 deg flare are the same thing.
module wall_seg(length, w0, w1, z0, h) {
  hull() {
    translate([-length/2, -w0/2, z0])
      cube([length, w0, 0.01]);
    translate([-length/2, -w1/2, z0 + h - 0.01])
      cube([length, w1, 0.01]);
  }
}

// A rail, bottom to top: plain wall, 45 deg flare out to the ledge, the groove, then 45 deg
// out again into the cap. Both flares are what keep the overhangs printable, and the cap
// tops out level with the lid, so nothing of the rail stands above it.
module seam_rail(length, nz) {
  t = divider_thickness;

  union() {
    wall_seg(length, t, t, floor_z(), ledge_bot(nz) - floor_z());
    wall_seg(length, t, ledge_w(), ledge_bot(nz), slot_ledge);
    wall_seg(length, t, t, ledge_top(nz), groove_h());
    wall_seg(length, t, rail_w(), ledge_top(nz) + groove_h(), lid_cap);
  }
}

// Compartment walls, standing 0.2 clear of the ledge so the lid slides over them — except
// the ones the lid is cut on, which come up to it as seats.
module bin_grid(nx, ny, nz) {
  t   = divider_thickness;
  top = divider_top(nz);

  intersection() {
    bin_void(nx, ny, nz);

    union() {
      if (row_count() > 1)
        for (i = [1 : row_count()-1])
          translate([0, row_y0(ny, i) - t/2, 0])
            if (seamed()) seam_rail(inner_x(nx) + 2, nz);
            else          wall_seg(inner_x(nx) + 2, t, t, floor_z(), top - floor_z());

      // the pins the pieces snap over, standing in the grooves like the walls' own
      if (seamed())
        for (i = [0 : row_count()-1])
          if (row_n(i) > 1)
            for (j = [1 : row_n(i)-1], s = [-1, 1])
              translate([rail_detent_x(nx, i, j, s), row_detent_y(ny, i), ledge_top(nz)])
                cylinder(r = slot_detent_radius, h = groove_h());

      for (i = [0 : row_count()-1])
        if (row_n(i) > 1)
          for (j = [1 : row_n(i)-1])
            translate([divider_x(nx, i, j), row_y0(ny, i) + row_h(ny)/2, 0])
              rotate([0, 0, 90])
                if (seamed())
                  seam_rail(row_h(ny) + 2, nz);
                else
                  wall_seg(row_h(ny) + 2, t, t, floor_z(), top - floor_z());
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

// The edge that goes under a cap is thinned to clear it, on the same 45 deg as the cap's own
// flare, so the two nest and the lid comes out flat on top. Cut from a rail's centreline
// outwards; the piece it belongs to is the one at +x.
module seam_chamfer(ny, y1) {
  d0 = divider_thickness/2 + plate_gap/2;
  y0 = tab_back(ny);

  hull() {
    translate([d0, y0, groove_h()])
      cube([0.01, y1 - y0, 2]);

    translate([d0 + lid_cap - 0.01, y0, groove_h() + lid_cap])
      cube([0.01, y1 - y0, 2]);
  }
}

// The leading edge is thinned the same way where it runs in under the cross rail's cap, so
// the two rows nest under it and the closed lid still comes out flat.
module cross_chamfer(nx) {
  d0 = seam_edge();
  w  = 2*outer_x(nx);

  hull() {
    translate([-outer_x(nx), -d0 - 0.01, groove_h()])
      cube([w, 0.01, 2]);

    translate([-outer_x(nx), -d0 - lid_cap, groove_h() + lid_cap])
      cube([w, 0.01, 2]);
  }
}

// One cell's piece of the lid: the whole lid, kept only between its two seams. Each piece
// slides into its own cell through the same mouth, and comes away with its slice of the tab
// and, where it meets a side wall, that wall's detent seat.
module lid_piece(nx, ny, nz, i, j) {
  x0 = piece_x0(nx, i, j);
  x1 = piece_x1(nx, i, j);
  y1 = piece_y1(ny);

  difference() {
    intersection() {
      plate(nx, ny, nz, lid_depth(ny), true);

      h = body_top(nz) + lip_height - ledge_top(nz) + 2;

      union() {
        translate([x0, -outer_y(ny), -1])
          cube([x1 - x0, y1 + outer_y(ny), h]);

        translate([tab_x0(nx, i, j), -outer_y(ny), -1])
          cube([
            tab_x1(nx, i, j) - tab_x0(nx, i, j),
            tab_back(ny) + outer_y(ny),
            h
          ]);
      }
    }

    if (j > 0)
      translate([divider_x(nx, i, j), 0, 0])
        seam_chamfer(ny, y1);

    if (j < row_n(i)-1)
      translate([divider_x(nx, i, j+1), 0, 0])
        mirror([1, 0, 0])
          seam_chamfer(ny, y1);

    if (two_rows())
      cross_chamfer(nx);

    // seats for the rail pins, concentric with them and 0.05 wider so they drop in
    if (j > 0)
      translate([rail_detent_x(nx, i, j, 1), detent_y(ny), -1])
        cylinder(r = slot_detent_radius + 0.05, h = plate_thickness + 2);

    if (j < row_n(i)-1)
      translate([rail_detent_x(nx, i, j+1, -1), detent_y(ny), -1])
        cylinder(r = slot_detent_radius + 0.05, h = plate_thickness + 2);
  }
}

// In pieces once a divider runs the full depth to cut it on, one whole plate while none does.
module bin_lid(nx, ny, nz) {
  if (!seamed())
    plate(nx, ny, nz, lid_depth(ny), true);
  else
    for (i = [0 : row_count()-1], j = [0 : row_n(i)-1])
      if (i == 0) lid_piece(nx, ny, nz, i, j);
      else        mirror([0, 1, 0]) lid_piece(nx, ny, nz, i, j);
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

      if (cover)
        bin_slot(nx, ny, nz);

      bin_lip(nx, ny, nz);
    }

    // a bin closed by a sliding lid needs a mouth for it to come in by
    if (lidded())
      lid_notch_cut(nx, ny, nz);

    // with two rows each one goes in through its own end, so the back wall gets a mouth too
    if (lidded() && seamed() && two_rows())
      mirror([0, 1, 0])
        lid_notch_cut(nx, ny, nz);
  }
}


// the plate this bin's slot was cut for
module bin_plate(nx, ny, nz) {
  if (lidded())
    bin_lid(nx, ny, nz);
  else
    plate(nx, ny, nz, card_length, false);
}

module selected_part() {
  if (part == "card") {
    plate(units_x, units_y, units_z, card_length, false);
  } else if (part == "lid") {
    bin_lid(units_x, units_y, units_z);
  } else if (part == "assembled") {
    // for looking at, not for printing: the plate put back where it sits in the bin
    bin(units_x, units_y, units_z);
    translate([0, 0, ledge_top(units_z)])
      bin_plate(units_x, units_y, units_z);
  } else {
    bin(units_x, units_y, units_z);
  }
}

// the cut is the last thing that happens, so it works on whichever part was picked
if (split) {
  difference() {
    selected_part();

    // both of them and what is left is a quarter, cut open at the corner
    if (split_axis != "y")
      translate([-60,0,0]) cube(100, center=true);

    if (split_axis != "x")
      translate([0,-60,0]) cube(100, center=true);
  }
} else {
  selected_part();
}
