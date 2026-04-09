#!/usr/bin/env python3

from __future__ import annotations

import argparse
import ast
import math
import re
from dataclasses import dataclass
from pathlib import Path


@dataclass
class Pad:
    number: str
    pad_type: str
    shape: str
    x: float
    y: float
    rotation: float
    size_x: float
    size_y: float


@dataclass
class Footprint:
    name: str
    x: float
    y: float
    rotation: float
    pads: list[Pad]


def extract_footprint_blocks(text: str, footprint_name: str) -> list[str]:
    marker = f'(footprint "{footprint_name}"'
    blocks: list[str] = []
    start = 0

    while True:
        idx = text.find(marker, start)
        if idx == -1:
            return blocks

        depth = 0
        end = idx
        while end < len(text):
            char = text[end]
            if char == "(":
                depth += 1
            elif char == ")":
                depth -= 1
                if depth == 0:
                    blocks.append(text[idx : end + 1])
                    start = end + 1
                    break
            end += 1
        else:
            raise ValueError(f"Unterminated footprint block for {footprint_name}")


def parse_at(block: str) -> tuple[float, float, float]:
    match = re.search(r"\(at\s+([-0-9.]+)\s+([-0-9.]+)(?:\s+([-0-9.]+))?\)", block)
    if not match:
        raise ValueError("Missing footprint location")
    return float(match.group(1)), float(match.group(2)), float(match.group(3) or 0.0)


def parse_pads(block: str) -> list[Pad]:
    pads: list[Pad] = []
    pattern = re.compile(
        r"\(pad\s+\"([^\"]*)\"\s+(\S+)\s+(\S+)\s+"
        r"\(at\s+([-0-9.]+)\s+([-0-9.]+)(?:\s+([-0-9.]+))?\)\s+"
        r"\(size\s+([-0-9.]+)\s+([-0-9.]+)\)",
        re.DOTALL,
    )
    for match in pattern.finditer(block):
        pads.append(
            Pad(
                number=match.group(1),
                pad_type=match.group(2),
                shape=match.group(3),
                x=float(match.group(4)),
                y=float(match.group(5)),
                rotation=float(match.group(6) or 0.0),
                size_x=float(match.group(7)),
                size_y=float(match.group(8)),
            )
        )
    return pads


def parse_footprints(text: str, footprint_name: str) -> list[Footprint]:
    footprints: list[Footprint] = []
    for block in extract_footprint_blocks(text, footprint_name):
        x, y, rotation = parse_at(block)
        footprints.append(
            Footprint(
                name=footprint_name,
                x=x,
                y=y,
                rotation=rotation,
                pads=parse_pads(block),
            )
        )
    return footprints


def parse_scad_array(text: str, name: str):
    match = re.search(rf"\b{name}\s*=\s*(\[[^;]*\]);", text, re.DOTALL)
    if not match:
        raise ValueError(f"Missing `{name}` in SCAD file")
    return ast.literal_eval(match.group(1))


def transform_point(
    origin_x: float, origin_y: float, rotation_deg: float, x: float, y: float
) -> tuple[float, float]:
    angle = math.radians(rotation_deg)
    return (
        origin_x + x * math.cos(angle) - y * math.sin(angle),
        origin_y + x * math.sin(angle) + y * math.cos(angle),
    )


def pad_radius(pad: Pad) -> float:
    return math.hypot(pad.size_x / 2.0, pad.size_y / 2.0)


def clearance_report(pcb_path: Path, scad_path: Path) -> list[str]:
    pcb_text = pcb_path.read_text()
    scad_text = scad_path.read_text()

    mount_hole_footprints = parse_footprints(
        pcb_text, "MountingHole:MountingHole_2.2mm_M2"
    )
    if not mount_hole_footprints:
        raise ValueError("No M2 mounting holes found in PCB")

    mount_holes = parse_scad_array(scad_text, "mount_holes")
    standoff_radii = parse_scad_array(scad_text, "standoff_radii")
    if len(mount_holes) != len(standoff_radii):
        raise ValueError("mount_holes and standoff_radii length mismatch")

    hotswap_footprints = parse_footprints(pcb_text, "PG1350")
    if not hotswap_footprints:
        raise ValueError("No PG1350 footprints found in PCB")

    report: list[str] = []
    min_clearance = None
    worst_label = ""

    for index, (hole, radius) in enumerate(zip(mount_holes, standoff_radii), start=1):
        hole_x, hole_y = hole
        nearest = None

        for footprint in hotswap_footprints:
            for pad in footprint.pads:
                pad_x, pad_y = transform_point(
                    footprint.x, footprint.y, footprint.rotation, pad.x, pad.y
                )
                center_distance = math.hypot(pad_x - hole_x, pad_y - hole_y)
                pad_edge_distance = center_distance - pad_radius(pad)
                boss_clearance = pad_edge_distance - radius
                candidate = (
                    boss_clearance,
                    pad_edge_distance,
                    center_distance,
                    pad_x,
                    pad_y,
                    pad,
                    footprint,
                )
                if nearest is None or boss_clearance < nearest[0]:
                    nearest = candidate

        assert nearest is not None
        boss_clearance, _, center_distance, pad_x, pad_y, pad, footprint = nearest
        pad_label = pad.number if pad.number else "npth"
        report.append(
            "hole{index}: radius={radius:.3f} mm clearance={clearance:.3f} mm "
            "nearest {pad_label} {shape} at ({pad_x:.3f}, {pad_y:.3f}) "
            "from switch ({switch_x:.3f}, {switch_y:.3f}), center distance {center_distance:.3f} mm".format(
                index=index,
                radius=radius,
                clearance=boss_clearance,
                pad_label=pad_label,
                shape=pad.shape,
                pad_x=pad_x,
                pad_y=pad_y,
                switch_x=footprint.x,
                switch_y=footprint.y,
                center_distance=center_distance,
            )
        )
        if min_clearance is None or boss_clearance < min_clearance:
            min_clearance = boss_clearance
            worst_label = f"hole{index}"

    report.append(f"minimum clearance: {min_clearance:.3f} mm ({worst_label})")
    return report


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check Feral case standoff clearance to PG1350 hotswap footprint features"
    )
    parser.add_argument(
        "--pcb",
        type=Path,
        default=Path("feral/feral.kicad_pcb"),
        help="Path to the KiCad PCB file",
    )
    parser.add_argument(
        "--scad",
        type=Path,
        default=Path("feral/case/cad/feral_case.scad"),
        help="Path to the OpenSCAD case source",
    )
    args = parser.parse_args()

    for line in clearance_report(args.pcb, args.scad):
        print(line)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
