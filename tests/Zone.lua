
-- Wherigo.Zone

ZonePoint = Wherigo.ZonePoint


zone = Wherigo.Zone()
zone.Name = "Paloucek"
zone.Points = {
	ZonePoint(49.22741, 16.62242, 0),
	ZonePoint(49.22741, 16.62261, 0),
	ZonePoint(49.22729, 16.62261, 0),
	ZonePoint(49.22729, 16.62242, 0)
}
zone.OriginalPoint = ZonePoint(49.22735, 16.622517, 0)

--for k,v in pairs(zone.Points) do print(k,v) end
-- duno how to test it ...

-- test inheritance


print(zone)
