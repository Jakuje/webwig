
-- Active

-- default value
zone = Wherigo.Zone()
assert(zone.Active == true, "Failed set default value in construct")
zone.Active = false
assert(zone.Active == false, "Failed to update activity status")


zone = Wherigo.ZTask({Active = false})
assert(zone.Active == false, "Failed to set value from construct")
zone.Active = true
assert(zone.Active == true, "Failed to update activity status")


