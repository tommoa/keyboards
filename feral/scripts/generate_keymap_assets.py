import json
import os
import re
import shlex
import subprocess
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path
from typing import Optional


SWITCH_RE = re.compile(
    r'\(footprint "PG1350".*?'
    r"\(at\s+(?P<x>-?[0-9.]+)\s+(?P<y>-?[0-9.]+)(?:\s+(?P<r>-?[0-9.]+))?\).*?"
    r'\(property "Reference" "(?P<ref>S\d+)"',
    re.S,
)

X_PITCH_MM = 18.0
Y_PITCH_MM = 17.0
HALF_GAP_MM = 28.0
KEYMAP_CMD = shlex.split(
    os.environ.get(
        "KEYMAP_CMD",
        "uvx --from keymap-drawer --with tree-sitter==0.22.3 keymap",
    )
)
PRESENTATION_DRAW_CONFIG = (
    "draw_config:\n"
    "  key_w: 56\n"
    "  key_h: 52\n"
    "  split_gap: 28\n"
    "  key_rx: 6\n"
    "  key_ry: 6\n"
    "  draw_key_sides: true\n"
    "  append_colon_to_layer_header: false\n"
)
PRESENTATION_KEYMAP_LAYERS = ["QWERTY", "Lower", "Raise"]
SINGLE_LAYER_ASSETS = [
    ("QWERTY", "feral-layer-qwerty"),
    ("Colemak", "feral-layer-colemak"),
    ("Gaming", "feral-layer-gaming"),
    ("Q in C", "feral-layer-q-in-c"),
    ("Lower", "feral-layer-lower"),
    ("Raise", "feral-layer-raise"),
]
SVG_NS = "http://www.w3.org/2000/svg"
XLINK_NS = "http://www.w3.org/1999/xlink"
MODIFIER_HOLD_LABELS = {
    "LALT",
    "RALT",
    "LCTRL",
    "RCTRL",
    "LGUI",
    "RGUI",
    "LSHFT",
    "RSHFT",
}
LAYER_HOLD_LABELS = {"Lower", "Raise"}
FUNCTION_STYLES = """

/* presentation function colors */
rect.fn-typing {
    fill: #f8fafc;
    stroke: #cbd5e1;
}

rect.side.fn-typing {
    fill: #e2e8f0;
}

text.fn-typing {
    fill: #0f172a;
}

rect.fn-mod {
    fill: #dbeafe;
    stroke: #60a5fa;
}

rect.side.fn-mod {
    fill: #bfdbfe;
}

text.fn-mod {
    fill: #1d4ed8;
}

rect.fn-layer-hold {
    fill: #ede9fe;
    stroke: #8b5cf6;
}

rect.side.fn-layer-hold {
    fill: #ddd6fe;
}

text.fn-layer-hold {
    fill: #6d28d9;
}

rect.fn-layer-switch {
    fill: #fef3c7;
    stroke: #f59e0b;
}

rect.side.fn-layer-switch {
    fill: #fde68a;
}

text.fn-layer-switch {
    fill: #92400e;
}

rect.fn-symbols {
    fill: #fae8ff;
    stroke: #d946ef;
}

rect.side.fn-symbols {
    fill: #f5d0fe;
}

text.fn-symbols {
    fill: #86198f;
}

rect.fn-system {
    fill: #d1fae5;
    stroke: #10b981;
}

rect.side.fn-system {
    fill: #a7f3d0;
}

text.fn-system {
    fill: #065f46;
}

rect.fn-transparent {
    fill: #f3f4f6;
    stroke: #d1d5db;
    stroke-dasharray: 4, 4;
}

rect.side.fn-transparent {
    fill: #e5e7eb;
}

text.fn-transparent {
    fill: #9ca3af;
}

text.legend-title {
    font-size: 18px;
    font-weight: bold;
    text-anchor: start;
    dominant-baseline: hanging;
}

text.legend-label {
    font-size: 14px;
    text-anchor: start;
    dominant-baseline: middle;
}

text.legend-note {
    font-size: 12px;
    text-anchor: start;
    dominant-baseline: hanging;
    fill: #4b5563;
}
"""
FUNCTION_LEGEND = [
    ("fn-typing", "Typing / standard tap"),
    ("fn-mod", "Hold for modifier"),
    ("fn-layer-hold", "Hold for Raise / Lower"),
    ("fn-layer-switch", "Switch base layer"),
    ("fn-symbols", "Symbols / numpad"),
    ("fn-system", "Navigation / system"),
    ("fn-transparent", "Transparent / unused"),
]

ET.register_namespace("", SVG_NS)
ET.register_namespace("xlink", XLINK_NS)


@dataclass(frozen=True)
class Switch:
    ref: str
    x: float
    y: float
    rotation: float


def _round(value: float) -> float:
    return round(value, 3)


def parse_switches(pcb_path: Path) -> list[Switch]:
    text = pcb_path.read_text()
    switches = [
        Switch(
            ref=match.group("ref"),
            x=float(match.group("x")),
            y=float(match.group("y")),
            rotation=float(match.group("r") or 0.0),
        )
        for match in SWITCH_RE.finditer(text)
    ]
    if len(switches) != 26:
        raise SystemExit(f"expected 26 PG1350 switches, found {len(switches)}")
    return switches


def cluster_matrix_columns(matrix_switches: list[Switch]) -> list[list[Switch]]:
    columns: list[list[Switch]] = []
    for switch in sorted(matrix_switches, key=lambda sw: (sw.x, sw.y)):
        if not columns or abs(columns[-1][0].x - switch.x) > 0.5:
            columns.append([switch])
        else:
            columns[-1].append(switch)

    if len(columns) != 6:
        raise SystemExit(f"expected 6 matrix columns, found {len(columns)}")

    ordered_columns = []
    for column in columns:
        if len(column) != 4:
            refs = ", ".join(sw.ref for sw in column)
            raise SystemExit(
                f"expected 4 switches per matrix column, found {len(column)} in [{refs}]"
            )
        ordered_columns.append(sorted(column, key=lambda sw: sw.y))
    return ordered_columns


def make_key_spec(x: float, y: float, rotation: float) -> dict[str, float]:
    key = {"x": _round(x), "y": _round(y)}
    if abs(rotation) > 1e-6:
        key["r"] = _round(rotation)
    return key


def build_layout_specs(switches: list[Switch]) -> list[dict[str, float]]:
    thumbs = sorted(
        [sw for sw in switches if abs(sw.rotation) > 1e-6], key=lambda sw: sw.x
    )
    matrix = [sw for sw in switches if abs(sw.rotation) <= 1e-6]

    if len(thumbs) != 2:
        raise SystemExit(f"expected 2 thumb switches, found {len(thumbs)}")
    if len(matrix) != 24:
        raise SystemExit(f"expected 24 matrix switches, found {len(matrix)}")

    columns = cluster_matrix_columns(matrix)
    tucked, relaxed = thumbs

    min_x = min(sw.x for sw in switches)
    max_x = max(sw.x for sw in switches)
    min_y = min(sw.y for sw in switches)
    half_width = (max_x - min_x) / X_PITCH_MM
    half_gap = HALF_GAP_MM / X_PITCH_MM

    def left(sw: Switch) -> dict[str, float]:
        return make_key_spec(
            (sw.x - min_x) / X_PITCH_MM,
            (sw.y - min_y) / Y_PITCH_MM,
            -sw.rotation,
        )

    def right(sw: Switch) -> dict[str, float]:
        return make_key_spec(
            ((max_x - sw.x) / X_PITCH_MM) + half_width + half_gap,
            (sw.y - min_y) / Y_PITCH_MM,
            sw.rotation,
        )

    layout: list[dict[str, float]] = []

    for row_idx in range(4):
        for column in columns:
            layout.append(left(column[row_idx]))
        for column in reversed(columns):
            layout.append(right(column[row_idx]))

    layout.extend(
        [
            left(tucked),
            left(relaxed),
            right(relaxed),
            right(tucked),
        ]
    )

    if len(layout) != 52:
        raise SystemExit(f"expected 52 full-keyboard positions, found {len(layout)}")

    return layout


def build_presentation_layout(layout: list[dict[str, float]]) -> list[dict[str, float]]:
    return [dict(item) for item in layout]


def extract_layer_blocks(parsed_yaml: str) -> dict[str, str]:
    blocks: dict[str, str] = {}
    lines = parsed_yaml.splitlines()
    in_layers = False
    current_name: Optional[str] = None
    current_lines: list[str] = []

    for line in lines:
        if not in_layers:
            if line.strip() == "layers:":
                in_layers = True
            continue

        match = re.match(r"^  ([^-][^:]*)\s*:\s*$", line)
        if match:
            if current_name is not None:
                blocks[current_name] = "\n".join(current_lines).rstrip() + "\n"
            current_name = match.group(1)
            current_lines = [line]
            continue

        if current_name is not None:
            current_lines.append(line)

    if current_name is not None:
        blocks[current_name] = "\n".join(current_lines).rstrip() + "\n"

    return blocks


def build_presentation_keymaps_yaml(blocks: dict[str, str]) -> str:
    missing = [name for name in PRESENTATION_KEYMAP_LAYERS if name not in blocks]
    if missing:
        raise SystemExit(
            f"missing layer blocks for presentation keymaps: {', '.join(missing)}"
        )

    return (
        "layout:\n"
        "  qmk_info_json: feral-presentation-layout.json\n\n"
        f"{PRESENTATION_DRAW_CONFIG}\n"
        "layers:\n" + "".join(blocks[name] for name in PRESENTATION_KEYMAP_LAYERS)
    )


def build_single_layer_yaml(blocks: dict[str, str], layer_name: str) -> str:
    if layer_name not in blocks:
        raise SystemExit(f"missing layer block for single-layer asset: {layer_name}")

    return (
        "layout:\n"
        "  qmk_info_json: feral-presentation-layout.json\n\n"
        f"{PRESENTATION_DRAW_CONFIG}\n"
        "layers:\n"
        f"{blocks[layer_name]}"
    )


def svg_tag(name: str) -> str:
    return f"{{{SVG_NS}}}{name}"


def add_class(element: ET.Element, class_name: str) -> None:
    classes = element.get("class", "").split()
    if class_name not in classes:
        element.set("class", " ".join([*classes, class_name]).strip())


def text_content(element: ET.Element) -> str:
    return " ".join("".join(element.itertext()).split())


def classify_key(layer_name: str, key_group: ET.Element) -> str:
    classes = set(key_group.get("class", "").split())
    tap_labels: list[str] = []
    hold_labels: list[str] = []

    for text in key_group.findall(f".//{svg_tag('text')}"):
        content = text_content(text)
        if not content:
            continue

        text_classes = set(text.get("class", "").split())
        if "tap" in text_classes:
            tap_labels.append(content)
        if "hold" in text_classes:
            hold_labels.append(content)

    if "held" in classes and not tap_labels and not hold_labels:
        return "fn-layer-hold"
    if "trans" in classes or (not tap_labels and not hold_labels):
        return "fn-transparent"
    if any(label in LAYER_HOLD_LABELS for label in hold_labels):
        return "fn-layer-hold"
    if any(label in MODIFIER_HOLD_LABELS for label in hold_labels):
        return "fn-mod"
    if layer_name == "Lower":
        return "fn-symbols"
    if layer_name == "Raise":
        if any(label == "toggle" for label in hold_labels):
            return "fn-layer-switch"
        return "fn-system"
    return "fn-typing"


def add_function_classes(key_group: ET.Element, category: str) -> None:
    add_class(key_group, category)
    for element in key_group.iter():
        if element.tag in {svg_tag("rect"), svg_tag("text")}:
            add_class(element, category)


def add_legend(root: ET.Element) -> None:
    view_box = [float(value) for value in root.get("viewBox", "0 0 0 0").split()]
    width = view_box[2]
    height = view_box[3]
    legend_x = width + 32
    legend_width = 272
    swatch_size = 28
    line_height = 46

    root.set("width", str(int(width + legend_width + 48)))
    root.set("viewBox", f"0 0 {int(width + legend_width + 48)} {int(height)}")

    legend = ET.SubElement(
        root,
        svg_tag("g"),
        {"class": "keymap-legend", "transform": f"translate({legend_x}, 36)"},
    )

    title = ET.SubElement(
        legend,
        svg_tag("text"),
        {"x": "0", "y": "0", "class": "legend-title"},
    )
    title.text = "Function legend"

    for index, (category, label) in enumerate(FUNCTION_LEGEND):
        y = 42 + (index * line_height)
        ET.SubElement(
            legend,
            svg_tag("rect"),
            {
                "x": "0",
                "y": str(y),
                "width": str(swatch_size),
                "height": str(swatch_size),
                "rx": "6",
                "ry": "6",
                "class": f"key {category}",
            },
        )
        text = ET.SubElement(
            legend,
            svg_tag("text"),
            {
                "x": str(swatch_size + 14),
                "y": str(y + (swatch_size / 2)),
                "class": f"legend-label {category}",
            },
        )
        text.text = label

    note = ET.SubElement(
        legend,
        svg_tag("text"),
        {
            "x": "0",
            "y": str(42 + (len(FUNCTION_LEGEND) * line_height) + 12),
            "class": "legend-note",
        },
    )
    note.text = "Blank purple key = thumb held to access the shown layer"

    note2 = ET.SubElement(
        legend,
        svg_tag("text"),
        {
            "x": "0",
            "y": str(42 + (len(FUNCTION_LEGEND) * line_height) + 34),
            "class": "legend-note",
        },
    )
    note2.text = "Other firmware layers: Colemak, Gaming, Q in C"


def build_legend_svg() -> str:
    root = ET.Element(
        svg_tag("svg"),
        {
            "width": "0",
            "height": "420",
            "viewBox": "0 0 0 420",
            "class": "keymap",
        },
    )
    style = ET.SubElement(root, svg_tag("style"))
    style.text = (
        "svg.keymap {"
        "font-family: SFMono-Regular,Consolas,Liberation Mono,Menlo,monospace;"
        "font-size: 14px;"
        "text-rendering: optimizeLegibility;"
        "fill: #24292e;"
        "}" + FUNCTION_STYLES
    )
    add_legend(root)
    return ET.tostring(root, encoding="unicode")


def add_function_colors(root: ET.Element) -> None:
    style = root.find(svg_tag("style"))
    if style is None:
        raise SystemExit("missing <style> block in rendered SVG")
    style.text = (style.text or "") + FUNCTION_STYLES

    for layer_group in root.findall(svg_tag("g")):
        layer_classes = layer_group.get("class", "").split()
        layer_class = next(
            (
                class_name
                for class_name in layer_classes
                if class_name.startswith("layer-")
            ),
            None,
        )
        if layer_class is None:
            continue

        layer_name = layer_class.removeprefix("layer-")
        for key_group in layer_group.findall(f".//{svg_tag('g')}"):
            if "keypos-" not in key_group.get("class", ""):
                continue
            add_function_classes(key_group, classify_key(layer_name, key_group))


def colorize_svg(svg_path: Path, *, include_legend: bool = False) -> None:
    root = ET.fromstring(svg_path.read_text())
    add_function_colors(root)
    if include_legend:
        add_legend(root)
    svg_path.write_text(ET.tostring(root, encoding="unicode"))


def run(cmd: list[str], cwd: Path, stdout_path: Optional[Path] = None) -> str:
    if stdout_path is None:
        try:
            completed = subprocess.run(
                cmd, cwd=cwd, check=True, text=True, capture_output=True
            )
        except subprocess.CalledProcessError as exc:
            raise SystemExit(exc.stderr or exc.stdout or str(exc)) from exc
        return completed.stdout

    with stdout_path.open("w") as handle:
        try:
            subprocess.run(cmd, cwd=cwd, check=True, text=True, stdout=handle)
        except subprocess.CalledProcessError as exc:
            raise SystemExit(exc.stderr or exc.stdout or str(exc)) from exc
    return ""


def repo_root_from_script(script_dir: Path) -> Path:
    return script_dir.parent


def zmk_keymap_path(repo_root: Path) -> Path:
    return Path(
        os.environ.get(
            "ZMK_KEYMAP_PATH",
            str(repo_root.parent / "zmk" / "feral" / "config" / "feral.keymap"),
        )
    )


def main() -> None:
    script_dir = Path(__file__).resolve().parent
    repo_root = repo_root_from_script(script_dir)
    output_dir = Path(os.environ.get("KEYMAP_ASSET_OUT_DIR", str(repo_root / "result")))
    output_dir.mkdir(parents=True, exist_ok=True)

    pcb_path = repo_root / "feral.kicad_pcb"
    zmk_path = zmk_keymap_path(repo_root)
    layout_json_path = output_dir / "feral-layout.json"
    presentation_layout_json_path = output_dir / "feral-presentation-layout.json"
    full_yaml_path = output_dir / "feral-from-zmk.yaml"
    full_svg_path = output_dir / "feral-from-zmk.svg"
    presentation_keymaps_yaml_path = output_dir / "feral-keymaps.yaml"
    presentation_keymaps_svg_path = output_dir / "feral-keymaps.svg"
    legend_svg_path = output_dir / "feral-keymap-legend.svg"

    switches = parse_switches(pcb_path)
    layout = build_layout_specs(switches)
    layout_json_path.write_text(json.dumps(layout, indent=2) + "\n")
    presentation_layout_json_path.write_text(
        json.dumps(build_presentation_layout(layout), indent=2) + "\n"
    )

    parsed_yaml = run(
        KEYMAP_CMD + ["parse", "-c", "12", "-z", str(zmk_path)],
        cwd=repo_root.parent,
    )
    full_yaml_path.write_text(
        "layout:\n  qmk_info_json: feral-layout.json\n\n" + parsed_yaml,
    )
    layer_blocks = extract_layer_blocks(parsed_yaml)
    presentation_keymaps_yaml_path.write_text(
        build_presentation_keymaps_yaml(layer_blocks)
    )

    for layer_name, asset_name in SINGLE_LAYER_ASSETS:
        single_layer_yaml_path = output_dir / f"{asset_name}.yaml"
        single_layer_svg_path = output_dir / f"{asset_name}.svg"
        single_layer_yaml_path.write_text(
            build_single_layer_yaml(layer_blocks, layer_name)
        )
        run(
            KEYMAP_CMD
            + [
                "draw",
                "--qmk-info-json",
                str(presentation_layout_json_path),
                str(single_layer_yaml_path),
            ],
            cwd=repo_root.parent,
            stdout_path=single_layer_svg_path,
        )
        colorize_svg(single_layer_svg_path)

    run(
        KEYMAP_CMD
        + ["draw", "--qmk-info-json", str(layout_json_path), str(full_yaml_path)],
        cwd=repo_root.parent,
        stdout_path=full_svg_path,
    )
    run(
        KEYMAP_CMD
        + [
            "draw",
            "--qmk-info-json",
            str(presentation_layout_json_path),
            str(presentation_keymaps_yaml_path),
        ],
        cwd=repo_root.parent,
        stdout_path=presentation_keymaps_svg_path,
    )
    colorize_svg(presentation_keymaps_svg_path, include_legend=True)
    legend_svg_path.write_text(build_legend_svg())


if __name__ == "__main__":
    main()
