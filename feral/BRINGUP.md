# Feral bring-up (XIAO nRF52840 + ZMK)

This flow validates matrix wiring and diode direction for the Feral PCB.

## Why two images?

In stock ZMK, `diode-direction` is build-time configuration for
`kscan-gpio-matrix`, not a runtime mode. To test both directions, build
and flash both diagnostic images:

- `feral-zmk-diag-col2row`
- `feral-zmk-diag-row2col`

Treat this as one combined bring-up step: same keymap, two diode scan
directions.

## Build

```sh
nix build .#feral-zmk-diag-col2row
nix build .#feral-zmk-diag-row2col
```

## Flash

1. Double-tap reset on XIAO to mount UF2 volume.
2. Copy `result/zmk.uf2` to the mounted volume.
3. Repeat for the other image.

## Diagnostic keymap

Both images use the same 26-key physical layout. Every populated switch
position sends a visible character for matrix verification:

```
Row 0: A B C D E F
Row 1: G H I J K L
Row 2: M N O P Q R
Row 3: S T U V W X
Thumb: Y Z
```

The matrix columns are ordered to match the Feral Ergogen source
(`outer -> pinky -> ring -> middle -> index -> inner`). The two thumb
keys are mapped separately as `Y` then `Z`.

## Interpreting results

- Keys work only on `feral-zmk-diag-col2row`: diode direction is
  `col2row`.
- Keys work only on `feral-zmk-diag-row2col`: diode direction is
  `row2col`.
- Keys behave in both images: likely diode bypass/short path in matrix.
- Missing keys or dead rows/columns in working image: wiring/solder/net
  issue.
