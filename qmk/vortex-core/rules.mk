# Keep the stock Vortex Core feature set for the initial bring-up build.

# qmk_pok3r predates newer GCC range analysis on the Holtek code path.
OPT_DEFS += -Wno-array-bounds
OPT_DEFS += -Wno-deprecated
OPT_DEFS += -Wno-header-guard
OPT_DEFS += -Wno-stringop-overread
