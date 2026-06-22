class_name NoWallJumpWall extends CSGBox3D

# Marker class for level geometry the player is NOT allowed to wall jump off of.
# Behaves exactly like the standard CSGBox3D level geometry; the player checks
# for this type when attempting a wall jump and rejects it if matched.
# Wall running is unaffected.
