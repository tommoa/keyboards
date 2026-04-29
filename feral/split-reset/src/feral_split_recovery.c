/*
 * Copyright (c) 2026 The ZMK Contributors
 *
 * SPDX-License-Identifier: MIT
 */

#include <zephyr/bluetooth/bluetooth.h>
#include <zephyr/bluetooth/conn.h>
#include <zephyr/bluetooth/hci.h>
#include <zephyr/init.h>
#include <zephyr/logging/log.h>
#include <zephyr/settings/settings.h>

#include <errno.h>
#include <stdio.h>

LOG_MODULE_DECLARE(zmk, CONFIG_ZMK_LOG_LEVEL);

#define FERAL_RESET_MAX_SETTINGS_SLOTS 8
#define ZMK_BLE_PROFILE_NAME_MAX 15

struct zmk_ble_profile {
    char name[ZMK_BLE_PROFILE_NAME_MAX];
    bt_addr_le_t peer;
};

struct addr_list {
    bt_addr_le_t addrs[CONFIG_BT_MAX_PAIRED];
    size_t count;
};

static bool addr_list_contains(const struct addr_list *list, const bt_addr_le_t *addr) {
    for (size_t i = 0; i < list->count; i++) {
        if (bt_addr_le_cmp(&list->addrs[i], addr) == 0) {
            return true;
        }
    }

    return false;
}

static int load_host_profile_cb(const char *key, size_t len, settings_read_cb read_cb, void *cb_arg,
                                void *param) {
    ARG_UNUSED(key);

    struct addr_list *profiles = param;

    if (profiles->count >= ARRAY_SIZE(profiles->addrs) || len != sizeof(struct zmk_ble_profile)) {
        return 0;
    }

    struct zmk_ble_profile profile;
    int err = read_cb(cb_arg, &profile, sizeof(profile));

    if (err <= 0) {
        LOG_WRN("Failed to read stored host profile (%d)", err);
        return 0;
    }

    if (bt_addr_le_cmp(&profile.peer, BT_ADDR_LE_ANY) == 0) {
        return 0;
    }

    bt_addr_le_copy(&profiles->addrs[profiles->count], &profile.peer);
    profiles->count++;

    return 0;
}

static void collect_bond_cb(const struct bt_bond_info *info, void *user_data) {
    struct addr_list *bonds = user_data;

    if (bonds->count >= ARRAY_SIZE(bonds->addrs)) {
        return;
    }

    bt_addr_le_copy(&bonds->addrs[bonds->count], &info->addr);
    bonds->count++;
}

static void disconnect_conn_cb(struct bt_conn *conn, void *user_data) {
    ARG_UNUSED(user_data);

    int err = bt_conn_disconnect(conn, BT_HCI_ERR_REMOTE_USER_TERM_CONN);

    if (err < 0 && err != -ENOTCONN) {
        LOG_WRN("Failed to disconnect active LE connection (%d)", err);
    }
}

static void clear_left_split_state(void) {
    struct addr_list host_profiles = {0};
    struct addr_list bonds = {0};

    int err = settings_load_subtree_direct("ble/profiles", load_host_profile_cb, &host_profiles);

    if (err) {
        LOG_WRN("Failed to load stored host profiles (%d)", err);
    }

    bt_foreach_bond(BT_ID_DEFAULT, collect_bond_cb, &bonds);

    for (size_t i = 0; i < bonds.count; i++) {
        if (addr_list_contains(&host_profiles, &bonds.addrs[i])) {
            continue;
        }

        bt_unpair(BT_ID_DEFAULT, &bonds.addrs[i]);
    }

    for (int i = 0; i < FERAL_RESET_MAX_SETTINGS_SLOTS; i++) {
        char setting_name[32];
        snprintf(setting_name, sizeof(setting_name), "ble/peripheral_addresses/%d", i);

        err = settings_delete(setting_name);
        if (err != 0 && err != -ENOENT) {
            LOG_WRN("Failed to delete %s (%d)", setting_name, err);
        }
    }
}

static void clear_right_split_state(void) { bt_unpair(BT_ID_DEFAULT, NULL); }

static int feral_split_reset_init(void) {
#if IS_ENABLED(CONFIG_SHIELD_FERAL_SPLIT_RESET_LEFT)
    LOG_WRN("Clearing stored Feral left-half split bond state");
    clear_left_split_state();
#elif IS_ENABLED(CONFIG_SHIELD_FERAL_SPLIT_RESET_RIGHT)
    LOG_WRN("Clearing stored Feral right-half split bond state");
    clear_right_split_state();
#else
#error "Feral split reset firmware must target either the left or right reset shield"
#endif

    bt_conn_foreach(BT_CONN_TYPE_LE, disconnect_conn_cb, NULL);
    (void)bt_le_adv_stop();
    LOG_WRN("Feral split reset complete; flash normal firmware next");

    return 0;
}

SYS_INIT(feral_split_reset_init, APPLICATION, 51);
