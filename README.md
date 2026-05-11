# keyboards

Custom keyboard firmware and hardware, built with Nix.

| Keyboard | Firmware | MCU | Status |
|---|---|---|---|
| Feral (custom split) | ZMK | 2x Seeed XIAO BLE | Making case |
| [Preonic rev3 Drop](https://drop.com/buy/preonic-mechanical-keyboard) | QMK, ZMK | STM32F303 | Retired |

Source lives on [sourcehut](https://git.sr.ht/~tommoa/keyboards),
mirrored to [GitHub](https://github.com/tommoa/keyboards).

## Feral

Custom split keyboard with Choc switches and a 24+2 thumb key layout,
built from an Ergogen PCB design. ZMK firmware with six layers,
home-row mods, and layer-tap keys.

### ConnectPro KVM compatibility

Feral's normal ZMK firmware keeps ZMK's stock combined keyboard and
consumer-control USB HID descriptor so media keys continue to work on
regular hosts. The ConnectPro UDP-12AP DDM keyboard port was more
selective in testing: keyboard typing worked through the KVM, but DDM
hotkey parsing only worked reliably when the keyboard report was exposed
as a dedicated boot-keyboard HID interface.

The `feral-zmk-connectpro` target is the UDP-12AP-compatible firmware. It
builds against the `tommoa/zmk` `usb-hid-device-indexes` branch from
zmkfirmware/zmk#3345 so USB exposes a report-ID-free keyboard HID descriptor
on `HID_0` and consumer/media reports on `HID_1`. This keeps media keys
available while giving the KVM a plain keyboard interface to parse. This
tracks the upstream split-HID support request in
https://github.com/zmkfirmware/zmk/issues/3339.

The relevant HID 1.11 details are:

- Boot-keyboard interfaces use a predefined 8-byte keyboard input report:
  modifiers, a reserved byte, and six key slots. See Appendix B.1
  (Protocol 1: Keyboard) and Appendix F (Legacy Keyboard Implementation).
- If a HID report descriptor uses any report ID, all reports for that HID
  device are prefixed with a report-ID byte. A dedicated single-report
  keyboard HID interface can omit report IDs entirely. See section 5.6
  (Reports) and section 6.2.2.7 (Global Items, `Report ID`).
- USB HID permits both combined report-ID-based descriptors and separate
  HID interfaces. The HID class is defined at the interface level, with
  subclass/protocol fields identifying boot interfaces. See sections 4.2
  (Subclass) and 4.3 (Protocols). Zephyr exposes separate HID instances as
  `HID_0`, `HID_1`, and so on via `CONFIG_USB_HID_DEVICE_COUNT`.

UDP-12AP testing results:

| Change tested | Result |
|---|---|
| Split keyboard `HID_0` and consumer/media `HID_1` | Worked |
| USB boot protocol enabled | Required |
| HKRO with `CONFIG_ZMK_HID_KEYBOARD_REPORT_SIZE=6` | Required |
| NKRO restored | Failed |
| USB boot protocol removed | Failed |
| Full consumer usage reports | Worked |
| `CONFIG_USB_MAX_POWER=250` | Worked |
| Default ZMK sleep behavior | Worked |

The minimal ConnectPro-specific configuration is therefore the split HID
topology plus USB boot protocol and 6KRO/HKRO. Consumer usage narrowing,
USB power reduction, and disabling sleep were not required.

### Keymap

![Feral keymap -- QWERTY, Lower, and Raise layers](https://tommoa.github.io/keyboards/feral-keymaps.svg)

Individual layers:
[QWERTY](https://tommoa.github.io/keyboards/feral-layer-qwerty.svg) |
[Colemak](https://tommoa.github.io/keyboards/feral-layer-colemak.svg) |
[Gaming](https://tommoa.github.io/keyboards/feral-layer-gaming.svg) |
[Q-in-C](https://tommoa.github.io/keyboards/feral-layer-q-in-c.svg) |
[Lower](https://tommoa.github.io/keyboards/feral-layer-lower.svg) |
[Raise](https://tommoa.github.io/keyboards/feral-layer-raise.svg)

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

<details>
<summary>Preonic keymaps (ASCII)</summary>

#### QWERTY

```
 `      1      2      3      4      5      6      7      8      9      0    Bksp
Tab     Q      W      E      R      T      Y      U      I      O      P   Del/GUI
Esc/Alt A      S    D/Ctl  F/GUI    G      H    J/GUI  K/Ctl    L      ;   '/Alt
Shift   Z      X      C      V      B      N      M      ,      .      /   Ent/Sft
Ctrl   Ctrl   Alt    GUI  Tab/Lwr     Space/Raise x3            Left  Down   Up   Right
```

Hold D for Ctrl, F for GUI, J for GUI, K for Ctrl, Esc for Alt,
' for Alt, Enter for Shift. Tapping term: 175 ms.

#### Lower (symbols + numpad)

```
 ~     F1     F2     F3     F4     F5     F6     F7     F8     F9    F10    F11
 ~      !      @      #      $      %      .      7      8      9          F12
Del     ^      &      *      (      )      -      4      5      6           \
        \      [      ]      {      }      =      1      2      3      =   Next
                                                   0    Mute   Vol-  Vol+  Play
```

#### Raise (navigation + system)

```
Q_in_C QWRTY  Clmk  Game                                                  Boot
                    Bri-  Bri+                   <Tab   Tab>
       Prev   Play  Next              Left   Down    Up  Right
                                      Home   PgDn   PgUp   End             Next
                                              Mute  Vol-  Vol+  Play
```

</details>

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

Flake outputs follow the naming convention `<keyboard>-<firmware>`.

### Firmware builds

```sh
nix build .#preonic-qmk               # Build QMK firmware
nix build .#preonic-zmk               # Build ZMK firmware
nix build .#feral-zmk                 # Build Feral split firmware (zmk_left.uf2 + zmk_right.uf2)
nix build .#feral-zmk-connectpro      # Build Feral ConnectPro split keyboard/consumer USB HID firmware
nix build .#feral-zmk-diag-col2row    # Build Feral bring-up firmware (C2R)
nix build .#feral-raw-scan            # Build standalone Feral raw GPIO scan app (USB serial bitmasks)
```

### Feral hardware and presentation assets

```sh
nix build .#feral-pcb                 # Build Feral Ergogen/KiCad outputs
nix build .#feral-case-shell-stls     # Build shell-only Feral case STLs
nix build .#feral-keymap-assets       # Build slide-ready Feral keymap assets (SVG/YAML/JSON)
```

### Utilities

```sh
nix run .#preonic-qmk-flash           # Build and flash via dfu-util
nix run .#preonic-zmk-update          # Update ZMK west.yml pins + zephyrDepsHash
nix develop                           # QMK dev shell
nix fmt                               # Format Nix + YAML files
```

To enter DFU mode for flashing, double-tap the reset button (or press
the bootloader key on the Raise layer in QMK).

Dependencies are updated automatically on a weekly schedule via GitHub
Actions.

## CI

GitHub Actions builds firmware on every push to `master` and runs
weekly dependency updates for both QMK and ZMK. Feral keymap SVGs are
deployed to [GitHub Pages](https://tommoa.github.io/keyboards/) on
each push. Sourcehut and GitHub are kept in sync bidirectionally.
