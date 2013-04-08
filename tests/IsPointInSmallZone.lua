
ZonePoint = Wherigo.ZonePoint
Distance = Wherigo.Distance
cart = Wherigo.ZCartridge()

zoneFinal = Wherigo.Zone(cart)
zoneFinal.Id = "b2ac47c5-6071-4ecc-b00c-8a7aa60a0634"
zoneFinal.Name = "Final"
zoneFinal.Description = "Na tomto miste se nachazi kes Zapomenute Archu Jundrovske."
zoneFinal.Visible = false
zoneFinal.DistanceRange = Distance(1500, "feet")
zoneFinal.ShowObjects = "OnEnter"
zoneFinal.ProximityRange = Distance(200, "feet")
zoneFinal.AllowSetPositionTo = false
zoneFinal.Active = false
zoneFinal.Points = {ZonePoint(49.20919, 16.54267, 0), ZonePoint(49.20919, 16.54277, 0), ZonePoint(49.20913, 16.54277, 0), ZonePoint(49.20913, 16.54267, 0)}
zoneFinal.OriginalPoint = ZonePoint(49.20916, 16.54272, 0)
zoneFinal.DistanceRangeUOM = "Feet"
zoneFinal.ProximityRangeUOM = "Feet"
zoneFinal.OutOfRangeName = ""
zoneFinal.InRangeName = ""
zoneFinal.Media = zmediaarcha


for n = 49.20910, 49.20925, 0.00001 do
	local row = ""
	for e = 16.54260, 16.54280, 0.00001 do
		if Wherigo.IsPointInZone(ZonePoint(n,e,0), zoneFinal) then
			row = row .. "M"
		else
			row = row .. " "
			end
		end
	print(row)
	end
