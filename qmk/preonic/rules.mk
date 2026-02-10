SRC += muse.c

# KVM compatibility: disable console (extra USB endpoint confuses KVMs)
CONSOLE_ENABLE = no

# KVM compatibility: give keyboard its own dedicated USB endpoint
KEYBOARD_SHARED_EP = no

# KVM compatibility: skip USB startup check (KVMs may not respond correctly)
NO_USB_STARTUP_CHECK = yes
