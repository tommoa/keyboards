list(APPEND DTS_ROOT ${CMAKE_CURRENT_SOURCE_DIR})

if(CONFIG_FERAL_RGBLED_STATUS)
  zephyr_library()
  zephyr_library_include_directories(${APPLICATION_SOURCE_DIR}/include)
  zephyr_library_sources(src/feral_rgbled.c)
endif()
