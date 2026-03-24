#include <errno.h>
#include <stdbool.h>
#include <stdint.h>

#include <zephyr/device.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/kernel.h>
#include <zephyr/sys/printk.h>
#include <zephyr/usb/usb_device.h>

#define COL_COUNT 6
#define ROW_COUNT 5

struct feral_pin {
    const struct device *port;
    gpio_pin_t pin;
};

/* XIAO BLE D7 D8 D10 D6 D5 D4 */
static const struct feral_pin cols[COL_COUNT] = {
    { DEVICE_DT_GET(DT_NODELABEL(gpio1)), 12 },
    { DEVICE_DT_GET(DT_NODELABEL(gpio1)), 13 },
    { DEVICE_DT_GET(DT_NODELABEL(gpio1)), 15 },
    { DEVICE_DT_GET(DT_NODELABEL(gpio1)), 11 },
    { DEVICE_DT_GET(DT_NODELABEL(gpio0)), 5 },
    { DEVICE_DT_GET(DT_NODELABEL(gpio0)), 4 },
};

/* XIAO BLE D0 D1 D2 D3 D9 */
static const struct feral_pin rows[ROW_COUNT] = {
    { DEVICE_DT_GET(DT_NODELABEL(gpio0)), 2 },
    { DEVICE_DT_GET(DT_NODELABEL(gpio0)), 3 },
    { DEVICE_DT_GET(DT_NODELABEL(gpio0)), 28 },
    { DEVICE_DT_GET(DT_NODELABEL(gpio0)), 29 },
    { DEVICE_DT_GET(DT_NODELABEL(gpio1)), 14 },
};

static const char *const col_names[COL_COUNT] = { "P7", "P8", "P10", "P6", "P5", "P4" };
static const char *const row_names[ROW_COUNT] = { "P0", "P1", "P2", "P3", "P9" };

static int wait_for_console(void)
{
    int ret;

    ret = usb_enable(NULL);
    if ((ret != 0) && (ret != -EALREADY)) {
        return ret;
    }

    k_sleep(K_MSEC(500));

    return 0;
}

static int setup_matrix(void)
{
    int ret;

    for (size_t i = 0; i < COL_COUNT; i++) {
        if (!device_is_ready(cols[i].port)) {
            return -ENODEV;
        }

        ret = gpio_pin_configure(cols[i].port, cols[i].pin, GPIO_OUTPUT_INACTIVE);
        if (ret != 0) {
            return ret;
        }
    }

    for (size_t i = 0; i < ROW_COUNT; i++) {
        if (!device_is_ready(rows[i].port)) {
            return -ENODEV;
        }

        ret = gpio_pin_configure(rows[i].port, rows[i].pin, GPIO_INPUT | GPIO_PULL_DOWN);
        if (ret != 0) {
            return ret;
        }
    }

    return 0;
}

static uint8_t scan_column(size_t col_index)
{
    uint8_t mask = 0;

    gpio_pin_set(cols[col_index].port, cols[col_index].pin, 1);
    k_busy_wait(50);

    for (size_t row_index = 0; row_index < ROW_COUNT; row_index++) {
        int value = gpio_pin_get(rows[row_index].port, rows[row_index].pin);

        if (value > 0) {
            mask |= BIT(row_index);
        }
    }

    gpio_pin_set(cols[col_index].port, cols[col_index].pin, 0);
    k_busy_wait(50);

    return mask;
}

static void print_masks(const uint8_t masks[COL_COUNT])
{
    printk("scan");

    for (size_t i = 0; i < COL_COUNT; i++) {
        printk(" %s=%02x", col_names[i], masks[i]);
    }

    printk(" rows=");

    for (size_t i = 0; i < ROW_COUNT; i++) {
        printk("%s%s", i == 0 ? "" : ",", row_names[i]);
    }

    printk("\n");
}

void main(void)
{
    uint8_t last_masks[COL_COUNT] = { 0 };
    bool first = true;
    int ret;

    ret = setup_matrix();
    if (ret != 0) {
        return;
    }

    ret = wait_for_console();
    if (ret != 0) {
        return;
    }

    printk("Feral raw scan ready\n");
    printk("Columns: P7 P8 P10 P6 P5 P4\n");
    printk("Rows: P0 P1 P2 P3 P9\n");
    printk("Press one key at a time and watch the nonzero mask\n");

    while (true) {
        uint8_t masks[COL_COUNT];
        bool changed = first;

        for (size_t col_index = 0; col_index < COL_COUNT; col_index++) {
            masks[col_index] = scan_column(col_index);
            if (masks[col_index] != last_masks[col_index]) {
                changed = true;
            }
        }

        if (changed) {
            print_masks(masks);
            for (size_t col_index = 0; col_index < COL_COUNT; col_index++) {
                last_masks[col_index] = masks[col_index];
            }
            first = false;
        }

        k_sleep(K_MSEC(20));
    }
}
