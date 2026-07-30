/* [Bin size] */
units_x = 2;   // [1:10]
units_y = 2;   // [1:10]
units_z = 3;   // [1:10]

/* [Walls] */
wall_thickness = 1;    // [0.4:0.1:5]
floor_thickness = 1;   // [0.4:0.1:5]
scoop = true;
scoop_flush = true;

/* [Debug] */
split=true;

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

// stacking lip profile (bottom to top)
lip_bottom_chamfer = 0.7;
lip_vertical       = 1.8;
lip_top_chamfer    = 1.9;
lip_height = lip_bottom_chamfer + lip_vertical + lip_top_chamfer; // 4.4

// footprint of a single foot at its three levels, inset from the outer surface
function foot_top(inset)  = grid_unit - clearance - 2*inset;
function foot_mid(inset)  = foot_top(inset) - 2*foot_top_chamfer;
function foot_base(inset) = foot_mid(inset) - 2*foot_bottom_chamfer;

// outer dimensions of the bin
function outer_x(nx) = grid_unit * nx - clearance;
function outer_y(ny) = grid_unit * ny - clearance;
function body_top(nz) = unit_height * nz - foot_height;

// dimensions of the inner cavity
function inner_x(nx) = outer_x(nx) - 2*wall_thickness;
function inner_y(ny) = outer_y(ny) - 2*wall_thickness;
function inner_r()   = corner_radius - wall_thickness;

// inner surfaces the scoop is tangent to
function wall_y(ny)  = -inner_y(ny)/2;          // front wall, inner face
function floor_z()   = -foot_height + wall_thickness;  // cavity floor, inside the foot
function scoop_wall()     = scoop_flush ? lip_top_chamfer : wall_thickness;
function scoop_wall_y(ny) = -outer_y(ny)/2 + scoop_wall();

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
            body_top(nz) + lip_bottom_chamfer - floor_z()
          ]);
    }
  }
}

// Stacking lip: a ring standing on the top face of the body.
module bin_lip(nx, ny, nz) {
  lip_inner_x = outer_x(nx) - 2*lip_top_chamfer;
  lip_inner_y = outer_y(ny) - 2*lip_top_chamfer;
  lip_inner_r = corner_radius - lip_top_chamfer;

  // Cone bridging the wall up to the lip, so the lip is not an unsupported ledge.
  // Spec's 0.7 assumes a 1.2mm wall; for thinner walls the excess goes below body_top.
  support = max(0, lip_top_chamfer - wall_thickness);
  extra   = max(0, support - lip_bottom_chamfer);

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

    bin_lip(nx, ny, nz);
  }
}


if (split) {
  difference() {
    bin(units_x, units_y, units_z);
    translate([-60,0,0]) cube(100, center=true);
  }
} else {
  bin(units_x, units_y, units_z);
}