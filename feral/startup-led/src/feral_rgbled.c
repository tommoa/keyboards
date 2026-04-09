#define DT_DRV_COMPAT zmk_behavior_feral_battery_indicator

#include <drivers/behavior.h>
#include <zephyr/device.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/init.h>
#include <zephyr/kernel.h>
#include <zephyr/sys/util.h>
#include <zmk/behavior.h>
#if IS_ENABLED(CONFIG_ZMK_BATTERY_REPORTING)
#include <zmk/battery.h>
#include <zmk/events/battery_state_changed.h>
#endif
#if IS_ENABLED(CONFIG_ZMK_BLE)
#include <zmk/ble.h>
#include <zmk/events/ble_active_profile_changed.h>
#endif
#include <zmk/endpoints.h>
#include <zmk/endpoints_types.h>
#include <zmk/event_manager.h>
#include <zmk/events/endpoint_changed.h>

#define RED_LED_NODE DT_ALIAS(led0)
#define GREEN_LED_NODE DT_ALIAS(led1)
#define BLUE_LED_NODE DT_ALIAS(led2)

#if DT_NODE_HAS_STATUS(RED_LED_NODE, okay) && DT_NODE_HAS_STATUS(GREEN_LED_NODE, okay) && \
    DT_NODE_HAS_STATUS(BLUE_LED_NODE, okay)

struct led_color {
    bool red;
    bool green;
    bool blue;
};

static const struct gpio_dt_spec red_led = GPIO_DT_SPEC_GET(RED_LED_NODE, gpios);
static const struct gpio_dt_spec green_led = GPIO_DT_SPEC_GET(GREEN_LED_NODE, gpios);
static const struct gpio_dt_spec blue_led = GPIO_DT_SPEC_GET(BLUE_LED_NODE, gpios);

static struct k_work_delayable startup_led_work;
static struct k_work_delayable battery_led_reset_work;
static struct k_work_delayable status_flash_reset_work;
static uint8_t startup_led_step;
static bool battery_indicator_active;
static bool battery_indicator_on;
static bool status_flash_active;
static uint8_t battery_blinks_remaining;
static struct led_color battery_indicator_color;
static struct led_color status_flash_color;

#define STATUS_FLASH_MS 500
#define BATTERY_BLINK_ON_MS CONFIG_FERAL_RGBLED_STATUS_BATTERY_BLINK_ON_MS
#define BATTERY_BLINK_OFF_MS CONFIG_FERAL_RGBLED_STATUS_BATTERY_BLINK_OFF_MS

static bool leds_ready(void)
{
    return gpio_is_ready_dt(&red_led) && gpio_is_ready_dt(&green_led) && gpio_is_ready_dt(&blue_led);
}

static void set_led_color(const struct led_color color)
{
    (void)gpio_pin_set_dt(&red_led, color.red);
    (void)gpio_pin_set_dt(&green_led, color.green);
    (void)gpio_pin_set_dt(&blue_led, color.blue);
}

static bool led_color_is_off(const struct led_color color)
{
    return !color.red && !color.green && !color.blue;
}

static void refresh_led_state(void);

static struct led_color battery_color(uint8_t state_of_charge)
{
    if (state_of_charge >= 75) {
        return (struct led_color){.green = true};
    }

    if (state_of_charge >= 50) {
        return (struct led_color){.blue = true};
    }

    if (state_of_charge >= 25) {
        return (struct led_color){.red = true, .green = true};
    }

    return (struct led_color){.red = true};
}

static struct led_color current_battery_color(void)
{
#if IS_ENABLED(CONFIG_ZMK_BATTERY_REPORTING)
    return battery_color(zmk_battery_state_of_charge());
#else
    return (struct led_color){.red = true, .blue = true};
#endif
}

static uint8_t current_battery_blink_count(void)
{
#if IS_ENABLED(CONFIG_ZMK_BATTERY_REPORTING)
    const uint8_t state_of_charge = zmk_battery_state_of_charge();
    const uint8_t band_start = state_of_charge >= 75 ? 75 : state_of_charge >= 50 ? 50 : state_of_charge >= 25 ? 25 : 0;
    const uint8_t offset = MIN((uint8_t)(state_of_charge - band_start), (uint8_t)24);

    return (offset / 5) + 1;
#else
    return 1;
#endif
}

static struct led_color current_endpoint_color(void)
{
#if IS_ENABLED(CONFIG_ZMK_SPLIT) && !IS_ENABLED(CONFIG_ZMK_SPLIT_ROLE_CENTRAL)
    return (struct led_color){};
#else
    const struct zmk_endpoint_instance endpoint = zmk_endpoint_get_selected();

    switch (endpoint.transport) {
    case ZMK_TRANSPORT_USB:
        return (struct led_color){.green = true, .blue = true};
    case ZMK_TRANSPORT_BLE:
        return (struct led_color){.blue = true};
    default:
        return (struct led_color){};
    }
#endif
}

static struct led_color current_ble_profile_color(void)
{
#if IS_ENABLED(CONFIG_ZMK_SPLIT) && !IS_ENABLED(CONFIG_ZMK_SPLIT_ROLE_CENTRAL)
    return (struct led_color){};
#else
#if IS_ENABLED(CONFIG_ZMK_BLE)
        if (zmk_ble_active_profile_is_connected()) {
            return (struct led_color){.blue = true};
        }

        return (struct led_color){.red = true};
#else
        return (struct led_color){};
#endif
#endif
}

static void flash_status_color(const struct led_color color)
{
    if (led_color_is_off(color)) {
        status_flash_active = false;
        k_work_cancel_delayable(&status_flash_reset_work);
        refresh_led_state();
        return;
    }

    status_flash_color = color;
    status_flash_active = true;
    k_work_reschedule(&status_flash_reset_work, K_MSEC(STATUS_FLASH_MS));
    refresh_led_state();
}

static void refresh_led_state(void)
{
    if (!leds_ready()) {
        return;
    }

    if (battery_indicator_active) {
        set_led_color(battery_indicator_on ? battery_indicator_color : (struct led_color){});
        return;
    }

    if (status_flash_active) {
        set_led_color(status_flash_color);
        return;
    }

    set_led_color((struct led_color){});
}

static void battery_led_reset_work_handler(struct k_work *work)
{
    ARG_UNUSED(work);

    if (!battery_indicator_active) {
        refresh_led_state();
        return;
    }

    if (battery_indicator_on) {
        battery_indicator_on = false;

        if (battery_blinks_remaining > 0) {
            battery_blinks_remaining--;
        }

        if (battery_blinks_remaining == 0) {
            battery_indicator_active = false;
            refresh_led_state();
            return;
        }

        refresh_led_state();
        k_work_reschedule(&battery_led_reset_work, K_MSEC(BATTERY_BLINK_OFF_MS));
        return;
    }

    battery_indicator_on = true;
    refresh_led_state();
    k_work_reschedule(&battery_led_reset_work, K_MSEC(BATTERY_BLINK_ON_MS));
}

static void status_flash_reset_work_handler(struct k_work *work)
{
    ARG_UNUSED(work);

    status_flash_active = false;
    refresh_led_state();
}

static void startup_led_work_handler(struct k_work *work)
{
    ARG_UNUSED(work);

#if IS_ENABLED(CONFIG_FERAL_RGBLED_STATUS_STARTUP_BLINK)
    if (startup_led_step < 6) {
        set_led_color((struct led_color){.red = (startup_led_step % 2) == 0});
        startup_led_step++;
        k_work_schedule(&startup_led_work, K_MSEC(120));
        return;
    }
#endif

    refresh_led_state();
}

static int feral_rgbled_listener(const zmk_event_t *eh)
{
#if !(IS_ENABLED(CONFIG_ZMK_SPLIT) && !IS_ENABLED(CONFIG_ZMK_SPLIT_ROLE_CENTRAL))
    if (as_zmk_endpoint_changed(eh) != NULL) {
        if (!battery_indicator_active) {
            flash_status_color(current_endpoint_color());
        }

        return ZMK_EV_EVENT_BUBBLE;
    }

#if IS_ENABLED(CONFIG_ZMK_BLE)
    if (as_zmk_ble_active_profile_changed(eh) != NULL) {
        if (!battery_indicator_active) {
            flash_status_color(current_ble_profile_color());
        }

        return ZMK_EV_EVENT_BUBBLE;
    }
#endif
#endif

#if IS_ENABLED(CONFIG_ZMK_BATTERY_REPORTING)
    if (as_zmk_battery_state_changed(eh) != NULL) {
        if (battery_indicator_active) {
            battery_indicator_color = current_battery_color();
            refresh_led_state();
        }

        return ZMK_EV_EVENT_BUBBLE;
    }
#endif

    return ZMK_EV_EVENT_BUBBLE;
}

ZMK_LISTENER(feral_rgbled_listener, feral_rgbled_listener);
#if !(IS_ENABLED(CONFIG_ZMK_SPLIT) && !IS_ENABLED(CONFIG_ZMK_SPLIT_ROLE_CENTRAL))
ZMK_SUBSCRIPTION(feral_rgbled_listener, zmk_endpoint_changed);
#if IS_ENABLED(CONFIG_ZMK_BLE)
ZMK_SUBSCRIPTION(feral_rgbled_listener, zmk_ble_active_profile_changed);
#endif
#endif
#if IS_ENABLED(CONFIG_ZMK_BATTERY_REPORTING)
ZMK_SUBSCRIPTION(feral_rgbled_listener, zmk_battery_state_changed);
#endif

static int on_battery_indicator_pressed(struct zmk_behavior_binding *binding,
                                        struct zmk_behavior_binding_event event)
{
    ARG_UNUSED(binding);
    ARG_UNUSED(event);

    battery_indicator_active = true;
    battery_indicator_on = true;
    battery_indicator_color = current_battery_color();
    battery_blinks_remaining = current_battery_blink_count();
    refresh_led_state();
    k_work_reschedule(&battery_led_reset_work, K_MSEC(BATTERY_BLINK_ON_MS));

    return 0;
}

static const struct behavior_driver_api feral_battery_indicator_driver_api = {
    .binding_pressed = on_battery_indicator_pressed,
    .locality = BEHAVIOR_LOCALITY_GLOBAL,
};

static int feral_rgbled_init(void)
{
    if (!leds_ready()) {
        return 0;
    }

    if (gpio_pin_configure_dt(&red_led, GPIO_OUTPUT_INACTIVE) != 0 ||
        gpio_pin_configure_dt(&green_led, GPIO_OUTPUT_INACTIVE) != 0 ||
        gpio_pin_configure_dt(&blue_led, GPIO_OUTPUT_INACTIVE) != 0) {
        return 0;
    }

    battery_indicator_active = false;
    battery_indicator_on = false;
    battery_blinks_remaining = 0;
    status_flash_active = false;
    startup_led_step = 0;
    k_work_init_delayable(&startup_led_work, startup_led_work_handler);
    k_work_init_delayable(&battery_led_reset_work, battery_led_reset_work_handler);
    k_work_init_delayable(&status_flash_reset_work, status_flash_reset_work_handler);
    k_work_schedule(&startup_led_work, K_NO_WAIT);

    return 0;
}

SYS_INIT(feral_rgbled_init, APPLICATION, CONFIG_APPLICATION_INIT_PRIORITY);

#define FERAL_BATTERY_INDICATOR_INST(n)                                                           \
    BEHAVIOR_DT_INST_DEFINE(n, NULL, NULL, NULL, NULL, POST_KERNEL,                             \
                            CONFIG_KERNEL_INIT_PRIORITY_DEFAULT,                                 \
                            &feral_battery_indicator_driver_api);

DT_INST_FOREACH_STATUS_OKAY(FERAL_BATTERY_INDICATOR_INST)

#endif
