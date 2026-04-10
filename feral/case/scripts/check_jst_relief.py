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


OVERLAP_VOLUME_EPSILON = 1e-6


def ensure_generated_assets(workspace_root: Path) -> None:
    generated_dir = workspace_root / "feral" / "case" / "cad" / "generated"
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


@dataclass
class MeshMetrics:
    x_span: float
    y_span: float
    z_span: float
    volume: float


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


def triangle_signed_volume(triangle) -> float:
    (ax, ay, az), (bx, by, bz), (cx, cy, cz) = triangle
    return (
        ax * (by * cz - bz * cy) - ay * (bx * cz - bz * cx) + az * (bx * cy - by * cx)
    ) / 6.0


def measure_overlap_mesh(path: Path) -> MeshMetrics:
    triangles = load_stl_triangles(path)
    if not triangles:
        return MeshMetrics(0.0, 0.0, 0.0, 0.0)
    xs = [vertex[0] for triangle in triangles for vertex in triangle]
    ys = [vertex[1] for triangle in triangles for vertex in triangle]
    zs = [vertex[2] for triangle in triangles for vertex in triangle]
    volume = abs(sum(triangle_signed_volume(triangle) for triangle in triangles))
    return MeshMetrics(
        x_span=max(xs) - min(xs),
        y_span=max(ys) - min(ys),
        z_span=max(zs) - min(zs),
        volume=volume,
    )


def run_check(workspace_root: Path, hand: str, output_dir: Path) -> tuple[bool, str]:
    output_path = output_dir / f"feral-{hand}-jst-opposite-relief-overlap.stl"
    command = [
        "nix",
        "develop",
        "./feral",
        "-c",
        "openscad",
        "-o",
        str(output_path),
        "-D",
        'part="jst-opposite-relief-overlap"',
        "-D",
        f'hand="{hand}"',
        "feral/case/cad/feral_case.scad",
    ]

    result = subprocess.run(
        command,
        cwd=workspace_root,
        capture_output=True,
        text=True,
        check=False,
    )

    combined_output = (result.stdout + result.stderr).strip()
    empty_object = "Current top level object is empty." in combined_output
    overlap_found = result.returncode == 0 and not empty_object and output_path.exists()

    if empty_object:
        return True, f"{hand}: no JST post overlap on the opposite shell"

    if result.returncode != 0:
        message = (
            combined_output or f"openscad failed with exit code {result.returncode}"
        )
        return False, f"{hand}: JST relief check failed to run\n{message}"

    if overlap_found:
        metrics = measure_overlap_mesh(output_path)
        if metrics.volume <= OVERLAP_VOLUME_EPSILON:
            return True, f"{hand}: no JST post overlap on the opposite shell"
        return (
            False,
            f"{hand}: JST post overlap detected on the opposite shell\n"
            f"overlap bbox: {metrics.x_span:.3f} x {metrics.y_span:.3f} x {metrics.z_span:.3f} mm\n"
            f"overlap volume: {metrics.volume:.3f} mm^3",
        )

    return True, f"{hand}: no JST post overlap on the opposite shell"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check JST post relief on the shell opposite the connector body"
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
    ensure_generated_assets(workspace_root)
    hands = args.hands or ["left", "right"]

    if args.output_dir is not None:
        args.output_dir.mkdir(parents=True, exist_ok=True)
        output_dir_context = None
        output_dir = args.output_dir
    else:
        output_dir_context = tempfile.TemporaryDirectory(prefix="feral-jst-relief-")
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
