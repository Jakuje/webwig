c = Wherigo.ZCartridge()

ZonePoint = Wherigo.ZonePoint
-- IsPointInZone
-- test simple zone from Certova rokle


insidePoint = Wherigo.ZonePoint(49.22735, 16.622517, 0)
borderPoint = Wherigo.ZonePoint(49.22741, 16.62252, 0)
outsidePoint = Wherigo.ZonePoint(49.22742, 16.62252, 0)

zone = Wherigo.Zone(c)
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


-- Another test ...

zone = Wherigo.Zone(c)
zone.Name = "Paloucek"
zone.Points = {
	ZonePoint(49.2239223286717, 16.5297473967075, 0), 
	ZonePoint(49.2237357655883, 16.5295341610909, 0), 
	ZonePoint(49.2236271557694, 16.5297849476337, 0), 
	ZonePoint(49.2238075880794, 16.530004888773, 0), 
	ZonePoint(49.2238671481148, 16.5299405157566, 0), 
	ZonePoint(49.2238846657585, 16.5298949182034, 0), 
	ZonePoint(49.2239039351595, 16.5298412740231, 0)
}
zone.OriginalPoint = ZonePoint(49.2238212267345, 16.5298211574555, 0)


print( Wherigo.VectorToZone(insidePoint, zone) )
assert( Wherigo.IsPointInZone(insidePoint, zone) == false, "Test 2 failed ... not in zone" )


-- Something around zero

zone = Wherigo.Zone(c)
zone.Name = "Zero"
zone.Points = {
	ZonePoint(-1, 1, 0), 
	ZonePoint(1, 1, 0), 
	ZonePoint(1, -1, 0), 
	ZonePoint(-1, -1, 0)
}
zone.OriginalPoint = ZonePoint(0, 0, 0)

assert( Wherigo.IsPointInZone(ZonePoint(0,0,0), zone) == true, "Inside Is not in zone" )
--assert( Wherigo.IsPointInZone(ZonePoint(1,0,0), zone) == true, "Border Is not in zone" )
--assert( Wherigo.IsPointInZone(ZonePoint(1,1,0), zone) == true, "Point is not in zone " )
assert( Wherigo.IsPointInZone(ZonePoint(2,0,0), zone) == false, "Outside Is in zone" )
assert( Wherigo.IsPointInZone(ZonePoint(0,2,0), zone) == false, "Outside Is in zone" )
assert( Wherigo.IsPointInZone(ZonePoint(-2,0,0), zone) == false, "Outside Is in zone" )


-- Another shape around zero.

zone = Wherigo.Zone(c)
zone.Name = "Zero 2"
zone.Points = {
	ZonePoint(0, 1, 0), 
	ZonePoint(-1, 0, 0), 
	ZonePoint(0, -1, 0), 
	ZonePoint(1, 0, 0)
}
zone.OriginalPoint = ZonePoint(0, 0, 0)

assert( Wherigo.IsPointInZone(ZonePoint(0,0,0), zone) == true, "Inside Is not in zone" )
--assert( Wherigo.IsPointInZone(ZonePoint(1,0,0), zone) == true, "Border Is not in zone" )
assert( Wherigo.IsPointInZone(ZonePoint(1,1,0), zone) == false, "Outside Is in zone" )
assert( Wherigo.IsPointInZone(ZonePoint(1,2,0), zone) == false, "Outside Is in zone" )
assert( Wherigo.IsPointInZone(ZonePoint(-1,-1,0), zone) == false, "Outside Is in zone" )


-- Test around day line
--[[
zone = Wherigo.Zone(c)
zone.Name = "Day Line"
zone.Points = {
	ZonePoint(0, -179, 0), 
	ZonePoint(-1, 180, 0), 
	ZonePoint(0, 179, 0), 
	ZonePoint(1, -180, 0)
}
zone.OriginalPoint = ZonePoint(0, 180, 0)

assert( Wherigo.IsPointInZone(ZonePoint(0,180,0), zone) == true, "Inside Is not in zone" )
--assert( Wherigo.IsPointInZone(ZonePoint(1,0,0), zone) == true, "Border Is not in zone" )
assert( Wherigo.IsPointInZone(ZonePoint(1,179,0), zone) == false, "Outside Is in zone" )
assert( Wherigo.IsPointInZone(ZonePoint(1,-179,0), zone) == false, "Outside Is in zone" ) -- f**k up with special cases ...
assert( Wherigo.IsPointInZone(ZonePoint(-1,-179,0), zone) == false, "Outside Is in zone" )
assert( Wherigo.IsPointInZone(ZonePoint(-1,179,0), zone) == false, "Outside Is in zone" )
assert( Wherigo.IsPointInZone(ZonePoint(2,180,0), zone) == false, "Outside Is in zone" )
]] 

















