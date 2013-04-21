
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
-- accuracy is 15 meters, so comfortZone is 7 meters


-- first we are away:
cart._update(ZonePoint(49.2, 16.6, 0), 0, 15)
print(zone.Inside, zone.State, zone.CurrentDistance())
assert(zone.State == 'Distant', "We should be distant")
-- far far away, as I expect

-- we move in zone:
cart._update(ZonePoint(49.22735, 16.622517, 0), 0, 15)
print(zone.Inside, zone.State)
assert(zone.State == 'Inside', "Now we should be inside")

-- we move on one corner and we should stay inside
cart._update(ZonePoint(49.22729, 16.62242, 0), 0, 15)
print(zone.Inside, zone.State, zone.CurrentDistance())
assert(zone.State == 'Inside', "We should stay inside, although we are in corner")

-- now we move litle bit further and expect staying in zone
cart._update(ZonePoint(49.227239294843955, 16.622391740501488, 0), 0, 15)
print(zone.Inside, zone.State, zone.CurrentDistance())
assert(zone.State == 'Inside', "We should stay inside, although we are away (less then 7 meters)")

-- now we move further and expect leaving zone to proximity
cart._update(ZonePoint(49.22678294812927, 16.6221374076249, 0), 0, 15)
print(zone.Inside, zone.State, zone.CurrentDistance())
assert(zone.State == 'Proximity', "We should now leave zone (away about 60 meters)")

-- now we move further and expect leaving zone to proximity
cart._update(ZonePoint(49.22673224290429, 16.622109148706393, 0), 0, 15)
print(zone.Inside, zone.State, zone.CurrentDistance())
assert(zone.State == 'Proximity', "Now we should stay in Proximity (away about 60 meters + 6 for comfortZone)")

-- We leave it and stay in distance
cart._update(ZonePoint(49.22669843941712, 16.62209030945961, 0), 0, 15)
print(zone.Inside, zone.State, zone.CurrentDistance())
assert(zone.State == 'Distant', "Now we should leave proximity and stay in distance (about 70 meters)")



