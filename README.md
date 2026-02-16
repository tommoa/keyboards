# keyboards

Custom keyboard firmware and hardware, built with Nix.

| Keyboard | Firmware | MCU | Status |
|---|---|---|---|
| [Preonic rev3 Drop](https://drop.com/buy/preonic-mechanical-keyboard) | QMK, ZMK | STM32F303 | Active |
| Feral (custom split) | -- | Seeed XIAO BLE | PCB design phase |

Source lives on [sourcehut](https://git.sr.ht/~tommoa/keyboards),
mirrored to [GitHub](https://github.com/tommoa/keyboards).

## Preonic

5x12 ortholinear with rotary encoder. Both QMK and ZMK firmware share
the same logical keymap: six layers, home-row mods, and layer-tap
keys.

### Layers

| # | Name | Purpose |
|---|------|---------|
| 0 | QWERTY | Default alpha layout |
| 1 | Colemak | Alternative alpha layout |
| 2 | Gaming | Clean QWERTY -- no home-row mods |
| 3 | Qwerty-in-Colemak | QWERTY output when OS is set to Colemak |
| 4 | Lower | Symbols, F-keys, right-hand numpad, media |
| 5 | Raise | Navigation, layer switching, system keys |

### QWERTY

```
 `      1      2      3      4      5      6      7      8      9      0    Bksp
Tab     Q      W      E      R      T      Y      U      I      O      P   Del/GUI
Esc/Alt A      S    D/Ctl  F/GUI    G      H    J/GUI  K/Ctl    L      ;   '/Alt
Shift   Z      X      C      V      B      N      M      ,      .      /   Ent/Sft
Ctrl   Ctrl   Alt    GUI  Tab/Lwr     Space/Raise x3            Left  Down   Up   Right
```

Hold D for Ctrl, F for GUI, J for GUI, K for Ctrl, Esc for Alt,
' for Alt, Enter for Shift. Tapping term: 175 ms.

### Lower (symbols + numpad)

```
 ~     F1     F2     F3     F4     F5     F6     F7     F8     F9    F10    F11
 ~      !      @      #      $      %      .      7      8      9          F12
Del     ^      &      *      (      )      -      4      5      6           \
        \      [      ]      {      }      =      1      2      3      =   Next
                                                   0    Mute   Vol-  Vol+  Play
```

### Raise (navigation + system)

```
Q_in_C QWRTY  Clmk  Game                                                  Boot
                    Bri-  Bri+                   <Tab   Tab>
       Prev   Play  Next              Left   Down    Up  Right
                                      Home   PgDn   PgUp   End             Next
                                              Mute  Vol-  Vol+  Play
```

### Notable features

- **Home-row mods** on QWERTY, Colemak, and Q-in-C layers. ZMK uses
  separate left/right `balanced` hold-tap behaviors.
- **Layer-tap**: Space activates Raise on hold; Tab activates Lower on
  hold.
- **Rotary encoder**: Page Down / Page Up. QMK also supports Muse mode
  tempo/offset adjustment via the encoder.
- **KVM compatibility**: boots in 6KRO (QMK), USB max power 100 mA,
  console endpoint disabled.
- **Audio** (QMK only): startup song, layer-change songs, NKRO toggle
  chimes, Muse generative music mode, basic MIDI.

### QMK vs ZMK feature gap

Some features exist only in QMK because ZMK lacks the underlying
support:

- Audio / piezo / Muse mode (no ZMK audio driver)
- NKRO toggle (ZMK is compile-time only)
- MIDI
- Persistent default layer (QMK saves to EEPROM)
- `&bootloader` key (broken on STM32F303;
  [ZMK #1086](https://github.com/zmkfirmware/zmk/issues/1086))

## Building

Everything is built with
[Nix flakes](https://zero-to-nix.com/concepts/flakes). No toolchain
installation required.

Flake outputs follow the naming convention `<keyboard>-<firmware>`:

```sh
nix build .#preonic-qmk        # Build QMK firmware
nix build .#preonic-zmk        # Build ZMK firmware
nix run .#preonic-qmk-flash    # Build and flash via dfu-util
nix run .#preonic-zmk-update   # Update ZMK west.yml pins + zephyrDepsHash
nix develop                    # QMK dev shell
nix fmt                        # Format Nix + YAML files
```

To enter DFU mode for flashing, double-tap the reset button (or press
the bootloader key on the Raise layer in QMK).

Dependencies are updated automatically on a weekly schedule via GitHub
Actions.

## CI

GitHub Actions builds firmware on every push to `master` and runs
weekly dependency updates for both QMK and ZMK. Sourcehut and GitHub
are kept in sync bidirectionally.
