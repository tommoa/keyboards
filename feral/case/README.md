# Feral Case

This directory holds the first printable case workflow for Feral.

## Current direction

- full-perimeter two-piece case
- flat bottom at rest
- full top shell
- M2 screw assembly using the PCB mounting holes
- OpenSCAD as the editable source format
- FDM-first prototype flow

## Mechanical sources of truth

- tracked PCB: `feral/feral.kicad_pcb`
- layout and helper geometry: `feral/ergogen/config.yaml`
- frozen measurements: `feral/case/measurements.md`
- hardware assumptions: `feral/case/hardware.md`

## Current repo notes

- `feral/result` is generated output and can lag behind the tracked KiCad source.
- For case fit, prefer `feral/feral.kicad_pcb` over `feral/result/pcbs/feral.kicad_pcb`.
- The new Ergogen helper outlines are intended for case planning, not as the final 3D case source.
- Ergogen DXF exports use the opposite Y direction from KiCad; the OpenSCAD prototype flips imported DXFs back into KiCad-style coordinates before applying hole and component constants.

## Verified helper outlines

The case helper outlines in `feral/ergogen/config.yaml` were checked by generating an outline-only Ergogen config in a temporary directory.

- `case_mount_holes` exports 6 circles at the same centers as the KiCad M2 holes
- `case_mount_bosses` exports 6 larger circles at those same centers
- `case_top_shell` matches the board outline envelope
- `case_component_keepouts` exports the XIAO, JST, reset, and power-switch keepout geometry for CAD reference

## Clearance checks

- Use `python3 feral/case/scripts/check_clearances.py` to check the current standoff radii in `feral/case/cad/feral_case.scad` against the `PG1350` hotswap footprint features in `feral/feral.kicad_pcb`.
- The script reports the nearest hotswap feature for each mounting-hole boss and the minimum clearance across all bosses.

## Component preview placement

- `feral/case/cad/generated/component_positions.scad` is generated from the tracked `feral/feral.kicad_pcb` by `python3 feral/case/scripts/extract_component_positions.py`.
- The OpenSCAD preview uses those KiCad-derived positions for PCB-mounted parts (`MCU1`, `JST1`, `B1`, `T1`) so the fit-check overlay is not tied to hand-copied case constants.
- On the reversible Feral board, the JST preview keeps the KiCad XY/rotation but follows the case `battery_side` for which face it is mounted on.
- The XIAO preview should use the generated per-solid wrapper `feral/case/cad/generated/xiao-nrf52840-parts.scad` plus the `xiao-nrf52840-parts/` STL directory. Generate them from the vendor STEP with `uv run --with cadquery --with trimesh --with pymeshfix --with numpy python3 feral/case/scripts/convert_step_to_stl.py ... --parts-dir ... --wrapper ...`. The merged single STL remains useful for quick inspection but is not watertight enough for OpenSCAD `Render`.
- The battery stays as a manual rectangular envelope because it is an off-board part and has no KiCad footprint placement.

## Generated analysis assets

- `feral/case/cad/generated/` is disposable generated data and should be reproducible locally.
- Regenerate KiCad-derived component placement with:
  `python3 feral/case/scripts/extract_component_positions.py`
- Regenerate the XIAO mesh wrapper and split STL parts from the vendor STEP with:
  `uv run --with cadquery --with trimesh --with pymeshfix --with numpy python3 feral/case/scripts/convert_step_to_stl.py "path/to/XIAO-nRF52840.step" feral/case/cad/generated/xiao-nrf52840.stl --parts-dir feral/case/cad/generated/xiao-nrf52840-parts --wrapper feral/case/cad/generated/xiao-nrf52840-parts.scad`
- The analytical clearance scripts (`check_keycap_clearance.py` and `check_usb_clearance.py`) expect those generated files to exist and will print the same regeneration commands if they are missing.

## Next modeling steps

1. create OpenSCAD source layout under `feral/case/`
2. build a fit-first bottom shell around the PCB outline and hole pattern
3. build the matching full top shell
4. print bottom-only fit checks before full halves
