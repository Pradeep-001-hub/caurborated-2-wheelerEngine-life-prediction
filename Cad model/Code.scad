// Engine Life Prediction Device Enclosure - Parametric OpenSCAD
// Customize these variables:
length = 130;  // Outer length (X)
width = 85;    // Outer width (Y)
height = 45;   // Outer height (Z)
wall = 3;      // Wall thickness
corner_r = 5;  // Corner radius

display_w = 70;  // e.g., 2.8" TFT cutout
display_h = 50;
display_offset_x = 10;
display_offset_y = 15;

pcb_length = 110;
pcb_width = 70;
pcb_height = 5;  // Space below lid

// Main box
module enclosure() {
    difference() {
        // Outer shell with rounded corners
        minkowski() {
            cube([length - 2*corner_r, width - 2*corner_r, height - 2*corner_r], center=true);
            sphere(r=corner_r, $fn=32);
        }
        
        // Inner cavity
        translate([0,0,wall/2])
        cube([length - 2*wall, width - 2*wall, height], center=true);
    }
}

// Bottom part (base with PCB mounts)
module base() {
    difference() {
        enclosure();
        // Cut top open
        translate([0,0,wall+1]) cube([length+1, width+1, height], center=true);
        
        // Mounting holes for PCB (4x)
        for (x = [-pcb_length/2 + 10, pcb_length/2 - 10]) {
            for (y = [-pcb_width/2 + 10, pcb_width/2 - 10]) {
                translate([x, y, -height/2 + wall + 5])
                    cylinder(h=10, r=1.5, center=true, $fn=20);  // M3 holes
            }
        }
    }
    
    // PCB risers
    for (x = [-pcb_length/2 + 10, pcb_length/2 - 10]) {
        for (y = [-pcb_width/2 + 10, pcb_width/2 - 10]) {
            translate([x, y, -height/2 + wall + 3])
                cylinder(h=8, r=4, center=false, $fn=20);
        }
    }
}

// Lid with display window
module lid() {
    difference() {
        enclosure();
        // Remove bottom
        translate([0,0,-wall-1]) cube([length+1, width+1, height], center=true);
        
        // Display cutout
        translate([display_offset_x - length/2 + display_w/2, 
                   display_offset_y - width/2 + display_h/2, 
                   height/2 - wall/2])
            cube([display_w, display_h, wall+2], center=true);
        
        // Button holes (example: 4 small buttons)
        for (i = [0:3]) {
            translate([30 + i*12 - length/2, -20, height/2 - wall/2])
                cylinder(h=wall+2, r=4, center=true, $fn=20);
        }
    }
    
    // Lip for sealing
    translate([0,0,-height/2 + wall + 2])
    difference() {
        cube([length - 2*wall - 0.5, width - 2*wall - 0.5, 4], center=true);
        cube([length - 4*wall, width - 4*wall, 5], center=true);
    }
}

// Cable ports (add glands or grommets)
module ports() {
    // Side ports for sensors/power
    translate([length/2 - wall/2, 0, -5])
        rotate([0,90,0]) cylinder(h=wall+2, r=6, center=true, $fn=30);  // Power/sensor
    translate([-length/2 + wall/2, 20, -5])
        rotate([0,90,0]) cylinder(h=wall+2, r=4, center=true, $fn=30);  // Antenna or probe
}

// Assemble (uncomment one at a time or use for printing)
base();
// translate([0,0,height]) lid();  // Uncomment for lid

// Add ports to base if desired
// ports();
