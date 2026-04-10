$fn = 64;

include <generated/component_positions.scad>;
include <generated/xiao-nrf52840-parts.scad>;

part = "top-electronics";
hand = "left";
show_components = true;
show_keycap_bounds = false;
keycap_check_label = "";
preview_top_explode = 8;
enable_top_battery_cavity = true;
enable_top_jst_cavity = true;
enable_top_wire_cavity = true;
enable_top_component_pod_cavity = true;
show_xiao_reference = false;
use_shared_aux_recess = true;

board_dxf = "../../result/outlines/board.dxf";
top_plate_dxf = "../../result/outlines/top_plate.dxf";

mirror_x = 155.835;

pcb_thickness = 1.6;

// The reversible PCB puts the XIAO on the bottom for the right half and on the
// top for the left half. JST, battery, reset, and power live on the opposite
// face from the XIAO.
electronics_side = hand == "right" ? "bottom" : "top";
battery_side = electronics_side == "bottom" ? "top" : "bottom";

bottom_floor = 2.4;
bottom_wall = 2.4;
pcb_edge_clearance = 0.4;
joint_depth = 1.4;
joint_inset = 0.8;
joint_clearance = 0.25;
bottom_lip_height = 0.6;
top_recess_depth = 0.6;
bottom_lip_pod_clearance = 0.8;
bottom_extra_depth = 2.0;

bottom_pcb_clearance = 2.2;
bottom_wall_above_pcb = 0.2;
top_component_clearance = 5.2;

bottom_inner_height = bottom_pcb_clearance + pcb_thickness + bottom_wall_above_pcb;
standoff_height = bottom_pcb_clearance;
standoff_radius = 2.2;
standoff_overlap = 0.05;
screw_clearance_radius = 1.2;
screw_head_radius = 2.1;
screw_head_depth = 1.1;
nut_flat = 4.4;
nut_depth = 1.6;
mount_hole_radius = 1.1;

top_plate_thickness = 1.2;
top_skirt_depth = joint_depth;
top_wall = 2.2;
top_inner_clearance = 0.35;
top_shell_overlap = 0.05;
closed_shell_wall_min = 0.45;

xiao_center = [211.6, 57.0];
xiao_size = [18.5, 23.0];
xiao_corner = 1.5;
xiao_cavity_height = 6.6;
xiao_usb_overhang_pos = [-3.81, -12.02];
xiao_usb_overhang_size = [7.62, 5.08];
usb_cutout_margin = 1.1;
usb_cutout_outward_shift = 0.2;
bottom_usb_cutout_toward_keys_shift = 2.0;
status_led_center = [xiao_center[0] + 4.25, xiao_center[1] - 9.5];
status_led_hole_radius = 1.0;
electronics_wire_relief_size = [12.0, 14.0];
electronics_wire_relief_corner = 2.4;
electronics_wire_link_size = [11.0, 6.5];
electronics_wire_link_corner = 2.2;
electronics_standoff_keepout_radius = 3.6;
battery_standoff_relief_size = [11.0, 13.0];
battery_standoff_relief_corner = 2.2;
battery_standoff_link_size = [9.0, 6.0];
battery_standoff_link_corner = 2.0;
battery_standoff_keepout_radius = 3.0;
aux_switch_body_size = [7.6, 5.0];
top_aux_switch_body_size = [7.0, 4.8];
aux_switch_body_corner = 1.2;
reset_switch_origin = [220.35, 73.28];
power_switch_origin = [220.35, 83.28];
reset_switch_window_size = [5.6, 5.1];
power_switch_window_size = [6.0, 7.0];

component_pod_inner_x = 198.0;
component_pod_top_y = 44.0;
component_pod_bottom_end_x = 193.5;
component_pod_bottom_end_y = 104.0;
component_pod_outer_x = 230.0;
component_pod_bottom_edge_slope =
    (129.318423 - 111.824276) / (209.106961 - 97.452079);
component_pod_turn_y =
    component_pod_bottom_end_y
    - component_pod_bottom_edge_slope
    * (component_pod_inner_x - component_pod_bottom_end_x);
component_pod_blister_height = 6.0;
component_pod_turn_radius = 4.5;
component_pod_roof_thickness = 1.0;
component_pod_mask_pad = 24.0;
top_usb_opening_z = top_plate_thickness - top_shell_overlap - 0.05;
top_usb_opening_drop = 2.5;
usb_opening_height = 7.15;
bottom_usb_opening_z = -1.32;
top_usb_opening_extra_above = 0.0;
top_usb_bottom_shell_relief_height = 1.4;
top_component_pod_wall_margin = 1.4;
top_component_pod_keycap_side_inset_x = 1.05;
top_component_pod_keycap_bottom_inset_x = 0.8;
top_component_pod_keycap_bottom_raise_y = 1.0;
top_jst_wall_margin = 0.1;

// Preview/check-only keycap envelopes for the keys closest to the electronics
// pod. MBK publishes Choc V1 blanks at 17.5 x 16.5 mm for 1u and
// 26.5 x 16.5 mm for 1.5u, which is a reasonable real-world proxy for fit
// checks without depending on a vendor mesh.
choc_keycap_1u_size = [17.5, 16.5];
choc_keycap_1_5u_size = [26.5, 16.5];
relaxed_thumb_keycap_size = choc_keycap_1u_size;
choc_keycap_compatible_corner = 0.8;
choc_keycap_check_height = 7.0;
keycap_clearance_tolerance = 0.5;
pod_adjacent_keycaps = [
    ["S24", [190.0, 37.78], 0, choc_keycap_1u_size],
    ["S23", [190.0, 54.78], 0, choc_keycap_1u_size],
    ["S22", [190.0, 71.78], 0, choc_keycap_1u_size],
    ["S21", [190.0, 88.78], 0, choc_keycap_1u_size],
    ["S25", [183.88, 110.03], -10, choc_keycap_1u_size],
    ["S26", [203.016286, 116.063648], -25, relaxed_thumb_keycap_size],
];

battery_center = [209.0, 91.8];
battery_size = [12.0, 30.0];
battery_corner = 2.0;
battery_cavity_height = 3.8;
battery_blister_height = 3.4;
battery_clearance = 0.3;
battery_blister_margin = 0.2;

jst_center = [202.5, 72.0];
jst_outline_local_pos = [-2.95, -1.35];
jst_size = [5.9, 7.6];
jst_corner = 0.6;
jst_cavity_height = 5.1;
jst_blister_height = 5.3;
jst_post_pitch = 2.0;
jst_post_pad_size = [1.7, 1.2];
jst_post_relief_size = [jst_post_pitch + jst_post_pad_size[0], jst_post_pad_size[1]];
jst_post_relief_corner = 0.3;
jst_post_relief_clearance = 0.2;
jst_post_relief_height = 2.0;
jst_opposite_relief_link_size = [3.2, 3.2];
jst_opposite_relief_link_corner = 0.35;
jst_top_opposite_relief_height = top_plate_thickness + component_pod_blister_height - component_pod_roof_thickness;

wire_channel_center = [202.7, 84.0];
wire_channel_size = [4.5, 10.0];
wire_channel_corner = 1.2;
wire_channel_cavity_height = 2.2;
wire_channel_blister_height = 2.6;

// Preview-only component envelopes. These are intended for visual fit checks and
// should stay slightly conservative rather than drive shell clearances directly.
xiao_model_board_size = [17.8, 21.0];
xiao_model_board_corner = 1.0;
xiao_model_total_height = 3.6;
xiao_usb_model_height = 3.0;
xiao_model_mesh_translate = [6.1114, -3.3470, 0.25];
xiao_bottom_mesh_offset = [0, -1.56, 0];

battery_model_size = [12.0, 30.0];
battery_model_corner = 1.6;
battery_model_height = 3.0;

jst_model_size = jst_size;
jst_model_corner = jst_corner;
jst_model_height = 4.8;

reset_switch_body_size = [4.7, 3.5];
reset_switch_body_corner = 0.6;
reset_switch_body_height = 1.65;
reset_switch_actuator_size = [2.6, 1.0];
reset_switch_actuator_offset = [0, -2.25];
reset_switch_actuator_height = 1.6;

power_switch_body_size = [6.6, 2.7];
power_switch_body_corner = 0.5;
power_switch_body_height = 1.4;
power_switch_slider_size = [1.5, 1.3];
power_switch_slider_offset = [0, -2.0];
power_switch_slider_height = 1.6;
aux_switch_clearance = 0.2;
top_aux_opening_height =
    top_skirt_depth
    + max(reset_switch_body_height, power_switch_body_height)
    - bottom_wall_above_pcb
    + aux_switch_clearance;

usb_cutout_pos = [
    xiao_center[0] + xiao_usb_overhang_pos[0] - usb_cutout_margin + usb_cutout_outward_shift,
    xiao_center[1] + xiao_usb_overhang_pos[1] - usb_cutout_margin,
];
usb_cutout_size = [
    xiao_usb_overhang_size[0] + 2 * usb_cutout_margin,
    xiao_usb_overhang_size[1] + 2 * usb_cutout_margin,
];
usb_inner_relief_width = 14.0;
usb_outer_throat_width = 13.36;
usb_outer_throat_corner = 0.8;
bottom_usb_cutout_pos = [usb_cutout_pos[0], usb_cutout_pos[1] + bottom_usb_cutout_toward_keys_shift];

reset_cutout_pos = [
    reset_switch_origin[0] - reset_switch_window_size[0] / 2,
    reset_switch_origin[1] - reset_switch_window_size[1] / 2,
];
reset_cutout_size = reset_switch_window_size;

power_cutout_pos = [
    power_switch_origin[0] - power_switch_window_size[0] / 2,
    power_switch_origin[1] - power_switch_window_size[1] / 2,
];
power_cutout_size = power_switch_window_size;

edge_exit_x = 223.5;
edge_exit_width = 3.0;
aux_edge_exit_width = 3.4;
usb_exit_margin = 1.4;
aux_recess_edge_lobe_width = 3.0;
aux_recess_side_lobe_height = 6.0;
aux_recess_center_lobe_height = 7.0;
aux_recess_corner = 1.0;
aux_outer_relief_depth = 1.8;
aux_outer_relief_expand = 0.8;
electronics_crop_min = [component_pod_inner_x - 8.0, component_pod_top_y - 6.0, -bottom_extra_depth - 0.5];
electronics_crop_max = [edge_exit_x + edge_exit_width + 2.0, 86.0, bottom_floor + bottom_inner_height + top_plate_thickness + component_pod_blister_height + 0.5];

mount_holes = [
    [191.6, 123.2], // Bottom left
    [162.4, 70.4], // Middle
    [105.2, 37.8], // Top right
    [213.6, 72.2], // Left
    [113.0, 110.4], // Bottom right
    [183.4, 26.8], // Top left
];

standoff_radii = [
    2.2,
    1.8,
    2.2,
    2.0,
    2.2,
    2.2,
];

mount_hole_screws = [
    true,
    false,
    true,
    false,
    true,
    true,
];

module board_outline_2d() {
    scale([1, -1])
        import(file = board_dxf, convexity = 10);
}

module handed() {
    if (hand == "left") {
        translate([2 * mirror_x, 0, 0])
            mirror([1, 0, 0])
                children();
    } else {
        children();
    }
}

module top_plate_2d() {
    scale([1, -1])
        import(file = top_plate_dxf, convexity = 10);
}

module top_bridge_2d() {
    difference() {
        offset(delta = top_shell_overlap)
            top_skirt_inner_2d();

        offset(delta = -top_shell_overlap)
            board_outline_2d();
    }
}

module top_surface_2d() {
    union() {
        top_plate_2d();
        top_bridge_2d();
    }
}

module outer_outline_2d() {
    offset(delta = bottom_wall)
        board_outline_2d();
}

module inner_cavity_2d() {
    offset(delta = pcb_edge_clearance)
        board_outline_2d();
}

module closed_shell_safe_region_2d() {
    offset(delta = -closed_shell_wall_min)
        outer_outline_2d();
}

module bottom_joint_outer_2d() {
    offset(delta = bottom_wall - joint_inset)
        board_outline_2d();
}

module bottom_lip_profile_2d() {
    difference() {
        bottom_joint_outer_2d();

        // Do not run the locating lip anywhere through the electronics region.
        translate([electronics_crop_min[0], electronics_crop_min[1]])
            square([
                electronics_crop_max[0] - electronics_crop_min[0],
                electronics_crop_max[1] - electronics_crop_min[1],
            ]);
    }
}

module top_skirt_outer_2d() {
    outer_outline_2d();
}

module top_skirt_inner_2d() {
    offset(delta = joint_clearance)
        bottom_joint_outer_2d();
}

module top_recess_2d() {
    difference() {
        top_skirt_outer_2d();
        top_skirt_inner_2d();
    }
}

module rounded_rect_2d(size, r) {
    offset(r = r)
        square([size[0] - 2 * r, size[1] - 2 * r], center = true);
}

module rounded_rect_pos_2d(pos, size, r) {
    translate([pos[0] + size[0] / 2, pos[1] + size[1] / 2])
        rounded_rect_2d(size, r);
}

function pcb_bottom_z() = bottom_floor + standoff_height;
function pcb_top_z() = pcb_bottom_z() + pcb_thickness;
function face_component_z(face, height) =
    face == "top" ? pcb_top_z() : pcb_bottom_z() - height;
function kicad_layer_face(layer_name) =
    hand == "left"
    ? (layer_name == "F.Cu" ? "top" : "bottom")
    : (layer_name == "F.Cu" ? "bottom" : "top");

module oriented_rounded_rect_2d(center, size, r, rotation = 0) {
    translate(center)
        rotate(rotation)
            rounded_rect_2d(size, r);
}

module keycap_compatible_geometry_2d(center, rotation, size, size_expand = 0) {
    oriented_rounded_rect_2d(
        center,
        [
            size[0] + 2 * size_expand,
            size[1] + 2 * size_expand,
        ],
        choc_keycap_compatible_corner + size_expand,
        -rotation
    );
}

module pod_adjacent_keycap_bounds_2d(size_expand = 0) {
    union() {
        for (keycap = pod_adjacent_keycaps) {
            if (keycap_check_label == "" || keycap[0] == keycap_check_label) {
                keycap_compatible_geometry_2d(keycap[1], keycap[2], keycap[3], size_expand);
            }
        }
    }
}

module xiao_geometry_2d(size_expand, radius_expand) {
    translate([xiao_center[0], xiao_center[1]])
        rounded_rect_2d(
            [xiao_size[0] + 2 * size_expand, xiao_size[1] + 2 * size_expand],
            xiao_corner + radius_expand
        );
}

module component_cluster_geometry_2d(size_expand, radius_expand) {
    union() {
        xiao_geometry_2d(size_expand, radius_expand);
        jst_geometry_2d(size_expand, radius_expand);
        wire_channel_geometry_2d(size_expand, radius_expand);
        battery_geometry_2d(size_expand, radius_expand);
    }
}

module aux_switch_geometry_2d(center, body_size, size_expand, radius_expand) {
    translate(center)
        rounded_rect_2d(
        [body_size[0] + 2 * size_expand, body_size[1] + 2 * size_expand],
        aux_switch_body_corner + radius_expand
    );
}

module electronics_cluster_geometry_2d(size_expand, radius_expand) {
    difference() {
        union() {
            xiao_geometry_2d(size_expand, radius_expand);

            hull() {
                translate([xiao_center[0] + 1.5, xiao_center[1] + xiao_size[1] / 2 - 1.0])
                    rounded_rect_2d(
                        [electronics_wire_link_size[0] + 2 * size_expand,
                         electronics_wire_link_size[1] + 2 * size_expand],
                        electronics_wire_link_corner + radius_expand
                    );

                translate([mount_holes[3][0], mount_holes[3][1]])
                    rounded_rect_2d(
                        [electronics_wire_relief_size[0] + 2 * size_expand,
                         electronics_wire_relief_size[1] + 2 * size_expand],
                        electronics_wire_relief_corner + radius_expand
                    );
            }
        }

        translate([mount_holes[3][0], mount_holes[3][1]])
            circle(r = electronics_standoff_keepout_radius - size_expand);
    }
}

module battery_cluster_geometry_2d(
    size_expand,
    radius_expand,
    reset_aux_switch_body_size_local,
    power_aux_switch_body_size_local
) {
    difference() {
        union() {
            jst_geometry_2d(size_expand, radius_expand);
            wire_channel_geometry_2d(size_expand, radius_expand);
            battery_geometry_2d(size_expand, radius_expand);

            aux_switch_geometry_2d(
                reset_switch_origin,
                reset_aux_switch_body_size_local,
                size_expand,
                radius_expand
            );

            aux_switch_geometry_2d(
                power_switch_origin,
                power_aux_switch_body_size_local,
                size_expand,
                radius_expand
            );

            hull() {
                translate([jst_center[0] + 3.0, jst_center[1] + 4.0])
                    rounded_rect_2d(
                        [battery_standoff_link_size[0] + 2 * size_expand,
                         battery_standoff_link_size[1] + 2 * size_expand],
                        battery_standoff_link_corner + radius_expand
                    );

                translate([mount_holes[3][0], mount_holes[3][1]])
                    rounded_rect_2d(
                        [battery_standoff_relief_size[0] + 2 * size_expand,
                         battery_standoff_relief_size[1] + 2 * size_expand],
                        battery_standoff_relief_corner + radius_expand
                    );
            }

        }

        translate([mount_holes[3][0], mount_holes[3][1]])
            circle(r = battery_standoff_keepout_radius - size_expand);
    }
}

module pod_cavity_geometry_2d(side, shell) {
    intersection() {
        component_pod_geometry_2d(0, 0);

        if (side == "electronics") {
            electronics_cluster_geometry_2d(1.6, 1.6);
        } else if (side == "battery") {
            battery_cluster_geometry_2d(
                1.0,
                1.0,
                shell == "top" ? reset_cutout_size : aux_switch_body_size,
                shell == "top" ? power_cutout_size : aux_switch_body_size
            );
        }
    }
}

module component_pod_geometry_2d(size_expand, radius_expand) {
    offset(delta = size_expand)
        offset(r = component_pod_turn_radius + radius_expand)
            offset(delta = -(component_pod_turn_radius + radius_expand))
                intersection() {
                    outer_outline_2d();

                    polygon(points = [
                        [component_pod_inner_x, component_pod_top_y],
                        [component_pod_outer_x + component_pod_mask_pad, component_pod_top_y],
                        [component_pod_outer_x + component_pod_mask_pad,
                         component_pod_bottom_end_y + component_pod_mask_pad],
                        [component_pod_bottom_end_x, component_pod_bottom_end_y],
                        [component_pod_inner_x, component_pod_turn_y],
                    ]);
                }
}

module top_component_pod_outer_2d(size_expand, radius_expand) {
    top_component_pod_inner_x = component_pod_inner_x + top_component_pod_keycap_side_inset_x;
    top_component_pod_bottom_end_x = component_pod_bottom_end_x + top_component_pod_keycap_bottom_inset_x;
    top_component_pod_bottom_end_y = component_pod_bottom_end_y - top_component_pod_keycap_bottom_raise_y;
    top_component_pod_turn_y =
        top_component_pod_bottom_end_y
        - component_pod_bottom_edge_slope
        * (top_component_pod_inner_x - top_component_pod_bottom_end_x);

    offset(delta = size_expand)
        offset(r = component_pod_turn_radius + radius_expand)
            offset(delta = -(component_pod_turn_radius + radius_expand))
                intersection() {
                    outer_outline_2d();

                    polygon(points = [
                        [top_component_pod_inner_x, component_pod_top_y],
                        [component_pod_outer_x + component_pod_mask_pad, component_pod_top_y],
                        [component_pod_outer_x + component_pod_mask_pad,
                         top_component_pod_bottom_end_y + component_pod_mask_pad],
                        [top_component_pod_bottom_end_x, top_component_pod_bottom_end_y],
                        [top_component_pod_inner_x, top_component_pod_turn_y],
                    ]);
                }
}

module right_edge_window_2d(pos, size) {
    translate(pos)
        square([edge_exit_x + edge_exit_width - pos[0], size[1]]);
}

module aux_edge_window_2d(pos, size) {
    translate(pos)
        square([edge_exit_x + aux_edge_exit_width - pos[0], size[1]]);
}

module shared_aux_recess_2d() {
    union() {
        aux_edge_window_2d(reset_cutout_pos, reset_cutout_size);
        aux_edge_window_2d(power_cutout_pos, power_cutout_size);
    }
}

module shared_aux_outer_relief_2d() {
    connector_top_y = reset_cutout_pos[1] + reset_cutout_size[1] + aux_outer_relief_expand;
    connector_bottom_y = power_cutout_pos[1] - aux_outer_relief_expand;

    union() {
        offset(delta = aux_outer_relief_expand)
            aux_edge_window_2d(reset_cutout_pos, reset_cutout_size);

        offset(delta = aux_outer_relief_expand)
            aux_edge_window_2d(power_cutout_pos, power_cutout_size);

        if (connector_bottom_y > connector_top_y)
            translate([edge_exit_x - aux_outer_relief_depth, connector_top_y])
                square([
                    aux_outer_relief_depth + aux_edge_exit_width,
                    connector_bottom_y - connector_top_y,
                ]);
    }
}

module aux_outer_relief_2d() {
    if (use_shared_aux_recess) {
        shared_aux_outer_relief_2d();
    } else {
        offset(delta = aux_outer_relief_expand)
            union() {
                aux_edge_window_2d(reset_cutout_pos, reset_cutout_size);
                aux_edge_window_2d(power_cutout_pos, power_cutout_size);
            }
    }
}

module screw_holes_3d(z0, height) {
    for (i = [0 : len(mount_holes) - 1]) {
        if (mount_hole_screws[i]) {
            hole = mount_holes[i];
            translate([hole[0], hole[1], z0])
                cylinder(h = height, r = screw_clearance_radius);
        }
    }
}

module screw_head_recesses_3d() {
    for (i = [0 : len(mount_holes) - 1]) {
        if (mount_hole_screws[i]) {
            hole = mount_holes[i];
            translate([hole[0], hole[1], top_plate_thickness - screw_head_depth])
                cylinder(h = screw_head_depth + 0.1, r = screw_head_radius);
        }
    }
}

module nut_traps_3d() {
    nut_radius = nut_flat / sqrt(3);

    for (i = [0 : len(mount_holes) - 1]) {
        if (mount_hole_screws[i]) {
            hole = mount_holes[i];
            translate([hole[0], hole[1], -bottom_extra_depth - 0.1])
                linear_extrude(height = nut_depth + 0.2)
                    rotate(30)
                        circle(r = nut_radius, $fn = 6);
        }
    }
}

module standoffs_3d() {
    for (i = [0 : len(mount_holes) - 1]) {
        hole = mount_holes[i];
        standoff_r = standoff_radii[i];
        standoff_top_z = bottom_floor + standoff_height;
        standoff_z0 = -bottom_extra_depth - standoff_overlap;
        standoff_total_height = standoff_top_z - standoff_z0;

        translate([hole[0], hole[1], standoff_z0])
            if (mount_hole_screws[i]) {
                difference() {
                    cylinder(h = standoff_total_height, r = standoff_r);
                    translate([0, 0, -0.1])
                        cylinder(h = standoff_total_height + 0.2, r = screw_clearance_radius);
                }
            } else {
                cylinder(h = standoff_total_height, r = standoff_r);
            }
    }
}

module battery_geometry_2d(size_expand, radius_expand) {
    translate([battery_center[0], battery_center[1]])
        rounded_rect_2d(
            [battery_size[0] + 2 * size_expand, battery_size[1] + 2 * size_expand],
            battery_corner + radius_expand
        );
}

module jst_geometry_2d(size_expand, radius_expand) {
    translate(kicad_jst_at)
        rotate(-kicad_jst_rotation)
            translate([
                jst_outline_local_pos[0] + jst_size[0] / 2,
                jst_outline_local_pos[1] + jst_size[1] / 2,
            ])
                rounded_rect_2d(
                    [jst_size[0] + 2 * size_expand, jst_size[1] + 2 * size_expand],
                    jst_corner + radius_expand
                );
}

module jst_post_relief_geometry_2d(size_expand = 0, radius_expand = 0) {
    translate(kicad_jst_at)
        rotate(-kicad_jst_rotation)
            rounded_rect_2d(
                [
                    jst_post_relief_size[0] + 2 * size_expand,
                    jst_post_relief_size[1] + 2 * size_expand,
                ],
                jst_post_relief_corner + radius_expand
            );
}

module jst_opposite_relief_geometry_2d(size_expand = 0, radius_expand = 0) {
    anchor = [
        (kicad_jst_at[0] + kicad_xiao_at[0]) / 2,
        (kicad_jst_at[1] + kicad_xiao_at[1]) / 2,
    ];
    bridge_delta = [anchor[0] - kicad_jst_at[0], anchor[1] - kicad_jst_at[1]];
    bridge_length = sqrt(bridge_delta[0] * bridge_delta[0] + bridge_delta[1] * bridge_delta[1]);
    bridge_center = [
        (kicad_jst_at[0] + anchor[0]) / 2,
        (kicad_jst_at[1] + anchor[1]) / 2,
    ];
    bridge_rotation = atan2(bridge_delta[1], bridge_delta[0]);

    union() {
        jst_post_relief_geometry_2d(size_expand, radius_expand);

        oriented_rounded_rect_2d(
            bridge_center,
            [
                bridge_length + jst_opposite_relief_link_size[0] + 2 * size_expand,
                jst_opposite_relief_link_size[1] + 2 * size_expand,
            ],
            jst_opposite_relief_link_corner + radius_expand,
            bridge_rotation
        );

        translate(anchor)
            rounded_rect_2d(
                [
                    jst_opposite_relief_link_size[0] + 2 * size_expand,
                    jst_opposite_relief_link_size[1] + 2 * size_expand,
                ],
                jst_opposite_relief_link_corner + radius_expand
            );
    }
}

module wire_channel_geometry_2d(size_expand, radius_expand) {
    hull() {
        translate([jst_center[0] + 1.8, jst_center[1] + 3.5])
            rounded_rect_2d(
                [5.0 + 2 * size_expand, 5.0 + 2 * size_expand],
                wire_channel_corner + radius_expand
            );

        translate([wire_channel_center[0], wire_channel_center[1]])
            rounded_rect_2d(
                [wire_channel_size[0] + 2 * size_expand, wire_channel_size[1] + 2 * size_expand],
                wire_channel_corner + radius_expand
            );

        translate([battery_center[0] - 1.0, battery_center[1] - 10.0])
            rounded_rect_2d(
                [5.0 + 2 * size_expand, 6.0 + 2 * size_expand],
                wire_channel_corner + radius_expand
            );
    }
}

module xiao_model_geometry_2d() {
    oriented_rounded_rect_2d(
        kicad_xiao_at,
        xiao_model_board_size,
        xiao_model_board_corner,
        kicad_xiao_rotation
    );
}

module battery_model_geometry_2d() {
    translate([battery_center[0], battery_center[1]])
        rounded_rect_2d(battery_model_size, battery_model_corner);
}

module jst_model_geometry_2d() {
    translate(kicad_jst_at)
        rotate(-kicad_jst_rotation)
            translate([
                jst_outline_local_pos[0] + jst_model_size[0] / 2,
                jst_outline_local_pos[1] + jst_model_size[1] / 2,
            ])
                rounded_rect_2d(jst_model_size, jst_model_corner);
}

module reset_switch_model_geometry_2d() {
    translate(kicad_reset_switch_at)
        // The side-actuated switch should face the case wall, not the PCB interior.
        rotate(kicad_reset_switch_rotation + 180)
            union() {
                rounded_rect_2d(reset_switch_body_size, reset_switch_body_corner);
                translate(reset_switch_actuator_offset)
                    rounded_rect_2d(reset_switch_actuator_size, 0.3);
            }
}

module power_switch_model_geometry_2d() {
    translate(kicad_power_switch_at)
        rotate(kicad_power_switch_rotation + 180)
            union() {
                rounded_rect_2d(power_switch_body_size, power_switch_body_corner);
                translate(power_switch_slider_offset)
                    rounded_rect_2d(power_switch_slider_size, 0.4);
            }
}

module face_component_3d(face, height) {
    translate([0, 0, face_component_z(face, height)])
        linear_extrude(height = height)
            children();
}

module pcb_model_3d() {
    translate([0, 0, pcb_bottom_z()])
        linear_extrude(height = pcb_thickness)
            difference() {
                board_outline_2d();

                for (hole = mount_holes) {
                    translate(hole)
                        circle(r = mount_hole_radius);
                }
            }
}

module xiao_model_3d(face) {
    face_component_3d(face, xiao_model_total_height)
        xiao_model_geometry_2d();

    face_component_3d(face, xiao_usb_model_height)
            translate(kicad_xiao_at)
            rotate(kicad_xiao_rotation)
                translate([
                    xiao_usb_overhang_pos[0] + xiao_usb_overhang_size[0] / 2,
                    xiao_usb_overhang_pos[1] + xiao_usb_overhang_size[1] / 2,
                ])
                    rounded_rect_2d(xiao_usb_overhang_size, 0.8);
}

module xiao_model_mesh_local() {
    // The official Seeed STEP uses [length, thickness, width] axes. Remap that
    // into the case's [x, y, z] board coordinates and shift to the XIAO origin.
    multmatrix([
        [0, 0, 1, xiao_model_mesh_translate[0]],
        [1, 0, 0, xiao_model_mesh_translate[1]],
        [0, 1, 0, xiao_model_mesh_translate[2]],
        [0, 0, 0, 1],
    ])
        xiao_nrf52840_parts();
}

module xiao_official_model_3d(face) {
    if (face == "top") {
        translate([kicad_xiao_at[0], kicad_xiao_at[1], pcb_top_z()])
            rotate([0, 0, kicad_xiao_rotation + 180])
                xiao_model_mesh_local();
    } else {
        translate([kicad_xiao_at[0], kicad_xiao_at[1], pcb_bottom_z()])
            rotate([0, 0, kicad_xiao_rotation])
                translate(xiao_bottom_mesh_offset)
                    rotate([0, 0, 180])
                    mirror([0, 0, 1])
                        xiao_model_mesh_local();
    }
}

module battery_model_3d(face) {
    face_component_3d(face, battery_model_height)
        battery_model_geometry_2d();
}

module jst_model_3d(face) {
    face_component_3d(face, jst_model_height)
        jst_model_geometry_2d();
}

module reset_switch_body_geometry_2d() {
    translate(kicad_reset_switch_at)
        rotate(kicad_reset_switch_rotation + 180)
            rounded_rect_2d(reset_switch_body_size, reset_switch_body_corner);
}

module power_switch_body_geometry_2d() {
    translate(kicad_power_switch_at)
        rotate(kicad_power_switch_rotation + 180)
            rounded_rect_2d(power_switch_body_size, power_switch_body_corner);
}

module reset_switch_body_3d() {
    face_component_3d(battery_side, reset_switch_body_height)
        reset_switch_body_geometry_2d();
}

module power_switch_body_3d() {
    face_component_3d(battery_side, power_switch_body_height)
        power_switch_body_geometry_2d();
}

module jst_post_relief_assembly_3d(face) {
    face_component_3d(face, jst_post_relief_height)
        jst_post_relief_geometry_2d(
            jst_post_relief_clearance,
            jst_post_relief_clearance
        );
}

module jst_joined_opposite_relief_assembly_3d(face) {
    face_component_3d(face, jst_top_opposite_relief_height)
        jst_opposite_relief_geometry_2d(
            jst_post_relief_clearance,
            jst_post_relief_clearance
        );
}

module bottom_jst_opposite_relief_3d() {
}

module top_jst_opposite_relief_3d() {
    translate([0, 0, -(bottom_floor + bottom_inner_height)])
        jst_joined_opposite_relief_assembly_3d("top");
}

module reset_switch_model_3d() {
    face_component_3d(
        battery_side,
        reset_switch_body_height
    )
        reset_switch_model_geometry_2d();
}

module power_switch_model_3d() {
    face_component_3d(
        battery_side,
        power_switch_body_height
    )
        power_switch_model_geometry_2d();
}

module component_models_3d() {
    color([0.12, 0.39, 0.19])
        pcb_model_3d();

    color([0.08, 0.08, 0.08])
        xiao_official_model_3d(kicad_layer_face(kicad_xiao_layer));

    color([0.88, 0.78, 0.28])
        battery_model_3d(battery_side);

    color([0.96, 0.96, 0.96])
        // The reversible PCB mounts the JST on the battery side, even though
        // the footprint layer in KiCad is fixed.
        jst_model_3d(battery_side);

    color([0.28, 0.28, 0.31])
        reset_switch_model_3d();

    color([0.28, 0.28, 0.31])
        power_switch_model_3d();
}

module xiao_reference_model_3d(face) {
    color([0.9, 0.1, 0.1, 0.35])
        face_component_3d(face, 0.4)
            xiao_geometry_2d(0, 0);
}

module optional_component_models_3d() {
    if (show_components) {
        component_models_3d();

        if (show_xiao_reference) {
            xiao_reference_model_3d(kicad_layer_face(kicad_xiao_layer));
        }
    }
}

module components_only_models_3d() {
    component_models_3d();

    if (show_xiao_reference) {
        xiao_reference_model_3d(kicad_layer_face(kicad_xiao_layer));
    }
}

module pod_adjacent_keycap_bounds_3d(size_expand = 0) {
    translate([0, 0, top_plate_thickness + 0.01])
        linear_extrude(height = choc_keycap_check_height)
            pod_adjacent_keycap_bounds_2d(size_expand);
}

module keycap_clearance_overlap_3d() {
    intersection() {
        top_shell(false);
        pod_adjacent_keycap_bounds_3d(keycap_clearance_tolerance);
    }
}

module keycap_clearance_overlap_footprint_3d() {
    linear_extrude(height = 1)
        intersection() {
            top_component_pod_outer_2d(0, 0);
            pod_adjacent_keycap_bounds_2d(keycap_clearance_tolerance);
        }
}

module top_battery_cavity_outside_pod_footprint_3d() {
    linear_extrude(height = 1)
        difference() {
            battery_geometry_2d(battery_clearance, battery_clearance);
            top_component_pod_outer_2d(0, 0);
        }
}

module top_jst_cavity_outside_pod_footprint_3d() {
    linear_extrude(height = 1)
        difference() {
            jst_geometry_2d(battery_clearance, battery_clearance);
            top_component_pod_outer_2d(0, 0);
        }
}

module top_jst_model_outside_pod_footprint_3d() {
    linear_extrude(height = 1)
        difference() {
            jst_model_geometry_2d();
            top_component_pod_outer_2d(0, 0);
        }
}

module jst_opposite_relief_overlap_3d() {
    opposite_face = battery_side == "top" ? "bottom" : "top";

    intersection() {
        if (opposite_face == "bottom") {
            bottom_shell();
        } else {
            translate([0, 0, bottom_floor + bottom_inner_height])
                top_shell(false);
        }

        jst_post_relief_assembly_3d(opposite_face);
    }
}

module aux_switch_body_overlap_3d() {
    intersection() {
        if (battery_side == "top") {
            translate([0, 0, bottom_floor + bottom_inner_height])
                top_shell(false);
        } else {
            bottom_shell();
        }

        union() {
            reset_switch_body_3d();
            power_switch_body_3d();
        }
    }
}

module top_wire_cavity_outside_pod_footprint_3d() {
    linear_extrude(height = 1)
        difference() {
            wire_channel_geometry_2d(battery_clearance, battery_clearance);
            top_component_pod_outer_2d(0, 0);
        }
}

module top_keycap_clearance_view() {
    color([0.72, 0.70, 0.67, 0.8])
        top_shell(false);

    color([0.15, 0.45, 0.95, 0.2])
        pod_adjacent_keycap_bounds_3d();

    color([0.95, 0.15, 0.15, 0.85])
        keycap_clearance_overlap_3d();
}

module bottom_battery_blister_3d() {
    translate([0, 0, -battery_blister_height])
        linear_extrude(height = battery_blister_height)
            battery_geometry_2d(battery_clearance + battery_blister_margin, battery_blister_margin);
}

module bottom_component_pod_blister_3d() {
    translate([0, 0, -component_pod_blister_height])
        linear_extrude(height = component_pod_blister_height)
            component_pod_geometry_2d(0, 0);
}

module bottom_component_pod_cavity_2d() {
    intersection() {
        pod_cavity_geometry_2d(
            electronics_side == "bottom" ? "electronics" :
            battery_side == "bottom" ? "battery" :
            "none",
            "bottom"
        );

        closed_shell_safe_region_2d();
    }
}

module bottom_component_pod_cavity_3d() {
    translate([0, 0, -bottom_extra_depth + component_pod_roof_thickness])
        linear_extrude(height = bottom_floor + bottom_extra_depth - component_pod_roof_thickness + 0.1)
            bottom_component_pod_cavity_2d();
}

module bottom_battery_cavity_3d() {
    translate([0, 0, -0.1])
        linear_extrude(height = battery_cavity_height + 0.1)
            battery_geometry_2d(battery_clearance, battery_clearance);
}

module bottom_jst_blister_3d() {
    translate([0, 0, -jst_blister_height])
        linear_extrude(height = jst_blister_height)
            jst_geometry_2d(battery_clearance + battery_blister_margin, battery_blister_margin);
}

module bottom_jst_cavity_3d() {
    translate([0, 0, -0.1])
        linear_extrude(height = jst_cavity_height + 0.1)
            jst_geometry_2d(battery_clearance, battery_clearance);
}

module bottom_wire_blister_3d() {
    translate([0, 0, -wire_channel_blister_height])
        linear_extrude(height = wire_channel_blister_height)
            wire_channel_geometry_2d(battery_clearance + battery_blister_margin, battery_blister_margin);
}

module bottom_wire_cavity_3d() {
    translate([0, 0, -0.1])
        linear_extrude(height = wire_channel_cavity_height + 0.1)
            wire_channel_geometry_2d(battery_clearance, battery_clearance);
}

module top_battery_blister_3d() {
    translate([0, 0, top_plate_thickness])
        linear_extrude(height = battery_blister_height)
            battery_geometry_2d(battery_clearance + battery_blister_margin, battery_blister_margin);
}

module top_component_pod_blister_3d() {
    translate([0, 0, top_plate_thickness - top_shell_overlap])
        linear_extrude(height = component_pod_blister_height + top_shell_overlap)
            top_component_pod_outer_2d(0, 0);
}

module top_component_pod_cavity_2d() {
    intersection() {
        pod_cavity_geometry_2d(
            electronics_side == "top" ? "electronics" :
            battery_side == "top" ? "battery" :
            "none",
            "top"
        );

        offset(delta = -top_component_pod_wall_margin)
            top_component_pod_outer_2d(0, 0);
    }
}

module top_component_pod_cavity_3d() {
    translate([0, 0, -0.1])
        linear_extrude(height = top_plate_thickness + component_pod_blister_height - component_pod_roof_thickness + 0.1)
            top_component_pod_cavity_2d();
}

module top_battery_cavity_3d() {
    translate([0, 0, -0.1])
        linear_extrude(height = battery_cavity_height + 0.1)
            battery_geometry_2d(battery_clearance, battery_clearance);
}

module top_jst_blister_3d() {
    translate([0, 0, top_plate_thickness])
        linear_extrude(height = jst_blister_height)
            jst_geometry_2d(battery_clearance + battery_blister_margin, battery_blister_margin);
}

module top_jst_cavity_3d() {
    translate([0, 0, -0.1])
        linear_extrude(height = jst_cavity_height + 0.1)
            intersection() {
                jst_geometry_2d(battery_clearance, battery_clearance);

                offset(delta = -top_jst_wall_margin)
                    top_component_pod_outer_2d(0, 0);
            }
}

module top_wire_blister_3d() {
    translate([0, 0, top_plate_thickness])
        linear_extrude(height = wire_channel_blister_height)
            wire_channel_geometry_2d(battery_clearance + battery_blister_margin, battery_blister_margin);
}

module top_wire_cavity_3d() {
    translate([0, 0, -0.1])
        linear_extrude(height = wire_channel_cavity_height + 0.1)
            wire_channel_geometry_2d(battery_clearance, battery_clearance);
}

module bottom_xiao_cavity_2d() {
    intersection() {
        xiao_geometry_2d(0.5, 0.5);
        closed_shell_safe_region_2d();
    }
}

module bottom_xiao_cavity_3d() {
    translate([0, 0, -0.1])
        linear_extrude(height = xiao_cavity_height + 0.1)
            bottom_xiao_cavity_2d();
}

module bottom_electronics_cavity_outside_safe_wall_footprint_3d() {
    linear_extrude(height = 1)
        difference() {
            union() {
                if (electronics_side == "bottom") {
                    bottom_component_pod_cavity_2d();
                    bottom_xiao_cavity_2d();
                }

                if (battery_side == "bottom") {
                    bottom_component_pod_cavity_2d();
                }
            }

            closed_shell_safe_region_2d();
        }
}

module top_xiao_cavity_3d() {
    translate([0, 0, -0.1])
        linear_extrude(height = xiao_cavity_height + 0.1)
            xiao_geometry_2d(0.5, 0.5);
}

module top_status_led_hole_3d() {
    translate([status_led_center[0], status_led_center[1], top_plate_thickness - top_shell_overlap - 0.05])
        cylinder(h = component_pod_blister_height + top_shell_overlap + 0.1, r = status_led_hole_radius);
}

module top_recess_3d() {
    translate([0, 0, -top_shell_overlap - 0.05])
        linear_extrude(height = top_recess_depth + 0.05)
            top_recess_2d();
}

module usb_opening_3d(pos, z0, height) {
    inner_relief_pos = [
        pos[0] + (usb_cutout_size[0] - usb_inner_relief_width) / 2,
        pos[1],
    ];
    outer_throat_pos = [
        pos[0] + (usb_cutout_size[0] - usb_outer_throat_width) / 2,
        component_pod_top_y - usb_exit_margin,
    ];
    outer_throat_depth = pos[1] + usb_cutout_size[1] - outer_throat_pos[1];

    translate([0, 0, z0])
        linear_extrude(height = height)
            union() {
                rounded_rect_pos_2d(inner_relief_pos, [usb_inner_relief_width, usb_cutout_size[1]], 1.2);
                rounded_rect_pos_2d(outer_throat_pos, [usb_outer_throat_width, outer_throat_depth], usb_outer_throat_corner);
            }
}

module aux_openings_3d(z0, height) {
    translate([0, 0, z0])
        linear_extrude(height = height)
            if (use_shared_aux_recess) {
                shared_aux_recess_2d();
            } else {
                union() {
                    aux_edge_window_2d(reset_cutout_pos, reset_cutout_size);
                    aux_edge_window_2d(power_cutout_pos, power_cutout_size);
                }
            }
}

module aux_outer_relief_3d(z0, height) {
    relief_min_x = edge_exit_x - aux_outer_relief_depth;
    relief_min_y = component_pod_top_y - component_pod_mask_pad;
    relief_size_y = component_pod_bottom_end_y - component_pod_top_y + 2 * component_pod_mask_pad;
    relief_size_x = aux_edge_exit_width + aux_outer_relief_depth;

    intersection() {
        translate([0, 0, z0])
            linear_extrude(height = height)
                aux_outer_relief_2d();

        translate([relief_min_x, relief_min_y, z0 - 0.1])
            cube([
                relief_size_x,
                relief_size_y,
                height + 0.2,
            ]);
    }
}

module bottom_external_openings_3d() {
    if (electronics_side == "bottom") {
        usb_opening_3d(
            bottom_usb_cutout_pos,
            bottom_usb_opening_z,
            usb_opening_height
        );
    } else if (electronics_side == "top" && top_usb_bottom_shell_relief_height > 0) {
        usb_opening_3d(
            usb_cutout_pos,
            bottom_floor + bottom_inner_height - top_usb_bottom_shell_relief_height,
            top_usb_bottom_shell_relief_height + 0.1
        );
    }

    aux_outer_relief_3d(
        -bottom_extra_depth,
        bottom_extra_depth + bottom_floor + bottom_inner_height
    );

    if (battery_side == "bottom") {
        aux_openings_3d(bottom_floor, bottom_inner_height);
    }
}

module top_external_openings_3d() {
    if (electronics_side == "top") {
        usb_opening_3d(
            usb_cutout_pos,
            top_usb_opening_z - top_usb_opening_drop,
            usb_opening_height + top_usb_opening_extra_above
        );
    }

    aux_outer_relief_3d(
        -top_skirt_depth,
        top_skirt_depth + top_plate_thickness + component_pod_blister_height
    );

    if (battery_side == "top") {
        aux_openings_3d(-top_skirt_depth, top_aux_opening_height);
    }
}

module bottom_shell() {
    difference() {
        union() {
            translate([0, 0, -bottom_extra_depth])
                linear_extrude(height = bottom_extra_depth)
                    outer_outline_2d();

            linear_extrude(height = bottom_floor)
                outer_outline_2d();

            linear_extrude(height = bottom_floor + bottom_inner_height)
                difference() {
                    outer_outline_2d();
                    inner_cavity_2d();
                }

            translate([0, 0, bottom_floor + bottom_inner_height])
                linear_extrude(height = bottom_lip_height)
                    difference() {
                        bottom_lip_profile_2d();
                        inner_cavity_2d();
                    }

            standoffs_3d();
        }

        screw_holes_3d(
            -bottom_extra_depth - 0.1,
            bottom_extra_depth + bottom_floor + bottom_inner_height + 0.2
        );
        nut_traps_3d();
        if (electronics_side == "bottom" || battery_side == "bottom") {
            bottom_component_pod_cavity_3d();
        }
        if (electronics_side == "bottom") {
            bottom_xiao_cavity_3d();
        }
        if (battery_side == "bottom") {
            bottom_battery_cavity_3d();
            bottom_jst_cavity_3d();
            bottom_wire_cavity_3d();
        }
        bottom_external_openings_3d();
    }
}

module top_shell(include_skirt = false) {
    difference() {
        union() {
            if (include_skirt) {
                translate([0, 0, -top_skirt_depth])
                    linear_extrude(height = top_skirt_depth + top_shell_overlap)
                        difference() {
                            top_skirt_outer_2d();
                            top_skirt_inner_2d();
                        }
            }

            translate([0, 0, -top_shell_overlap])
                linear_extrude(height = top_plate_thickness + top_shell_overlap)
                    top_surface_2d();

            top_component_pod_blister_3d();
        }

        screw_holes_3d(-top_shell_overlap - 0.1, top_skirt_depth + top_plate_thickness + 0.2);
        screw_head_recesses_3d();
        if (!include_skirt) {
            top_recess_3d();
        }
        if (enable_top_component_pod_cavity && (electronics_side == "top" || battery_side == "top")) {
            top_component_pod_cavity_3d();
        }
        if (electronics_side == "top") {
            top_status_led_hole_3d();
        }
        if (battery_side == "top") {
            if (enable_top_battery_cavity) {
                top_battery_cavity_3d();
            }
            if (enable_top_jst_cavity) {
                top_jst_cavity_3d();
            }
            if (enable_top_wire_cavity) {
                top_wire_cavity_3d();
            }
        } else {
            top_jst_opposite_relief_3d();
        }
        top_external_openings_3d();
    }
}

module preview_assembly(include_top_skirt = false) {
    color([0.85, 0.82, 0.78])
        bottom_shell();

    optional_component_models_3d();

    translate([0, 0, bottom_floor + bottom_inner_height + preview_top_explode])
        union() {
            color([0.72, 0.70, 0.67, 0.8])
                top_shell(include_top_skirt);

            if (show_keycap_bounds) {
                color([0.15, 0.45, 0.95, 0.2])
                    pod_adjacent_keycap_bounds_3d();
            }
        }
}

module bottom_electronics_view() {
    cropped_electronics() {
        bottom_shell();
        optional_component_models_3d();
    }
}

module top_electronics_view() {
    cropped_electronics() {
        translate([0, 0, bottom_floor + bottom_inner_height])
            top_shell(false);
        optional_component_models_3d();
    }
}

module preview_electronics_view() {
    cropped_electronics()
        preview_assembly(false);
}

module components_electronics_view() {
    cropped_electronics()
        components_only_models_3d();
}

module electronics_crop_3d() {
    translate(electronics_crop_min)
        cube([
            electronics_crop_max[0] - electronics_crop_min[0],
            electronics_crop_max[1] - electronics_crop_min[1],
            electronics_crop_max[2] - electronics_crop_min[2],
        ]);
}

module cropped_electronics() {
    intersection() {
        children();
        electronics_crop_3d();
    }
}

if (part == "bottom") {
    handed()
        bottom_shell();
} else if (part == "bottom-electronics") {
    handed()
        bottom_electronics_view();
} else if (part == "top") {
    handed()
        top_shell();
} else if (part == "top-electronics") {
    handed()
        top_electronics_view();
} else if (part == "top-keycap-clearance") {
    handed()
        top_keycap_clearance_view();
} else if (part == "keycap-clearance-overlap") {
    handed()
        keycap_clearance_overlap_3d();
} else if (part == "keycap-clearance-overlap-footprint") {
    handed()
        keycap_clearance_overlap_footprint_3d();
} else if (part == "top-battery-cavity-outside-pod-footprint") {
    handed()
        top_battery_cavity_outside_pod_footprint_3d();
} else if (part == "top-jst-cavity-outside-pod-footprint") {
    handed()
        top_jst_cavity_outside_pod_footprint_3d();
} else if (part == "top-jst-model-outside-pod-footprint") {
    handed()
        top_jst_model_outside_pod_footprint_3d();
} else if (part == "jst-opposite-relief-overlap") {
    handed()
        jst_opposite_relief_overlap_3d();
} else if (part == "aux-switch-body-overlap") {
    handed()
        aux_switch_body_overlap_3d();
} else if (part == "top-wire-cavity-outside-pod-footprint") {
    handed()
        top_wire_cavity_outside_pod_footprint_3d();
} else if (part == "bottom-electronics-cavity-outside-safe-wall-footprint") {
    handed()
        bottom_electronics_cavity_outside_safe_wall_footprint_3d();
} else if (part == "preview-electronics") {
    handed()
        preview_electronics_view();
} else if (part == "components-electronics") {
    handed()
        components_electronics_view();
} else {
    handed()
        preview_assembly();
}
