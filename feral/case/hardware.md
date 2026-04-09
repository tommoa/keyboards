# Feral Case Hardware

These are the working assumptions for the first prototype.

## Fasteners

- PCB mounting holes: `6x M2`, `2.2 mm` hole diameter in `feral/feral.kicad_pcb`
- first prototype strategy: M2 machine screws with captured nuts
- reason: easier to tune in FDM than heat-set inserts for an early prototype

## To be finalized during CAD

- M2 screw length
- nut trap depth and wrench clearance
- whether the screws install from top or bottom
- whether any bosses need washers or counterbores

## Battery

- battery type: `301230`
- nominal size: `30 x 12 x 3 mm`
- battery sits below the JST area and below JST height
- pocket should allow extra room for pouch tolerance, tape, and wire bend radius

## Feet and tenting

- base case should work flat with normal bumpons
- leave flat landing zones on the underside for adhesive feet
- reserve compatibility with TOTEM-style adhesive tenting feet
- exact integrated tenting geometry can come after the base shell fits correctly

## Printing assumptions

- optimize the first revision for FDM
- use forgiving clearances for nut capture and shell mating
- prefer fit and serviceability over cosmetics in v1
