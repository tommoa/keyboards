# Feral bring-up (XIAO nRF52840 + ZMK)

This flow validates matrix wiring for the Feral PCB using the intended
`col2row` diode direction.

## Build

```sh
nix build .#feral-zmk-diag-col2row
```

## Flash

1. Double-tap reset on the half you want to test.
2. Copy `result/zmk.uf2` to the mounted UF2 volume.
3. Repeat for the other half if needed.

## Diagnostic keymap

The image uses the same 26-key physical layout on either half. Every
populated switch
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

- Keys match the visible map: matrix wiring is correct for `col2row`.
- Missing keys or dead rows/columns: wiring, solder, or net issue.
