#!/usr/bin/env python3

from __future__ import annotations

import argparse
import ast
import re
import sys
from pathlib import Path
from typing import Any, cast


SCAD_NAMES = {
    "aux_switch_clearance",
    "aux_switch_opening_height",
    "bottom_aux_opening_z",
    "bottom_pcb_clearance",
    "bottom_floor",
    "bottom_wall_above_pcb",
    "joint_depth",
    "pcb_thickness",
    "power_switch_body_height",
    "reset_switch_body_height",
    "standoff_height",
    "top_skirt_depth",
    "top_aux_opening_z",
}


def parse_assignment_file(path: Path, names: set[str]) -> dict[str, object]:
    values: dict[str, object] = {}
    pattern = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+);\s*$", re.DOTALL)

    current: list[str] = []
    for raw_line in path.read_text().splitlines():
        line = raw_line.split("//", 1)[0].rstrip()
        if not line and not current:
            continue

        current.append(line)
        candidate = " ".join(part.strip() for part in current if part.strip())
        if not candidate.endswith(";"):
            continue

        match = pattern.match(candidate)
        current = []
        if not match:
            continue

        name, raw_value = match.groups()
        if name not in names:
            continue

        try:
            values[name] = ast.literal_eval(raw_value)
        except Exception as exc:
            if raw_value in values:
                values[name] = values[raw_value]
                continue
            try:
                values[name] = eval(
                    raw_value,
                    {"__builtins__": {}, "max": max, "min": min},
                    values,
                )
                continue
            except Exception:
                pass
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


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check switch-side opening height and placement against the switch body heights"
    )
    parser.add_argument(
        "--min-clearance",
        type=float,
        default=0.15,
        help="Minimum allowed body-to-opening clearance in mm",
    )
    parser.add_argument(
        "--max-clearance",
        type=float,
        default=0.3,
        help="Maximum allowed body-to-opening clearance in mm",
    )
    args = parser.parse_args()

    scad_path = Path(__file__).resolve().parents[1] / "cad" / "feral_case.scad"
    values = parse_assignment_file(scad_path, SCAD_NAMES)

    tallest = max(
        scalar(values, "reset_switch_body_height"),
        scalar(values, "power_switch_body_height"),
    )
    bottom_inner_height = (
        scalar(values, "bottom_pcb_clearance")
        + scalar(values, "pcb_thickness")
        + scalar(values, "bottom_wall_above_pcb")
    )
    pcb_bottom_z = scalar(values, "bottom_floor") + scalar(values, "standoff_height")
    pcb_top_z = pcb_bottom_z + scalar(values, "pcb_thickness")
    top_shell_base = scalar(values, "bottom_floor") + bottom_inner_height
    opening_height = scalar(values, "aux_switch_opening_height")

    reports = [
        (
            "left/bottom",
            scalar(values, "bottom_aux_opening_z"),
            scalar(values, "bottom_aux_opening_z") + opening_height,
            pcb_bottom_z - tallest,
            pcb_bottom_z,
        ),
        (
            "right/top",
            top_shell_base + scalar(values, "top_aux_opening_z"),
            top_shell_base + scalar(values, "top_aux_opening_z") + opening_height,
            pcb_top_z,
            pcb_top_z + tallest,
        ),
    ]

    ok = True
    for label, opening_min, opening_max, body_min, body_max in reports:
        lower_clearance = body_min - opening_min
        upper_clearance = opening_max - body_max
        status = (
            "PASS"
            if args.min_clearance <= lower_clearance <= args.max_clearance
            and args.min_clearance <= upper_clearance <= args.max_clearance
            else "FAIL"
        )
        if status == "FAIL":
            ok = False
        print(
            f"{label}: {status}\n"
            f"  opening z-range: {opening_min:.3f}..{opening_max:.3f} mm\n"
            f"  body z-range: {body_min:.3f}..{body_max:.3f} mm\n"
            f"  lower clearance: {lower_clearance:.3f} mm\n"
            f"  upper clearance: {upper_clearance:.3f} mm"
        )

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
