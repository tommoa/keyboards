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

Outputs follow the naming convention `<keyboard>-<firmware>` for
packages and `<keyboard>-<firmware>-<action>` for apps:

```sh
nix build .#preonic-qmk          # Build QMK firmware (.hex)
nix build .#preonic-zmk          # Build ZMK firmware (.bin + .hex)
nix run .#preonic-qmk-flash      # Build + flash QMK via dfu-util
nix run .#preonic-zmk-flash      # Flash ZMK via dfu-util
nix run .#preonic-zmk-update     # Update west.yml pins + zephyrDepsHash
```

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
nix develop ./feral               # Ergogen dev shell (Feral PCB)
```

### Feral sub-project

`feral/` is an independent flake with its own `treefmt.nix`. It is
excluded from the root formatter config. Use `nix fmt ./feral` and
`nix build ./feral` separately.

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
  on both)
- Automated commits use bot identities (`qmk-update-bot`,
  `zmk-update-bot`) with `github-actions[bot]` email

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
