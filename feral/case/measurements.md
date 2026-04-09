# Feral Case Measurements

This file freezes the current mechanical references for the first case prototype.

## Source files

- Ergogen layout intent: `feral/ergogen/config.yaml`
- Tracked PCB fit authority: `feral/feral.kicad_pcb`
- Generated PCB output: `feral/result/pcbs/feral.kicad_pcb`
- Generated outlines: `feral/result/outlines/board.dxf`, `feral/result/outlines/top_plate.dxf`
- XIAO footprint details: `feral/ergogen/footprints/seeed_xiao.js`
- Reset switch footprint details: `feral/ergogen/footprints/button_side_push.js`

Note: `feral/result` is an ignored generated symlink into the Nix store, while `feral/feral.kicad_pcb` is now present locally and includes the real mounting-hole geometry.

## Layout summary

- 26 keys per half total
  - 24-key main matrix
  - 2-key thumb cluster
- Ergogen uses a 6-column main matrix plus 2 thumb keys in `feral/ergogen/config.yaml`.
- Existing outline primitives:
  - `board`
  - `switch_holes`
  - `top_plate`
  - `combo`

## PCB summary

- PCB thickness: `1.6 mm`
- PCB title: `feral`
- Tracked PCB path: `feral/feral.kicad_pcb`
- Generated PCB path: `feral/result/pcbs/feral.kicad_pcb`
- Generated outline path: `feral/result/outlines/board.dxf`

## Mounting holes

From `feral/feral.kicad_pcb`:

- 6x `MountingHole_2.2mm_M2`
- Hole centers:
  - `191.6, 123.2`
  - `162.4, 70.4`
  - `105.2, 37.8`
  - `213.6, 72.2`
  - `113.0, 110.4`
  - `183.4, 26.8`

## Approximate board envelope

From the current `Edge.Cuts` in `feral/result/pcbs/feral.kicad_pcb`:

- X range: about `89.0 mm` to `222.67 mm`
- Y range: about `18.74 mm` to `129.32 mm`

These are good enough for case planning; final CAD should import or trace the generated outline rather than rely only on the bounding box.

## Major component placements

- XIAO module origin: `211.6, 57.78`, from `feral/result/pcbs/feral.kicad_pcb`
- Reset button origin: `220.35, 73.28`, rotated `-90 deg`
- Power switch origin: `220.35, 83.28`, rotated `-90 deg`
- JST battery connector origin: `202.35, 71.73`, rotated `90 deg`

## Component size references

- XIAO body drawing in `feral/ergogen/footprints/seeed_xiao.js`
  - body rectangle: `17.78 mm x 21.0 mm`
  - USB overhang sketch: from `x = -3.81..3.81`, `y = -12.02..-6.94` relative to the module origin
- XIAO keepout note
  - the footprint adds extra `Edge.Cuts` relief for the underside pads because `smd_cutouts: true` is enabled in `feral/ergogen/config.yaml`
- Reset switch footprint in `feral/ergogen/footprints/button_side_push.js`
  - courtyard width: `7.8 mm`
  - courtyard height: `5.5 mm`

## Battery assumption

- Cell: `301230`
- Nominal battery size: `30 x 12 x 3 mm`
- Battery sits below the JST area and below JST height per user note.
- First pocket should include extra room for pouch tolerance, tape, and wire bend.

## Repo state note

- The tracked KiCad source and the generated `feral/result` output are not currently in sync.
- The tracked `feral/feral.kicad_pcb` includes the six M2 mounting holes and should be treated as the mechanical source of truth for the case.
- If we later refresh the Ergogen output, we should make sure the generated flow preserves these holes.
