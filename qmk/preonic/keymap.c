/* Copyright 2015-2021 Jack Humbert
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include QMK_KEYBOARD_H
#include "muse.h"

enum preonic_layers {
  _QWERTY,
  _COLEMAK,
  _GAMING,
  _QWERTY_IN_COLEMAK,
  _LOWER,
  _RAISE,
};

enum preonic_keycodes {
  LOWER = SAFE_RANGE,
  RAISE,
  BACKLIT
};

#define QWERTY PDF(_QWERTY)
#define COLEMAK PDF(_COLEMAK)
#define GAMING DF(_GAMING)
#define Q_IN_C DF(_QWERTY_IN_COLEMAK)
#define SP_RAISE LT(_RAISE, KC_SPC)
#define TB_LOWER LT(_LOWER, KC_TAB)

const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {

/* Qwerty
 * ,-----------------------------------------------------------------------------------.
 * |   `  |   1  |   2  |   3  |   4  |   5  |   6  |   7  |   8  |   9  |   0  | Bksp |
 * |------+------+------+------+------+------+------+------+------+------+------+------|
 * | Tab  |   Q  |   W  |   E  |   R  |   T  |   Y  |   U  |   I  |   O  |   P  | Del  |
 * |------+------+------+------+------+-------------+------+------+------+------+------|
 * |Esc/Al|   A  |   S  |   D  |   F  |   G  |   H  |   J  |   K  |   L  |   ;  |  "   |
 * |------+------+------+------+------+------|------+------+------+------+------+------|
 * | Shift|   Z  |   X  |   C  |   V  |   B  |   N  |   M  |   ,  |   .  |   /  |Enter |
 * |------+------+------+------+------+------+------+------+------+------+------+------|
 * | Ctrl | Ctrl | Alt  | GUI  |Lower |    Space    |Raise | Left | Down |  Up  |Right |
 * `-----------------------------------------------------------------------------------'
 */
[_QWERTY] = LAYOUT_preonic_grid(
  KC_GRV,         KC_1,    KC_2,    KC_3,         KC_4,         KC_5,     KC_6,     KC_7,         KC_8,         KC_9,    KC_0,    KC_BSPC,
  KC_TAB,         KC_Q,    KC_W,    KC_E,         KC_R,         KC_T,     KC_Y,     KC_U,         KC_I,         KC_O,    KC_P,    RGUI_T(KC_DEL),
  LALT_T(KC_ESC), KC_A,    KC_S,    LCTL_T(KC_D), LGUI_T(KC_F), KC_G,     KC_H,     LGUI_T(KC_J), LCTL_T(KC_K), KC_L,    KC_SCLN, LALT_T(KC_QUOT),
  KC_LSFT,        KC_Z,    KC_X,    KC_C,         KC_V,         KC_B,     KC_N,     KC_M,         KC_COMM,      KC_DOT,  KC_SLSH, RSFT_T(KC_ENT),
  KC_LCTL,        KC_LCTL, KC_LALT, KC_LGUI,      TB_LOWER,     SP_RAISE, SP_RAISE, SP_RAISE,     KC_LEFT,      KC_DOWN, KC_UP,   KC_RGHT
),

/* Colemak
 * ,-----------------------------------------------------------------------------------.
 * |   `  |   1  |   2  |   3  |   4  |   5  |   6  |   7  |   8  |   9  |   0  | Bksp |
 * |------+------+------+------+------+------+------+------+------+------+------+------|
 * | Tab  |   Q  |   W  |   F  |   P  |   G  |   J  |   L  |   U  |   Y  |   ;  | Del  |
 * |------+------+------+------+------+-------------+------+------+------+------+------|
 * | Esc  |   A  |   R  |   S  |   T  |   D  |   H  |   N  |   E  |   I  |   O  |  "   |
 * |------+------+------+------+------+------|------+------+------+------+------+------|
 * | Shift|   Z  |   X  |   C  |   V  |   B  |   K  |   M  |   ,  |   .  |   /  |Enter |
 * |------+------+------+------+------+------+------+------+------+------+------+------|
 * | Brite| Ctrl | Alt  | GUI  |Lower |    Space    |Raise | Left | Down |  Up  |Right |
 * `-----------------------------------------------------------------------------------'
 */
[_COLEMAK] = LAYOUT_preonic_grid(
  KC_GRV,         KC_1,    KC_2,    KC_3,         KC_4,         KC_5,     KC_6,     KC_7,         KC_8,         KC_9,    KC_0,    KC_BSPC,
  KC_TAB,         KC_Q,    KC_W,    KC_F,         KC_P,         KC_G,     KC_J,     KC_L,         KC_U,         KC_Y,    KC_SCLN, RGUI_T(KC_BSLS),
  LALT_T(KC_ESC), KC_A,    KC_R,    LCTL_T(KC_S), LGUI_T(KC_T), KC_D,     KC_H,     LGUI_T(KC_N), LCTL_T(KC_E), KC_I,    KC_O,    LALT_T(KC_QUOT),
  KC_LSFT,        KC_Z,    KC_X,    KC_C,         KC_V,         KC_B,     KC_K,     KC_M,         KC_COMM,      KC_DOT,  KC_SLSH, RSFT_T(KC_ENT),
  KC_LCTL,        KC_LCTL, KC_LALT, KC_LGUI,      TB_LOWER,     SP_RAISE, SP_RAISE, SP_RAISE,     KC_LEFT,      KC_DOWN, KC_UP,   KC_RGHT
),

/* Gaming
 * ,-----------------------------------------------------------------------------------.
 * |   `  |   1  |   2  |   3  |   4  |   5  |   6  |   7  |   8  |   9  |   0  | Bksp |
 * |------+------+------+------+------+------+------+------+------+------+------+------|
 * | Tab  |   Q  |   W  |   E  |   R  |   T  |   Y  |   U  |   I  |   O  |   P  | Del  |
 * |------+------+------+------+------+-------------+------+------+------+------+------|
 * | Esc  |   A  |   S  |   D  |   F  |   G  |   H  |   J  |   K  |   L  |   ;  |  "   |
 * |------+------+------+------+------+------|------+------+------+------+------+------|
 * | Shift|   Z  |   X  |   C  |   V  |   B  |   N  |   M  |   ,  |   .  |   /  |Enter |
 * |------+------+------+------+------+------+------+------+------+------+------+------|
 * | Ctrl |      |      |      | Space|    Space    |Raise | Left | Down |  Up  |Right |
 * `-----------------------------------------------------------------------------------'
 */
[_GAMING] = LAYOUT_preonic_grid(
  KC_GRV,  KC_1,    KC_2,    KC_3,    KC_4,    KC_5,   KC_6,    KC_7,  KC_8,    KC_9,    KC_0,    KC_BSPC,
  KC_TAB,  KC_Q,    KC_W,    KC_E,    KC_R,    KC_T,   KC_Y,    KC_U,  KC_I,    KC_O,    KC_P,    LGUI(KC_TAB),
  KC_ESC,  KC_A,    KC_S,    KC_D,    KC_F,    KC_G,   KC_H,    KC_J,  KC_K,    KC_L,    KC_SCLN, KC_QUOT,
  KC_LSFT, KC_Z,    KC_X,    KC_C,    KC_V,    KC_B,   KC_N,    KC_M,  KC_COMM, KC_DOT,  KC_SLSH, KC_ENT,
  KC_LCTL, XXXXXXX, XXXXXXX, XXXXXXX, KC_SPC,  KC_SPC, KC_SPC,  RAISE, KC_LEFT, KC_DOWN, KC_UP,   KC_RGHT
),

/* Qwerty in Colemak
 * ,-----------------------------------------------------------------------------------.
 * |   `  |   1  |   2  |   3  |   4  |   5  |   6  |   7  |   8  |   9  |   0  | Bksp |
 * |------+------+------+------+------+------+------+------+------+------+------+------|
 * | Tab  |   Q  |   W  |   K  |   S  |   F  |   O  |   I  |   L  |   ;  |   R  | Del  |
 * |------+------+------+------+------+-------------+------+------+------+------+------|
 * | Esc  |   A  |   D  |   G  |   E  |   T  |   H  |   Y  |   N  |   U  |   P  |  "   |
 * |------+------+------+------+------+------|------+------+------+------+------+------|
 * | Shift|   Z  |   X  |   C  |   V  |   B  |   J  |   M  |   ,  |   .  |   /  |Enter |
 * |------+------+------+------+------+------+------+------+------+------+------+------|
 * | Ctrl |      |      |      | Space|    Space    |Raise | Left | Down |  Up  |Right |
 * `-----------------------------------------------------------------------------------'
 */
[_QWERTY_IN_COLEMAK] = LAYOUT_preonic_grid(
  KC_GRV,         KC_1,    KC_2,    KC_3,         KC_4,         KC_5,     KC_6,     KC_7,         KC_8,         KC_9,    KC_0,    KC_BSPC,
  KC_TAB,         KC_Q,    KC_W,    KC_K,         KC_S,         KC_F,     KC_O,     KC_I,         KC_L,         KC_SCLN, KC_R,    RGUI_T(KC_BSLS),
  LALT_T(KC_ESC), KC_A,    KC_D,    LCTL_T(KC_G), LGUI_T(KC_E), KC_T,     KC_H,     LGUI_T(KC_Y), LCTL_T(KC_N), KC_U,    KC_P,    LALT_T(KC_QUOT),
  KC_LSFT,        KC_Z,    KC_X,    KC_C,         KC_V,         KC_B,     KC_J,     KC_M,         KC_COMM,      KC_DOT,  KC_SLSH, RSFT_T(KC_ENT),
  KC_LCTL,        KC_LCTL, KC_LALT, KC_LGUI,      TB_LOWER,     SP_RAISE, SP_RAISE, SP_RAISE,     KC_LEFT,      KC_DOWN, KC_UP,   KC_RGHT
),

/* Lower
 * ,-----------------------------------------------------------------------------------.
 * |   ~  |  F1  |  F2  |  F3  |  F4  |  F5  |  F6  |  F7  |  F8  |  F9  |  F10 | F11  |
 * |------+------+------+------+------+-------------+------+------+------+------+------|
 * |   ~  |   !  |   @  |   #  |   $  |   %  |   7  |   8  |   9  |   -  |   /  | F12  |
 * |------+------+------+------+------+-------------+------+------+------+------+------|
 * | Del  |   ^  |   &  |   *  |   (  |   )  |   4  |   5  |   6  |   +  |   *  |  \   |
 * |------+------+------+------+------+------|------+------+------+------+------+------|
 * |      |      |   [  |   ]  |   {  |   }  |   1  |   2  |   3  |   .  |   =  |  0   |
 * |------+------+------+------+------+------+------+------+------+------+------+------|
 * |      |      |      |      |      |             |      | Next | Vol- | Vol+ | Play |
 * `-----------------------------------------------------------------------------------'
 */
[_LOWER] = LAYOUT_preonic_grid(
  KC_TILD, KC_F1,   KC_F2,   KC_F3,   KC_F4,   KC_F5,   KC_F6,   KC_F7,     KC_F8,   KC_F9,   KC_F10,  KC_F11,
  KC_TILD, KC_EXLM, KC_AT,   KC_HASH, KC_DLR,  KC_PERC, KC_DOT,  KC_7,      KC_8,    KC_9,    XXXXXXX, KC_F12,
  KC_DEL,  KC_CIRC, KC_AMPR, KC_ASTR, KC_LPRN, KC_RPRN, KC_MINS, KC_4,      KC_5,    KC_6,    XXXXXXX, KC_BSLS,
  _______, KC_BSLS, KC_LBRC, KC_RBRC, KC_LCBR, KC_RCBR, KC_EQL,  KC_1,      KC_2,    KC_3,    KC_EQL,  KC_0,
  _______, _______, _______, _______, _______, _______, _______, KC_0,      KC_MNXT, KC_VOLD, KC_VOLU, KC_MPLY
),

/* Raise
 * ,-----------------------------------------------------------------------------------.
 * |Q_in_C|Qwerty|Colemk|Gaming|AudOff|Aud on|Voice-|Voice+|Aud cy|Mus on|MusOff| Reset|
 * |------+------+------+------+------+------+------+------+------+------+------+------|
 * |      |      |      |      |      |      |      |PrevTb|NextTb|      |      | Debug|
 * |------+------+------+------+------+-------------+------+------+------+------+------|
 * |      |      |      |      |      |      | Left | Down |  Up  | Right|      |      |
 * |------+------+------+------+------+------|------+------+------+------+------+------|
 * |      |      |      |      |      |      |      |      |      | Pg Up| Pg Dn|      |
 * |------+------+------+------+------+------+------+------+------+------+------+------|
 * |      |      |      |      |      |             |      | Next | Vol- | Vol+ | Play |
 * `-----------------------------------------------------------------------------------'
 */
[_RAISE] = LAYOUT_preonic_grid(
  Q_IN_C,  QWERTY,  COLEMAK, GAMING,  AU_OFF,    AU_ON, AU_PREV, AU_NEXT,     MU_NEXT,  MU_ON,    MU_OFF,  QK_BOOT,
  XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, C(S(KC_TAB)),C(KC_TAB),XXXXXXX,  XXXXXXX, DB_TOGG,
  XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, KC_LEFT, KC_DOWN,     KC_UP,    KC_RGHT,  XXXXXXX, XXXXXXX,
  XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, KC_PGDN,     KC_PGUP,  XXXXXXX,  XXXXXXX, XXXXXXX,
  XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX, XXXXXXX,     KC_MNXT,  KC_VOLD,  KC_VOLU, KC_MPLY
)

};

bool process_record_user(uint16_t keycode, keyrecord_t *record) {
    switch (keycode) {
      case RAISE: {
        if (record->event.pressed) {
          layer_on(_RAISE);
        } else {
          layer_off(_RAISE);
        }
        return false;
      } break;
    }
    return true;
};

bool muse_mode = false;
uint8_t last_muse_note = 0;
uint16_t muse_counter = 0;
uint8_t muse_offset = 70;
uint16_t muse_tempo = 50;

bool encoder_update_user(uint8_t index, bool clockwise) {
  if (muse_mode) {
    if (IS_LAYER_ON(_RAISE)) {
      if (clockwise) {
        muse_offset++;
      } else {
        muse_offset--;
      }
    } else {
      if (clockwise) {
        muse_tempo+=1;
      } else {
        muse_tempo-=1;
      }
    }
  } else {
    if (clockwise) {
      register_code(KC_PGDN);
      unregister_code(KC_PGDN);
    } else {
      register_code(KC_PGUP);
      unregister_code(KC_PGUP);
    }
  }
    return true;
}

void matrix_scan_user(void) {
#ifdef AUDIO_ENABLE
    if (muse_mode) {
        if (muse_counter == 0) {
            uint8_t muse_note = muse_offset + SCALE[muse_clock_pulse()];
            if (muse_note != last_muse_note) {
                stop_note(compute_freq_for_midi_note(last_muse_note));
                play_note(compute_freq_for_midi_note(muse_note), 0xF);
                last_muse_note = muse_note;
            }
        }
        muse_counter = (muse_counter + 1) % muse_tempo;
    } else {
        if (muse_counter) {
            stop_all_notes();
            muse_counter = 0;
        }
    }
#endif
}

bool music_mask_user(uint16_t keycode) {
  switch (keycode) {
    case RAISE:
    case LOWER:
      return false;
    default:
      return true;
  }
}
