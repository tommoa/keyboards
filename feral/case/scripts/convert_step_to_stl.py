#!/usr/bin/env python3

# pyright: reportMissingImports=false

import argparse
import shutil
from pathlib import Path

from cadquery import exporters, importers
import numpy as np
import pymeshfix
import trimesh


def repair_mesh_if_needed(path: Path) -> None:
    mesh = trimesh.load(path, force="mesh")
    if mesh.is_watertight:
        return

    vertices, faces = pymeshfix.clean_from_arrays(
        np.asarray(mesh.vertices, dtype=np.float64),
        np.asarray(mesh.faces, dtype=np.int32),
    )
    repaired = trimesh.Trimesh(vertices=vertices, faces=faces, process=False)
    repaired.export(path)


def export_parts(
    shape,
    parts_dir: Path,
    wrapper: Path,
    module_name: str,
    tolerance: float,
    angular_tolerance: float,
) -> int:
    solids = shape.solids().vals()

    if parts_dir.exists():
        shutil.rmtree(parts_dir)
    parts_dir.mkdir(parents=True, exist_ok=True)

    wrapper_lines = [
        "// Generated from convert_step_to_stl.py",
        f"module {module_name}() {{",
    ]
    import_prefix = f"{wrapper.parent.name}/{parts_dir.name}"

    for index, solid in enumerate(solids):
        part_name = f"part_{index:03}.stl"
        part_path = parts_dir / part_name
        exporters.export(
            solid,
            str(part_path),
            tolerance=tolerance,
            angularTolerance=angular_tolerance,
        )
        repair_mesh_if_needed(part_path)
        wrapper_lines.append(f'    import("{import_prefix}/{part_name}");')

    wrapper_lines.append("}")
    wrapper.write_text("\n".join(wrapper_lines) + "\n")

    print({"parts": len(solids), "parts_dir": str(parts_dir), "wrapper": str(wrapper)})
    return len(solids)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--tolerance", type=float, default=0.05)
    parser.add_argument("--angular-tolerance", type=float, default=0.1)
    parser.add_argument("--parts-dir", type=Path)
    parser.add_argument("--wrapper", type=Path)
    parser.add_argument("--module-name", default="xiao_nrf52840_parts")
    args = parser.parse_args()

    shape = importers.importStep(str(args.input))
    bbox = shape.val().BoundingBox()

    args.output.parent.mkdir(parents=True, exist_ok=True)
    if args.wrapper is not None:
        args.wrapper.parent.mkdir(parents=True, exist_ok=True)

    exporters.export(
        shape,
        str(args.output),
        tolerance=args.tolerance,
        angularTolerance=args.angular_tolerance,
    )

    print(
        "bbox:",
        {
            "xmin": bbox.xmin,
            "xmax": bbox.xmax,
            "ymin": bbox.ymin,
            "ymax": bbox.ymax,
            "zmin": bbox.zmin,
            "zmax": bbox.zmax,
            "xlen": bbox.xlen,
            "ylen": bbox.ylen,
            "zlen": bbox.zlen,
        },
    )

    if args.parts_dir and args.wrapper:
        export_parts(
            shape,
            args.parts_dir,
            args.wrapper,
            args.module_name,
            args.tolerance,
            args.angular_tolerance,
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
