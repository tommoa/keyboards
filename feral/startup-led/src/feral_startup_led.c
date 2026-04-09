#include <zephyr/device.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/init.h>
#include <zephyr/kernel.h>
#include <zephyr/sys/util.h>

#define STARTUP_LED_NODE DT_ALIAS(led0)

#if DT_NODE_HAS_STATUS(STARTUP_LED_NODE, okay)
static const struct gpio_dt_spec startup_led =
    GPIO_DT_SPEC_GET(STARTUP_LED_NODE, gpios);
static struct k_work_delayable startup_led_work;
static uint8_t startup_led_step;

static void startup_led_work_handler(struct k_work *work)
{
    ARG_UNUSED(work);

    if (startup_led_step >= 6) {
        (void)gpio_pin_set_dt(&startup_led, 0);
        return;
    }

    (void)gpio_pin_set_dt(&startup_led, (startup_led_step % 2) == 0);
    startup_led_step++;
    k_work_schedule(&startup_led_work, K_MSEC(120));
}

static int feral_startup_led_init(void)
{
    if (!gpio_is_ready_dt(&startup_led)) {
        return 0;
    }

    if (gpio_pin_configure_dt(&startup_led, GPIO_OUTPUT_INACTIVE) != 0) {
        return 0;
    }

    startup_led_step = 0;
    k_work_init_delayable(&startup_led_work, startup_led_work_handler);
    k_work_schedule(&startup_led_work, K_NO_WAIT);

    return 0;
}

SYS_INIT(feral_startup_led_init, APPLICATION, CONFIG_APPLICATION_INIT_PRIORITY);
#endif
