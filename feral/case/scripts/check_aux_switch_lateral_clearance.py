#!/usr/bin/env python3

from __future__ import annotations

import argparse
import ast
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, cast


SCAD_NAMES = {
    "aux_edge_exit_width",
    "aux_outer_relief_expand_x",
    "aux_outer_relief_expand_y",
    "edge_exit_x",
    "power_cutout_pos",
    "power_cutout_size",
    "power_switch_window_size",
    "power_switch_body_size",
    "power_switch_origin",
    "reset_cutout_pos",
    "reset_cutout_size",
    "reset_switch_window_size",
    "reset_switch_body_size",
    "reset_switch_origin",
}

COMPONENT_POSITION_NAMES = {
    "kicad_power_switch_at",
    "kicad_power_switch_rotation",
    "kicad_reset_switch_at",
    "kicad_reset_switch_rotation",
}


@dataclass(frozen=True)
class Rect:
    x_min: float
    x_max: float
    y_min: float
    y_max: float


@dataclass(frozen=True)
class Clearances:
    top: float
    bottom: float
    pod_side: float
    edge_side: float


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

        normalized_value = re.sub(r"\btrue\b", "True", raw_value)
        normalized_value = re.sub(r"\bfalse\b", "False", normalized_value)

        try:
            values[name] = ast.literal_eval(normalized_value)
        except Exception as exc:
            if raw_value in values:
                values[name] = values[raw_value]
                continue
            try:
                values[name] = eval(
                    normalized_value,
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


def vector(values: dict[str, object], name: str) -> tuple[float, float]:
    raw = cast(Any, values[name])
    return (float(raw[0]), float(raw[1]))


def body_rect(center: tuple[float, float], size: tuple[float, float]) -> Rect:
    return Rect(
        x_min=center[0] - size[0] / 2,
        x_max=center[0] + size[0] / 2,
        y_min=center[1] - size[1] / 2,
        y_max=center[1] + size[1] / 2,
    )


def oriented_size(
    size: tuple[float, float], rotation_degrees: float
) -> tuple[float, float]:
    rotation = abs(rotation_degrees) % 180
    if abs(rotation - 90) < 1e-6:
        return (size[1], size[0])
    return size


def edge_window_rect(
    cutout_pos: tuple[float, float],
    cutout_size: tuple[float, float],
    edge_exit_x: float,
    aux_edge_exit_width: float,
) -> Rect:
    return Rect(
        x_min=cutout_pos[0],
        x_max=edge_exit_x + aux_edge_exit_width,
        y_min=cutout_pos[1],
        y_max=cutout_pos[1] + cutout_size[1],
    )


def expand_rect(rect: Rect, expand_x: float, expand_y: float) -> Rect:
    return Rect(
        x_min=rect.x_min - expand_x,
        x_max=rect.x_max + expand_x,
        y_min=rect.y_min - expand_y,
        y_max=rect.y_max + expand_y,
    )


def measure_clearances(body: Rect, opening: Rect) -> Clearances:
    return Clearances(
        top=body.y_min - opening.y_min,
        bottom=opening.y_max - body.y_max,
        pod_side=body.x_min - opening.x_min,
        edge_side=opening.x_max - body.x_max,
    )


def shell_label_for_hand(hand: str) -> str:
    return "bottom" if hand == "left" else "top"


def check_issues(clearances: Clearances, max_clearance: float | None) -> list[str]:
    issues: list[str] = []
    for label, value in (
        ("top", clearances.top),
        ("bottom", clearances.bottom),
        ("pod-side", clearances.pod_side),
        ("edge-side", clearances.edge_side),
    ):
        if value < 0:
            issues.append(f"{label} overlaps by {-value:.3f} mm")
        elif max_clearance is not None and value > max_clearance:
            issues.append(f"{label} exceeds max by {value - max_clearance:.3f} mm")

    return issues


def format_report(
    hand: str,
    switch_name: str,
    region_name: str,
    body: Rect,
    opening: Rect,
    clearances: Clearances,
    max_clearance: float | None,
) -> tuple[bool, str]:
    issues = check_issues(clearances, max_clearance)
    if max_clearance is None:
        status = "WARN" if issues else "INFO"
        ok = True
    else:
        status = "PASS" if not issues else "FAIL"
        ok = not issues
    label = f"{hand}/{shell_label_for_hand(hand)} {switch_name} {region_name}"
    lines = [
        f"{label}: {status}",
        f"  body x-range: {body.x_min:.3f}..{body.x_max:.3f} mm",
        f"  body y-range: {body.y_min:.3f}..{body.y_max:.3f} mm",
        f"  opening x-range: {opening.x_min:.3f}..{opening.x_max:.3f} mm",
        f"  opening y-range: {opening.y_min:.3f}..{opening.y_max:.3f} mm",
        f"  top clearance: {clearances.top:.3f} mm",
        f"  bottom clearance: {clearances.bottom:.3f} mm",
        f"  pod-side clearance: {clearances.pod_side:.3f} mm",
        f"  edge-side clearance: {clearances.edge_side:.3f} mm",
    ]
    if issues:
        lines.append(f"  issue: {'; '.join(issues)}")
    return (ok, "\n".join(lines))


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Report lateral clearances from the reset/power switch bodies to the "
            "switch-side outer opening and its outer relief"
        )
    )
    parser.add_argument(
        "--hand",
        dest="hands",
        action="append",
        choices=["left", "right"],
        help="Hand to inspect; repeat to check multiple hands. Defaults to both.",
    )
    parser.add_argument(
        "--max-clearance",
        type=float,
        help="Optional maximum allowed clearance in mm for each reported side",
    )
    args = parser.parse_args()

    scad_path = Path(__file__).resolve().parents[1] / "cad" / "feral_case.scad"
    values = parse_assignment_file(scad_path, SCAD_NAMES)
    component_positions_path = (
        Path(__file__).resolve().parents[1]
        / "cad"
        / "generated"
        / "component_positions.scad"
    )
    component_values = parse_assignment_file(
        component_positions_path, COMPONENT_POSITION_NAMES
    )
    hands = args.hands or ["left", "right"]

    edge_exit_x = scalar(values, "edge_exit_x")
    aux_edge_exit_width = scalar(values, "aux_edge_exit_width")
    relief_expand_x = scalar(values, "aux_outer_relief_expand_x")
    relief_expand_y = scalar(values, "aux_outer_relief_expand_y")

    switches = [
        (
            "reset",
            body_rect(
                vector(component_values, "kicad_reset_switch_at"),
                oriented_size(
                    vector(values, "reset_switch_body_size"),
                    scalar(component_values, "kicad_reset_switch_rotation"),
                ),
            ),
            edge_window_rect(
                vector(values, "reset_cutout_pos"),
                vector(values, "reset_cutout_size"),
                edge_exit_x,
                aux_edge_exit_width,
            ),
        ),
        (
            "power",
            body_rect(
                vector(component_values, "kicad_power_switch_at"),
                oriented_size(
                    vector(values, "power_switch_body_size"),
                    scalar(component_values, "kicad_power_switch_rotation"),
                ),
            ),
            edge_window_rect(
                vector(values, "power_cutout_pos"),
                vector(values, "power_cutout_size"),
                edge_exit_x,
                aux_edge_exit_width,
            ),
        ),
    ]

    reports: list[tuple[bool, str]] = []
    for hand in hands:
        for switch_name, body, opening in switches:
            reports.append(
                format_report(
                    hand,
                    switch_name,
                    "opening",
                    body,
                    opening,
                    measure_clearances(body, opening),
                    args.max_clearance,
                )
            )
            reports.append(
                format_report(
                    hand,
                    switch_name,
                    "outer relief",
                    body,
                    expand_rect(opening, relief_expand_x, relief_expand_y),
                    measure_clearances(
                        body,
                        expand_rect(opening, relief_expand_x, relief_expand_y),
                    ),
                    args.max_clearance,
                )
            )

    for _, message in reports:
        print(message)

    return 0 if all(ok for ok, _ in reports) else 1


if __name__ == "__main__":
    sys.exit(main())
