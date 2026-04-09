#!/usr/bin/env python3

import argparse
import re
import sys
from pathlib import Path


TARGETS = {
    "MCU1": "xiao",
    "JST1": "jst",
    "B1": "reset_switch",
    "T1": "power_switch",
}


def iter_footprint_blocks(text: str):
    lines = text.splitlines(keepends=True)
    collecting = False
    depth = 0
    block = []

    for line in lines:
        stripped = line.lstrip()
        if not collecting and stripped.startswith("(footprint "):
            collecting = True
            block = [line]
            depth = line.count("(") - line.count(")")
            if depth == 0:
                yield "".join(block)
                collecting = False
            continue

        if collecting:
            block.append(line)
            depth += line.count("(") - line.count(")")
            if depth == 0:
                yield "".join(block)
                collecting = False


def parse_footprint(block: str):
    ref_match = re.search(r'\(property "Reference" "([^"]+)"', block)
    at_match = re.search(r"\n\s*\(at ([^ )]+) ([^ )]+)(?: ([^ )]+))?\)", block)
    layer_match = re.search(r'\n\s*\(layer "([^"]+)"\)', block)

    if not ref_match or not at_match or not layer_match:
        return None

    rotation = at_match.group(3) or "0"
    return {
        "reference": ref_match.group(1),
        "x": float(at_match.group(1)),
        "y": float(at_match.group(2)),
        "rotation": float(rotation),
        "layer": layer_match.group(1),
    }


def format_number(value: float) -> str:
    return f"{value:.6f}".rstrip("0").rstrip(".")


def render_scad(data):
    lines = [
        "// Generated from feral/feral.kicad_pcb by extract_component_positions.py.",
        "// PCB-mounted parts come from KiCad; off-board parts like the battery stay in",
        "// the case model as manual assumptions.",
        "",
    ]

    for ref, name in TARGETS.items():
        item = data[ref]
        lines.extend(
            [
                f"kicad_{name}_at = [{format_number(item['x'])}, {format_number(item['y'])}];",
                f"kicad_{name}_rotation = {format_number(item['rotation'])};",
                f'kicad_{name}_layer = "{item["layer"]}";',
                "",
            ]
        )

    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    repo_root = Path(__file__).resolve().parents[3]
    default_input = repo_root / "feral" / "feral.kicad_pcb"
    default_output = (
        repo_root / "feral" / "case" / "cad" / "generated" / "component_positions.scad"
    )

    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, default=default_input)
    parser.add_argument("--output", type=Path, default=default_output)
    parser.add_argument("--stdout", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    text = args.input.read_text()
    parsed = {}
    for block in iter_footprint_blocks(text):
        item = parse_footprint(block)
        if item and item["reference"] in TARGETS:
            parsed[item["reference"]] = item

    missing = [ref for ref in TARGETS if ref not in parsed]
    if missing:
        raise SystemExit(f"missing target footprints: {', '.join(missing)}")

    rendered = render_scad(parsed)

    if args.stdout:
        sys.stdout.write(rendered)

    if args.check:
        if not args.output.exists():
            sys.stderr.write(f"{args.output} is missing\n")
            return 1
        existing = args.output.read_text()
        if existing != rendered:
            sys.stderr.write(f"{args.output} is out of date\n")
            return 1
        return 0

    if not args.stdout:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
