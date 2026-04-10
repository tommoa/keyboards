#!/usr/bin/env python3

from __future__ import annotations

import argparse
import ast
import math
import re
import struct
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, cast


SCAD_NAMES = {
    "bottom_floor",
    "bottom_pcb_clearance",
    "bottom_wall_above_pcb",
    "component_pod_blister_height",
    "component_pod_roof_thickness",
    "component_pod_top_y",
    "bottom_usb_opening_z",
    "bottom_usb_cutout_toward_keys_shift",
    "pcb_thickness",
    "standoff_height",
    "top_plate_thickness",
    "top_usb_opening_drop",
    "top_usb_opening_extra_above",
    "top_usb_bottom_shell_relief_height",
    "top_shell_overlap",
    "usb_cutout_margin",
    "usb_cutout_outward_shift",
    "usb_exit_margin",
    "usb_inner_relief_width",
    "usb_opening_height",
    "usb_outer_throat_width",
    "xiao_bottom_mesh_offset",
    "xiao_center",
    "xiao_model_mesh_translate",
    "xiao_usb_overhang_pos",
    "xiao_usb_overhang_size",
}

COMPONENT_NAMES = {
    "kicad_xiao_at",
    "kicad_xiao_rotation",
}

USB_PART_BROAD_X_MARGIN = 4.0
USB_PART_BROAD_Y_MARGIN = 4.0
USB_PART_MIN_X_SPAN = 5.0
USB_PART_MIN_Y_SPAN = 4.0
USB_PART_FACE_EPSILON = 0.01
USB_PART_SELECTION_EPSILON = 0.001

# USB Type-C plug overmold clearance references the common 12.35 x 6.5 mm
# max cross-section used in the USB Type-C connector spec plug drawings.
STANDARD_USB_C_PLUG_WIDTH = 12.35
STANDARD_USB_C_PLUG_HEIGHT = 6.5


@dataclass
class Range:
    minimum: float
    maximum: float

    @property
    def size(self) -> float:
        return self.maximum - self.minimum


@dataclass
class OpeningReport:
    label: str
    source_part: str
    top_clearance: float
    bottom_clearance: float
    left_clearance: float
    right_clearance: float
    outward_clearance: float
    inward_clearance: float

    def worst_axis(self) -> tuple[str, float]:
        candidates = {
            "top": self.top_clearance,
            "bottom": self.bottom_clearance,
            "left": self.left_clearance,
            "right": self.right_clearance,
        }
        return min(candidates.items(), key=lambda item: item[1])


def ensure_generated_assets(scad_dir: Path) -> None:
    generated_dir = scad_dir / "generated"
    component_positions = generated_dir / "component_positions.scad"
    xiao_wrapper = generated_dir / "xiao-nrf52840-parts.scad"
    xiao_parts_dir = generated_dir / "xiao-nrf52840-parts"

    missing = []
    if not component_positions.exists():
        missing.append(str(component_positions))
    if not xiao_wrapper.exists():
        missing.append(str(xiao_wrapper))
    if not xiao_parts_dir.exists() or not any(xiao_parts_dir.glob("part_*.stl")):
        missing.append(str(xiao_parts_dir))

    if not missing:
        return

    message = [
        "Missing generated CAD analysis assets:",
        *[f"- {path}" for path in missing],
        "",
        "Regenerate them with:",
        "- python3 feral/case/scripts/extract_component_positions.py",
        '- uv run --with cadquery --with trimesh --with pymeshfix --with numpy python3 feral/case/scripts/convert_step_to_stl.py "path/to/XIAO-nRF52840.step" feral/case/cad/generated/xiao-nrf52840.stl --parts-dir feral/case/cad/generated/xiao-nrf52840-parts --wrapper feral/case/cad/generated/xiao-nrf52840-parts.scad',
    ]
    raise SystemExit("\n".join(message))


def parse_assignment_file(path: Path, names: set[str]) -> dict[str, object]:
    values: dict[str, object] = {}
    pattern = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+?);\s*$")

    for line in path.read_text().splitlines():
        match = pattern.match(line)
        if not match:
            continue

        name, raw_value = match.groups()
        if name not in names:
            continue

        raw_value = raw_value.split("//", 1)[0].strip()
        try:
            values[name] = ast.literal_eval(raw_value)
        except Exception as exc:
            if raw_value in values:
                values[name] = values[raw_value]
                continue
            raise ValueError(
                f"Could not parse {name} from {path}: {raw_value}"
            ) from exc

    missing = sorted(names - values.keys())
    if missing:
        raise ValueError(
            f"Missing required assignments in {path}: {', '.join(missing)}"
        )

    return values


def scalar(values: dict[str, object], name: str) -> float:
    return float(cast(Any, values[name]))


def vector(values: dict[str, object], name: str) -> list[float]:
    raw = values[name]
    if not isinstance(raw, list):
        raise ValueError(f"{name} is not a vector")
    return [float(item) for item in raw]


def rotate_xy(x: float, y: float, degrees: float) -> tuple[float, float]:
    radians = math.radians(degrees)
    cos_theta = math.cos(radians)
    sin_theta = math.sin(radians)
    return x * cos_theta - y * sin_theta, x * sin_theta + y * cos_theta


def parse_binary_stl(data: bytes) -> list[tuple[float, float, float]] | None:
    if len(data) < 84:
        return None

    triangle_count = struct.unpack_from("<I", data, 80)[0]
    expected_size = 84 + triangle_count * 50
    if len(data) != expected_size:
        return None

    vertices: list[tuple[float, float, float]] = []
    offset = 84
    for _ in range(triangle_count):
        values = struct.unpack_from("<12fH", data, offset)
        vertices.extend(
            [
                (values[3], values[4], values[5]),
                (values[6], values[7], values[8]),
                (values[9], values[10], values[11]),
            ]
        )
        offset += 50
    return vertices


def parse_ascii_stl(text: str) -> list[tuple[float, float, float]]:
    matches = re.findall(
        r"vertex\s+([-0-9.eE+]+)\s+([-0-9.eE+]+)\s+([-0-9.eE+]+)",
        text,
    )
    return [(float(x), float(y), float(z)) for x, y, z in matches]


def load_stl_vertices(path: Path) -> list[tuple[float, float, float]]:
    data = path.read_bytes()
    binary_vertices = parse_binary_stl(data)
    if binary_vertices is not None:
        return binary_vertices
    return parse_ascii_stl(data.decode("utf-8"))


def usb_cutout_position(values: dict[str, object]) -> list[float]:
    xiao_center = vector(values, "xiao_center")
    usb_overhang_pos = vector(values, "xiao_usb_overhang_pos")
    margin = scalar(values, "usb_cutout_margin")
    outward_shift = scalar(values, "usb_cutout_outward_shift")
    return [
        xiao_center[0] + usb_overhang_pos[0] - margin + outward_shift,
        xiao_center[1] + usb_overhang_pos[1] - margin,
    ]


def usb_cutout_size(values: dict[str, object]) -> list[float]:
    usb_overhang_size = vector(values, "xiao_usb_overhang_size")
    margin = scalar(values, "usb_cutout_margin")
    return [
        usb_overhang_size[0] + 2 * margin,
        usb_overhang_size[1] + 2 * margin,
    ]


def opening_position_for_hand(values: dict[str, object], hand: str) -> list[float]:
    pos = usb_cutout_position(values)
    if hand == "left":
        return pos
    if hand == "right":
        return [pos[0], pos[1] + scalar(values, "bottom_usb_cutout_toward_keys_shift")]
    raise ValueError(f"Unsupported hand: {hand}")


def opening_x_range_at_y(
    values: dict[str, object], pos: list[float], y: float
) -> Range | None:
    size = usb_cutout_size(values)
    inner_width = scalar(values, "usb_inner_relief_width")
    outer_width = scalar(values, "usb_outer_throat_width")
    outer_start_y = scalar(values, "component_pod_top_y") - scalar(
        values, "usb_exit_margin"
    )
    outer_end_y = pos[1] + size[1]
    inner_start_y = pos[1]
    inner_end_y = pos[1] + size[1]

    ranges: list[Range] = []
    if inner_start_y <= y <= inner_end_y:
        inner_x = pos[0] + (size[0] - inner_width) / 2
        ranges.append(Range(inner_x, inner_x + inner_width))

    if outer_start_y <= y <= outer_end_y:
        outer_x = pos[0] + (size[0] - outer_width) / 2
        ranges.append(Range(outer_x, outer_x + outer_width))

    if not ranges:
        return None

    return Range(
        min(item.minimum for item in ranges), max(item.maximum for item in ranges)
    )


def opening_z_range(values: dict[str, object], hand: str) -> Range:
    top_usb_opening_z = (
        scalar(values, "top_plate_thickness")
        - scalar(values, "top_shell_overlap")
        - 0.05
    )
    usb_opening_height = scalar(values, "usb_opening_height")
    bottom_inner_height = (
        scalar(values, "standoff_height")
        + scalar(values, "pcb_thickness")
        + scalar(values, "bottom_wall_above_pcb")
    )

    if hand == "left":
        shell_base = scalar(values, "bottom_floor") + bottom_inner_height
        local_bottom = top_usb_opening_z - scalar(values, "top_usb_opening_drop")
        return Range(
            shell_base + local_bottom,
            shell_base
            + local_bottom
            + usb_opening_height
            + scalar(values, "top_usb_opening_extra_above"),
        )

    if hand == "right":
        local_bottom = scalar(values, "bottom_usb_opening_z")
        return Range(local_bottom, local_bottom + usb_opening_height)

    raise ValueError(f"Unsupported hand: {hand}")


def cable_opening_z_range(values: dict[str, object], hand: str) -> Range:
    opening_z = opening_z_range(values, hand)
    if hand == "right":
        return opening_z

    shell_base = scalar(values, "bottom_floor") + (
        scalar(values, "standoff_height")
        + scalar(values, "pcb_thickness")
        + scalar(values, "bottom_wall_above_pcb")
    )
    relief_height = scalar(values, "top_usb_bottom_shell_relief_height")
    if relief_height <= 0:
        return Range(shell_base, opening_z.maximum)
    return Range(min(opening_z.minimum, shell_base - relief_height), opening_z.maximum)


def outer_throat_x_range(values: dict[str, object], opening_pos: list[float]) -> Range:
    opening_size = usb_cutout_size(values)
    outer_width = scalar(values, "usb_outer_throat_width")
    outer_x = opening_pos[0] + (opening_size[0] - outer_width) / 2
    return Range(outer_x, outer_x + outer_width)


def pcb_planes(values: dict[str, object]) -> tuple[float, float]:
    pcb_bottom_z = scalar(values, "bottom_floor") + scalar(values, "standoff_height")
    pcb_top_z = pcb_bottom_z + scalar(values, "pcb_thickness")
    return pcb_bottom_z, pcb_top_z


def local_mesh_vertices(
    values: dict[str, object], parts_dir: Path
) -> dict[str, list[tuple[float, float, float]]]:
    translate = vector(values, "xiao_model_mesh_translate")
    result: dict[str, list[tuple[float, float, float]]] = {}
    for path in sorted(parts_dir.glob("part_*.stl")):
        local_vertices: list[tuple[float, float, float]] = []
        for x_raw, y_raw, z_raw in load_stl_vertices(path):
            local_vertices.append(
                (z_raw + translate[0], x_raw + translate[1], y_raw + translate[2])
            )
        result[path.name] = local_vertices
    return result


def transform_vertices_for_hand(
    local_vertices: list[tuple[float, float, float]],
    values: dict[str, object],
    component_values: dict[str, object],
    hand: str,
) -> list[tuple[float, float, float]]:
    kicad_xiao_at = vector(component_values, "kicad_xiao_at")
    kicad_xiao_rotation = scalar(component_values, "kicad_xiao_rotation")
    xiao_bottom_mesh_offset = vector(values, "xiao_bottom_mesh_offset")
    pcb_bottom_z, pcb_top_z = pcb_planes(values)
    result: list[tuple[float, float, float]] = []

    for x_local, y_local, z_local in local_vertices:
        if hand == "left":
            x_rot, y_rot = rotate_xy(x_local, y_local, kicad_xiao_rotation + 180)
            result.append(
                (
                    kicad_xiao_at[0] + x_rot,
                    kicad_xiao_at[1] + y_rot,
                    pcb_top_z + z_local,
                )
            )
        elif hand == "right":
            x_rot, y_rot = rotate_xy(x_local, y_local, 180)
            x_rot += xiao_bottom_mesh_offset[0]
            y_rot += xiao_bottom_mesh_offset[1]
            z_bottom = -z_local + xiao_bottom_mesh_offset[2]
            x_final, y_final = rotate_xy(x_rot, y_rot, kicad_xiao_rotation)
            result.append(
                (
                    kicad_xiao_at[0] + x_final,
                    kicad_xiao_at[1] + y_final,
                    pcb_bottom_z + z_bottom,
                )
            )
        else:
            raise ValueError(f"Unsupported hand: {hand}")

    return result


def bounds(vertices: list[tuple[float, float, float]]) -> tuple[Range, Range, Range]:
    xs = [vertex[0] for vertex in vertices]
    ys = [vertex[1] for vertex in vertices]
    zs = [vertex[2] for vertex in vertices]
    return Range(min(xs), max(xs)), Range(min(ys), max(ys)), Range(min(zs), max(zs))


def select_usb_shell_vertices(
    parts: dict[str, list[tuple[float, float, float]]],
    values: dict[str, object],
    component_values: dict[str, object],
    hand: str,
) -> tuple[str, list[tuple[float, float, float]]]:
    opening_pos = opening_position_for_hand(values, hand)
    opening_size = usb_cutout_size(values)
    opening_z = opening_z_range(values, hand)
    outer_start_y = scalar(values, "component_pod_top_y") - scalar(
        values, "usb_exit_margin"
    )
    outer_end_y = opening_pos[1] + opening_size[1]
    pcb_bottom_z, pcb_top_z = pcb_planes(values)
    face_plane = pcb_top_z if hand == "left" else pcb_bottom_z

    best_name = ""
    best_vertices: list[tuple[float, float, float]] = []
    best_score = float("-inf")

    for name, local_vertices in parts.items():
        global_vertices = transform_vertices_for_hand(
            local_vertices, values, component_values, hand
        )
        if hand == "left":
            face_vertices = [
                vertex
                for vertex in global_vertices
                if vertex[2] > face_plane + USB_PART_FACE_EPSILON
            ]
        else:
            face_vertices = [
                vertex
                for vertex in global_vertices
                if vertex[2] < face_plane - USB_PART_FACE_EPSILON
            ]

        if not face_vertices:
            continue

        x_bounds, y_bounds, z_bounds = bounds(face_vertices)
        intersects = not (
            x_bounds.maximum < opening_pos[0] - USB_PART_BROAD_X_MARGIN
            or x_bounds.minimum
            > opening_pos[0] + opening_size[0] + USB_PART_BROAD_X_MARGIN
            or y_bounds.maximum < outer_start_y - USB_PART_SELECTION_EPSILON
            or y_bounds.minimum > outer_end_y + USB_PART_BROAD_Y_MARGIN
            or z_bounds.maximum < opening_z.minimum - USB_PART_SELECTION_EPSILON
            or z_bounds.minimum > opening_z.maximum + USB_PART_BROAD_Y_MARGIN
        )
        if not intersects:
            continue
        if x_bounds.size < USB_PART_MIN_X_SPAN or y_bounds.size < USB_PART_MIN_Y_SPAN:
            continue

        if hand == "left":
            score = z_bounds.maximum - face_plane
        else:
            score = face_plane - z_bounds.minimum

        if score > best_score:
            best_score = score
            best_name = name
            best_vertices = face_vertices

    if not best_vertices:
        raise RuntimeError(f"Could not isolate USB shell vertices for {hand}")

    return best_name, best_vertices


def analyze_hand(
    parts: dict[str, list[tuple[float, float, float]]],
    values: dict[str, object],
    component_values: dict[str, object],
    hand: str,
    shell_only: bool,
) -> OpeningReport:
    source_part, shell_vertices = select_usb_shell_vertices(
        parts, values, component_values, hand
    )
    opening_pos = opening_position_for_hand(values, hand)
    opening_size = usb_cutout_size(values)
    opening_z = opening_z_range(values, hand)
    outer_start_y = scalar(values, "component_pod_top_y") - scalar(
        values, "usb_exit_margin"
    )
    outer_end_y = opening_pos[1] + opening_size[1]

    in_depth_vertices = [
        vertex
        for vertex in shell_vertices
        if outer_start_y - USB_PART_SELECTION_EPSILON
        <= vertex[1]
        <= outer_end_y + USB_PART_SELECTION_EPSILON
    ]
    if not in_depth_vertices:
        raise RuntimeError(
            f"No USB shell vertices remained inside opening depth for {hand}"
        )

    x_bounds, y_bounds, z_bounds = bounds(in_depth_vertices)
    effective_y = Range(
        y_bounds.minimum if shell_only else outer_start_y,
        min(y_bounds.maximum, outer_end_y),
    )

    sample_count = 401
    left_clearance = float("inf")
    right_clearance = float("inf")
    for index in range(sample_count):
        y = effective_y.minimum + effective_y.size * index / (sample_count - 1)
        x_range = opening_x_range_at_y(values, opening_pos, y)
        if x_range is None:
            left_clearance = float("-inf")
            right_clearance = float("-inf")
            break

        left_clearance = min(left_clearance, x_bounds.minimum - x_range.minimum)
        right_clearance = min(right_clearance, x_range.maximum - x_bounds.maximum)

    return OpeningReport(
        label="left/top" if hand == "left" else "right/bottom",
        source_part=source_part,
        top_clearance=opening_z.maximum - z_bounds.maximum,
        bottom_clearance=z_bounds.minimum - opening_z.minimum,
        left_clearance=left_clearance,
        right_clearance=right_clearance,
        outward_clearance=y_bounds.minimum - outer_start_y if shell_only else 0.0,
        inward_clearance=outer_end_y - y_bounds.maximum,
    )


def analyze_cable_fit(
    parts: dict[str, list[tuple[float, float, float]]],
    values: dict[str, object],
    component_values: dict[str, object],
    hand: str,
    cable_width: float,
    cable_height: float,
) -> OpeningReport:
    source_part, shell_vertices = select_usb_shell_vertices(
        parts, values, component_values, hand
    )
    opening_pos = opening_position_for_hand(values, hand)
    opening_size = usb_cutout_size(values)
    opening_z = cable_opening_z_range(values, hand)
    outer_start_y = scalar(values, "component_pod_top_y") - scalar(
        values, "usb_exit_margin"
    )
    outer_end_y = opening_pos[1] + opening_size[1]

    outer_vertices = [
        vertex
        for vertex in shell_vertices
        if outer_start_y - USB_PART_SELECTION_EPSILON
        <= vertex[1]
        <= outer_end_y + USB_PART_SELECTION_EPSILON
    ]
    if not outer_vertices:
        raise RuntimeError(
            f"No USB shell vertices remained inside the cable throat for {hand}"
        )

    shell_x_bounds, _, shell_z_bounds = bounds(outer_vertices)
    shell_x_center = (shell_x_bounds.minimum + shell_x_bounds.maximum) / 2
    shell_z_center = (shell_z_bounds.minimum + shell_z_bounds.maximum) / 2
    cable_x = Range(
        shell_x_center - cable_width / 2,
        shell_x_center + cable_width / 2,
    )
    cable_z = Range(
        shell_z_center - cable_height / 2,
        shell_z_center + cable_height / 2,
    )
    throat_x = outer_throat_x_range(values, opening_pos)

    return OpeningReport(
        label=("left/top" if hand == "left" else "right/bottom") + " cable",
        source_part=f"{source_part} centered {cable_width:.2f} x {cable_height:.2f} mm envelope",
        top_clearance=opening_z.maximum - cable_z.maximum,
        bottom_clearance=cable_z.minimum - opening_z.minimum,
        left_clearance=cable_x.minimum - throat_x.minimum,
        right_clearance=throat_x.maximum - cable_x.maximum,
        outward_clearance=0.0,
        inward_clearance=0.0,
    )


def format_report(report: OpeningReport, min_clearance: float) -> str:
    worst_axis, worst_value = report.worst_axis()
    status = "PASS" if worst_value + 1e-9 >= min_clearance else "FAIL"
    return "\n".join(
        [
            f"{report.label}: {status}",
            f"  source: {report.source_part}",
            f"  top: {report.top_clearance:.3f} mm",
            f"  bottom: {report.bottom_clearance:.3f} mm",
            f"  left: {report.left_clearance:.3f} mm",
            f"  right: {report.right_clearance:.3f} mm",
            f"  outward: {report.outward_clearance:.3f} mm",
            f"  inward: {report.inward_clearance:.3f} mm",
            f"  worst: {worst_axis} {worst_value:.3f} mm",
        ]
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check analytical USB shell and cable-fit margins for the Feral case"
    )
    parser.add_argument(
        "--hand",
        dest="hands",
        action="append",
        choices=["left", "right"],
        help="Hand to check; repeat to check multiple hands. Defaults to both.",
    )
    parser.add_argument(
        "--min-clearance",
        type=float,
        default=0.3,
        help="Required minimum clearance in mm for pass/fail reporting",
    )
    parser.add_argument(
        "--usb-cable-width",
        type=float,
        default=STANDARD_USB_C_PLUG_WIDTH,
        help="USB-C plug overmold width to validate against in mm",
    )
    parser.add_argument(
        "--usb-cable-height",
        type=float,
        default=STANDARD_USB_C_PLUG_HEIGHT,
        help="USB-C plug overmold height to validate against in mm",
    )
    parser.add_argument(
        "--skip-shell-fit",
        action="store_true",
        help="Skip the existing XIAO shell clearance check",
    )
    parser.add_argument(
        "--skip-cable-fit",
        action="store_true",
        help="Skip the USB-C cable plug envelope check",
    )
    parser.add_argument(
        "--shell-only",
        action="store_true",
        help="Inspect the board-side shell only, without extending its envelope to the outer case edge",
    )
    args = parser.parse_args()

    scad_dir = Path(__file__).resolve().parents[1] / "cad"
    ensure_generated_assets(scad_dir)
    values = parse_assignment_file(scad_dir / "feral_case.scad", SCAD_NAMES)
    component_values = parse_assignment_file(
        scad_dir / "generated" / "component_positions.scad", COMPONENT_NAMES
    )
    parts = local_mesh_vertices(values, scad_dir / "generated" / "xiao-nrf52840-parts")
    hands = args.hands or ["left", "right"]

    reports: list[OpeningReport] = []
    for hand in hands:
        if not args.skip_shell_fit:
            reports.append(
                analyze_hand(parts, values, component_values, hand, args.shell_only)
            )
        if not args.skip_cable_fit:
            reports.append(
                analyze_cable_fit(
                    parts,
                    values,
                    component_values,
                    hand,
                    args.usb_cable_width,
                    args.usb_cable_height,
                )
            )

    if not reports:
        raise SystemExit("No checks selected; remove a --skip-* flag")

    print("\n\n".join(format_report(report, args.min_clearance) for report in reports))

    return (
        0
        if all(
            report.worst_axis()[1] + 1e-9 >= args.min_clearance for report in reports
        )
        else 1
    )


if __name__ == "__main__":
    sys.exit(main())
