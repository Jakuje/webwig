
--ComfortZone
cart = Wherigo.ZCartridge()

ZonePoint = Wherigo.ZonePoint

zone = Wherigo.Zone(cart)
zone.Name = "Paloucek"
zone.Points = {
	ZonePoint(49.22741, 16.62242, 0),
	ZonePoint(49.22741, 16.62261, 0),
	ZonePoint(49.22729, 16.62261, 0),
	ZonePoint(49.22729, 16.62242, 0)
}

-- first we are away:
cart._update(ZonePoint(49.2, 16.6, 0), 0, 5)
print(zone.Inside, zone.State, zone.CurrentDistance())
assert(zone.State == 'Distant', "We should be distant")
-- far far away, as I expect

-- we move in zone:
cart._update(ZonePoint(49.22735, 16.622517, 0), 0, 5)
print(zone.Inside, zone.State)
assert(zone.State == 'Inside', "Now we should be inside")

-- we move on one corner and we should stay inside
cart._update(ZonePoint(49.22729, 16.62242, 0), 0, 5)
print(zone.Inside, zone.State, zone.CurrentDistance())
assert(zone.State == 'Inside', "We should stay inside, although we are in corner")

-- mow we move litle bit further and expect staying in zone
cart._update(ZonePoint(49.2272, 16.62235, 0), 0, 5)
print(zone.Inside, zone.State, zone.CurrentDistance())
assert(zone.State == 'Inside', "We should stay inside, although we are away (less then 15 meters)")

-- mow we move further and expect leaving zone to proximity
cart._update(ZonePoint(49.22715, 16.6223, 0), 0, 5)
print(zone.Inside, zone.State, zone.CurrentDistance())
assert(zone.State == 'Proximity', "We should now leave zone (away more then 15 meters)")
