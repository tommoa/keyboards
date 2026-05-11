# AGENTS.md

Guidelines for AI coding agents working in this repository.
**Update this file** when you discover new patterns, encounter
confusing conventions, or introduce architectural changes.

## Repository overview

Custom keyboard firmware (QMK + ZMK) for the Preonic rev3 Drop, plus
a custom split keyboard PCB design (Feral). Everything is built with
Nix flakes. The primary remote is sourcehut (`master` branch, not
`main`), mirrored bidirectionally to GitHub.

## Build commands

All builds go through Nix. No toolchain installation required.

Because this repo is built as a git flake source, `nix build` only sees
new files after they are added to the git index. Modified tracked files
are picked up without committing, but newly created files must be
`git add`ed first.

Outputs follow the naming convention `<keyboard>-<firmware>` for
packages and `<keyboard>-<firmware>-<action>` for apps. Use the root
`README.md` as the source of truth for the current exposed targets.

### Formatting and checks

```sh
nix fmt                           # Format Nix + YAML files
nix flake check                   # Run formatter check (CI uses this)
```

There are no unit tests. Verification is done by building firmware
successfully (`nix build`). CI builds every `*-qmk` and `*-zmk`
package in a matrix discovered at runtime via `nix eval`.

### Development shells

```sh
nix develop                       # QMK dev shell (default)
nix develop .#zmk                 # ZMK dev shell
nix develop .#vortex-core         # Vortex Core QMK + flashing shell
nix develop ./feral               # Feral Ergogen + OpenSCAD shell
```

### Feral sub-project

`feral/` is an independent flake with its own `treefmt.nix`. It is
excluded from the root formatter config. Use `nix fmt ./feral` and
`nix build ./feral` separately. The root flake also exposes the
sub-flake output as `nix build .#feral-pcb`.

Feral now also has ZMK bring-up firmware under `zmk/feral/config`
built from the root flake. Bring-up uses a single `feral_diag`
firmware that validates the `col2row` matrix wiring.
- Any Feral ZMK target that reads the shared `zmk/feral/config/feral.conf`
  must include the local `feral/startup-led` ZMK module via
  `-DZMK_EXTRA_MODULES=...`, or Kconfig will fail on
  `CONFIG_FERAL_RGBLED_STATUS`.
- For out-of-tree ZMK behaviors shipped through `feral/startup-led`, keep
  `list(APPEND DTS_ROOT ${CMAKE_CURRENT_SOURCE_DIR})` in the module
  `CMakeLists.txt` so Zephyr finds custom devicetree bindings, and add
  `zephyr_library_include_directories(${APPLICATION_SOURCE_DIR}/include)`
  so the module can include ZMK's `app/include/drivers/behavior.h`.
- `feral-zmk` uses `buildSplitKeyboard` and outputs `zmk_left.uf2`
  and `zmk_right.uf2`. The left half is the ZMK split central and the
  right half is the peripheral.
- The Feral diagnostic transform is sparse: 24 main matrix positions
  plus 2 thumb keys. Keep the visible test keymap in physical order,
  with columns matching Ergogen's `outer -> pinky -> ring -> middle ->
  index -> inner` net order.
- On `xiao_ble`, disable `&uart0` in Feral diagnostic overlays. The
  board default claims `D6/D7` for UART TX/RX, which corrupts matrix
  diagnostics that use those pins as columns.
- For powered matrix debugging beyond ZMK key events, use the standalone
  `feral-raw-scan` Zephyr app. It prints raw per-column row bitmasks over
  USB CDC ACM serial, which is more reliable than interpreting typed text
  when investigating row/column coupling.
- For Feral case work, use `python3 feral/case/scripts/check_clearances.py`
  after changing mounting-boss radii to confirm they still clear the
  `PG1350` hotswap footprint features in `feral/feral.kicad_pcb`.
- For Feral pod/keycap fit checks, use
  `python3 feral/case/scripts/check_keycap_clearance.py [--tolerance 0.5]`.
  It runs OpenSCAD through `nix develop ./feral -c openscad`, checks the
  top pod against nearby Choc keycap envelopes, and reports which
  pod-adjacent keys overlap. Use `--define name=value` to compare SCAD
  parameter tweaks without editing the file, and read the reported
  top-view overlap bbox/area to quantify before/after changes. The
  relaxed thumb defaults to a 1u Choc envelope; use
  `--define 'relaxed_thumb_keycap_size=choc_keycap_1_5u_size'` to
  stress-test a 1.5u thumb cap.
- For Feral USB opening checks, use
  `python3 feral/case/scripts/check_usb_clearance.py [--min-clearance 0.3]`.
  It analytically checks both the `left/top` and `right/bottom` USB
  openings against the current modeled XIAO USB shell envelope and a
  standard USB-C plug overmold envelope centered on that shell. It reports
  `top`, `bottom`, `left`, `right`, `outward`, and `inward` clearances;
  use `--shell-only` to inspect the board-side shell without the outward
  extension. On the `left/top` half, cable fit also treats the lower shell
  as an obstruction unless `top_usb_bottom_shell_relief_height` opens the
  split line enough for the plug envelope to pass.
- For the USB/aux-side wall breach check, use
  `python3 feral/case/scripts/check_aux_openings.py --hand right --shell bottom`.
  It exports the bottom-side electronics cavity footprint that falls
  outside a required closed-wall band near the USB/aux area and fails if
  any breach remains. Item 2 is fixed when the affected shell reports no
  cavity breach at the chosen wall width. The checker defaults that wall
  threshold to `0.45 mm`.
- For JST opposite-side relief checks, use
  `python3 feral/case/scripts/check_jst_relief.py`.
  It exports the overlap between the opposite shell and a conservative
  JST PH post-protrusion envelope derived from the connector post length.
  Item 3 is fixed when both hands report no overlap.
- For shared aux-support placement checks, use
  `python3 feral/case/scripts/check_aux_switch_support.py`.
  It exports the direct overlap between the switch-side shell and the
  reset/power switch body envelopes. Item 4 is fixed when both hands
  report no overlap.
- For aux switch height checks, use
  `python3 feral/case/scripts/check_aux_switch_height.py`.
  It reports the switch opening/body `z` ranges plus the lower and upper
  clearances for each hand. Item 5 is fixed when both clearances stay
  within the configured band; the checker defaults that band to
  `0.15..0.30 mm`.
- For aux switch lateral gap checks, use
  `python3 feral/case/scripts/check_aux_switch_lateral_clearance.py`.
  It analytically reports `top`, `bottom`, `pod-side`, and `edge-side`
  clearances from each switch body to both the through opening and the
  switch-side outer relief, for both hands. Use it to identify which side
  of the reset/power cutout is still visually too open before changing the
  CAD.
- The Feral case preview can source PCB-mounted component positions from
  `feral/feral.kicad_pcb` via
  `python3 feral/case/scripts/extract_component_positions.py`, which
  regenerates `feral/case/cad/generated/component_positions.scad`. Keep
  the battery as a manual case-side envelope because it is off-board.
- For reversible Feral previews, keep JST XY/rotation from KiCad but place
  the JST on `battery_side`, not the raw footprint layer.
- For asymmetric 2D preview envelopes derived from KiCad footprints in
  `feral_case.scad` (for example the JST PH side-entry header or rotated
  keycap bounds), double-check the rotation sign against a render. In this
  model, copied KiCad angles can need sign inversion before the asymmetric
  outline lands on the expected side of the footprint.
- For XIAO USB-C fit checks, prefer the vendor 3D model over a hand-made
  bounding box. Convert the Seeed STEP file into the generated wrapper
  `feral/case/cad/generated/xiao-nrf52840-parts.scad` and
  `feral/case/cad/generated/xiao-nrf52840-parts/` STL directory with
  `uv run --with cadquery --with trimesh --with pymeshfix --with numpy python3 feral/case/scripts/convert_step_to_stl.py`
  and use that wrapper in the OpenSCAD preview. The single merged STL is
  not watertight enough for OpenSCAD `Render`.
- The shell-only STL package (`nix build .#feral-case-shell-stls`) regenerates
  `component_positions.scad` from the tracked KiCad PCB and stubs the
  preview-only XIAO mesh include. It is the right CI target for printable
  shell artifacts, but it does not validate electronics preview renders.

## Code style

### Nix (`.nix`)

- Formatted by `nixfmt` (enforced by treefmt, checked in CI)
- 2-space indentation
- Run `nix fmt` before committing -- CI will reject unformatted files

### YAML (`.yml`)

- Formatted by `yamlfmt` (root) or `prettier` (feral)
- 2-space indentation
- Inline comments after west.yml revision hashes: `# main`, `# v4.1.0+zmk-fixes`

### C and headers (`.c`, `.h`) -- QMK

**Do NOT auto-format C files.** clang-format destroys the ASCII-art
keymap diagrams and produces non-functional firmware. These are
hand-formatted.

- 4-space indentation in logic code
- Keymap grid: each keyboard row on one line, columns space-aligned
  to match the physical layout. Preserving this alignment is critical.
- `#pragma once` for include guards (not `#ifndef`/`#define`)
- Preprocessor: `#` at column 0, then spaces to indent nested
  directives (e.g. `#    define FOO` inside an `#ifdef`)
- License header: GPL v2+ block comment at top of each file
- Naming:
  - Layer enums: `_UPPER_CASE` with leading underscore (`_QWERTY`)
  - Custom keycodes: `UPPER_CASE` (`SP_RAISE`, `TB_LOWER`)
  - Functions/variables: `snake_case` (`process_record_user`)
- Includes: `#include QMK_KEYBOARD_H` first (macro), then quoted
  local includes (`#include "muse.h"`)
- Comments: `/* */` blocks for keymap diagrams and headers,
  `//` for inline explanations. Explain **why**, not just what.

### Devicetree keymaps (`.keymap`) -- ZMK

**Do NOT auto-format .keymap files.** clang-format splits `&kp`
bindings and rewrites property names, breaking the firmware.

- 4-space indentation per nesting level
- Binding rows: each keyboard row on one line inside
  `bindings = < ... >;`, columns space-aligned like QMK keymaps
- Layer node naming: `snake_case_layer` (`qwerty_layer`)
- Behavior labels: short abbreviations (`hml`, `hmr`)
- `compatible` property first in each node, `#binding-cells` second
- Layer defines: plain `UPPER_CASE` without leading underscore
  (`#define QWERTY 0` -- differs from QMK convention)
- ZMK system includes use angle brackets:
  `#include <behaviors.dtsi>`, `#include <dt-bindings/zmk/keys.h>`
- Shared behaviors live in `zmk/shared/base.keymap`, included via
  relative path from board-specific keymaps

### Kconfig (`.conf`)

- `CONFIG_VAR=value` format, `#` comments explaining purpose

### Makefile (`.mk`)

- Standard Makefile syntax with tabs, `UPPER_CASE` variable names

### JavaScript (`.js`) -- Feral Ergogen footprints

- Formatted by `prettier` (feral treefmt)
- 2-space indentation, CommonJS modules
- `snake_case` for params, `UPPER_CASE` for net names

## Commit messages

Conventional Commits format: `type(scope): description`

**Types**: `feat`, `fix`, `refactor`, `chore`, `docs`

**Scopes**: `qmk/preonic`, `zmk/preonic`, `flake`, `ci`, or omitted

**Rules**:
- Lowercase first word after scope, no trailing period
- Body explains the problem and solution, not just the diff
- Wrap body at 72 characters
- Automated dependency updates use a simpler format:
  `qmk: update firmware source` (no conventional prefix)

## CI / mirroring

- **GitHub Actions**: builds firmware on push to `master`, runs weekly
  dependency updates (QMK Monday 07:00 UTC, ZMK Monday 06:00 UTC)
- **Sourcehut builds**: mirrors pushes to GitHub
- **Bidirectional sync**: pushes with `GITHUB_TOKEN` don't trigger
  other workflows, so update workflows explicitly dispatch `ci.yml`
  and `sync.yml` via `gh workflow run` (requires `workflow_dispatch`
  on both). Keep those dispatch steps independent with
  `if: always() && steps.<push-step>.outcome == 'success'` so a failed
  CI dispatch does not skip the sourcehut mirror.
- Automated commits use bot identities (`qmk-update-bot`,
  `zmk-update-bot`) with `github-actions[bot]` email
- **GitHub Pages**: the `deploy-pages` job in `ci.yml` publishes Feral
  keymap SVGs to `https://tommoa.github.io/keyboards/` after each
  push to `master`. It depends on the `feral-keymap-assets` job,
  downloads only the SVGs, generates a minimal `index.html`, and
  deploys via `actions/deploy-pages@v4`. The `pages: write` and
  `id-token: write` permissions are scoped to that job only so they
  don't affect other jobs. The Pages concurrency group is also scoped
  to that job. The GitHub repo must have Pages enabled with source set
  to "GitHub Actions" (not "Deploy from a branch").

- The normal split Feral firmware builds as `feral-zmk-left` and
  `feral-zmk-right`. The left half is the ZMK split central and the
  right half is the peripheral.
- `feral-zmk-connectpro` is the UDP-12AP DDM-compatible Feral firmware.
  It temporarily builds from `tommoa/zmk` for split HID indexes and opts
  into them via `connectpro.conf`.

## Architecture notes

- The ZMK board ID for the Preonic is `preonic//zmk` (HWMv2 variant
  syntax, required since ZMK PR #3145)
- The Preonic uses STM32 DFU bootloader, not UF2. Builds produce
  `.bin`/`.hex`, flashed via `dfu-util`
- `&bootloader` is broken on STM32F303 in ZMK (issue #1086).
  Double-tap physical reset button works instead.
- `zephyrDepsHash` in `flake.nix` must match the west dependencies.
  Use `nix run .#preonic-zmk-update` to recompute it after updating
  `zmk-nix` or `west.yml`
- QMK firmware source is a non-flake git input with `submodules = true`
  (not a git submodule of this repo)

## Updating this file

If you introduce a new pattern, naming convention, build target, or
workflow -- or encounter something confusing that took investigation
to understand -- add it here so future agents don't repeat the work.
