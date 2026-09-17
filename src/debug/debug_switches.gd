class_name DebugSwitches
extends RefCounted
## Debug toggles that live for one launch of the game: never saved, default on every launch.

## He passes through anything solid. Read by Player every physics tick.
static var walk_through := false
## The readout box top-right: day and time, speed, FPS, position.
static var readout := false
## Solid shapes outlined in red.
static var collision_areas := false
## Use areas outlined in blue.
static var use_areas := false
