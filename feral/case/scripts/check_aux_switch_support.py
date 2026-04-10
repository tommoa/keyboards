#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
import struct
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path


def parse_binary_stl(data: bytes):
    if len(data) < 84:
        return None

    triangle_count = struct.unpack_from("<I", data, 80)[0]
    expected_size = 84 + triangle_count * 50
    if len(data) != expected_size:
        return None

    triangles = []
    offset = 84
    for _ in range(triangle_count):
        values = struct.unpack_from("<12fH", data, offset)
        triangles.append(
            (
                (values[3], values[4], values[5]),
                (values[6], values[7], values[8]),
                (values[9], values[10], values[11]),
            )
        )
        offset += 50
    return triangles


def parse_ascii_stl(text: str):
    triangles = []
    matches = re.findall(
        r"vertex\s+([-0-9.eE+]+)\s+([-0-9.eE+]+)\s+([-0-9.eE+]+)",
        text,
    )
    if len(matches) % 3 != 0:
        raise ValueError("Unexpected ASCII STL vertex count")

    values = [tuple(float(value) for value in match) for match in matches]
    for index in range(0, len(values), 3):
        triangles.append(
            (
                values[index + 0],
                values[index + 1],
                values[index + 2],
            )
        )
    return triangles


def load_stl_triangles(path: Path):
    data = path.read_bytes()
    triangles = parse_binary_stl(data)
    if triangles is not None:
        return triangles
    return parse_ascii_stl(data.decode("utf-8"))


@dataclass
class MeshMetrics:
    x_min: float
    x_max: float
    y_min: float
    y_max: float
    z_min: float
    z_max: float
    x_span: float
    y_span: float
    z_span: float
    volume: float


def triangle_signed_volume(triangle) -> float:
    (ax, ay, az), (bx, by, bz), (cx, cy, cz) = triangle
    return (
        ax * (by * cz - bz * cy) - ay * (bx * cz - bz * cx) + az * (bx * cy - by * cx)
    ) / 6.0


def measure_overlap_mesh(path: Path) -> MeshMetrics:
    triangles = load_stl_triangles(path)
    if not triangles:
        return MeshMetrics(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

    xs = [vertex[0] for triangle in triangles for vertex in triangle]
    ys = [vertex[1] for triangle in triangles for vertex in triangle]
    zs = [vertex[2] for triangle in triangles for vertex in triangle]
    volume = abs(sum(triangle_signed_volume(triangle) for triangle in triangles))
    return MeshMetrics(
        x_min=min(xs),
        x_max=max(xs),
        y_min=min(ys),
        y_max=max(ys),
        z_min=min(zs),
        z_max=max(zs),
        x_span=max(xs) - min(xs),
        y_span=max(ys) - min(ys),
        z_span=max(zs) - min(zs),
        volume=volume,
    )


def run_check(workspace_root: Path, hand: str, output_dir: Path) -> tuple[bool, str]:
    success_message = f"{hand}: shell clears both switch bodies"
    overlap_path = output_dir / f"feral-{hand}-aux-switch-body-overlap.stl"
    overlap_command = [
        "nix",
        "develop",
        "./feral",
        "-c",
        "openscad",
        "-o",
        str(overlap_path),
        "-D",
        'part="aux-switch-body-overlap"',
        "-D",
        f'hand="{hand}"',
        "feral/case/cad/feral_case.scad",
    ]

    overlap_result = subprocess.run(
        overlap_command,
        cwd=workspace_root,
        capture_output=True,
        text=True,
        check=False,
    )

    overlap_output = (overlap_result.stdout + overlap_result.stderr).strip()
    overlap_empty = "Current top level object is empty." in overlap_output
    overlap_found = (
        overlap_result.returncode == 0 and not overlap_empty and overlap_path.exists()
    )

    if overlap_result.returncode != 0 and not overlap_empty:
        message = (
            overlap_output
            or f"openscad failed with exit code {overlap_result.returncode}"
        )
        return False, f"{hand}: aux switch overlap check failed to run\n{message}"

    if overlap_empty:
        return (True, success_message)

    if overlap_found:
        metrics = measure_overlap_mesh(overlap_path)
        if metrics.volume <= 1e-6:
            return (True, success_message)
        return (
            False,
            f"{hand}: switch-side shell overlaps a switch body\n"
            f"overlap x-range: {metrics.x_min:.3f}..{metrics.x_max:.3f} mm\n"
            f"overlap y-range: {metrics.y_min:.3f}..{metrics.y_max:.3f} mm\n"
            f"overlap z-range: {metrics.z_min:.3f}..{metrics.z_max:.3f} mm\n"
            f"overlap bbox: {metrics.x_span:.3f} x {metrics.y_span:.3f} x {metrics.z_span:.3f} mm\n"
            f"overlap volume: {metrics.volume:.3f} mm^3",
        )

    return (True, success_message)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check that the switch-side shell does not overlap the reset or power switch bodies"
    )
    parser.add_argument(
        "--hand",
        dest="hands",
        action="append",
        choices=["left", "right"],
        help="Hand to inspect; repeat to check multiple hands. Defaults to both.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        help="Directory for diagnostic STL output. Defaults to a temporary directory.",
    )
    args = parser.parse_args()

    workspace_root = Path(__file__).resolve().parents[3]
    hands = args.hands or ["left", "right"]

    if args.output_dir is not None:
        args.output_dir.mkdir(parents=True, exist_ok=True)
        output_dir_context = None
        output_dir = args.output_dir
    else:
        output_dir_context = tempfile.TemporaryDirectory(
            prefix="feral-aux-switch-overlap-"
        )
        output_dir = Path(output_dir_context.name)

    try:
        results = [run_check(workspace_root, hand, output_dir) for hand in hands]
    finally:
        if output_dir_context is not None:
            output_dir_context.cleanup()

    for _, message in results:
        print(message)

    return 0 if all(ok for ok, _ in results) else 1


if __name__ == "__main__":
    sys.exit(main())
