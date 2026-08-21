-- AimMod owns the shared Obsidian instance.  Keeping this forwarding module
-- preserves the gunmod module boundary without creating a second GUI library.
return require("aimmod.Obsidian")
