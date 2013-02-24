
-- IsPointInZone

insidePoint = Wherigo.ZonePoint(49.22735, 16.622517, 0)
borderPoint = Wherigo.ZonePoint(49.22741, 16.62252, 0)
outsidePoint = Wherigo.ZonePoint(49.22742, 16.62252, 0)

zone = Wherigo.Zone()
zone.Name = "Paloucek"
zone.Points = {
	Wherigo.ZonePoint(49.22741, 16.62242, 0),
	Wherigo.ZonePoint(49.22741, 16.62261, 0),
	Wherigo.ZonePoint(49.22729, 16.62261, 0),
	Wherigo.ZonePoint(49.22729, 16.62242, 0)
}

zone.OriginalPoint = Wherigo.ZonePoint(49.22735, 16.622517, 0)


assert(Wherigo.IsPointInZone(insidePoint, zone) == true, "Inside point wrongly recognised")
assert(Wherigo.IsPointInZone(borderPoint, zone) == false, "Border point wrongly recognised")
assert(Wherigo.IsPointInZone(outsidePoint, zone) == false, "Outside point wrongly recognised")

