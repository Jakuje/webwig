
-- Wherigo.ZonePoint

point = Wherigo.ZonePoint(49, 16, 230)
assert(point.latitude == 49, "Wrong latitude")
assert(point.longitude == 16, "Wrong longitude")
assert(point.altitude == Wherigo.Distance(230), "Wrong altitude")

point = Wherigo.ZonePoint.new(50, 17, 400)
assert(point.latitude == 50, "Wrong latitude")
assert(point.longitude == 17, "Wrong longitude")
assert(point.altitude == Wherigo.Distance(400), "Wrong altitude")
print(point)
