cart = Wherigo.ZCartridge()
-- Active

-- default value
zone = Wherigo.Zone(cart)
assert(zone.Active == true, "Failed set default value in construct")
zone.Active = false
assert(zone.Active == false, "Failed to update activity status")


zone = Wherigo.Zone({Cartridge = cart, Active = false})
assert(zone.Active == false, "Failed to set value from construct")
zone.Active = true
assert(zone.Active == true, "Failed to update activity status")


