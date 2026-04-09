if(CONFIG_FERAL_STARTUP_LED_BLINK)
  zephyr_library()
  zephyr_library_sources(src/feral_startup_led.c)
endif()
