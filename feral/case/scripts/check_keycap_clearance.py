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


POD_ADJACENT_KEYS = {
    "S24": (190.0, 37.78),
    "S23": (190.0, 54.78),
    "S22": (190.0, 71.78),
    "S21": (190.0, 88.78),
    "S25": (183.88, 110.03),
    "S26": (203.016286, 116.063648),
}


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
    area: float


def parse_binary_stl(data: bytes):
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
    xs = [vertex[0] for triangle in triangles for vertex in triangle]
    ys = [vertex[1] for triangle in triangles for vertex in triangle]
    volume = abs(sum(triangle_signed_volume(triangle) for triangle in triangles))
    return MeshMetrics(
        x_span=max(xs) - min(xs),
        y_span=max(ys) - min(ys),
        area=volume,
    )


def run_check(
    workspace_root: Path,
    hand: str,
    tolerance: float,
    output_dir: Path,
    defines: list[str],
    key_label: str = "",
) -> tuple[bool, str, MeshMetrics | None]:
    file_suffix = f"-{key_label.lower()}" if key_label else ""
    output_path = output_dir / f"feral-{hand}-keycap-clearance-overlap{file_suffix}.stl"
    command = [
        "nix",
        "develop",
        "./feral",
        "-c",
        "openscad",
        "-o",
        str(output_path),
        "-D",
        'part="keycap-clearance-overlap-footprint"',
        "-D",
        f'hand="{hand}"',
        "-D",
        f"keycap_clearance_tolerance={tolerance}",
        "-D",
        f'keycap_check_label="{key_label}"',
    ]
    for define in defines:
        command.extend(["-D", define])
    command.append("feral/case/cad/feral_case.scad")

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
    scope = key_label or "all pod-adjacent keycaps"

    if empty_object:
        return (
            True,
            f"{hand}: no overlap for {scope} at {tolerance:.2f} mm tolerance",
            None,
        )

    if result.returncode != 0:
        message = (
            combined_output or f"openscad failed with exit code {result.returncode}"
        )
        return False, f"{hand}: check failed to run for {scope}\n{message}", None

    if overlap_found:
        metrics = measure_overlap_mesh(output_path)
        return (
            False,
            f"{hand}: overlap detected for {scope} at {tolerance:.2f} mm tolerance\n"
            f"top-view overlap bbox: {metrics.x_span:.3f} x {metrics.y_span:.3f} mm\n"
            f"top-view overlap area: {metrics.area:.3f} mm^2",
            metrics,
        )

    return True, f"{hand}: no overlap for {scope} at {tolerance:.2f} mm tolerance", None


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check Feral pod clearance against nearby Choc-compatible keycap envelopes"
    )
    parser.add_argument(
        "--hand",
        dest="hands",
        action="append",
        choices=["left", "right"],
        help="Hand to check; repeat to check multiple hands. Defaults to both.",
    )
    parser.add_argument(
        "--tolerance",
        type=float,
        default=0.5,
        help="Extra radial clearance to require around each keycap envelope in mm",
    )
    parser.add_argument(
        "--define",
        dest="defines",
        action="append",
        default=[],
        help="Extra OpenSCAD -D definition, e.g. top_component_pod_keycap_side_inset_x=0.8",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        help="Directory for overlap STL output. Defaults to a temporary directory.",
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
        output_dir_context = tempfile.TemporaryDirectory(
            prefix="feral-keycap-clearance-"
        )
        output_dir = Path(output_dir_context.name)

    try:
        all_clear = True
        messages: list[str] = []
        for hand in hands:
            clear, message, _ = run_check(
                workspace_root,
                hand,
                args.tolerance,
                output_dir,
                args.defines,
            )
            all_clear = all_clear and clear

            if not clear:
                overlapping_keys: list[str] = []
                for key_label, (key_x, key_y) in POD_ADJACENT_KEYS.items():
                    key_clear, _, metrics = run_check(
                        workspace_root,
                        hand,
                        args.tolerance,
                        output_dir,
                        args.defines,
                        key_label=key_label,
                    )
                    if not key_clear and metrics is not None:
                        overlapping_keys.append(
                            f"{key_label} ({key_x:.2f}, {key_y:.2f}): "
                            f"{metrics.x_span:.3f} x {metrics.y_span:.3f} mm, "
                            f"{metrics.area:.3f} mm^2"
                        )

                if overlapping_keys:
                    message = (
                        f"{message}\noverlapping keycaps: {'; '.join(overlapping_keys)}"
                    )

            messages.append(message)

        print("\n".join(messages))
        return 0 if all_clear else 1
    finally:
        if output_dir_context is not None:
            output_dir_context.cleanup()


if __name__ == "__main__":
    sys.exit(main())
