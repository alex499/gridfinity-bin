/* [Bin size] */
units_x = 2;   // [1:10]
units_y = 2;   // [1:10]
units_z = 3;   // [1:10]

/* [Walls] */
wall_thickness = 1;    // [0.4:0.1:5]
floor_thickness = 1;   // [0.4:0.1:5]
scoop = true;

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

// outer dimensions of the bin
function outer_x(nx) = grid_unit * nx - clearance;
function outer_y(ny) = grid_unit * ny - clearance;
function outer_z(nz) = unit_height * nz;

// dimensions of the inner cavity
function inner_x(nx) = outer_x(nx) - 2*wall_thickness;
function inner_y(ny) = outer_y(ny) - 2*wall_thickness;
function inner_r()   = corner_radius - wall_thickness;

// inner surfaces the scoop is tangent to
function wall_y(ny)  = -inner_y(ny)/2;          // front wall, inner face
function floor_z()   = -foot_height + wall_thickness;  // cavity floor, inside the foot


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

module bin_foot_shape(inset=0) {
  outer_x = grid_unit - clearance - 2*inset;
  outer_y = grid_unit - clearance - 2*inset;
  
  mid_x = outer_x - 2 * foot_top_chamfer;
  mid_y = outer_y - 2 * foot_top_chamfer;
 
  foot_x = outer_x - 2 * (foot_bottom_chamfer + foot_top_chamfer);
  foot_y = outer_y - 2 * (foot_bottom_chamfer + foot_top_chamfer);

  mid_r = 3.2 / 2;
  foot_r = 1.6 / 2;
  
  translate([0,0,inset])
    union() {
      tapered_hull(
        foot_x,
        foot_y,
        foot_r,
        mid_x,
        mid_y,
        mid_r,
        foot_bottom_chamfer
      );

      translate([0, 0, foot_bottom_chamfer])
        rounded_box(mid_x, mid_y, foot_vertical, mid_r);

      translate([0, 0, foot_bottom_chamfer + foot_vertical])
        tapered_hull(
          mid_x,
          mid_y,
          mid_r,
          outer_x,
          outer_y,
          corner_radius,
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

module bin_void(nx, ny, nz) {
  union() {
    translate([0, 0, floor_thickness])
      rounded_box(
        inner_x(nx),
        inner_y(ny),
        outer_z(nz) - floor_thickness + 1,
        inner_r()
      );

    translate([0, 0, -foot_height])
      foot_grid(nx, ny) bin_foot_shape(inset = wall_thickness);
  }
}

module bin_scoop(nx, ny, nz) {
  intersection() {
    bin_void(nx, ny, nz);

    difference() {
      translate([-inner_x(nx)/2, wall_y(ny), floor_z()])
        cube([inner_x(nx), scoop_radius, scoop_radius]);

      translate([0, wall_y(ny) + scoop_radius, floor_z() + scoop_radius])
        rotate([0, 90, 0])
          cylinder(r = scoop_radius, h = inner_x(nx) + 2, center = true);
    }
  }
}

module bin(nx, ny, nz) {
  union() {
    difference() {
      union() {
        translate([0, 0, -foot_height])
          foot_grid(nx, ny) bin_foot_shape();
        rounded_box(outer_x(nx), outer_y(ny), outer_z(nz), corner_radius);
      }
      bin_void(nx, ny, nz);
    }

    if (scoop)
      bin_scoop(nx, ny, nz);
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